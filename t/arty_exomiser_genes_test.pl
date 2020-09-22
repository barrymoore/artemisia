#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;

use FindBin;
use lib "$FindBin::RealBin/../lib";
use Arty::Exomiser_Genes;

#-----------------------------------------------------------------------------
#----------------------------------- MAIN ------------------------------------
#-----------------------------------------------------------------------------
my $usage = "

Synopsis:

arty_exomiser_genes_test.pl data/exomiser_genes.tsv

Description:

Test script for developing Arty::Exomiser_Genes.pm

";


my ($help);
my $opt_success = GetOptions('help'    => \$help,
			      );

die $usage if $help || ! $opt_success;

my $file = shift;
die $usage unless $file;

my $ex_genes = Arty::Exomiser_Genes->new(file => $file);


print $ex_genes->get_header;
print "\n";
print '';

while (my $record = $ex_genes->next_record) {

    print join "\t", @{$record}{qw(gene_symbol entrez_gene_id
				   exomiser_gene_pheno_score
				   exomiser_gene_variant_score
				   exomiser_gene_combined_score
				   human_pheno_score mouse_pheno_score
				   fish_pheno_score walker_score
				   phive_all_species_score omim_score
				   matches_candidate_gene
				   human_pheno_evidence
				   mouse_pheno_evidence
				   fish_pheno_evidence
				   human_ppi_evidence
				   mouse_ppi_evidence
				   fish_ppi_evidence)};

    print "\n";
    print '';
}
