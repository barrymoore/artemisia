#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;

use lib "$ENV{HOME}/artemisia/lib/";
use Arty::VAAST_Simple;

#-----------------------------------------------------------------------------
#----------------------------------- MAIN ------------------------------------
#-----------------------------------------------------------------------------
my $usage = "

Synopsis:

arty_test.pl vaast.simple

Description:

Test script for developing Arty::VAAST_Simple.pm

";


my ($help);
my $opt_success = GetOptions('help'    => \$help,
			      );

die $usage if $help || ! $opt_success;

my $file = shift;
die $usage unless $file;

my $vaast = Arty::VAAST_Simple->new(file => $file);

while (my $record = $vaast->next_record) {

    print $record->{gene};
    print "\n";

}
