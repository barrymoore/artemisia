#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;

use lib "$ENV{HOME}/artemisia/lib/";
use Arty::VCF;

#-----------------------------------------------------------------------------
#----------------------------------- MAIN ------------------------------------
#-----------------------------------------------------------------------------
my $usage = "

Synopsis:

arty_vcf_test.pl vcf.txt

Description:

Test script for developing Arty::VCF.pm

";


my ($help);
my $opt_success = GetOptions('help'    => \$help,
			      );

die $usage if $help || ! $opt_success;

my $file = shift;
die $usage unless $file;

my $vcf = Arty::VCF->new(file => $file);

while (my $record = $vcf->next_record) {

    print $record->{ref};
    print "\n";
}
