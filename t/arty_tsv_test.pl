#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;

use lib "$ENV{HOME}/artemisia/lib/";
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

my $tsv = Arty::TSV->new(file => $file)->all_records;

for my $record (@{$tsv}) {
    print join "\t", @{$record};
    print "\n";
}

# while (my $record = $tsv->next_record) {
# 
#     print join "\t", @{$record}{qw(chrom start end)};
#     print "\n";
# }