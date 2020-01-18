#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;

use Arty::GFF3;

#-----------------------------------------------------------------------------
#----------------------------------- MAIN ------------------------------------
#-----------------------------------------------------------------------------


my $CL = join ' ', $0, @ARGV;

my $usage = "

Synopsis:

map_gff3_ids.pl --map id_map.txt genes.gff3

Description:

This script will map the IDs in the following attributes: ID, Name,
Parent, Derives_from

Options:

  --map, -m <id_map.txt>

    A two-column, tab-delimited text file in which the first columns
    has IDs that are currently used in the GFF3 file and the second
    column has the IDs that you want to map into the GFF3 attributes.

";

my ($help, $map_file);
my $opt_success = GetOptions('help'    => \$help,
			     'map|m=s' => \$map_file);

die $usage if $help || ! $opt_success;

my $gff3_file = shift;
die $usage unless $gff3_file;

die $usage unless $map_file;

my $id_map = build_map($map_file);

my $gff3 = Arty::GFF3->new(file => $gff3_file);

print join "\n", $gff3->get_header;

print "\n";
print "# Command='$CL'\n";

my @map_atts = qw(ID Name Parent Derives_from);

while (my $record = $gff3->next_record) {
    my $attributes = $record->{attributes};
    for my $key (@map_atts) {
	if (exists $attributes->{$key}) {
	    my $values = $attributes->{$key};
	    for my $value (@{$values}) {
		$value = (exists $id_map->{$value} ?
			  $id_map->{$value}           :
			  $value);
		print '';
	    }
	    print '';
	}
	print '';
    }
    print $gff3->format_gff3_record($record);
    print "\n";
    print '';
}
print '';
     
#-----------------------------------------------------------------------------
#-------------------------------- SUBROUTINES --------------------------------
#-----------------------------------------------------------------------------

sub build_map {

    my $map_file = shift @_;
    
    open(my $IN, '<', $map_file) or
	die "FATAL : cant_open_file_for_reading : $map_file\n";
    
    # Build ID map
    my %id_map;
  LINE:
    while (my $line = <$IN>) {
	my ($old, $new) = split /\s+/, $line;
	next LINE unless $old && $new;
	if (exists $id_map{$old}) {
	    my $current = $id_map{$old};
	    if ($current ne $new) {
		warn("WARN : id_maps_to_multiple_values_in_map_file : " .
		     "replacing mapping: $old -> $current with: $old -> $new\n");
	    }
	}
	$id_map{$old} = $new;
    }
    
    # Build reverse map to check for duplicate mappings.
    my %reverse_map;
    for my $key (keys %id_map) {
	my $value = $id_map{$key};
	push @{$reverse_map{$value}}, $key;
    }
    
    # Check for duplicate mappings
    for my $key (keys %reverse_map) {
	my $value = $reverse_map{$key};
	if (scalar @{$value} > 1) {
	    my @values = @{$reverse_map{$key}};
	    my $values_txt = join '|', @values;
	    warn("WARN : multiple_keys_map_to_same_id_in_map_file : " .
		 ": $values_txt all map to $key\n");
	}
    }
    return wantarray ? %id_map : \%id_map;
}
