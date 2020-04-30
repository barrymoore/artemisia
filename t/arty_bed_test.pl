#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;

use lib "$ENV{HOME}/artemisia/lib/";
use Arty::BED;

#-----------------------------------------------------------------------------
#----------------------------------- MAIN ------------------------------------
#-----------------------------------------------------------------------------
my $usage = "

Synopsis:

arty_bed_test.pl data/cds.bed

Description:

Test script for developing Arty::BED.pm

";


my ($help);
my $opt_success = GetOptions('help'    => \$help,
			      );

die $usage if $help || ! $opt_success;

my $file = shift;
die $usage unless $file;

my $bed = Arty::BED->new(file => $file)->all_records;

for my $record (@{$bed}) {
    print join "\t", @{$record}{qw(chrom start end)};
    print "\n";
}

# while (my $record = $bed->next_record) {
# 
#     print join "\t", @{$record}{qw(chrom start end)};
#     print "\n";
# }
