#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;

use FindBin;
use lib "$FindBin::RealBin/../lib";
use Arty::HPO_Genes2Phenotypes;

#-----------------------------------------------------------------------------
#----------------------------------- MAIN ------------------------------------
#-----------------------------------------------------------------------------
my $usage = "

Synopsis:

arty_hpo_genes2phenotypes_test.pl data/hpo_genes_to_phenotypes.txt

Description:

Test script for developing Arty::HPO_Genes2Phenotypes.pm

";


my ($help);
my $opt_success = GetOptions('help'    => \$help,
			      );

die $usage if $help || ! $opt_success;

my $file = shift;
die $usage unless $file;

my $hpo = Arty::HPO_Genes2Phenotypes->new(file => $file);

while (my $record = $hpo->next_record) {
    print join "\t", @{$record}{qw(gene_id gene_symbol hpo_name hpo_id freq_raw freq_hpo gd_info gd_source disease_id)};
    print "\n";
    print '';
}

# while (my $record = $tsv->next_record) {
# 
#     print join "\t", @{$record}{qw(chrom start end)};
#     print "\n";
# }
