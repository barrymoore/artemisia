#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;

#-----------------------------------------------------------------------------
#----------------------------------- MAIN ------------------------------------
#-----------------------------------------------------------------------------

my $usage = '

Synopsis:

cat file | purify -
purify text_file > pure_text_file # Clean file and write to a new file.
purify -i text_file               # Clean file and rewrite to the same file.
purify text_file | less           # Clean file and pipe output to another program.
purify -i *                       # Clean all files and rewrite to the same file.

Description:

This script will remove ^M or \cM control charachters from a text
file.  These characters can be introduced moving files from Mac or Windows
to Unix.

Options:

  --in_place, -i

    Pufiry the file \'in place\', that is rewrite to the same file.
    Be CAREFUL - your file is not backed up first!!!

  --remove_only

    Only remove the ^M or \cM charachters, don\'t replace them with \n.

  --trim

    Trim trailing whitespace at the end of lines.

  --squish

    Compress multiple empty lines to just one.

';

my ($help, $in_place, $remove_only, $trim, $squish);

my $opt_success = GetOptions('in_place|i'  => \$in_place,
			     'help'        => \$help,
			     'remove_only' => \$remove_only,
			     'trim'        => \$trim,
			     'squish'      => \$squish,
			    );

die $usage unless $opt_success;

my @files = @ARGV;
die $usage unless @files;

for my $file (@files) {

	next unless -T $file || $file eq '-'; # Only do text files

	my $IN;

	if ($file eq '-') {
		open ($IN, "<&=STDIN")   or die "Can't open STDIN:\n$!\n";
	}
	else {
		open ($IN, "<", $file)   or die "Can't open $file for reading: $!\n";
	}

	my $OUT;
	if (! $in_place) {
		open ($OUT, ">&=STDOUT") or die "Can't open STDOUT for writing:\n$!\n";
	}
	else {
		unlink $file;
		open ($OUT, ">", $file)   or die "Can't open $file for writing:\n$!\n";
	}

	while (my $line = <$IN>) {

                if ($trim) {
                        $line =~ s/\s+$/\n/;
                }
                elsif ($squish) {
                        $line =~ s/\n+/\n/;
                }
		else {
			$line =~ s/^M\n?|\cM\n?/\n/g;
		}
		print $OUT $line;
	}
}
