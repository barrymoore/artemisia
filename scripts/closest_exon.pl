#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
use Storable;

use Arty::Utils qw(:all);
use Arty::GFF3;
use Arty::vIQ_List;
use Arty::Skeleton;

#-----------------------------------------------------------------------------
#----------------------------------- MAIN ------------------------------------
#-----------------------------------------------------------------------------

my $usage = "

Synopsis:

closest_cds.pl viq_list_file.txt genes.gff3

Description:

Annotate vIQ list and skeletion files with the distance to the
closest CDS within the VVP transcript OR for all mRNAs within a 10KB
window if the transcript is NONE.  If the variant is scored against a
transcript that is not found in the mRNA lookup from the GFF3 file the
distance is set to null.

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

  --format, -f viq_list

    The format of the provided data file.  This can be one of:
      viq_list: A vIQ input list file.
      skeleton: A vIQ skeleton file.

  --range, -r 10000

    The range within which to look for neighboring genes to provide
    distance measurements to.  Default is 10000

  --max_dist, -m 10000

    Skip records that have distance > max_distance to closest CDS
    neighbor.  Default is 10000

";

my %SEEN;
my $ROW_COUNT = 1;

my ($help, $format, $RANGE, $MAX_DIST);
my $opt_success = GetOptions('help|h'       => \$help,
                             'format|f=s'   => \$format,
                             'range|r=i'    => \$RANGE,
                             'max_dist|m=i' => \$MAX_DIST,
    );

die $usage if $help || ! $opt_success;

$format   ||= 'viq_list';
$RANGE    ||= 10000;
$MAX_DIST ||= 10000;

if ($MAX_DIST <= $RANGE) {
    $MAX_DIST = $RANGE + 1;
    print STDERR "INFO : resetting_max_dist : max_dist cannot by <= range; resetting max_dist=$MAX_DIST\n";
}

my ($data_file, $gff3_file) = @ARGV;
die $usage unless $data_file && $gff3_file;

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

# my $file_descriptor = $data_file =~ /\.gz$/ ? "gunzip -c $data_file |" : "< $data_file";
# open(my $IN, $file_descriptor) || die "FATAL : cant_open_file_for_reading : $data_file\n";
# 
# print join "\t", qw(#chrom pos end id vid vvp_gene transcript type
#                     parentage zygosity phevor coverage vvp_hemi
#                     vvp_het vvp_hom clinvar chrom_code gnomad_af
#                     vaast_dom_p vaast_rec_p distance alt_count
#                     gnomad_code gq csq);
# print "\n";

my $parser;

if ($format eq 'viq_list') {
        $parser = Arty::vIQ_List->new(file => $data_file);
}
elsif ($format eq 'skeleton') {
        $parser = Arty::Skeleton->new(file => $data_file);
}
else {
        die "FATAL : invavlid_format : $format\n";
}

print '#';
print join "\t", $parser->columns();
print "\n";

my $row_count = 1;
my %seen;
 LINE:
    while (my $record = $parser->next_record) {
        # if ($line =~ /^\#/) {
        #     # print $line;
        #     next LINE;
        # }
        # 
        # chomp $line;
        # 
        # my %record;
        # @record{qw(chrom pos end id vid vvp_gene transcript type parentage
	# 	   zygosity phevor coverage vvp_hemi vvp_het vvp_hom
	# 	   clinvar chrom_code gnomad_af vaast_dom_p vaast_rec_p
	# 	   distance alt_count gnomad_code gq csq)} = split /\t/, $line;

        my $distance = \$record->{distance};
	$$distance = 1 if ($$distance eq 'null' || ! length($$distance));  #  Take this out after sv2viq update 11/22/19
        my $chrom    = \$record->{chrom};

        # Flag to determine if record was printed.
        my $printed;

        # * Rule #1
        #     * If the variant is annotated as coding by VVP,
        #     * Then the distance value is 0.
        if ($$distance eq '0') {
            $printed++;
            print_record($record, $format);
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
               exists $mrnas->{ids}{$record->{transcript}}) {
            my $mrna = $mrnas->{ids}{$record->{transcript}};
            $$distance = get_cds_distance($record, $mrna);
            $printed++;
            print_record($record, $format);
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
               $record->{transcript} eq 'NONE') {

            # Default distance when transcript ID is 'NONE'
            $$distance = $RANGE + 1;

            # Set up 10KB range around variant
            my $range_start = $record->{pos} - $RANGE;
            $range_start = 1 if $range_start < 1;
            my $range_end = $record->{pos} + $RANGE;

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
                $record->{transcript}  = $mrna->{attributes}{ID}[0];
                $record->{gene}        = $mrna->{attributes}{Parent}[0];
                if (exists $record->{vaast_rec_p}) {
                        $record->{vaast_rec_p} = 'null';
                }
                if (exists $record->{vaast_dom_p}) {
                        $record->{vaast_dom_p} = 'null';
                }

                $$distance = get_cds_distance($record, $mrna);
		last MRNA if $$distance > $MAX_DIST;
                $printed++;
                print_record($record, $format);
                next MRNA;
            }

            # If no other mRNAs printed the record then make sure we print
            # it here so it's not lost
            if (! $printed) {
                if (exists $record->{vaast_rec_p}) {
                        $record->{vaast_rec_p} = 'null';
                }
                if (exists $record->{vaast_dom_p}) {
                        $record->{vaast_dom_p} = 'null';
                }
                $printed++;
                print_record($record, $format);
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
                if (exists $record->{vaast_rec_p}) {
                        $record->{vaast_rec_p} = 'null';
                }
                if (exists $record->{vaast_dom_p}) {
                        $record->{vaast_dom_p} = 'null';
                }
            $record->{distance}    = $RANGE + 1;
            $printed++;
            print_record($record, $format);
            print '';
        }
        print '';
}

#-----------------------------------------------------------------------------
#------------------------------- SUBROUTINES ---------------------------------
#-----------------------------------------------------------------------------

sub print_record {

        my ($record, $format) = @_;

        if ($format eq 'viq_list') {
                print_list_record($record);
        }
        elsif ($format eq 'skeleton') {
                print_skeleton_record($record);
        }
        else {
                die "FATAL : invavlid_format : $format\n";
        }
        print '';
}

#-----------------------------------------------------------------------------

sub print_list_record {

    my ($record) = @_;

    # Skip records that have distance > $MAX_DIST
    return if $record->{distance} > $MAX_DIST;

    my $key = join ':', @{$record}{qw(chrom pos end vid vvp_gene
                                      transcript type parentage
                                      zygosity phevor coverage
                                      vvp_hemi vvp_het vvp_hom clinvar
                                      chrom_code gnomad_af vaast_dom_p
                                      vaast_rec_p distance
                                      alt_count gnomad_code gq csq)};

        if (! $SEEN{$key}++) {
            $record->{rid} = sprintf("%08d", $ROW_COUNT++);

            print join "\t", @{$record}{qw(chrom pos end rid vid vvp_gene
                                           transcript type parentage
                                           zygosity phevor coverage
                                           vvp_hemi vvp_het vvp_hom
                                           clinvar chrom_code
                                           gnomad_af vaast_dom_p
                                           vaast_rec_p distance
                                           alt_count gnomad_code gq csq)};

            print "\n";
        }
}

#-----------------------------------------------------------------------------

sub print_skeleton_record {

    my $record = shift @_;

    # Skip records that have distance > $MAX_DIST
    return if $record->{distance} > $MAX_DIST;

    my $key = join ':', @{$record}{qw(chrom pos end ref alt gene transcript csq_so
                                      overlap distance af)};

        if (! $SEEN{$key}++) {
            $record->{rid} = sprintf("%08d", $ROW_COUNT++);

            print join "\t", @{$record}{qw(chrom pos end ref alt gene transcript csq_so
                                           overlap distance af)};

            print "\n";
            print '';
        }
}

#-----------------------------------------------------------------------------

sub get_cds_distance {

    my ($record, $mrna) = @_;

    my $rcd_chrom  = $record->{chrom};
    my $rcd_pos    = $record->{pos};
    my $rcd_end    = $record->{end};
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
        if ($cds->{start} >= $rcd_end) {
            $distance = $cds->{start} - $rcd_end;
            last CDS;
        }
	# If variant overlaps the CDS then distance = 0
        # and exit CDS loop as per Rule #2
        elsif ($cds->{start} <= $rcd_end && $cds->{end} >= $rcd_pos) {
            $distance = 0;
            last CDS;
        }
        # Else set distance, but keep loop to look for a shorter
        # distance as per Rule #3.
        elsif ($cds->{end} < $rcd_pos) {
            $distance = ($rcd_pos - $cds->{end} < $distance ?
                         $rcd_pos - $cds->{end} :
                         $distance);
        }
        elsif ($cds->{start} > $rcd_end) {
            $distance = ($cds->{start} - $rcd_end < $distance ?
                         $cds->{start} - $rcd_end :
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
