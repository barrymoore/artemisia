#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;

use lib "$ENV{HOME}/artemisia/lib/";
use Arty::vIQ;

#-----------------------------------------------------------------------------
#----------------------------------- MAIN ------------------------------------
#-----------------------------------------------------------------------------

my $usage = "

Synopsis:

arty_viq_test.pl data/cases.viq

Description:

Test script for developing Arty::vIQ.pm

";


my ($help);
my $opt_success = GetOptions('help' => \$help,
                            );

die $usage if $help || ! $opt_success;

my $file = shift @ARGV;
$file ||= 'data/viq_output2.txt';

die $usage unless $file;

my $viq = Arty::vIQ->new(file => $file);

while (my $record = $viq->next_record) {

    print join "\t", @{$record}{qw(rank gene transcript vid csq denovo type zygo par loc breath viqscr p_scor s_scor phev_k vvp_svp vaast g_tag p_mod s_mod g_tag_scr clinvar vid)};

    print "\n";
    print '';
}
