#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;

use FindBin;
use lib "$FindBin::RealBin/../lib";
use Arty::VAAST;
use Arty::Utils qw(:all);

#-----------------------------------------------------------------------------
#----------------------------------- MAIN ------------------------------------
#-----------------------------------------------------------------------------
my $usage = "

Synopsis:

arty_test.pl vaast.simple

Description:

Test script for developing Arty::VAAST.pm

";


my ($help);
my $opt_success = GetOptions('help'    => \$help,
			      );

die $usage if $help || ! $opt_success;

my $file = shift;
die $usage unless $file;

my $vaast = Arty::VAAST->new(file => $file);

while (my $record = $vaast->next_record) {

    print join "\t", @{$record}{qw(rank gene feature_id score p_value)};
    print "\n";

    # warn_msg();
    # handle_message('WARN', 'error_code', 'Error message');
    
}
