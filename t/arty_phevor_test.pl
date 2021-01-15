#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;

use FindBin;
use lib "$FindBin::RealBin/../lib";
use Arty::Phevor;

#-----------------------------------------------------------------------------
#----------------------------------- MAIN ------------------------------------
#-----------------------------------------------------------------------------
my $usage = "

Synopsis:

arty_phevor_test.pl phevor.txt

Description:

Test script for developing Arty::Phevor.pm

";


my ($help);
my $opt_success = GetOptions('help'    => \$help,
			      );

die $usage if $help || ! $opt_success;

my $file = shift;
die $usage unless $file;

my $phevor = Arty::Phevor->new(file => $file);

while (my $record = $phevor->next_record) {

    print $record->{gene};
    print "\n";
}
