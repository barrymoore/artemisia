#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;

use FindBin;
use lib "$FindBin::RealBin/../lib";
use Arty::PED;

#-----------------------------------------------------------------------------
#----------------------------------- MAIN ------------------------------------
#-----------------------------------------------------------------------------
my $usage = "

Synopsis:

arty_ped_test.pl data/pedigree.ped

Description:

Test script for developing Arty::PED.pm

";


my ($help);
my $opt_success = GetOptions('help'    => \$help,
			      );

die $usage if $help || ! $opt_success;

my $file = shift;
die $usage unless $file;

my $ped = Arty::PED->new(file => $file)->all_records;

for my $record (@{$ped}) {
    print join "\t", @{$record}{qw(kindred proband mother father sex phenotype)};
    print "\n";
}

# while (my $record = $ped->next_record) {
# 
#     print join "\t", @{$record}{qw(chrom start end)};
#     print "\n";
# }
