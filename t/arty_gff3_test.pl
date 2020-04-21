#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;

use lib "$ENV{HOME}/artemisia/lib/";
use Arty::GFF3;

#-----------------------------------------------------------------------------
#----------------------------------- MAIN ------------------------------------
#-----------------------------------------------------------------------------
my $usage = "

Synopsis:

arty_gff3_test.pl data.gff3

Description:

Test script for developing Arty::GFF3.pm

";


my ($help);
my $opt_success = GetOptions('help'    => \$help,
			      );

die $usage if $help || ! $opt_success;

my $file = shift;
die $usage unless $file;

my $gff3 = Arty::GFF3->new(file => $file);

while (my $record = $gff3->next_record) {

    print join "\t", @{$record}{qw(chrom source type start end score strand phase)};
    print "\n";
}
