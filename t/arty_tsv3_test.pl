#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;

use FindBin;
use lib "$FindBin::RealBin/../lib";
use Arty::TSV;

#-----------------------------------------------------------------------------
#----------------------------------- MAIN ------------------------------------
#-----------------------------------------------------------------------------
my $usage = "

Synopsis:

arty_tsv_test.pl data/tsv.txt

Description:

Test script for developing Arty::TSV.pm

";


my ($help);
my $opt_success = GetOptions('help'    => \$help,
			      );

die $usage if $help || ! $opt_success;

my $file = shift;
die $usage unless $file;

my $tsv = Arty::TSV->new(file => $file,
			 as_hash => 1,
    );

$tsv->cols(qw(Kindred Indv_ID Paternal_ID Maternal_ID Sex Phenotype));

while (my $record = $tsv->next_record()) {
    print join "\t", @{$record}{qw(Kindred Indv_ID Paternal_ID Maternal_ID Sex Phenotype)};
    print "\n";
}

# while (my $record = $tsv->next_record) {
# 
#     print join "\t", @{$record}{qw(chrom start end)};
#     print "\n";
# }
