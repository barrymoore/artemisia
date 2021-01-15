#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;

use FindBin;
use lib "$FindBin::RealBin/../lib";
use Arty::Exomiser_Variants;

#-----------------------------------------------------------------------------
#----------------------------------- MAIN ------------------------------------
#-----------------------------------------------------------------------------
my $usage = "

Synopsis:

arty_exomiser_variants_test.pl data/exomiser_variants.tsv

Description:

Test script for developing Arty::Exomiser_Variants.pm

";


my ($help);
my $opt_success = GetOptions('help'    => \$help,
			      );

die $usage if $help || ! $opt_success;

my $file = shift;
die $usage unless $file;

my $ex_var = Arty::Exomiser_Variants->new(file => $file);


print $ex_var->get_header;
print "\n";
print '';

while (my $record = $ex_var->next_record) {

    print join "\t", @{$record}{qw(chrom pos ref alt qual filter
				   genotype coverage functional_class
				   hgvs exomiser_gene cadd polyphen
				   mutationtaster sift remm dbsnp_id
				   max_frequency dbsnp_frequency
				   evs_ea_frequency evs_aa_frequency
				   exac_afr_freq exac_amr_freq
				   exac_eas_freq exac_fin_freq
				   exac_nfe_freq exac_sas_freq
				   exac_oth_freq
				   exomiser_variant_score
				   exomiser_gene_pheno_score
				   exomiser_gene_variant_score
				   exomiser_gene_combined_score
				   contributing_variant)};

    print "\n";
    print '';
}
