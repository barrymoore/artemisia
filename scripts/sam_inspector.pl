#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
use Set::IntSpan::Fast;
use Statistics::Descriptive::Discrete;
use Text::Graph;
use Text::Graph::DataSet;
use File::Temp qw(tempfile);
use File::Spec;
# use Devel::Size qw(size total_size);
# use IO::Compress::Gzip qw(gzip $GzipError);

#-----------------------------------------------------------------------------
#----------------------------------- MAIN ------------------------------------
#-----------------------------------------------------------------------------

my $usage = "

Synopsis:

sam_inspector --summary alignments.sam

Description:

This script provides simple line-by-line access to SAM/BAM files.  It allows
you do do filtering and reporting on the files.  Access to BAM files
requires that samtools is installed and in your \$PATH.

Options:

  --summary, s

      Print a summary of the SAM file

  --qc

      Print QC metrics on the SAM file.

  --filter, i 'perl code'

      Filter the SAM file based on some criteria.  This option takes a
      string of perl code which is evaled for each read in the file.
      If the code block RETURNS A TRUE VALUE then the read IS SKIPPED.
      See the field tables below, the FILTER section below and the
      examples below.

  --options, o

      Do extra work to parse the optional fields (column 12+) into a
      hash.  Some functions force this behavior, and the user can
      force this behavior with this option.  When this option is used
      then a \$o hash reference is available to the filtering code
      block.  See the the Code and Examples sections below.

  --flag, f INT

      Only output alignments with all bits in INT present in the FLAG
      field.

  --FLAG, F INT

      Skip alignments with all bits present in INT.

  --clean, c

      Remove invalid lines such as those that have an unmapped flag
      and yet still have a mapping quality because bwa mapped them off
      the end of the reference.

  --vaast_clean, a

      Give the SAM/BAM file a hard scrubbing behind the ears to clean
      up potential false positives often found in VAAST analyses.
      This option will remove reads that match any of the following
      criteria (Filter fails if any of):
	1) MAPQ < 20
	2) Number of Best Hits > 1
	3) Number of Mismatches > 5
	4) Insert Size < 100
	5) Insert Size > 300
      Bit Flags:
	1) MUST be paired in sequencing AND mapped in proper
	   pair.
	2) MUST NOT be unmapped OR not primary OR fails
	   filter OR duplicate

  --ill_rg, r

      Adds RG header and tag for Illumina based files.  This uses an
      Illumina formatted header like this:

      \@EAS139:136:FC706VJ:2:2104:15343:197393 1:Y:18:ATCACG
      |--------------------|

      Each unique combination of:
	EAS139	the unique instrument name
	136	the run id
	FC706VJ	the flowcell id
	2	flowcell lane

      Becomes a read group like this:
	\@RG ID:RG_01 # Header
	RG:Z:RG01    # Opt field

      See http://en.wikipedia.org/wiki/FASTQ_format.

  --sample, p

      Provide the sample name to be used for \@RG SM:Sample_Name.
      Currently only used by --ill_rg.  Default is to use the filename
      with the bam/sam extension removed.

  --regions, g

      Limit analysis to a region by passing a region to samtools view.
      This only works on indexed BAM files.

  --bam, b

      Output in BAM format

  --fastq, q

      Extract fastq from the SAM/BAM file. Single-end libraries only.

  --headers, h

      Print headers with output

  --intervals, v

      Print a list of intervals where there is any read coverage

  --tmpdir, t

      Use the given directory as the location for temporary files.
      Used by --ill_rg.

  --print_flags

      Print a comma separated list of bit flag values (as words) for
      each alignment.

  --estimate_read_count 100000,.25

    Estimate the number of reads based on file size and line size from
    reading the top of the file. Provide 2 comma separated values.
    The first value is the number of lines to sample, and the second
    value if the compression ratio of BAM to SAM.  The second value is
    optional.

  --print_sm

    Print the SM tag from the \@RG header.  This is the sample name as
    described in the BAM header.

Code:

The --filter option takes a block of perl code and the read is SKIPPED
IF the code block returns TRUE.  Think of the code as defining SKIP
IF.  The \$a variable is available as a hash reference with the 11
required fields available as lowercase keys (see below).  If the
--options option is set a \$o variable is also available as a hash
reference with the tags in the optional 12th field parsed
\$o->{TAG}{type} and \$o->{TAG}{value}.  For example:

\$a = ('qname' => 'HWI-ST479:174:C03Y6ACXX:6:2307:17131:61693'
      'flag'  => 147
      'rname' => 'chr1'
      'pos'   => 14600
      'map'   => 23
      'cigar' => '101M'
      'mpos'  => 14518
      'mrnm'  => '='
      'isize' => '-182'
      'seq'   => 'CCCAAGGAAGTAGGTCTGAGCTGCTTGTCCTGGCTGTGTCCATGTCAGAGCAACGGCCCAAGTCTAGGTCTGGGGGGGAAGGTGTCATGTAGCCCCCTACG'
      'qual'  => ':?8AAA?8ABAA:>?A??7?7/B\@\@=:6&?=?=6BBBBA?8&8AA?A>A<\@=<<DB\@>;7FFC=5\'4>03?\@D=8\'GGGFAE<D>FD?:)8>/BBB;B\@8='
      'length' => 100 # Added by sam_inspector length(\$a->{seq})
      );

\$o = ('X0' => HASH
	 'type' => 'i'
	 'value' => 1
     );

Examples:

# Print a summary on a SAM file
sam_inspector --summary alignment.sam

# Print alignments from a BAM file for the region chr1:1-10000000 with
# MAPQ >= 30.  Print output in BAM format.
sam_inspector --region chr1:1-10000000 --filter '\$a->{map} < 30' \
  --bam --headers alignment.bam

# As above but also require the X0 optional feild to be <= 1;
sam_inspector --region chr1:1-10000000 \
  --filter '\$a->{map} < 30 || (exists \$o->{X0} && \$o->{X0}{value} > 1)' \
  --bam --headers alignment.bam



Reference Tables:

Mandatory SAM/BAM fields
See: http://samtools.sourceforge.net/SAM1.pdf
--------------------------------------------------------------------------------
Field  Descriptions
================================================================================
qname  Query (pair) NAME
flag   bitwise FLAG
rname  Reference sequence NAME
pos    1-based leftmost POSition/coordinate of clipped sequence
map    QMAPping Quality (Phred-scaled)
cigar  extended CIGAR string
mrnm   Mate Reference sequence NaMe (\342\200\230=\342\200\231 if same as RNAME)
mpos   1-based Mate POSistion
isize  Inferred insert SIZE
seq    query SEQuence on the same strand as the reference
qual   query QUALity (ASCII-33 gives the Phred base quality)
opt    variable OPTional fields in the format TAG:VTYPE:VALUE

Bitwise Flags
See http://picard.sourceforge.net/explain-flags.html
    http://bio-bwa.sourceforge.net/bwa.shtml

--------------------------------------------------------------------------------
Flag	Dec	Name            Description
================================================================================
0x0001	1	PAIRED		the read is paired in sequencing
0x0002	2	PAIR_MAPPED	the read is mapped in a proper pair
0x0004	4	UNMAPPED	the query sequence itself is unmapped
0x0008	8	MATE_UNMAPPED	the mate is unmapped
0x0010	16	REVERSE		strand of the query (1 for reverse)
0x0020	32	MATE_REVERSE	strand of the mate
0x0040	64	FIRST_READ	the read is the first read in a pair
0x0080	128	SECOND_READ	the read is the second read in a pair
0x0100	256	NOT_PRIMARY	the alignment is not primary
0x0200	512	FAILS		the read fails platform/vendor quality checks
0x0400	1024	DUPLICATE	the read is either a PCR or an optical duplicate

BWA Opt fields
See http://bio-bwa.sourceforge.net/bwa.shtml
    http://samtools.sourceforge.net/SAM1.pdf
--------------------------------------------------------------------------------
Tag	Meaning
================================================================================
NM	Edit distance
MD	Mismatching positions/bases
AS	Alignment score
BC	Barcode sequence
X0	Number of best hits
X1	Number of suboptimal hits found by BWA
XN	Number of ambiguous bases in the referenece
XM	Number of mismatches in the alignment
XO	Number of gap opens
XG	Number of gap extentions
XT	Type: Unique/Repeat/N/Mate-sw
XA	Alternative hits; format: (chr,pos,CIGAR,NM;)*
XS	Suboptimal alignment score
XF	Support from forward/reverse alignment
XE	Number of supporting seeds

";


my ($help, $summary, $qc, $FILTER, $bflag, $BFLAG, $clean,
    $vaast_clean, $region, $ill_rg, $sample_name, $bam_format, $fastq,
    $headers, $intervals, $OPTIONS, $TMPDIR, $print_flags, $print_sm,
    $estimate_read_count);

my $opt_success = GetOptions(
			     'help|h'                 =>  \$help,
			     'summary|s'              =>  \$summary,
			     'qc'                     =>  \$qc,
			     'filter|i=s'             =>  \$FILTER,
			     'FLAG|F=i'               =>  \$BFLAG,
			     'flag|f=i'               =>  \$bflag,
			     'clean|c'                =>  \$clean,
			     'vaast_clean|a'          =>  \$vaast_clean,
			     'regions|g=s'            =>  \$region,
			     'ill_rg|r'               =>  \$ill_rg,
			     'sample|p=s'             =>  \$sample_name,
			     'bam|b'                  =>  \$bam_format,
			     'fastq|q'                =>  \$fastq,
			     'headers'                =>  \$headers,
			     'intervals|v'            =>  \$intervals,
			     'options|o'              =>  \$OPTIONS,
			     'tmpdir|t=s'             =>  \$TMPDIR,
			     'print_flags'            =>  \$print_flags,
			     'print_sm'               =>  \$print_sm,
			     'estimate_read_count=s'  =>  \$estimate_read_count,
			     );

if (! $opt_success) {
    print STDERR join ' : ', ('FATAL',
			      'command_line_parse_error',
			      'Use sam_inspector --help to see correct usage');
}

if ($help) {
 print $usage;
 exit(0);
}

# Handle defaults and required combinations
$region ||= '';
$FILTER && $OPTIONS++;
$TMPDIR ||= './';
$TMPDIR .= '/' unless $TMPDIR =~ /\/$/;

my %HEADERS;

my $PAIRED        = 0x0001; # 1
my $PAIR_MAPPED   = 0x0002; # 2
my $UNMAPPED      = 0x0004; # 4
my $MATE_UNMAPPED = 0x0008; # 5
my $REVERSE       = 0x0010; # 16
my $MATE_REVERSE  = 0x0020; # 32
my $FIRST_READ    = 0x0040; # 64
my $SECOND_READ   = 0x0080; # 128
my $NOT_PRIMARY   = 0x0100; # 256
my $FAILS         = 0x0200; # 512
my $DUPLICATE     = 0x0400; # 1024

my @files = @ARGV;

die $usage unless ! grep {-r @_} @files;

# Set predefined filters
if ($clean) {
	$FILTER = '($a->{flag} & $UNMAPPED) && ($a->{map} != 0 || $a->{cigar} ne "*")';
}
if ($vaast_clean) {                                             # Filters Fail IF
    $FILTER = ('exists $o->{X0} && $o->{X0}{value} > 1 || '   . # Number of best hits > 1
	       'exists $o->{XM} && $o->{XM}{value} > 5 || '   . # Number of mismatches must be > 5
	       'abs($a->{isize}) < 100 || ' .			# Insert size < 100
	       'abs($a->{isize}) > 300 || ' .			# Insert size > 300
	       '$a->{map} < 20');                               # Mapping quality < 20

    # Bit Flag MUST be paired in sequencing AND mapped in proper pair
    $bflag = $PAIRED | $PAIR_MAPPED;
    # Bit Flag MUST NOT be unmapped OR not primary OR fails filter OR duplicate
    $BFLAG = $UNMAPPED + $NOT_PRIMARY + $FAILS + $DUPLICATE;
}

# Run appropriate functions
if ($summary) {
  build_summary(\@files);
}
if ($qc) {
  build_qc(\@files);
}
elsif ($ill_rg) {
  add_illumina_readgroup(\@files);
}
elsif ($intervals) {
  calc_intervals(\@files);
}
elsif ($fastq) {
  print_fastq(\@files);
}
elsif ($print_flags) {
  print_flags(\@files);
}
elsif ($estimate_read_count) {
  estimate_read_count($estimate_read_count, \@files);
}
elsif ($print_sm) {
  print_sm(\@files);
}
else {
  print_file(\@files);
}

#-----------------------------------------------------------------------------
#-------------------------------- SUBROUTINES --------------------------------
#-----------------------------------------------------------------------------

sub build_summary {
  
  my $files = shift;
  
  my %sets;
  my $isizes  = Statistics::Descriptive::Discrete->new();
  my $lengths = Statistics::Descriptive::Discrete->new();
  my $best_hits  = Statistics::Descriptive::Discrete->new();
  my $mismatches = Statistics::Descriptive::Discrete->new();
  
  my $count;
  my %mapped_length;
  my $unmapped_length;
  my %raw_flags;
  my %flags;
  my %qnames;
  my %rnames;
  my %mapqs;
  
  my $bar_graph = Text::Graph->new('Bar', maxlen => 50, showval => 1);
  
  for my $file (@{$files}) {
    my $iterator = make_iterator($file, $region, 'options');
    
    while (my $a = &{$iterator}) {
      $count++;
      my ($qname, $flag, $rname, $pos, $mapq, $cigar, $mrnm,
	  $mpos, $isize, $seq, $qual, $opt)
	=
	  @{$a}{qw(qname flag rname pos map cigar mrnm mpos
		   isize seq qual opt)};
      
      $qnames{$qname}++;
      $raw_flags{$flag}++;
      ($flag & $PAIRED)        && $flags{paired}++;
      ($flag & $PAIR_MAPPED)   && $flags{pair_mapped}++;
      ($flag & $UNMAPPED)      && $flags{unmapped}++;
      ($flag & $MATE_UNMAPPED) && $flags{mate_unmapped}++;
      ($flag & $REVERSE)       && $flags{reverse}++;
      ($flag & $MATE_REVERSE)  && $flags{mate_reverse}++;
      ($flag & $FIRST_READ)    && $flags{first_read}++;
      ($flag & $SECOND_READ)   && $flags{second_read}++;
      ($flag & $NOT_PRIMARY)   && $flags{not_primary}++;
      ($flag & $FAILS)	     && $flags{fails}++;
      ($flag & $DUPLICATE)     && $flags{duplicate}++;
      
      $mapped_length{$rname} += $a->{length} unless ($flag & $UNMAPPED);
      $mapped_length{$rname} += $a->{length} if ($flag & $PAIR_MAPPED);
      
      $rnames{$rname}++;
      $sets{$rname} ||= Set::IntSpan::Fast->new();
      $sets{$rname}->add_range($pos, $pos + $a->{length} - 1) if $pos;
      $sets{$rname}->add_range($mpos, $mpos + $a->{length} - 1) if $mpos;
      $mapqs{$mapq}++;
      $isizes->add_data(abs($isize)) if $isize;
      $lengths->add_data($a->{length}) if $a->{length};
      $best_hits->add_data($a->{opt}{X0}{value})  if $a->{opt}{X0}{value};
      $mismatches->add_data($a->{opt}{XM}{value}) if $a->{opt}{XM}{value};
      
    }
  }
  my %coverage;
  for my $rname (keys %sets) {
    my $iter = $sets{$rname}->iterate_runs();
    while (my ( $start, $end ) = $iter->()) {
      $coverage{$rname} += ($end - $start + 1);
    }
  }
  my $total_coverage;
  map {$total_coverage += $_} values %coverage;
  
  my $total_mapped_length;
  map {$total_mapped_length += $_} values %mapped_length;
  
  my %depth;
  for my $rname (keys %mapped_length) {
    $depth{$rname} = $coverage{$rname} / $mapped_length{$rname};
  }
  
  print "TOTAL ALIGNMENTS:  $count\n\n";
  
  print "TOTAL LENGTH:  " . $lengths->sum . "\n";
  print "MAPPED LENGTH:  $total_mapped_length\n";
  print "MEAN   LENGTH:  " . sprintf("%.2f", $lengths->mean) . "\n";
  print "MEDIAN LENGTH:  " . $lengths->median . "\n\n";
  
  print "QNAMES:  " . (scalar keys(%qnames)) . "\n\n";
  
  print "RNAMES:\n";
  print $bar_graph->to_string(\%rnames,
			      sort =>
			      sub {sort {my ($x) = ($a =~ /(\d+)/) || 99;
					 my ($y) = ($b =~ /(\d+)/) || 99;
					 $x <=> $y || $a cmp $b} @_});
  print "\n";
  
  print "Coverage:\n";
  print $bar_graph->to_string(\%coverage,
			      sort =>
			      sub {sort {my ($x) = ($a =~ /(\d+)/) || 99;
					 my ($y) = ($b =~ /(\d+)/) || 99;
					 $x <=> $y || $a cmp $b} @_});
  print "\n";
  
  print "Mapped Length:\n";
  print $bar_graph->to_string(\%mapped_length,
			      sort =>
			      sub {sort {my ($x) = ($a =~ /(\d+)/) || 99;
					 my ($y) = ($b =~ /(\d+)/) || 99;
					 $x <=> $y || $a cmp $b} @_});
  print "\n";
  
  print "Depth of Coverage:\n";
  print $bar_graph->to_string(\%depth,
			      sort =>
			      sub {sort {my ($x) = ($a =~ /(\d+)/) || 99;
					 my ($y) = ($b =~ /(\d+)/) || 99;
					 $x <=> $y || $a cmp $b} @_});
  print "\n";
  
  print "TOTAL COVERAGE:  $total_coverage\n\n";
  print "AVERAGE DEPTH COVERAGE:  " . sprintf("%.2f", $total_mapped_length / $total_coverage) . "\n\n";
  
  print "MEAN    INSERT SIZE:  " . sprintf("%.2f", $isizes->mean) . "\n";
  print "TR_MEAN INSERT SIZE:  " . sprintf("%.2f", $isizes->trimmed_mean(0.1,0.1)) . "\n";
  print "MIN     INSERT SIZE:  " . $isizes->min . "\n\n";
  print "1ST Q   INSERT SIZE:  " . $isizes->quantile(1) . "\n";
  print "MEDIAN  INSERT SIZE:  " . $isizes->median . "\n";
  print "3RD Q   INSERT SIZE:  " . $isizes->quantile(3) . "\n";
  print "STDEV   INSERT SIZE:  " . $isizes->standard_deviation() . "\n";
  print "MAX     INSERT SIZE:  " . $isizes->max . "\n\n";
  print "INSERT_SIZE:\n";
  my @is_bins;
  my $is_max = $isizes->median * 3;
  my $step = abs(int(($isizes->quantile(3)/2 - $isizes->quantile(1)*2)/10));
  for (my $bin = $isizes->quantile(1)/2; $bin <= $isizes->quantile(3)*2; $bin += $step) {push @is_bins, $bin};
  print $bar_graph->to_string($isizes->frequency_distribution_ref(\@is_bins), sort => sub {sort {$a <=> $b} @_});
  print "\n\n";
  
  
  print "MEAN    BEST HITS:  " . sprintf("%.2f", $best_hits->mean) . "\n";
  print "TR_MEAN BEST HITS:  " . sprintf("%.2f", $best_hits->trimmed_mean(0.1,0.1)) . "\n";
  print "MIN     BEST HITS:  " . $best_hits->min . "\n";
  print "1ST Q   BEST HITS:  " . $best_hits->quantile(1) . "\n";
  print "MEDIAN  BEST HITS:  " . $best_hits->median . "\n";
  print "3RD Q   BEST HITS:  " . $best_hits->quantile(3) . "\n";
  print "STDEV   BEST HITS:  " . $best_hits->standard_deviation() . "\n";
  print "MAX     BEST HITS:  " . $best_hits->max . "\n";
  print "BEST HITS:\n";
  print $bar_graph->to_string($best_hits->frequency_distribution_ref([(1..10)]), sort => sub {sort {$a <=> $b} @_});
  print "\n\n";
  
  print "MEAN    MISMATCHES:  " . sprintf("%.2f", $mismatches->mean) . "\n";
  print "TR_MEAN MISMATCHES:  " . sprintf("%.2f", $mismatches->trimmed_mean(0.1,0.1)) . "\n";
  print "MIN     MISMATCHES:  " . $mismatches->min . "\n\n";
  print "1ST Q   MISMATCHES:  " . $mismatches->quantile(1) . "\n";
  print "MEDIAN  MISMATCHES:  " . $mismatches->median . "\n";
  print "3RD Q   MISMATCHES:  " . $mismatches->quantile(3) . "\n";
  print "STDEV   MISMATCHES:  " . $mismatches->standard_deviation() . "\n";
  print "MAX     MISMATCHES:  " . $mismatches->max . "\n\n";
  print "MISMATCHES:\n";
  print $bar_graph->to_string($mismatches->frequency_distribution_ref([(0..20)]), sort => sub {sort {$a <=> $b} @_});
  print "\n\n";
  
  print "FLAGS:\n";
  print $bar_graph->to_string(\%flags, [qw(paired pair_mapped
					   unmapped mate_unmapped
					   reverse mate_reverse
					   first_read second_read
					   not_primary fails
					   duplicate)]);
  
  print "\n\n";
  print "MAPQ:\n";
  print $bar_graph->to_string(\%mapqs, sort => sub {sort {$a <=> $b} @_});
  print "\n\n";
  print '';
}

#-----------------------------------------------------------------------------

sub build_qc {
  
  my $files = shift;
  
  my %sets;
  my $isizes  = Statistics::Descriptive::Discrete->new();
  my $best_hits  = Statistics::Descriptive::Discrete->new();
  
  my $count;
  my %raw_flags;
  my %flags;
  my %qnames;
  my %rnames;
  my %mapqs;
  
  for my $file (@{$files}) {
    my $iterator = make_iterator($file, $region, 'options');
    
    while (my $a = &{$iterator}) {
      $count++;
      my ($qname, $flag, $rname, $pos, $mapq, $cigar, $mrnm,
	  $mpos, $isize, $seq, $qual, $opt)
	=
	  @{$a}{qw(qname flag rname pos map cigar mrnm mpos
		   isize seq qual opt)};
      
      $qnames{$qname}++;
      $raw_flags{$flag}++;
      ($flag & $PAIRED)        && $flags{paired}++;
      ($flag & $PAIR_MAPPED)   && $flags{pair_mapped}++;
      ($flag & $UNMAPPED)      && $flags{unmapped}++;
      ($flag & $MATE_UNMAPPED) && $flags{mate_unmapped}++;
      ($flag & $REVERSE)       && $flags{reverse}++;
      ($flag & $MATE_REVERSE)  && $flags{mate_reverse}++;
      ($flag & $FIRST_READ)    && $flags{first_read}++;
      ($flag & $SECOND_READ)   && $flags{second_read}++;
      ($flag & $NOT_PRIMARY)   && $flags{not_primary}++;
      ($flag & $FAILS)	     && $flags{fails}++;
      ($flag & $DUPLICATE)     && $flags{duplicate}++;
      
      $rnames{$rname}++;
      $mapqs{$mapq}++;
    }
  }
  print "TOTAL ALIGNMENTS:  $count\n\n";
  print "QNAMES:  " . (scalar keys(%qnames)) . "\n\n";
  
}

#-----------------------------------------------------------------------------

sub fails_filter {

    my $a = shift;

    # QNAME  Query (pair) NAME
    # FLAG   bitwise FLAG
    # RNAME  Reference sequence NAME
    # POS    1-based leftmost POSition/coordinate of clipped sequence
    # MAP    QMAPping Quality (Phred-scaled)
    # CIGAR  extended CIGAR string
    # MRNM   Mate Reference sequence NaMe (‘=’ if same as RNAME)
    # MPOS   1-based Mate POSistion
    # ISIZE  Inferred insert SIZE
    # SEQ    query SEQuence on the same strand as the reference
    # QUAL   query QUALity (ASCII-33 gives the Phred base quality)
    # OPT    variable OPTional fields in the format TAG:VTYPE:VALUE

    my $o = $a->{opt};

    my $eval_value = eval $FILTER;
    die "Fatal Error in code ref: $FILTER\n$@\n" if $@;

    my ($f, $F);
    $f = ! ($a->{flag} & $bflag) if $bflag;
    $F =   ($a->{flag} & $BFLAG) if $BFLAG;
    
    return $eval_value || $f || $F;
  }

#-----------------------------------------------------------------------------

sub clean_file {

    my $files = shift;

    $FILTER = '($a->{flag} & $UNMAPPED) && ($a->{map} != 0 || $a->{cigar} ne "*")';

    for my $file (@{$files}) {
      my $fh = print_fh_out();
      my $iterator = make_iterator($file, $region, undef, $fh);
      while (my $a = &{$iterator}) {
	print_alignment($a, $fh);
      }
    }
  }

#-----------------------------------------------------------------------------

sub vaast_clean {

    my $files = shift;

    # my $PAIRED        = 0x0001; # 1
    # my $PAIR_MAPPED   = 0x0002; # 2
    # my $UNMAPPED      = 0x0004; # 4
    # my $MATE_UNMAPPED = 0x0008; # 5
    # my $REVERSE       = 0x0010; # 16
    # my $MATE_REVERSE  = 0x0020; # 32
    # my $FIRST_READ    = 0x0040; # 64
    # my $SECOND_READ   = 0x0080; # 128
    # my $NOT_PRIMARY   = 0x0100; # 256
    # my $FAILS         = 0x0200; # 512
    # my $DUPLICATE     = 0x0400; # 1024

    # This read will FAIL the filter if any of the following is true:
    $FILTER = ('exists $o->{X0} && $o->{X0}{value} > 1 || '   . # Number of best hits < 1
	       'exists $o->{XM} && $o->{XM}{value} > 5 || '   . # Number of mismatches must be < 5
	       '$a->{isize} < 100 || ' .			# Insert size < 100
	       '$a->{isize} > 300 || ' .			# Insert size > 300
	       #'($a->{flag} & $UNMAPPED) || ' .                 # Read is unmapped
	       # Read is paired, but pair is not mapped.
	       #'($a->{flag} & $PAIRED) && ! ($a->{flag} & $PAIR_MAPPED) || ' .
	       '$a->{map} < 20'); # Mapping quality < 20

    for my $file (@{$files}) {
	my $fh = get_fh_out();
	my $iterator = make_iterator($file, $region, 'options', $fh);
	while (my $a = &{$iterator}) {
	    print_alignment($a, $fh);
	}
    }
}

#-----------------------------------------------------------------------------

sub print_flags {

    my $files = shift;

    # --------------------------------------------------------------------------------
    # Flag	Dec	Name            Description
    # ================================================================================
    # 0x0001	1	PAIRED		the read is paired in sequencing
    # 0x0002	2	PAIR_MAPPED	the read is mapped in a proper pair
    # 0x0004	4	UNMAPPED	the query sequence itself is unmapped
    # 0x0008	8	MATE_UNMAPPED	the mate is unmapped
    # 0x0010	16	REVERSE		strand of the query (1 for reverse)
    # 0x0020	32	MATE_REVERSE	strand of the mate
    # 0x0040	64	FIRST_READ	the read is the first read in a pair
    # 0x0080	128	SECOND_READ	the read is the second read in a pair
    # 0x0100	256	NOT_PRIMARY	the alignment is not primary
    # 0x0200	512	FAILS		the read fails platform/vendor quality checks
    # 0x0400	1024	DUPLICATE	the read is either a PCR or an optical duplicate


    for my $file (@{$files}) {
	my $iterator = make_iterator($file, $region, 'options');
	while (my $a = &{$iterator}) {
	    my %flags = (PAIRED		=> $a->{flag} & $PAIRED,
			 PAIR_MAPPED	=> $a->{flag} & $PAIR_MAPPED,
			 UNMAPPED	=> $a->{flag} & $UNMAPPED,
			 MATE_UNMAPPED	=> $a->{flag} & $MATE_UNMAPPED,
			 REVERSE	=> $a->{flag} & $REVERSE,
			 MATE_REVERSE	=> $a->{flag} & $MATE_REVERSE,
			 FIRST_READ	=> $a->{flag} & $FIRST_READ,
			 SECOND_READ	=> $a->{flag} & $SECOND_READ,
			 NOT_PRIMARY	=> $a->{flag} & $NOT_PRIMARY,
			 FAILS		=> $a->{flag} & $FAILS,
			 DUPLICATE	=> $a->{flag} & $DUPLICATE,
		);
	    my @names = grep {$flags{$_}} keys %flags;
	    print join ',', @names;
	    print "\n";
	}
    }
}

#-----------------------------------------------------------------------------

sub estimate_read_count {

	my ($data, $files) = @_;

	my ($line_count, $compression) = split /,/, $data;
	$line_count  ||= 100000;
	$compression ||= 0.25;

	print '#';
	print join("\t", qw(Filename SM_ID File_Size Est_Read_Length
			    Median_Line_Length Est_Read_Count
			    Total_Seq_Length Hsap_WGS_Depth));
	print "\n";

	for my $file (@{$files}) {
		my $iterator = make_iterator($file);
		my $read_lengths  = Statistics::Descriptive::Discrete->new();
		my $line_lengths = Statistics::Descriptive::Discrete->new();
		my $count = 0;
		# my $line_data;
		while (my $a = &{$iterator}) {
			next if $count++ < $line_count;
			last if $count++ > $line_count * 2;
			$read_lengths->add_data($a->{length}) if $a->{length};

			my $line =
			  join("\t", @{$a}{qw(cigar flag isize
					      length map mpos mrnm
					      pos qname qual rname
					      seq)}, @{$a->{opt}});
			my $line_length = length($line);
			# $line_data .= "$line\n";
			$line_lengths->add_data($line_length);
			print '';
		}
		my $SM_ID = ref $HEADERS{RG} eq 'ARRAY' ? $HEADERS{RG}[0]{SM} : '';
		# my $compressed_data;
		# gzip(\$line_data, \$compressed_data)
		#   or die "FATAL : gzip failed : $GzipError\n";
		# my $data_size = size($line_data);
		# my $compressed_size = size($compressed_data);
		# my $compression = $compressed_size / $data_size;

		my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$fsize,
		    $atime,$mtime,$ctime,$blksize,$blocks)
		  = stat($file);
		my $esize = $fsize / $compression;
		my $median_read_length = $read_lengths->count ? $read_lengths->median : 0;
		my $median_line_length = $line_lengths->count ? $line_lengths->median : 0;
		my $read_count = $median_line_length ? sprintf("%.0f", $esize / $median_line_length) : 0;
		my $total_seq_length = sprintf("%.0f", $read_count * $median_read_length);
		my $three_gig_coverage = sprintf("%.2f", $total_seq_length / 3_000_000_000);
		my ($volume,$directories,$filename) = File::Spec->splitpath($file);

		print join("\t", ($filename, $SM_ID, $fsize, $median_read_length,
				  $median_line_length, $read_count,
				  $total_seq_length,
				  $three_gig_coverage));

		print "\n";
	}
}



#-----------------------------------------------------------------------------

sub add_illumina_readgroup {

    my $files = shift;

    for my $file (@{$files}) {
      $sample_name ||= $file;
      $sample_name =~ s/\.(sam|bam)$//;
	my $temp_file = $TMPDIR . $file . '.tmp';
	open(my $TEMP, '>', $temp_file) or
	    die "FATAL : cant_open_file_for_reading : $temp_file\n";
	my $iterator = make_iterator($file, $region, 'options', $TEMP);
	my $counter = make_counter(1);
	my %rgs;
	while (my $a = &{$iterator}) {
	    my $qname = $a->{qname};
	    my ($instrument, $run_id, $flow_cell, $lane) = split /:/, $qname;
	    my $rg_key = join '|', ($instrument, $run_id, $flow_cell, $lane);
	    $rgs{$rg_key} ||= sprintf("RG_%02d", &$counter());
	    $a->{opt}{RG} = {type  => 'Z', value => $rgs{$rg_key}};
	    print_alignment($a, $TEMP);
	}
	close $TEMP;

	for my $rg_key (keys %rgs) {
	  my %rg_data = (ID => $rgs{$rg_key},
			 SM => $sample_name);
	    push @{$HEADERS{RG}}, \%rg_data;
	}
	my $fh = get_fh_out();
	open($TEMP, '<', $temp_file);
	print_headers(\%HEADERS, $fh);
	while (<$TEMP>) {
	    print $fh $_;
	}
	`rm -f $temp_file`;
    }
}

#-----------------------------------------------------------------------------

sub calc_intervals {

    my $files = shift;

    my %intervals;

    for my $file (@{$files}) {
	my $iterator = make_iterator($file, $region);
	while (my $a = &{$iterator}) {
	    my $rname = $a->{rname};
	    my $pos   = $a->{pos};
	    my $mpos  = $a->{mpos};
	    $intervals{$rname} ||= Set::IntSpan::Fast->new();
	    $intervals{$rname}->add_range($pos, $pos + $a->{length} - 1) if $pos;
	    $intervals{$rname}->add_range($mpos, $mpos + $a->{length} - 1) if $mpos;
	}
    }
    for my $rname (keys %intervals) {
	my $iter = $intervals{$rname}->iterate_runs();
	while (my ( $start, $end ) = $iter->()) {
	    print join "\t", ($rname, $start, $end);
	    print "\n";
	}
    }
}

#-----------------------------------------------------------------------------

sub print_headers {

  my ($headers, $fh) = @_;
  
  $fh || open($fh, '>-') or die "FATAL : cant_open_stdout_for_writing : STDOUT";
  
  # $HEADERS{$head_tag}{$key} = $value;
  
  my %order = (HD => 1,
	       SQ => 2,
	       RG => 3,
	       CO => 4);
  
  for my $tag (sort {($order{$a} || 99) <=> ($order{$b} || 99)} keys %HEADERS) {
    my $lines = $HEADERS{$tag};
    for my $line (@{$lines}) {
      print $fh "\@$tag";
      for my $key (keys %{$line}) {
	my $value = $line->{$key};
	print $fh "\t$key:$value";
      }
      print $fh "\n";
    }
  }
}
  
#-----------------------------------------------------------------------------

sub print_sm {

  my ($files) = @_;

  print join("\t", qw(Filename SM_ID));
  print "\n";
  
  for my $file (@{$files}) {
    my $iterator = make_iterator($file);
    my $a = &{$iterator};
    my $SM_ID = ref $HEADERS{RG} eq 'ARRAY' ? $HEADERS{RG}[0]{SM} : '';
    print "$file\t$SM_ID\n";
  }
}

#-----------------------------------------------------------------------------

sub print_alignment {

    my ($a, $fh) = @_;

    $fh || open($fh, '>-') or die "FATAL : cant_open_stdout_for_writing : STDOUT";

    my @opts = ();
    if (ref $a->{opt} eq 'HASH') {
	my $opts = $a->{opt};
	for my $key (keys %{$opts}) {
	    push @opts, join ':', ($key, @{$opts->{$key}}{qw(type value)});
	}
    }
    else {
	@opts = @{$a->{opt}};
    }
    print $fh join "\t", (@{$a}{qw(qname flag rname pos map cigar mrnm mpos isize
			      seq qual)}, @opts);
    print $fh "\n";
}

#-----------------------------------------------------------------------------

sub print_file {

    my $files = shift;

    for my $file (@{$files}) {
	my $fh = get_fh_out();
	my $iterator = make_iterator($file, $region, undef, $fh);
	while (my $a = &{$iterator}) {
	    print_alignment($a, $fh);
	}
    }
}

#-----------------------------------------------------------------------------

sub print_fastq {

    my $files = shift;

    for my $file (@{$files}) {
	my $iterator = make_iterator($file, $region);
	while (my $a = &{$iterator}) {
	    #qname flag rname pos map cigar mrnm mpos isize seq qual
	    my ($id, $seq, $qual) = @{$a}{qw(qname seq qual)};
	    print join "\n", ('@' . $id, $seq, '+', $qual);
	    print "\n";
	}
    }
}

#-----------------------------------------------------------------------------

sub make_iterator {

    my ($file, $region, $options, $fh) = @_;

    $region ||= '';
    if ($region) {
	`samtools index $file` unless -e ($file . 'bai');
    }

    $file = "samtools view -h $file $region |" if $file =~ /\.bam$/;
    my $IN;
    if ($file eq '-') {
	open ($IN, "<&=STDIN") or die "FATAL : cant_open_STDIN :\n";
    }
    else {
	open ($IN, $file) or
	    die "FATAL : cant_open_file_for_reading : $file\n";
    }

    return
	sub {
	  LINE:
	    while (my $line  = <$IN>) {
		chomp $line;
		if ($line =~/^@/) {
		    if ($headers) {
			print $fh "$line\n";
		    }
		    my ($head_tag, @pairs) = split /\t+/, $line;
		    $head_tag =~ s/^\@//;
		    my %pairs;
		    for my $pair (@pairs) {
			my ($key, $value) = split /:/, $pair;
			$pairs{$key} = $value;
		    }
		    push @{$HEADERS{$head_tag}}, \%pairs;
		    next LINE;
		}
		# QNAME  Query (pair) NAME
		# FLAG   bitwise FLAG
		# RNAME  Reference sequence NAME
		# POS    1-based leftmost POSition/coordinate of clipped sequence
		# MAP    QMAPping Quality (Phred-scaled)
		# CIGAR  extended CIGAR string
		# MRNM   Mate Reference sequence NaMe (‘=’ if same as RNAME)
		# MPOS   1-based Mate POSistion
		# ISIZE  Inferred insert SIZE
		# SEQ    query SEQuence on the same strand as the reference
		# QUAL   query QUALity (ASCII-33 gives the Phred base quality)
		# OPT    variable OPTional fields in the format TAG:VTYPE:VALUE
		my %alignment;
		my @opts;
		(@alignment{qw(qname flag rname pos map cigar mrnm mpos isize seq qual)}, @opts) = split /\t/, $line;
		if ($options || $OPTIONS) {
		    my %opts;
		    for my $opt (@opts) {
			my ($tag, $type, $value) = split /:/, $opt;
			$opts{$tag}{value} = $value;
			$opts{$tag}{type} = $type;
		    }
		    $alignment{opt} = \%opts;
		}
		else {
		    $alignment{opt} = \@opts;
		}
		$alignment{length} = (length $alignment{seq}) - 1;
		if ($FILTER) {
		    next LINE if fails_filter(\%alignment);
		}
		return %alignment ? \%alignment : undef;
	    }
	}
}

#-----------------------------------------------------------------------------

sub make_counter {
    my $counter = shift || 0;
    return sub {$counter++};
}

#-----------------------------------------------------------------------------

sub get_fh_out {

    my $fh;
    if ($bam_format) {
	open($fh, '|-', 'samtools view -Sb -') or die "FATAL : cant_open_pipe : samtools view -Sb\n";
    }
    else {
	open($fh, '>-') or die "FATAL : cant_open_stdout_for_writing : STDOUT\n";
    }
    return $fh;
}

#-----------------------------------------------------------------------------
