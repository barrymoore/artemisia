#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;

use lib "$ENV{HOME}/artemisia/lib/";
use Arty::CDR;

#-----------------------------------------------------------------------------
#----------------------------------- MAIN ------------------------------------
#-----------------------------------------------------------------------------

my $usage = "

Synopsis:

arty_cdr_test.pl data/cases.cdr

Description:

Test script for developing Arty::CDR.pm

";


my ($help);
my $opt_success = GetOptions('help'    => \$help,
			      );

die $usage if $help || ! $opt_success;

my $file = shift;
die $usage unless $file;

my $cdr = Arty::CDR->new(file => $file);

while (my $record = $cdr->next_record) {

    print join "\t", @{$record}{qw(chrom start end type)};
    print "\n";
}
