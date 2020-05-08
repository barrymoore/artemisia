#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;

#-----------------------------------------------------------------------------
#----------------------------------- MAIN ------------------------------------
#-----------------------------------------------------------------------------
my $usage = "

Synopsis:

cat list.txt | list2comma.pl

Description:

Convert a stream of text records (one per line) into a comma separated
list.

";

my ($help);
my $opt_success = GetOptions('help'    => \$help,
			      );

die $usage if ! $opt_success;
print $usage if $help;

my @list;
LINE:
while (my $line = <>) {
    chomp $line;
    push @list, $line;
}

print join ',', @list;
print'';

