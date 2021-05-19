#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;

use Arty::vIQ;
use Arty::PED;

#-----------------------------------------------------------------------------
#----------------------------------- MAIN ------------------------------------
#-----------------------------------------------------------------------------

my $usage = "

Synopsis:

viq_report.pl viq_output.txt

Description:

A script to produce various types of reports of vIQ output.

Options:

  --format, -f

    The following arguments define which type of report is generated: 

      tsv: currently the default and only format.

The remaining arguments instruct viq_report.pl to not parse rows with
various cut-offs:

  --min_score, -m [0]

    Minimum vIQ score to print.  Default is 0, don't skip any rows.

  --max_rank, -r [-1]

    Maximum rank of genes to include.  A value <= 0 indicates no
    max_rank.  Default is -1 - don't skip any rows.

  --skip_incdt, -s

    Skip indendental findings.  Default is false - don't skip
    incendental rows.

  --add_miq, -d

    Add columns for mQIscr, MIM and disease name for best hit from Mendelian Diagnosis section for
    each gene.

";

my ($help, $min_score, $skip_incdt, $add_miq);

my $opt_success = GetOptions('help'            => \$help,
			     'format'          => \$format,
                             'min_score|m=s'   => \$min_score,
			     'max_rank|r=i'    => \$max_rank,
                             'skip_incdt|s'    => \$skip_incdt,
                             'add_miq|d'       => \$add_miq,
    );

die $usage if $help || ! $opt_success;

$min_score = 0  unless defined $min_score;
$max_rank  = -1 unless defined $max_rank;

my @viq_files = @ARGV;

die "$usage\n\nFATAL : missing_viq_file(s)\n" unless @viq_files;

my %csq_map = (
               0  => 'sequence_variant',
               1  => 'transcript_ablation',
               2  => 'splice_acceptor_variant',
               3  => 'splice_donor_variant',
               4  => 'stop_gained',
               5  => 'frameshift_variant',
               6  => 'stop_lost',
               7  => 'start_lost',
               8  => 'transcript_amplification',
               9  => 'inframe_insertion',
               10 => 'inframe_deletion',
               11 => 'missense_variant',
               12 => 'protein_altering_variant',
               13 => 'splice_region_variant',
               14 => 'incomplete_terminal_codon_variant',
               15 => 'start_retained_variant',
               16 => 'stop_retained_variant',
               17 => 'synonymous_variant',
               18 => 'coding_sequence_variant',
               19 => 'mature_miRNA_variant',
               20 => '5_prime_UTR_variant',
               21 => '3_prime_UTR_variant',
               22 => 'non_coding_transcript_exon_variant',
               23 => 'intron_variant',
               24 => 'NMD_transcript_variant',
               25 => 'non_coding_transcript_variant',
               26 => 'upstream_gene_variant',
               27 => 'downstream_gene_variant',
               28 => 'TFBS_ablation',
               29 => 'TFBS_amplification',
               30 => 'TF_binding_site_variant',
               31 => 'regulatory_region_ablation',
               32 => 'regulatory_region_amplification',
               33 => 'feature_elongation',
               34 => 'regulatory_region_variant',
               35 => 'feature_truncation',
               36 => 'intergenic_variant',
              );

my %clinvar_map =  (0    => 'benign_het',
                    1    => 'benign_hom',
                    2    => 'likely_benign_het',
                    3    => 'likely_benign_hom',
                    4    => 'likely_pathogenic_het',
                    5    => 'likely_pathogenic_hom',
                    6    => 'pathogenic_het',
                    7    => 'pathogenic_hom',
		    8    => 'drug_het',
		    9    => 'drug_hom',
                    null => 'unknown',
                   );

my %type_map = (1 => 'SNV',
                2 => 'INDEL',
                3 => 'SV',
                4 => 'DEL',
                5 => 'INS',
                6 => 'DUP',
                7 => 'INV',
                8 => 'CNV',
                9 => 'BND',
               );

my @headers = qw(kindred rank chr gene vid csq denovo type zygo pldy
                 sites par length gqs viqscr phev_k vvp_svp vaast
                 g_tag p_mod clinvar incndtl var_qual);

if ($add_miq) {
        push @headers, qw(miqscr mim disease);
}

print join "\t", @headers;
print "\n";

for my $viq_file (@viq_files) {

        my $viq = Arty::vIQ->new(file => $viq_file);

        # print "## $viq_file\n";

        my %miq_data;
        if ($add_miq) {
                my %seen_miq;
              MIQ:
                for my $miq_record (sort {($b->{viqscr} <=>
                                           $a->{viqscr})}
                                    @{$viq->{mendelian_diagnoses}}) {
                        my $gene = $miq_record->{gene};
                        next MIQ if $seen_miq{$gene}++;
                        @{$miq_data{$gene}}{qw(miqscr mim disease)} = 
                          @{$miq_record}{qw(miqscr mim disease)};
                }
        }

      RECORD:
        while (my $record = $viq->next_record) {

                for my $key (keys %{$record}) {
                        $record->{$key} = 'null' unless length $record->{$key};
                }

                my @csq_mapped;
                map {push @csq_mapped, $csq_map{$_}} split /,/, $record->{csq};
                $record->{csq} = join ',', @csq_mapped;

                # Map variant type
                $record->{type} = (exists $type_map{$record->{type}} ?
                                   $type_map{$record->{type}}        :
                                   $record->{type});

                # Extract numeric value from ploidy
                $record->{pldy} =~ s/^(\d+).*/$1/g;


                # Remove whitespace from vid
                $record->{vid} =~ s/\s+/-/g;
                # my $ad_txt = join '\,', @{$record->{var_qual}{ad}};
                # my $var_qual_txt = join ":", $ad_txt, $record->{var_qual}{bayesf}, $record->{var_qual}{prob};
                $record->{var_qual} =~ s/\s+/,/g;

                ($record->{clinvar_incdt}) = $record->{clinvar} =~ s/([g|p])$//;
		$record->{clinvar_incdt} ||= 'none';
                $record->{clinvar} = (exists $clinvar_map{$record->{clinvar}} ?
                                      $clinvar_map{$record->{clinvar}}
                                      : $record->{clinvar});
                # $record->{clinvar} .= '*' if $clinvar_incdt;

                next RECORD if $record->{viqscr} < $min_score;
		next RECORD if $max_rank > 0 && $record->{rank} > $max_rank;
                next RECORD if $skip_incdt && $clinvar_incdt;

                my @print_data = @{$record}{qw(rank chr gene vid csq
                                               denovo type zygo pldy
                                               sites par length gqs
                                               viqscr phev_k vvp_svp
                                               vaast g_tag p_mod
                                               clinvar var_qual)};

                if ($add_miq) {
                        my $miqscr  = 0;
                        my $mim     = 'NA';
                        my $disease = 'NA';
                        if (exists $miq_data{$record->{gene}}) {
                                ($miqscr, $mim, $disease) =
                                  @{$miq_data{$record->{gene}}}{qw(miqscr mim disease)};
                        }
                        push @print_data, ($miqscr, $mim, $disease);
                }

                print join "\t", $viq_file, @print_data;
>>>>>>> 54a3377c0f15067c10f6abe2b5fe7fe6870e14bb

                print "\n";
                print '';
        }
        # print "--------------------\n\n";
}

#-------------------------------------------------------------------------------
