#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
use Storable;

use GAL::Annotation;
use Arty::Utils qw(:all);
use Arty::GFF3;

#-----------------------------------------------------------------------------
#----------------------------------- MAIN ------------------------------------
#-----------------------------------------------------------------------------

my $usage = "

Synopsis:

closest_cds.pl viq_list_file.txt genes.gff3

Description:

Annotate a vIQ List file with the distance to the closest CDS within
the VVP transcript OR for all mRNAs within a 10KB window if the
transcript is NONE.  If the variant is scored against a transcript
that is not found in the mRNA lookup from the GFF3 file the distance
is set to null.

 * Rule #1
     * If the variant is annotated as coding by VVP,
     * Then the distance value is 0.

 * Rule #2
     * If the variant is annotated as noncoding by VVP,
     * And the VVP transcript is found in the GFF3 file,
     * And the variant overlaps the CDS portion of the scored VVP
       transcript,
     * Then the distance value is 1.

 * Rule #3
     * If the variant is annotated as noncoding by VVP,
     * And the VVP transcript is found in the GFF3 file,
     * And the variant overlaps the non-CDS portion of the scored
       VVP transcript,
     * Then the distance is set to the distance to the nearst CDS within
       that transcript.

 * Rule #4
     * If the variant is annotated as noncoding by VVP,
     * And the variant is annotated with transcript 'NONE',
     * And the variant lies <= RANGE (10KB) from an mRNA from the GFF3 file,
     * Then the distance is set to the closest coding nucleotide in
       each mRNA within the RANGE * 2 (10KB * 2) window,
     * And the VVP gene and mRNA IDs are set accordingly,
     * And VAAST scores are set to null.

 * Rule #5
     * If the variant is annotated as noncoding by VVP,
     * And the variant is annotated to transcript 'NONE',
     * And the variant lies > RANGE (10KB) from an mRNA in the GFF3
       file,
     * Then the distance is set to RANGE + 1 (10,001),
     * And VAAST scores are set to null.

 * Rule #6
     * If the variant is annotated as noncoding by VVP
     * And the VVP transcript is NOT found in the mRNA lookup from
       the GFF3 file,
     * Then the distance is set to 'null'.

Options:

  --range, -r 10000

    The range within which to look for neighboring genes to provide
    distance measurements to.  Default is 10000

  --max_dist, -m 10000

    Skip records that have distance > max_distance to closest CDS
    neighbor.  Default is 10000

";

my %SEEN;
my $ROW_COUNT = 1;

my ($help, $RANGE, $MAX_DIST);
my $opt_success = GetOptions('help|h'       => \$help,
                             'range|r=i'    => \$RANGE,
                             'max_dist|m=i' => \$MAX_DIST,
    );

die $usage if $help || ! $opt_success;

$RANGE    ||= 10000;
$MAX_DIST ||= 10000;

my ($list_file, $gff3_file) = @ARGV;
die $usage unless $list_file && $gff3_file;

my $gff3_store = $gff3_file . '.stor';

if (! -e $gff3_store ||
    (stat($gff3_file))[9] > (stat($gff3_store))[9]) {

    my $gff3 = Arty::GFF3->new(file => $gff3_file);

    my %mrnas;
    my %mapped_cds;
  RECORD:
    while (my $record = $gff3->next_record) {
        if ($record->{type} eq 'mRNA') {
            $record->{attributes}{ID}[0] =~ s/^transcript://;
            $record->{attributes}{Parent}[0] =~ s/^gene://;
            push @{$mrnas{chrs}{$record->{chrom}}}, $record;
            $mrnas{ids}{$record->{attributes}{ID}[0]} = $record
        }
        elsif ($record->{type} eq 'CDS') {
            $record->{attributes}{Parent}[0] =~ s/^transcript://;
            next RECORD unless exists $record->{attributes}{Parent} &&
                defined $record->{attributes}{Parent}[0];
            my $parent = $record->{attributes}{Parent}[0];
            push @{$mapped_cds{$parent}}, $record;
            print '';
        }
        print '';
    }

    for my $chrom (keys %{$mrnas{chrs}}) {
        my $chrom_mrnas = $mrnas{chrs}{$chrom};
        for my $mrna (@{$chrom_mrnas}) {
            my $id = $mrna->{attributes}{ID}[0];
            $mrna->{CDS} = $mapped_cds{$id} || [];
        }
    }
    store \%mrnas, $gff3_store;
}

my $mrnas = retrieve($gff3_store);

my $file_descriptor = $list_file =~ /\.gz$/ ? "gunzip -c $list_file |" : "< $list_file";
open(my $IN, $file_descriptor) || die "FATAL : cant_open_file_for_reading : $list_file\n";

my $row_count = 1;
my %seen;
 LINE:
    while (my $line = <$IN>) {
        if ($line =~ /^\#/) {
            print $line;
            next LINE;
        }

        chomp $line;

        my %record;
        @record{qw(chrom pos rid vid vvp_gene transcript type parentage
               zygosity phevor coverage vvp_hemi vvp_het vvp_hom
               clinvar chrom_code gnomad_af vaast_dom_p vaast_rec_p
               distance alt_count gnmd_code)} = split /\t/, $line;
        my $distance = \$record{distance};
        my $chrom    = \$record{chrom};

        # Flag to determine if record was printed.
        my $printed;

        # * Rule #1
        #     * If the variant is annotated as coding by VVP,
        #     * Then the distance value is 0.
        if ($$distance eq '0') {
            $printed++;
            print_record(\%record);
            next LINE;
        }
        # * Rule #2
        #     * If the variant is annotated as noncoding by VVP,
        #     * And the VVP transcript is found in the GFF3 file,
        #     * And the variant overlaps the CDS portion of the scored VVP
        #       transcript,
        #     * Then the distance value is 1.
        # * Rule #3
        #     * If the variant is annotated as noncoding by VVP,
        #     * And the VVP transcript is found in the GFF3 file,
        #     * And the variant overlaps the non-CDS portion of the scored
        #       VVP transcript,
        #     * Then the distance value is the distance to the nearst CDS within
        #       that transcript.
        elsif ($$distance eq '1' &&
               exists $mrnas->{ids}{$record{transcript}}) {
            my $mrna = $mrnas->{ids}{$record{transcript}};
            $$distance = get_cds_distance(\%record, $mrna);
            $printed++;
            print_record(\%record);
            next LINE;
        }
        # * Rule #4
        #     * If the variant is annotated as noncoding by VVP,
        #     * And the variant is annotated with transcript 'NONE',
        #     * And the variant lies <= 10KB from an mRNA from the GFF3 file,
        #     * Then the distance is set to the closest coding
        #       nucleotide in each mRNA within the 10KB window,
        #     * And the VVP gene and mRNA IDs are set accordingly,
        #     * And VAAST scores are set to null.
        # * Rule #5
        #     * If the variant is annotated as noncoding by VVP,
        #     * And the variant is annotated to transcript 'NONE',
        #     * And the variant lies > 10KB from an mRNA in the GFF3 file,
        #     * Then the distance is set to 10001,
        #     * And VAAST scores are set to null.
        elsif ($$distance eq '1' &&
               $record{transcript} eq 'NONE') {

            # Default distance when transcript ID is 'NONE'
            $$distance = $RANGE + 1;

            # Set up 10KB range around variant
            my $range_start = $record{pos} - $RANGE;
            $range_start = 1 if $range_start < 1;
            my $range_end = $record{pos} + $RANGE;

            # Remove mrnas from list that are behind us
          TRIM_MRNA:
            while (defined $mrnas->{chrs}{$$chrom}[0] &&
                   $mrnas->{chrs}{$$chrom}[0]{end} < $range_start) {
                shift @{$mrnas->{chrs}{$$chrom}};
            }

          MRNA:
            for my $idx (0 .. $#{$mrnas->{chrs}{$$chrom}}) {
                # If mrna start is beyond range_end then quit looking
                # Print variant and bail.
                my $mrna = $mrnas->{chrs}{$$chrom}[$idx];
                # Reset record values for current mRNA.
                $record{transcript}  = $mrna->{attributes}{ID}[0];
                $record{vvp_gene}    = $mrna->{attributes}{Parent}[0];
                $record{vaast_rec_p} = 'null';
                $record{vaast_dom_p} = 'null';

                $$distance = get_cds_distance(\%record, $mrna);
                $printed++;
                print_record(\%record);
                next MRNA;
            }

            # If no other mRNAs printed the record then make sure we print
            # it here so it's not lost
            if (! $printed) {
                $record{vaast_rec_p} = 'null';
                $record{vaast_dom_p} = 'null';
                $printed++;
                print_record(\%record);
            }
            next LINE;
        }

        # If no other rules printed the record then make sure we print
        # it here so it's not lost (or is skipped in > MAX_DISTANCE
        # * Rule #6
        #     * If the variant is annotated as noncoding by VVP
        #     * And the VVP transcript is NOT found in the mRNA lookup from
        #       the GFF3 file,
        #     * Then the distance is set to $RANGE + 1.
        if (! $printed) {
            $record{vaast_rec_p} = 'null';
            $record{vaast_dom_p} = 'null';
            $record{distance}    = $RANGE + 1;
            $printed++;
            print_record(\%record);
        }
        print '';
}

#-----------------------------------------------------------------------------
#------------------------------- SUBROUTINES ---------------------------------
#-----------------------------------------------------------------------------

sub print_record {

    my $record = shift @_;

    # Skip records that have distance > $MAX_DIST
    return if $record->{distance} >= $MAX_DIST;

    my $key = join ':', @{$record}{qw(chrom pos vid vvp_gene
                                      transcript type parentage
                                      zygosity phevor coverage
                                      vvp_hemi vvp_het vvp_hom clinvar
                                      chrom_code gnomad_af vaast_dom_p
                                      vaast_rec_p distance
                                      alt_count gnmd_code)};

        if (! $SEEN{$key}++) {
            $record->{rid} = sprintf("%08d", $ROW_COUNT++);

            print join "\t", @{$record}{qw(chrom pos rid vid vvp_gene
                                           transcript type parentage
                                           zygosity phevor coverage
                                           vvp_hemi vvp_het vvp_hom
                                           clinvar chrom_code
                                           gnomad_af vaast_dom_p
                                           vaast_rec_p distance
                                           alt_count gnmd_code)};

            print "\n";
        }
}

#-----------------------------------------------------------------------------

sub get_cds_distance {

    my ($record, $mrna) = @_;

    my $rcd_chrom  = $record->{chrom};
    my $rcd_pos    = $record->{pos};
    my $mrna_chrom = $mrna->{chrom};

    if ($rcd_chrom ne $mrna_chrom) {
        my $rcd_txt = join ',', @{$record}{qw(chrom pos rid vid)};
        die("FATAL : mismatched_chromosomes_in_get_cds_distance : " .
            "mRNA=$mrna_chrom, record=$rcd_txt\n");
    }

    my $mrna_length = $mrna->{end} - $mrna->{start};
    my $distance = $RANGE + 1;

  CDS:
    for my $cds (@{$mrna->{CDS}}) {
        # If CDS start is past variant POS then set distance
        # and exit CDS loop
        if ($cds->{start} >= $rcd_pos) {
            $distance = ($cds->{start} - $rcd_pos < $distance ?
                         $cds->{start} - $rcd_pos :
                         $distance);
            last CDS;
        }
        # If variant POS is contained in CDS then distance = 1
        # and exit CDS loop as per Rule #2
        elsif ($cds->{start} <= $rcd_pos && $cds->{end} >= $rcd_pos) {
            $distance = 1;
            last CDS;
        }
        # Else set distance, but keep loop to look for a shorter
        # distance as per Rule #3.
        elsif ($cds->{end} <= $rcd_pos) {
            $distance = ($rcd_pos - $cds->{end} < $distance ?
                         $rcd_pos - $cds->{end} :
                         $distance);
        }
        else {
            my $rcd_txt = join ',', @{$record}{qw(chrom pos rid vid)};
            my $mrna_txt = join ',', @{$mrna}{qw(chrom start end id)};
            die "FATAL : overlap_cds_error : record=$rcd_txt mRNA=$mrna_txt\n"
        }
    }

    return $distance;
}
