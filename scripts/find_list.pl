#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;

#-----------------------------------------------------------------------------
#----------------------------------- MAIN ------------------------------------
#-----------------------------------------------------------------------------
my $usage = "

Synopsis:

find_list.pl -f1 4 -f2 1 data.txt list.txt 

Description:

Script to print rows from one file based on the list of values from a
second file.  Files should be tab-delimited.  The data file can have
header rows (see --header_count and --header_pattern below).  Rows
begining with # are skipped in the list file, but the --header_*
options do not apply to it.

Options:

  -f1 [1]

   The column number (1-based numbering) from the first file that
   contains the text to match on.

  -f2 [1]

   The column number (1-based numbering) from the second file that
   contains the text to match on.

  --header, -d

    Print header rows from data file as defined by the --header_*
    options below.

  --header_count, -c

    The number of rows of header in the data file to print, but not
    filter.  This must be an integer.  Default is to have no header
    rows.  This does not apply to the list file.

  --header_pattern, -p

    A pattern used to identify header rows.  This must be a valid perl
    regular expression.

  --help, -h

    Print this usage statement and exit.

";

my $CL = join ' ', $0, @ARGV;

my ($help, $f1, $f2, $header, $header_count, $header_pattern);
my $opt_success = GetOptions('help'               => \$help,
                             'f1=i'               => \$f1,
                             'f2=i'               => \$f2,
                             'header|d'           => \$header,
                             'header_count|c=s'   => \$header_count,
                             'header_pattern|p=s' => \$header_pattern,
			      );

$f1 ||= 1;
$f1--;
$f2 ||= 1;
$f2--;
$header_count ||= 0;

die $usage if ! $opt_success;
print $usage if $help;

my ($data_file, $list_file) = @ARGV;
die "$usage\n\nFATAL : missing_data_file : $CL\n"  unless $data_file;
die "$usage\n\nFATAL : missing_list_file : $CL\n"  unless $list_file;

open (my $LIST, '<', $list_file) or die "FATAL : cant_open_file_for_reading : $list_file\n$!\n";

my %list;
LIST_LINE:
while (my $line = <$LIST>) {
        next LIST_LINE if $line =~ /^\#/;
        chomp $line;
        my @cols = split /\t/, $line;
        my $value = $cols[$f2];
        $list{$value}++;
}

close $LIST;

open (my $DATA, '<', $data_file) or die "FATAL : cant_open_file_for_reading : $data_file\n$!\n";

my $head_count;
DATA_LINE:
while (my $line = <$DATA>) {
        chomp $line;

        if ($header_count) {
                print "$line\n" if $header;
                next DATA_LINE if $head_count++ <= $header_count;
        }
        elsif ($header_pattern) {
                print "$line\n" if $header;
                next DATA_LINE if $line =~ /$header_pattern/;
        }

        my @cols = split /\t/, $line;
        my $value = $cols[$f1];
        next DATA_LINE unless exists $list{$value};
        print "$line\n";
}

close $DATA;

