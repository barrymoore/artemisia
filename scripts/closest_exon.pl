#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
use Storable;
use Fcntl qw(:flock);

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
       * And the variant overlaps the exon portion of the transcript,
     * Then the distance value is set to 0.
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
     * And the variant is annotated by VVP with transcript 'NONE',
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
      viq_list        : A vIQ input list file.
      viq_list_payload: A vIQ input list file with an additional 26th
                        data payload column
      skeleton        : A vIQ skeleton file.

  --range, -r 2000

    The range within which to look for neighboring genes to provide
    distance measurements to.  Default is 2000

  --max_dist, -m 10000

    Skip records that have distance > max_distance to closest gene
    neighbor.  Default is 10000

  --mrnas, -a [mRNA,transcript]

    Proviced a comma separated list of SO terms for supported coding
    RNA types.  Default is mRNA (used by Ensembl and RefSeq) and
    transcript (used by MANE and Gencode).  Provided values will
    overwrite defaults.

  --ncrnas, -n [snRNA,snoRNA]

    Proviced a comma separated list of SO terms for supported ncRNA
    types.  Default is snRNA & snoRNA.  Provided values will overwrite
    defaults.  Provide `--ncrnas NONE` to clear defaults.

  --store, -s

    Force the Storable (*.stor) file to be rebuilt.  This script uses
    Per's Storable module to store a persistent version of the GFF3
    datastructure for efficient script startup.  The storable file
    will be used instead of the GFF3 file if it exists and is newer
    than the GFF3 file.  This option forces a storable file to be
    rebuilt which is useful if the code changes or if you change
    command-line options.

";

my %SEEN;
my $ROW_COUNT = 1;

my ($help, $format, $RANGE, $MAX_DIST, $mrnas, $ncrnas, $store);

my $opt_success = GetOptions('help|h'       => \$help,
                             'format|f=s'   => \$format,
                             'range|r=i'    => \$RANGE,
                             'max_dist|m=i' => \$MAX_DIST,
                             'mrnas|a=s'    => \$mrnas,
                             'ncrnas|n=s'   => \$ncrnas,
                             'store|s'      => \$store,
    );

die $usage if $help || ! $opt_success;

$format   ||= 'viq_list';
$RANGE    ||= 2000;
$MAX_DIST ||= 10000;

# Supported ncRNAs
my %SUPPORTED_NCRNAS = (snRNA  => 1,
                        snoRNA => 1,
    );

if ($ncrnas) {
        %SUPPORTED_NCRNAS = ();
        my @ncrna_list = split /,/, $ncrnas;
        for my $ncrna (@ncrna_list) {
                $SUPPORTED_NCRNAS{$ncrna}++;
        }
}

# Supported mRNAs
my %SUPPORTED_MRNAS = (mRNA       => 1, # Ensembl GFF3
                       transcript => 1, # MANE & Gencode GFF3
                      );

if ($mrnas) {
        %SUPPORTED_MRNAS = ();
        my @mrna_list = split /,/, $mrnas;
        for my $mrna (@mrna_list) {
                $SUPPORTED_MRNAS{$mrna}++;
        }
}

my %SUPPORTED_RNAS;
map {$SUPPORTED_RNAS{$_}++} keys %SUPPORTED_NCRNAS;
map {$SUPPORTED_RNAS{$_}++} keys %SUPPORTED_MRNAS;

if ($MAX_DIST <= $RANGE) {
    $MAX_DIST = $RANGE + 1;
    print STDERR "INFO : resetting_max_dist : max_dist cannot be <= range; resetting max_dist=$MAX_DIST\n";
}

my ($data_file, $gff3_file) = @ARGV;
die $usage unless $data_file && $gff3_file;

my $gff3_store = $gff3_file . '.stor';

my %gff3_transcripts;
if ($store ||
    ! -e $gff3_store ||
    (stat($gff3_file))[9] > (stat($gff3_store))[9]) {

        print STDERR "INFO : building_storable_file : $gff3_store\n";

        my $gff3 = Arty::GFF3->new(file => $gff3_file);

        my %seen_ncRNAs;
        # First pass to record all ncRNAs for logic below.
        while (my $record = $gff3->next_record) {
                if (exists $SUPPORTED_NCRNAS{$record->{type}}) {
                        $seen_ncRNAs{$record->{attributes}{Parent}[0]}++
                }
        }

        # Reopen GFF3 file
        $gff3 = Arty::GFF3->new(file => $gff3_file);

        my %mapped_cds;
        my %mapped_exon;
      RECORD:
        while (my $record = $gff3->next_record) {
                # Store transcripts
                if (exists $SUPPORTED_RNAS{$record->{type}}) {
                        $record->{attributes}{ID}[0] =~ s/^transcript://;
                        $record->{attributes}{Parent}[0] =~ s/^gene://;
                        push @{$gff3_transcripts{chrs}{$record->{chrom}}}, $record;
                        $gff3_transcripts{ids}{$record->{attributes}{ID}[0]} = $record;
                }
                # Store CDSs (will only happen for mRNA)
                elsif ($record->{type} eq 'CDS') {
                        $record->{attributes}{Parent}[0] =~ s/^transcript://;
                        next RECORD unless exists $record->{attributes}{Parent} &&
                          defined $record->{attributes}{Parent}[0];
                        my $parent = $record->{attributes}{Parent}[0];
                        push @{$mapped_cds{$parent}}, $record;
                        print '';
                }
                # Store exons...
                elsif ($record->{type} eq 'exon') {
                        $record->{attributes}{Parent}[0] =~ s/^transcript://;
                        #...only for ncRNAs
                        if (exists $seen_ncRNAs{$record->{type}}) {
                                next RECORD unless exists $record->{attributes}{Parent} &&
                                  defined $record->{attributes}{Parent}[0];
                                my $parent = $record->{attributes}{Parent}[0];
                                push @{$mapped_exon{$parent}}, $record;
                                print '';
                        }
                }
                print '';
        }

        # Copy CDSs on top of exons.  This will clobber mRNA exons
        # which is what we want - exons for ncRNA and CDSs for mRNAs.
        for my $mrna (keys %mapped_cds) {
                $mapped_exon{$mrna} = $mapped_cds{$mrna};
        }

        for my $chrom (keys %{$gff3_transcripts{chrs}}) {
                my $chrom_transcripts = $gff3_transcripts{chrs}{$chrom};
                for my $transcript (@{$chrom_transcripts}) {
                        my $id = $transcript->{attributes}{ID}[0];
                        $transcript->{exon} = $mapped_exon{$id} || [];
                }
        }

        if (open(my $STORE, '>', $gff3_store)) {
                if (flock($STORE, LOCK_EX)) {
                        store \%gff3_transcripts, $gff3_store;
                        flock($STORE, LOCK_UN) or die "FATAL : cannot_unlock_storable_file : $gff3_store$!\n";
                        close $STORE;
                }
                else {
                        warn "WARN : cannot_lock_storable_file : $gff3_store Using data in $gff3_file";
                }
        }
        else {
                print "WARN : could_not_open_storable_file : $gff3_store Using data in $gff3_file";
        }
}

my $transcripts = (retrieve($gff3_store) || \%gff3_transcripts);

my $transcript_count = scalar keys %{$transcripts->{ids}};

die "FATAL : no_transcript_loaded : Check $gff3_file and $gff3_store for problems.\n"
    unless $transcript_count > 0;
print STDERR "INFO : loaded_transcripts : $transcript_count transcripts loaded\n";

my $parser;
if ($format =~ /^viq_list/) {
    my $payload = $format eq 'viq_list_payload' ? 1 : 0;
    $parser = Arty::vIQ_List->new(file    => $data_file,
                                  payload => $payload);
}
elsif ($format eq 'skeleton') {
        $parser = Arty::Skeleton->new(file => $data_file);
}
else {
        die "FATAL : invavlid_format : $format\n";
}


my @COLUMNS = $parser->columns();
print '#';
print join "\t", @COLUMNS;
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
                # my $keep_one_5p_trns;
              TRIM_TRANSCRIPT:

                # Check [1] here not [0] to always leave the closest
                # 5' transcript for distance calculations.
                while (defined $transcripts->{chrs}{$$chrom}[1] &&
                       $transcripts->{chrs}{$$chrom}[1]{end} < $range_start) {
                        shift @{$transcripts->{chrs}{$$chrom}};
                }


              TRANSCRIPT:
                for my $idx (0 .. $#{$transcripts->{chrs}{$$chrom}}) {
                        # If transcript start is beyond range_end then quit looking
                        # Print variant and bail.
                        my $transcript = $transcripts->{chrs}{$$chrom}[$idx];
                        # Reset record values for current transcript.
                        $record->{transcript} = $transcript->{attributes}{ID}[0];
                        $record->{vvp_gene}   = $transcript->{attributes}{Parent}[0];
                        if (exists $record->{vaast_rec_p}) {
                                $record->{vaast_rec_p} = 'null';
                        }
                        if (exists $record->{vaast_dom_p}) {
                                $record->{vaast_dom_p} = 'null';
                        }

                        $$distance = get_exon_distance($record, $transcript);
                        last TRANSCRIPT if $$distance >= $MAX_DIST;
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

        $record->{chrom} =~ s/^chr//;

        if ($format =~ '^viq_list') {
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

    my $key = join ':', @{$record}{@COLUMNS};

        if (! $SEEN{$key}++) {
            $record->{rid} = sprintf("%08d", $ROW_COUNT++);

            print join "\t", @{$record}{@COLUMNS};

            print "\n";
        }
    print '';
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
        warn("WARN : mismatched_chromosomes_in_get_exon_distance : " .
             "transcript=$transcript_chrom, record=$rcd_txt. Will
             return a very large distance to allow the script to
             complete\n");

        # Edit 12/08/20 changing this from fatal error to warn and
        # returning distance=260,000,000 because Javier found case
        # where VEP was annotating a variant to a gene on another
        # chromosome.  We coudn't figure out why, so he is reporting
        # it as a bug to the VEP dev team and we will add a workaround
        # here in the mean time to allow the script to run on cases
        # where a variant is annotated to a gene on another
        # chromosome.  The solution here is to simply return a
        # distance greather than the largest chromosome.

        my $distance = 250_000_000;
        return $distance;
    }

    my $transcript_length = $transcript->{end} - $transcript->{start};
    my $distance = $RANGE + 1;

  EXON:
    for my $exon (@{$transcript->{exon}}) {
        # If EXON start is past variant POS then set distance
        # and exit EXON loop
        if ($exon->{start} >= $rcd_end) {
            $distance = ($exon->{start} - $rcd_end < $distance) ? $exon->{start} - $rcd_end : $distance;
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
