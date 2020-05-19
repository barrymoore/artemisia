#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
use Statistics::Descriptive;
use Statistics::Descriptive::Discrete;
use Number::Format;

#-----------------------------------------------------------------------------
#----------------------------------- MAIN ------------------------------------
#-----------------------------------------------------------------------------
my $usage = "

Synopsis:

fastq_tool -read_count sequence1.fastq [sequence2.fastq ...]

Description:

This script does various conversions and analyses on fastq files.


Options:

  --count	  Return the count of reads in the file.
  --lengths	  Print a summary of the read lengths.
  --seq           Print only the sequences.
  --clean         Print only valid records. Currenlty requires seq and
                  qual to be of equal length.
  --fasta         Print the sequences in fasta format.
  --extract_ids   Extract the records who's IDs are in the given file.
  --quals	  Print a summary of quality values.
  --summary       Print a summary of read counts, lengths and base qualities
  --total         Print total read length (combined).
  --ill2sanger	  Convert Illumina 1.3+ base quality scores to standard
		  Sanger scores.
  --sol2sanger	  Convert Solexa/Illumina 1.0 base quality scores to standard
		  Sanger scores.
  --fastq2fasta   Convert to fasta
  --trim_qual	  Remove reads that don't pass quality filter.
  --guess_format  Guess which format (Sanger Solexa/Illumina 1.0, 1.3, 1.5
		  or Sanger standard) the file is.
  --grep_seq      Print sequence that match a given Perl regular expression.
  --verbose       Talk to me baby!

";


my ($help, $count, $lengths, $seq, $clean, $id_file, $quals, $summary, $total, $ill2sanger,
    $sol2sanger, $fastq2fasta, $trim_qual, $guess_format, $grep_seq,
    $verbose);

my $opt_success = GetOptions('help'          => \$help,
			     'count'	     => \$count,
			     'lengths'	     => \$lengths,
			     'seq'           => \$seq,
			     'clean'         => \$clean,
			     'extract_ids=s' => \$id_file,
			     'quals'	     => \$quals,
			     'summary'       => \$summary,
			     'total'	     => \$total,
			     'ill2sanger'    => \$ill2sanger,
			     'sol2sanger'    => \$sol2sanger,
			     'fastq2fasta'   => \$fastq2fasta,
			     'trim_qual'     => \$trim_qual,
			     'guess_format'  => \$guess_format,
			     'grep_seq=s'    => \$grep_seq,
			     'verbose'       => \$verbose,
			      );

if (! $opt_success) {
    print STDERR join ' : ', ('FATAL',
                              'command_line_parse_error',
                              'Use fastq_tool --help to see correct usage');
}

if ($help) {
 print $usage;
 exit(0);
}

my $file = shift;

die "FATAL : missing_required_input_fastq_file\n" unless $file;
unless ($file eq '-') {
    die "FATAL : file_does_not_exist\n"               unless -e $file;
    die "FATAL : cant_read_fastq_file : $file\n"      unless -r $file;
}

if ($count) {
    read_count($file);
}
elsif ($lengths) {
    length_summary($file);
}
elsif ($seq) {
    seq_only($file);
}
elsif ($clean) {
    clean($file);
}
elsif ($id_file) {
    extract_ids($id_file, $file);
}
elsif ($quals) {
    quality_summary($file)
}
elsif ($summary) {
    all_summary($file)
}
elsif ($total) {
    total_read_length($file)
}
elsif ($ill2sanger) {
    ill2sanger($file);
}
elsif ($sol2sanger) {
    sol2sanger($file);
}
elsif ($fastq2fasta) {
    fastq2fasta($file);
}
elsif ($trim_qual) {
    trim_qualities($file);
}
elsif ($guess_format) {
    guess_format($file);
}
elsif ($grep_seq) {
    grep_seq($file, $grep_seq);
}
else {
    die $usage;
}
#-----------------------------------------------------------------------------
#-------------------------------- SUBROUTINES --------------------------------
#-----------------------------------------------------------------------------

sub read_count {
    my $file = shift;

    my $iterator = make_read_iterator($file);
    my $nf = new Number::Format;

    my $count;
    while (my $read = &$iterator) {
	$count++;
    }
    print ((' ' x 80) . "\r") if $verbose;
    print 'Total reads: ';
    print $nf->format_number($count);
    print "\n";
}

#-----------------------------------------------------------------------------

sub length_summary {
    my $file = shift;

    my $iterator = make_read_iterator($file);

    my $stat = Statistics::Descriptive::Discrete->new();

    my $count;
    my $min;
    print "Length Summary\n";
    print '#' x 50;
    print "\n";
    while (my $read = &$iterator) {
	my $length = length($read->[1]);
	$stat->add_data($length);
    }
    print ((' ' x 80) . "\r") if $verbose;
    print get_stat_summary($stat);
    print "\n";
    # print get_stat_histogram($stat);
}

#-----------------------------------------------------------------------------

sub seq_only {
    my $file = shift;

    my $iterator = make_read_iterator($file);

    while (my $read = &$iterator) {
	print $read->[1] . "\n";
    }
}

#-----------------------------------------------------------------------------

sub clean {
    my $file = shift;

    my $iterator = make_read_iterator($file);

    while (my $read = &$iterator) {
	next if length $read->[1] != length $read->[3];
	print join "\n", @{$read};
	print "\n";
    }
}

#-----------------------------------------------------------------------------

sub extract_ids {
    my ($id_file, $fastq_file) = @_;

    my $iterator = make_read_iterator($fastq_file);

    open (my $IDS, '<', $id_file) or
	die "FATAL : cant_open_file_for_reading : $id_file $!\n";
    my %ids = map {next unless $_;my ($id) = split /\s+/, $_;$id => 1} (<$IDS>);
    close $IDS;

    while (my $read = &$iterator) {
	my $this_id;
	($this_id = $read->[0]) =~ s/^\@//;
	next unless exists $ids{$this_id};
	print join "\n", @{$read};
	print "\n";
    }
}

#-----------------------------------------------------------------------------

sub quality_summary {
    my $file = shift;

    my $iterator = make_read_iterator($file);

    my $stat = Statistics::Descriptive::Discrete->new();

    print "Quality Summary\n";
    print '#' x 50;
    print "\n";
    while (my $read = &$iterator) {
	my @quals = split '', $read->[3];
	map {$_ = ord} @quals;
	$stat->add_data(@quals);
    }
    print ((' ' x 80) . "\r") if $verbose;
    print get_stat_summary($stat);
    print "\n";
    # print get_stat_histogram($stat);
}

#-----------------------------------------------------------------------------

sub all_summary {
    my $file = shift;

    my $iterator = make_read_iterator($file);

    my $read_count;
    my $total_length;
    my $length_stat = Statistics::Descriptive::Discrete->new();
    my $qual_stat   = Statistics::Descriptive::Discrete->new();
    my %atgc_count;
    my @read_location_qual;

    print "Summary\n";
    print '#' x 50;
    print "\n";
    while (my $read = &$iterator) {
	$read_count++;
	my $length = length $read->[1];
	$total_length += $length;
	$length_stat->add_data($length);
	my @quals = split '', $read->[3];
	map {$_ = ord($_) - 33} @quals;
	map {$atgc_count{$_}++} split '', $read->[1];
	my $loc = 0;
	for my $qual (@quals) {
	    $read_location_qual[$loc] ||= Statistics::Descriptive::Discrete->new();
	    $read_location_qual[$loc]->add_data($qual);
	    $loc++;
	}
	$qual_stat->add_data(@quals);
    }
    print ((' ' x 80) . "\r") if $verbose;
    print "Read count\n";
    print "$read_count\n";
    print "Total Length\n";
    print "$total_length\n";
    print "Length Metrics\n";
    print get_stat_summary($length_stat);
    print "\n";
    print "Quality Metrics\n";
    print get_stat_summary($qual_stat);
    print "\n";
    print "Nucleotide Counts\n";
    for my $nt (keys %atgc_count) {
	print uc $nt . ":\t";
	print $atgc_count{$nt};
	my $pct = int($atgc_count{$nt} / $total_length * 100);
	print " ($pct\%)\n";
    }
    print "Base Location/Quality Metric\n";
    print "nt\tmin\tmean\tmedian\tmax\n";
    my $loc = 1;
    for my $read_loc (@read_location_qual) {
	print $loc++ . "\t";
	print $read_loc->min . "\t";
	printf("%.1f\t", $read_loc->mean);
	print $read_loc->median . "\t";
	print $read_loc->max . "\t";
	print "\n";
    }
    # print get_stat_histogram($stat);
}

#-----------------------------------------------------------------------------

sub total_read_length {
    my $file = shift;

    die "Method not yet implimented\n";

    my $iterator = make_read_iterator($file);

    while (my $read = &$iterator) {
    }
}

#-----------------------------------------------------------------------------

sub ill2sanger {
    my $file = shift;

    my $iterator = make_read_iterator($file);

    my $stat = Statistics::Descriptive::Sparse->new();

    # This was an attempt to account for Illumin 1.5+ not using 0,1,2
    # as quality scores, but I don't think it's necessary any more.
    #my $count;
    #my $min;
    #while (my $read = &$iterator) {
    #	my @quals = split '', $read->[3];
    #	map {$_ = ord} @quals;
    #	$stat->add_data(@quals);
    #	if (++$count == 10000) {
    #	    $min = $stat->min;
    #	    last;
    #	}
    #}

    my $adjust = 31; #$min - 33;
    $iterator = make_read_iterator($file);

    while (my $read = &$iterator) {
	my @quals = split '', $read->[3];
	map {$_ = chr(ord($_) - $adjust)} @quals;
	$read->[3] = join '', @quals;
	print join "\n", @{$read};
	print "\n";
    }
}

#-----------------------------------------------------------------------------

sub sol2sanger {
    my $file = shift;

    die "Method not yet implimented\n";

    my $iterator = make_read_iterator($file);

    while (my $read = &$iterator) {
    }
}

#-----------------------------------------------------------------------------

sub fastq2fasta {
    my $file = shift;

    my $iterator = make_read_iterator($file);

    while (my $read = &$iterator) {
	my ($head) = split /\s/, $read->[0];
	$head =~ s/^\@//;
	my $seq  = $read->[1];
	print ">$head\n$seq\n";
    }
}

#-----------------------------------------------------------------------------

sub trim_qualities {
    my $file = shift;

    die "Method not yet implimented\n";

    my $iterator = make_read_iterator($file);

    while (my $read = &$iterator) {
    }
}

#-----------------------------------------------------------------------------

sub guess_format {
    my $file = shift;

    my $iterator = make_read_iterator($file);

    my $stat = Statistics::Descriptive::Sparse->new();

    $| = 1;

    while (my $read = &$iterator) {
	my @quals = split '', $read->[3];
	map {$_ = ord} @quals;
	$stat->add_data(@quals);
	unless (++$count % 1000) {
	    my $min = $stat->min;
	    my $max = $stat->max;
	    if ($min < 59) {
		print "Sanger Format\n";
	    }
	    elsif ($min < 64) {
		print "Solexa/Illumina 1.0 Format\n";
	    }
	    elsif ($min < 66) {
		print "Illumina 1.3 Format\n";
	    }
	    else {
		print "Illumina 1.5+ Format\n";
	    }
	}
    }
}

#-----------------------------------------------------------------------------

sub grep_seq {
    my ($file, $pattern) = @_;

    my $iterator = make_read_iterator($file);

    $pattern = qr/$pattern/;

    while (my $read = &$iterator) {
	my $seq = $read->[1];
	next unless $seq =~ $pattern;
	print join "\n", @{$read};
	print "\n";
    }
}

#-----------------------------------------------------------------------------

sub get_stat_summary {

    my $stats = shift;

    my $nf = new Number::Format;

    my @stat_types = qw(mean median mode standard_deviation variance
			count sum min max);

    my $text;
    for my $stat_type (@stat_types) {
	$text .= "$stat_type\t";
	$text .= $nf->format_number($stats->$stat_type);
	$text .= "\n";
    }
    return $text;
}

#-----------------------------------------------------------------------------

sub make_read_iterator {

    my $file = shift;

    my $IN;
    my $line_count = 1;
    my $read_count = 1;
    if ($file eq '-') {
	open ($IN, "<&=STDIN") or die "Can't open STDIN\n";
    }
    else {
	my $mode = '<';
	if ($file =~ /\.gz$/) {
	    $mode = '-|';
	    $file = "gunzip < $file";
	}
	open ($IN, $mode, $file) or die "Can't open $file for reading:\n$!\n";
    }

    return sub {
	my @data;
	for (0 .. 3) {
	    my $line = <$IN>;
	    return undef unless defined $line;
	    push @data, $line;
	}
	chomp @data;
	my $failed;
	while ($data[0] !~ /^@/ && $data[2] !~ /^\+/) {
	    warn "WARN : skipping_bad_lines : " . join("\t", @data) . "\n";
	    shift @data;
	    my $line = <$IN>;
	    return undef unless defined $line;
	    push @data, $line;
	    $line_count++;
	    die "FATAL : bad_fastq_format : " if ++$failed > 3;
	}
	print STDERR "line: $line_count\t read: $read_count\r" if ($verbose && ! (($read_count / 4) % 1000));
	$line_count += 4; $read_count++;
	return @data ? \@data : undef;
    };
}
