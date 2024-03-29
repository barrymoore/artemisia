#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
use JSON;
use Storable qw(dclone);

use FindBin;
use lib "$FindBin::RealBin/../lib";
use Arty::vIQ;
use Arty::PED;

#-----------------------------------------------------------------------------
#----------------------------------- MAIN ------------------------------------
#-----------------------------------------------------------------------------

my $usage = "

Synopsis:

viq_report.pl viq_output.txt

Description:

A script to produce a report of vIQ output that has key fields for
human consumption in a tab-delimited format.


Options:

  --ped, -p

    Peidgree file of family. Optional. Not yet implimented.

  --min_score, -m [0]

    Minimum vIQ score to print.

  --skip_incdt, -s

    Skip indendental findings.  Default is false.

  --add_miq, -d

    Add columns for mQIscr, MIM and disease name for best hit from Mendelian Diagnosis section for
    each gene.

  --payload, -y 'INFO:CSQ:CADD_PHRED,INFO:gnomad_AF'

    Data to include in the report from the listfile 'payload' section.
    This data is added as a JSON string by viq_tool vcf2viq.  The
    values supplied to this argument are in the form --payload
    INFO:CSQ:CADD_PHRED,INFO:gnomad_AF.  Note that in most cases
    payloads are only two-levels deep (e.g. INFO:gnomad_AF'), but in
    the case of the CSQ tag, the parser understands additional levels
    'INFO:CSQ:CADD_PHRED' as a special case.

  --adjust_rank, -r

    A boolean flag that indicates if the vIQ gene rank should be
    adjusted to not count incendental candidates and not double-count
    compound hets.

";

my ($help, $ped_file, $min_score, $skip_incdt, $add_miq, $payload,
    $adjust_rank);

my $opt_success = GetOptions('help'            => \$help,
                             'min_score|m=s'   => \$min_score,
                             'skip_incdt|s'    => \$skip_incdt,
                             'ped|p=s'         => \$ped_file,
                             'add_miq|d'       => \$add_miq,
                             'payload|y=s'     => \$payload,
                             'adjust_rank|r'   => \$adjust_rank,
    );

die $usage if $help || ! $opt_success;

$min_score = 0 unless defined $min_score;

my @viq_files = @ARGV;

die "$usage\n\nFATAL : missing_viq_file(s)\n" unless @viq_files;

# my %ped_data;
# my $ped = Arty::PED->new(file => $ped_file);
#
# while (my $record = $ped->next_record) {
#     print '';
#     my $kindred = $record->{kindred};
#     my $sample  = $record->{sample};
#     my $father  = $record->{father};
#     my $mother  = $record->{mother};
#     my $sex     = $record->{sex};
#     my $pheno   = $record->{phenotype};
#     # $ped_data{graph}{$kindred}{$sample}{father} = $father if $father;
#     # $ped_data{graph}{$kindred}{$sample}{mother} = $mother if $mother;
#     # $ped_data{data}{$kindred}{$sample} = $record;
#
#     if ($ped_data{$kindred}{samples}{$sample}++ > 1) {
#         print STDERR "WARN : sample_id_seen_before_in_family : $kindred $sample\n";
#     }
#     if ($record->{father} ne '0') {
#         $ped_data{$kindred}{father} = $father;
#         $ped_data{$kindred}{children}{$sample}++;
#     }
#     if ($record->{mother} ne '0') {
#         $ped_data{$kindred}{mother} = $mother;
#         $ped_data{$kindred}{children}{$sample}++;
#     }
#
#     if ($record->{phenotype} eq '2') {
#         $ped_data{$kindred}{affected}{$sample}++;
#         $ped_data{$kindred}{affected_count}++
#     }
#     elsif ($record->{phenotype} eq '1') {
#         $ped_data{$kindred}{unaffected}{$sample}++;
#         $ped_data{$kindred}{unaffected_count}++
#     }
#     $ped_data{$kindred}{samples}{$sample} = $record;
#     print '';
# }
#
# my %ped_summary;
# for my $kindred (keys %ped_data) {
#     my $fam = $ped_data{$kindred};
#     my $father = $fam->{father};
#     my $mother = $fam->{mother};
#     my $samples = $fam->{samples};
#
#     my @member_types;
#     my $child_count = 0;
#   SAMPLE:
#     for my $sample (sort {$fam->{samples}{$b}{phenotype} <=> $fam->{samples}{$a}{phenotype}} keys %{$samples}) {
#         # Skip the parents here and process them separately below
#         next SAMPLE if exists $fam->{father} && $fam->{father} eq $sample;
#         next SAMPLE if exists $fam->{mother} && $fam->{mother} eq $sample;
#         my $child_type = ++$child_count > 1 ? 'S' : 'P';
#         push @member_types, ($fam->{samples}{$sample}{phenotype} == 2 ? "${child_type}2" :
#                              $fam->{samples}{$sample}{phenotype} == 1 ? '${child_type}1' :
#                              '${child_type}0');
#   }
#     if (exists $fam->{father}) {
#         push @member_types, ($fam->{samples}{$fam->{father}}{phenotype} == 2 ? 'F2' :
#                              $fam->{samples}{$fam->{father}}{phenotype} == 1 ? 'F1' :
#                              'F0');
#   }
#     else {
#         push @member_types, 'F-';
#   }
#
#     if (exists $fam->{mother}) {
#         push @member_types, ($fam->{samples}{$fam->{mother}}{phenotype} == 2 ? 'M2' :
#                              $fam->{samples}{$fam->{mother}}{phenotype} == 1 ? 'M1' :
#                              'M0');
#   }
#     else {
#         push @member_types, 'M-';
#   }
#
#
#     $ped_summary{$kindred} = join ':', @member_types;
# }
# print '';

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
                    8    =>  'drug_resp_het',
                    9    =>  'drug_resp_hom',
                    null => 'unknown',
                   );

my %incdt_map = 
    (
     e => 'panel',
     g => 'gene',
     d => 'drug',
     p => 'phenotype',
     u => 'unknown',
     v => 'variant',
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
                 g_tag p_mod clinvar incdt var_qual);

if ($add_miq) {
        push @headers, qw(miqscr mim disease);
}

my @payloads;
if ($payload) {
        for my $payload_txt (split /,/, $payload) {
                my @keys = split /:/, $payload_txt;
                push @payloads, \@keys;
                push @headers, $keys[-1];
        }
}

print join "\t", @headers;
print "\n";
print '';

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

        my $adj_rank = 0;
        my %g_tag_count;
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

                # Remove whitespace from ploidy
                $record->{pldy} =~ s/\s+/,/g;


                # Remove whitespace from vid
                $record->{vid} =~ s/\s+/-/g;
                # my $ad_txt = join '\,', @{$record->{var_qual}{ad}};
                # my $var_qual_txt = join ":", $ad_txt, $record->{var_qual}{bayesf}, $record->{var_qual}{prob};
                $record->{var_qual} =~ s/\s+/,/g;

                $record->{incdt} = '';
                my ($clinvar_incdt) = $record->{clinvar} =~ /([edgpuv])$/;
                if ($clinvar_incdt) {
                        $record->{clinvar} =~ s/([gpd])$//;
                        $clinvar_incdt = (exists $incdt_map{$clinvar_incdt} ?
                                          $incdt_map{$clinvar_incdt} :
                                          $clinvar_incdt);
                        $record->{incdt} = $clinvar_incdt;
                        # $record->{rank} = '@';
                        # $record->{clinvar} .= ":$clinvar_incdt" if $clinvar_incdt;
                }

                $record->{clinvar} = (exists $clinvar_map{$record->{clinvar}} ?
                                      $clinvar_map{$record->{clinvar}} : 
                                      $record->{clinvar});

                next RECORD if $skip_incdt && $clinvar_incdt;
                next RECORD if $record->{viqscr} < $min_score;

                # Manage rank
                if ($adjust_rank) {
                        my $increment;
                        if ($clinvar_incdt) {
                                $record->{rank} = '@';
                                $increment = 0;
                        }
                        else {
                                $increment = 1 unless defined $increment;
                        }

                        if ($record->{g_tag} ne 'null') {
                                if (exists $g_tag_count{$record->{g_tag}}) {
                                        # Don't double count compound hets
                                        $increment = 0;
                                }
                                else {
                                        $increment = 1 unless defined $increment;
                                        $g_tag_count{$record->{g_tag}}++

                                }
                        }
                        $adj_rank++ if $increment;
                        $record->{rank} = $adj_rank unless $record->{rank} eq '@';
                }

                my @print_data = @{$record}{qw(rank chr gene vid csq
                                               denovo type zygo pldy
                                               sites par length gqs
                                               viqscr phev_k vvp_svp
                                               vaast g_tag p_mod
                                               clinvar incdt var_qual)};

                if ($add_miq) {
                        my $miqscr  = 0;
                        my $mim     = 'NA';
                        my $disease = 'NA';
                        if (exists $miq_data{$record->{gene}}) {
                                $miqscr  = $miq_data{$record->{gene}}{miqscr}  || $miqscr;
                                $mim     = $miq_data{$record->{gene}}{mim}     || $mim;
                                $disease = $miq_data{$record->{gene}}{disease} || $disease;
                        }
                        push @print_data, ($miqscr, $mim, $disease);
                }

                if ($payload) {
                        my $json = decode_json $record->{payload};
                        my $my_payloads = dclone(\@payloads);
                        for my $payload_keys (@{$my_payloads}) {
                                my $key = shift @{$payload_keys};
                                my $value = $json->{$key};
                                while (ref $value eq 'HASH') {
                                        $key = shift @{$payload_keys};
                                        $value = $value->{$key};
                                }
                                if (ref $value eq 'ARRAY') {
                                        map {$_ = '' unless defined $_} @{$value};
                                        $value = join ',', @{$value};
                                }
                                # $value = '' unless defined $value;
                                push @print_data, $value;
                        }
                }

                map {$_ = '' unless defined $_} @print_data;

                print join "\t", $viq_file, @print_data;

                print "\n";
                print '';
        }
        # print "--------------------\n\n";
}

#-------------------------------------------------------------------------------
