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

closest_exon.pl viq_list_file.txt genes.gff3

Description:

Annotate vIQ list and skeletion files with the distance to the closest
CDS for variants within an mRNA, to the nearest exon for variants
within ncRNA or to the nearest exon/CDS for intergenic variants.  If
the variant overlaps a transcript that is not found in the provided
GFF3 file (that shouldn't happen) the distance is set to null.

 * Rule #1 (Believe existing distance=0)
     * If the variant has a distance value of 0,
     * Then the distance value is 0.
     * Next.
 * Rule #2 (Overlap of exon/CDS distance = 0)
     * If the variant has a distance value of 1 (annotated as
       noncoding by VVP or polish_skeleton.pl)
     * And the annotated transcript is an mRNA in the GFF3 file,
       * And the variant overlaps the CDS portion of the mRNA,
     * Or the annotated transcript is an ncRNA in the GFF3 file,
       * Ant the variant overlaps the exon portion of the transcript,
     * Then the distance value is 0.
     * Next.

 * Rule #3 (Distance to nearest exon/CDS within transcript)
     * If the variant has a distance value of 1 (annotated as
       noncoding by VVP or polish_skeleton.pl),
     * And the variant overlaps the non-exon/CDS portion of the transcript,
     * Then the distance is set to the distance to the nearst exon/CDS
       within THAT transcript.
     * Next.

 * Rule #4 (Distance to nearest exon/CDS within nearby transcripts)
     * If the variant has a distance value of 1 (annotated as
       noncoding by VVP or polish_skeleton.pl),
     * And the variant is annotated by with transcript 'NONE',
     * And the variant lies <= RANGE (2KB) from an exon (CDS for mRNA)
       in the GFF3 file
     * Then the distance is set to the nearest exon/CDS
       within the RANGE * 2 (2KB * 2) window,
     * And gene and mRNA IDs are set accordingly,
     * And VAAST scores (list files only) are set to null.

 * Rule #5 (Max distance for isolated intergenic variants)
     * If the variant has a distance value of 1 (annotated as
       noncoding by VVP or polish_skeleton.pl),
     * And the variant is annotated to transcript 'NONE',
     * And the variant lies > RANGE (2KB) from a exon/CDS in the GFF3
       file,
     * Then the distance is set to RANGE + 1 (10,001),
     * And VAAST scores (list files only) are set to null.

 * Rule #6 (NULL if transcript not found - should never happen)
     * If the variant has a distance value of 1 (annotated as
       noncoding by VVP or polish_skeleton.pl),
     * And the transcript is NOT set to 'NONE' AND is NOT
       found in the GFF3 
     * Then the distance is set to RANGE + 1.

Options:

  --format, -f viq_list

    The format of the provided data file.  This can be one of:
      viq_list: A vIQ input list file.
      skeleton: A vIQ skeleton file.

  --range, -r 2000

    The range within which to look for neighboring genes to provide
    distance measurements to.  Default is 2000

  --max_dist, -m 10000

    Skip records that have distance > max_distance to closest gene
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
$RANGE    ||= 2000;
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

        my %transcripts;
        my %mapped_exon;
        my %seen_mRNAs;
      RECORD:
        while (my $record = $gff3->next_record) {
                # Store transcripts
                if ($record->{type} =~ /^(mRNA|snRNA|snoRNA)$/) {
                        $record->{attributes}{ID}[0] =~ s/^transcript://;
                        $record->{attributes}{Parent}[0] =~ s/^gene://;
                        push @{$transcripts{chrs}{$record->{chrom}}}, $record;
                        $transcripts{ids}{$record->{attributes}{ID}[0]} = $record;
                        $seen_mRNAs{$record->{attributes}{ID}[0]}++ if $record->{type} eq 'mRNA';
                }
                # Store CDSs (will only happen for mRNA)
                elsif ($record->{type} eq 'CDS') {
                        $record->{attributes}{Parent}[0] =~ s/^transcript://;
                        next RECORD unless exists $record->{attributes}{Parent} &&
                          defined $record->{attributes}{Parent}[0];
                        my $parent = $record->{attributes}{Parent}[0];
                        push @{$mapped_exon{$parent}}, $record;
                        print '';
                }
                # Store exons...
                elsif ($record->{type} eq 'exon') {
                        $record->{attributes}{Parent}[0] =~ s/^transcript://;
                        #...only for ncRNAs
                        if (! exists $seen_mRNAs{$record->{attributes}{Parent}[0]}) {
                                next RECORD unless exists $record->{attributes}{Parent} &&
                                  defined $record->{attributes}{Parent}[0];
                                my $parent = $record->{attributes}{Parent}[0];
                                push @{$mapped_exon{$parent}}, $record;
                                print '';
                        }
                }
                print '';
        }


        for my $chrom (keys %{$transcripts{chrs}}) {
                my $chrom_transcripts = $transcripts{chrs}{$chrom};
                for my $transcript (@{$chrom_transcripts}) {
                        my $id = $transcript->{attributes}{ID}[0];
                        $transcript->{exon} = $mapped_exon{$id} || [];
                }
        }
        store \%transcripts, $gff3_store;
}

my $transcripts = retrieve($gff3_store);

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
        my $distance = \$record->{distance};

        # Default distance is 1
        $$distance = 1 if ($$distance eq 'null' || ! length($$distance));  #  Take this out after sv2viq update 11/22/19
        my $chrom    = \$record->{chrom};

        # Flag to determine if record was printed.
        my $printed;

        #  * Rule #1 (Believe existing distance=0)
        #      * If the variant has a distance value of 0,
        #      * Then the distance value is 0.
        #      * Next.
        if ($$distance eq '0') {
                $printed++;
                print_record($record, $format);
        }
        #  * Rule #2 (Overlap of exon/CDS distance = 0)
        #      * If the variant has a distance value of 1 (annotated as
        #        noncoding by VVP or polish_skeleton.pl)
        #      * And the annotated transcript is an mRNA in the GFF3 file,
        #        * And the variant overlaps the CDS portion of the mRNA,
        #      * Or the annotated transcript is an ncRNA in the GFF3 file,
        #        * Ant the variant overlaps the exon portion of the transcript,
        #      * Then the distance value is 0.
        #      * Next.
        # 
        #  * Rule #3 (Distance to nearest exon/CDS within transcript)
        #      * If the variant has a distance value of 1 (annotated as
        #        noncoding by VVP or polish_skeleton.pl),
        #      * And the variant overlaps the non-exon/CDS portion of the transcript,
        #      * Then the distance is set to the distance to the nearst exon/CDS
        #        within THAT transcript.
        #      * Next.
        elsif (exists $transcripts->{ids}{$record->{transcript}}) {
                my $transcript = $transcripts->{ids}{$record->{transcript}};
                $$distance = get_exon_distance($record, $transcript);
                $printed++;
                print_record($record, $format);
        }
        #  * Rule #4 (Distance to nearest exon/CDS within nearby transcripts)
        #      * If the variant has a distance value of 1 (annotated as
        #        noncoding by VVP or polish_skeleton.pl),
        #      * And the variant is annotated by with transcript 'NONE',
        #      * And the variant lies <= RANGE (2KB) from an exon (CDS for mRNA)
        #        in the GFF3 file
        #      * Then the distance is set to the nearest exon/CDS
        #        within the RANGE * 2 (2KB * 2) window,
        #      * And gene and mRNA IDs are set accordingly,
        #      * And VAAST scores (list files only) are set to null.
        # 
        #  * Rule #5 (Max distance for isolated intergenic variants)
        #      * If the variant has a distance value of 1 (annotated as
        #        noncoding by VVP or polish_skeleton.pl),
        #      * And the variant is annotated to transcript 'NONE',
        #      * And the variant lies > RANGE (2KB) from a exon/CDS in the GFF3
        #        file,
        #      * Then the distance is set to RANGE + 1 (10,001),
        #      * And VAAST scores (list files only) are set to null.
        elsif ($record->{transcript} eq 'NONE') {

                # Default distance when transcript ID is 'NONE'
                $$distance = $RANGE + 1;

                # Set up range around variant
                my $range_start = $record->{pos} - $RANGE;
                $range_start = 1 if $range_start < 1;
                my $range_end = $record->{pos} + $RANGE;
                # Remove transcripts from list that are behind us
              TRIM_TRANSCRIPT:
                while (defined $transcripts->{chrs}{$$chrom}[0] &&
                       $transcripts->{chrs}{$$chrom}[0]{end} < $range_start) {
                        shift @{$transcripts->{chrs}{$$chrom}};
                }

              TRANSCRIPT:
                for my $idx (0 .. $#{$transcripts->{chrs}{$$chrom}}) {
                        # If transcript start is beyond range_end then quit looking
                        # Print variant and bail.
                        my $transcript = $transcripts->{chrs}{$$chrom}[$idx];
                        # Reset record values for current transcript.
                        $record->{transcript}  = $transcript->{attributes}{ID}[0];
                        $record->{gene}        = $transcript->{attributes}{Parent}[0];
                        if (exists $record->{vaast_rec_p}) {
                                $record->{vaast_rec_p} = 'null';
                        }
                        if (exists $record->{vaast_dom_p}) {
                                $record->{vaast_dom_p} = 'null';
                        }

                        $$distance = get_exon_distance($record, $transcript);
                        last TRANSCRIPT if $$distance > $MAX_DIST;
                        $printed++;
                        print_record($record, $format);
                        next TRANSCRIPT;
                }

                # If no other transcripts printed the record then make sure we print
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
        }
        else {
                #  * Rule #6 (NULL if transcript not found - should never happen)
                #      * If the variant has a distance value of 1 (annotated as
                #        noncoding by VVP or polish_skeleton.pl),
                #      * And the transcript is NOT set to 'NONE' AND is NOT
                #        found in the GFF3 file,
                #      * Then the distance is set to $RANGE + 1.
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
                next LINE;
        }

        if (! $printed) {
                # This is just a stop gap, but should never happen
                my $var_text = join ':', @{$record}{qw(chrom pos)};
                $var_text .= " ($record->{var_id})";
                die "FATAL : variant_failed_to_print : $var_text\n";
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

sub get_exon_distance {

    my ($record, $transcript) = @_;

    my $rcd_chrom  = $record->{chrom};
    my $rcd_pos    = $record->{pos};
    my $rcd_end    = $record->{end};
    my $transcript_chrom = $transcript->{chrom};

    if ($rcd_chrom ne $transcript_chrom) {
        my $rcd_txt = join ',', @{$record}{qw(chrom pos rid vid)};
        die("FATAL : mismatched_chromosomes_in_get_exon_distance : " .
            "transcript=$transcript_chrom, record=$rcd_txt\n");
    }

    my $transcript_length = $transcript->{end} - $transcript->{start};
    my $distance = $RANGE + 1;

  EXON:
    for my $exon (@{$transcript->{exon}}) {
        # If EXON start is past variant POS then set distance
        # and exit EXON loop
        if ($exon->{start} >= $rcd_end) {
            $distance = $exon->{start} - $rcd_end;
            last EXON;
        }
        # If variant overlaps the EXON then distance = 0
        # and exit EXON loop as per Rule #2
        elsif ($exon->{start} <= $rcd_end && $exon->{end} >= $rcd_pos) {
            $distance = 0;
            last EXON;
        }
        # Else set distance, but keep loop to look for a shorter
        # distance as per Rule #3.
        elsif ($exon->{end} < $rcd_pos) {
            $distance = ($rcd_pos - $exon->{end} < $distance ?
                         $rcd_pos - $exon->{end} :
                         $distance);
        }
        elsif ($exon->{start} > $rcd_end) {
            $distance = ($exon->{start} - $rcd_end < $distance ?
                         $exon->{start} - $rcd_end :
                         $distance);
        }
        else {
            my $rcd_txt = join ',', @{$record}{qw(chrom pos rid vid)};
            my $transcript_txt = join ',', @{$transcript}{qw(chrom start end id)};
            die "FATAL : overlap_exon_error : record=$rcd_txt transcript=$transcript_txt\n"
        }
    }
    return $distance;
}
