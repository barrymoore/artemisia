#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;

#-----------------------------------------------------------------------------
#----------------------------------- MAIN ------------------------------------
#-----------------------------------------------------------------------------
my $usage = "

Synopsis:

polish_skeleton.pl skeleton_data.txt > skeleton_file.txt

Description:

A script to polish the raw skeleton data from Gnomad VCF file into a
skeleton file ready for closest_cds.pl.

Specifically, the script adds the following columns:

End
Gene
Transcript
Distance

In addition, it maps CSQ consequence values to integer values.  See
the %csq_map variable in the code for the mapping.

";


my ($help);
my $opt_success = GetOptions('help'    => \$help,
			      );

die $usage if $help || ! $opt_success;


my %csq_map = (
               'sequence_variant'                    =>  0,
               'transcript_ablation'                 =>  1,
               'splice_acceptor_variant'             =>  2,
               'splice_donor_variant'                =>  3,
               'stop_gained'                         =>  4,
               'frameshift_variant'                  =>  5,
               'stop_lost'                           =>  6,
               'start_lost'                          =>  7,
               'transcript_amplification'            =>  8,
               'inframe_insertion'                   =>  9,
               'inframe_deletion'                    =>  10,
               'missense_variant'                    =>  11,
               'protein_altering_variant'            =>  12,
               'splice_region_variant'               =>  13,
               'splice_donor_5th_base_variant'       =>  14, # New in 2022
               'splice_donor_region_variant'         =>  15, # New in 2022
               'splice_polypyrimidine_tract_variant' =>  16, # New in 2022
               'incomplete_terminal_codon_variant'   =>  17,
               'start_retained_variant'              =>  18,
               'stop_retained_variant'               =>  19,
               'synonymous_variant'                  =>  20,
               'coding_sequence_variant'             =>  21,
               'mature_miRNA_variant'                =>  22,
               '5_prime_UTR_variant'                 =>  23,
               '3_prime_UTR_variant'                 =>  24,
               'non_coding_transcript_exon_variant'  =>  25,
               'intron_variant'                      =>  26,
               'NMD_transcript_variant'              =>  27,
               'non_coding_transcript_variant'       =>  28,
               'upstream_gene_variant'               =>  29,
               'downstream_gene_variant'             =>  30,
               'TFBS_ablation'                       =>  31,
               'TFBS_amplification'                  =>  32,
               'TF_binding_site_variant'             =>  33,
               'regulatory_region_ablation'          =>  34,
               'regulatory_region_amplification'     =>  35,
               'feature_elongation'                  =>  36,
               'regulatory_region_variant'           =>  37,
               'feature_truncation'                  =>  38,
               'intergenic_variant'                  =>  39,
              );

my $file = shift;
die $usage unless $file;
open (my $IN, '<', $file) or die "FATAL : cant_open_file_for_reading : $file\n";

LINE:
while (my $line = <$IN>) {
        chomp $line;
        my ($chrom, $pos, $ref, $alt, $csq_txt, $overlap, $af) =
          split /\t/, $line;

        my $end = $pos + length($ref) - 1;

        $af = join(';', (map {$_ = $_ eq '.' ? 0 : $_} split(/;/, $af)));

        my @csq_values = split /\|/, $csq_txt;
        # Add this step to the polish script
        # "| perl -F'\\t' -lane '@x = split /\|/, $F[4];splice(@F,4,1,@x[3,6,1]);print join qq|\\t|, @F' "
        my ($gene, $transcript, $csq_so) = @csq_values[3, 6, 1];
        $gene ||= 'NONE';
        $transcript ||= 'NONE';

        # Splice coding flag before AF
        # Add this step to the polish script
        # "| perl -F'\\t' -lane '$c = ($F[7] =~ /CDS/ ? 1 : 0);
        # $c = ($F[6] =~ /synonymous_variant/ ? -1 : $c);
        # splice(@F,8,0,$c);print join qq|\\t|, @F' "
        my $distance = $overlap =~ /CDS/ ? 0 : 1;
        if ($csq_so =~ /synonymous_variant/) {
                $distance = 1;
        }

        next LINE if ($csq_txt eq 'intron_variant' || $csq_txt eq 'intergenic_variant');
        my @csqs = split /&/, $csq_so;
        my @mapped_csqs;
        for my $csq (@csqs) {
                my $mapped_csq;
                if (exists $csq_map{$csq}) {
                        $mapped_csq = $csq_map{$csq};
                        push @mapped_csqs, $mapped_csq;
                }
                else {
                        warn "WARN : cant_map_csq : $csq (using sequence_variant=0 as default).\n";
                          push @mapped_csqs, 0;
                }
        }
        my $mapped_csq_txt = join ',', @mapped_csqs;
        print join "\t", ($chrom, $pos, $end, $ref, $alt, $gene,
                          $transcript, $mapped_csq_txt, $overlap,
                          $distance, $af);
        print "\n";
}
