#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;

#-----------------------------------------------------------------------------
#----------------------------------- MAIN ------------------------------------
#-----------------------------------------------------------------------------

my $usage = "

Synopsis:

map_column_value.pl --map map_file.txt --map_cols 1,2 --cols 1 data_file.txt

Description:

A script to map values in one or more columns from a data file 

Options:

  --map, -m <map_file.txt>

    A required mapping file that has one column ('MAP FROM VALUE')
    with values that match the column in the data file to be mapped
    and another column ('MAP TO VALUE') that have values to map to.
    Not that this file should typically have a one to one mapping,
    although a many-to-one mapping is allowed, but not a one-to-many
    mapping.  This behvior can be modified with --allow_one_to_many.
    File should be tab-delimited text.  Default behavior is to use the
    first column as the 'MAP FROM VALUE' and the second column as the
    'MAP TO VALUE', however, mapping columns can be altered with the
    --map_cols option.  If a value from the data file column being
    mapped is not found in the mapping file it's value is left as-is
    in the data file, however this behavior can be modified with the
    --missing_to_null option.  Rows begining with '#' are skipped.

  --map_cols, -o [1,2]

    A comma-separated list of two columns (1-based column count) that
    describe the two columns used for mapping.  First column given
    will be the 'MAP FROM VALUE' and the second column will be the
    'MAP TO VALUE'.  Default is 1,2.

  --cols, -c [1]

    A comma separated list of one or more columns (1-based column
    count) from the data file that will be mapped.  Note that all data
    file columns will be updated with the same map.  Default behavior
    is to map the first column.

  --missing_to_null, -n

    A flag to indicate that if a value from the data file column is
    not found in the map file lookup, the the value in the data file
    column should be mapped to null (no value).

  --allow_one_to_many, -a

    Tolerate one-to-many mappings in the mapping file.  The script
    does not support on-to-manny mapping, but it ignores one-to-many
    errors and just uses the last 'MAP TO VALUE' seen for a given 'MAP
    FROM VALUE'.

";


my ($help, $map_file, $map_cols_txt, $data_cols_txt, $missing_null, $allow_one_many);

my $opt_success = GetOptions('help'           	   => \$help,
			     'map|m=s'        	   => \$map_file,
			     'map_cols|o=s'   	   => \$map_cols_txt,
			     'cols|c=s'       	   => \$data_cols_txt,
			     'missing_null|n' 	   => \$missing_null,
			     'allow_one_to_many|a' => \$allow_one_many,
    );

die $usage if ! $opt_success;
print $usage if $help;

# Default and split map_cols
$map_cols_txt ||= '1,2';
my @map_cols = split /,/, $map_cols_txt;
my $max_map_col = 0;
for my $map_col (@map_cols) {
  $map_col--;
  $max_map_col = ($map_col > $max_map_col) ? $map_col : $max_map_col;
  if ($map_col < 0) {
    die ("$usage\n\nFATAL : map_cols_value_to_low : Values cannot be < 1 " .
	 "($map_cols_txt) use 1-based column numbers.\n\n");
  }
}

# Default and split data_cols
$data_cols_txt ||= 1;
my @data_cols = split /,/, $data_cols_txt;
my $max_data_col = 0;
for my $data_col (@data_cols) {
  $data_col--;
  $max_data_col = ($data_col > $max_data_col) ? $data_col : $max_data_col;
  if ($data_col < 0) {
    die("$usage\n\nFATAL : data_cols_value_to_low : Values cannot be < 1 ".
	"($data_cols_txt) use 1-based column numbers.\n\n");
  }
}


die "$usage\n\nFATAL : missing_map_file\n\n" unless $map_file;

my $data_file = shift;
die "$usage\n\nFATAL : missing_data_file\n\n" unless $data_file;

# Read mapping file
open (my $MAP, '<', $map_file) or die("FATAL : cant_open_map_file_for_reading : " .
				 "$map_file\n$!\n");

my %map;
MAP_LINE:
while (my $line = <$MAP>) {
  next MAP_LINE if $line =~ /^\#/;
  chomp $line;
  my @cols = split /\t/, $line;
  if ((scalar(@cols) - 1) < $max_map_col) {
    die("$usage\n\nFATAL : map_cols_value_too_high : Mapping column values " .
	"cannot be > column count in mapping file ($map_cols_txt - $line).\n\n");
  }
  my ($key, $value) = @cols[@map_cols];
  if (exists $map{$key}) {
      if ($allow_one_many) {
	  warn "WARN : one_to_many_mapping_allowed : $line\n";
      }
      else {
	  die "$usage\n\nFATAL : one_to_many_mapping_not_allowed : $line\n";
      }
  }
  $map{$key} = $value;
}

open (my $IN, '<', $data_file) or die("FATAL : cant_open_data_file_for_reading : " .
				      "$data_file\n$!\n");

LINE:
while (my $line = <$IN>) {
  chomp $line;
  my @cols = split /\t/, $line;

  if ((scalar(@cols) - 1) < $max_data_col) {
    die("$usage\n\nFATAL : data_cols_value_to_high : Data column values cannot " .
	"be > column count in data file ($data_cols_txt - $line).\n\n");
  }
  for my $data_col (@data_cols) {
    my $value = $cols[$data_col];
    if (exists $map{$value}) {
      $value = $map{$value};
    }
    elsif ($missing_null) {
      warn "WARN : setting_value_to_null : $value\n";
      $value = '';
    }
    $value = '' unless defined $value;
    $cols[$data_col] = $value;
  }
  print join "\t", @cols;
  print "\n";
}
