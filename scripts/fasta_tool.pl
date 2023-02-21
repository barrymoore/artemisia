#!/usr/bin/perl

# Interpreted by shell on systems that don't support the shebang...
eval 'exec /usr/bin/perl  -S $0 ${1+"$@"}'
  if 0; # ...but perl will ignore the eval

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/../perl/lib";
use Getopt::Long;
use Bio::SeqIO;
use IO::All;

#-----------------------------------------------------------------------------
#----------------------------------- MAIN ------------------------------------
#-----------------------------------------------------------------------------

my $usage = "

Synopsis:

fasta_tool [-options] fasta_file

Description: The script takes a fasta file and can search it, reformat
it, and manipulate it in a variety of ways that can prove very usful.
For options that provide the ability to evaluate code, use Perl.

Options:

  --chunks <integer>

    Split a single multi-fasta file into the given number of sub
    files specified by chunks.

  --split

    Split a multi-fasta into individual files.  One for each fasta.


  --break <integer>

    Break a the sequence from a single-fasta file into a multi-fasta
    file with subsequences of the given size.

  --eval_code <code>

    Run the given code on (\$seq_obj, \$seq or \$header).  If
    the code block returns a positive value then the sequence is
    printed.  This can be used to build complex and custom filters.

  --eval_all <code>

    Run the given code on (\$seq_obj, \$seq or \$header).
    Prints all sequences regardless of the return value of the
    evaled code.  This can but used to perform operations (e.g. soft
    to hard masking with s/[a-z]/N/g, but still print every sequence
    even if it's unaltered.

  --extract_ids <id_file.txt>

    Extract all of the sequences who's IDs are found in the given
    file.

  --grep_header <pattern>

    Grep through a multi fasta file and print out only the fasta
    sequences that have a match in the header. Use grepv_header for
    negation.

  --grepv_header <pattern>

    Grep through a multi fasta file and print out only the fasta
    sequences that DO NOT have a match in the header.

  --grep_seq <pattern>

    Grep through a multi fasta file and print out only the fasta
    sequences that have a match in the sequence. Use grepv_seq for
    negation.

  --grepv_seq <pattern>

    Grep through a multi fasta file and print out only the fasta
    sequences that DO NOT have a match in the sequence.

  --wrap <integer>

    Wrap the sequence output to a given number of columns.

  --translate <string>

    Translate a given nucleotide sequence to protein sequence.
    Accepts 0,1,2 (for the phase) or 'maker' if you want to use the
    frame from MAKER produced headers

  --trim_maker_utr

    Prints MAKER produced transcipts without the leading and
    trailing UTR sequence

  --seq_only

    Print only the sequence (without the header) to STDOUT.  This
    can also be accomplished with grep -v '>' fasta_file.

  --nt_count

    Print the number and percentage of every nt/aa found in the
    sequence.

  --summary

    For functions that can report data for every sequence
    (nt_count), use this flag to report only summary data for all
    sequences combined.

  --length

    Print the length of each sequence.

  --mapable_length

    Print the mapable length (remove all Ns) of each sequence.

  --total_length

    Print the total length of all sequences.

  --n50

    Calculate the N-50 (http://en.wikipedia.org/wiki/N50_statistic)
    of the sequences in the file.

  --tab

    Print the header and sequence on the same line separated by a
    tab.

  --table

    Print in table format rather than fasta format.

  --print

    Print the sequence.  Use in conjuction with 'wrap' or other
    formatting commands to reformat the sequence.

  --reverse

    Reverse the order of the sequences in a fasta file.

  --rev_seq

    Reverse the sequence (the order of the nt/aa).

  --comp_seq

    Complement the nucleotide sequence.

  --rev_comp

    Reverse compliment a sequence.  Same as --rev_seq && --comp_seq
    together.

  --uniq

    Print only uniq sequences.  This method only compares complete
    sequences.

  --uniq_sub

    Print only uniq sequences, but also check that shorter sequences
    are not perfect substrings of longer sequences.

  --shuffle_order

    Randomize the order of the sequences in a multi-fasta file.

  --shuffle_seq

    Randomize the sequence (the order of the nt/aa).

  --shuffle_codon

    Randomize the order of the codons in a nucleotide sequence.

  --shuffle_pick

    Pick a given number of sequences from a multi-fasta file.

  --select

    Pass in a file with IDs and return sequences with these IDs.

  --remove

    Pass in a file with IDs and remove sequences with these IDs.

  --map_ids

    Pass in a file with two columns of IDs and map the IDs in the
    fasta headers from the first column of the ID file to the second
    column of the ID file.  If an ID in the fasta header is not
    found in the first column of the ID file then issue a warning,
    but leave the ID unmapped.

  --fix_prot

    Fix protein fasta files for use as blast database.  Removes spaces
    and '*' and replaces any non amino acid codes with C.

  --subseq

    Grab a sub-sequence from a fasta file based on coordinates.  The
    requested coordinates are in the form seqid:start-end;

  --filter_horter

    Filter (remove) entries shorter than the filter. IE \"--filter_shorter 800\"
    will filter all sequences <= 800 basepairs long.

  --filter_longer

    Filter (remove entries longer than the filter. IE \"--filter_longer 800\" 
    will filter all sequences > 800 basepairs long.

  --mask_fasta

    Masks the genome using coordinates from a gff3 file

";

my ($summary, $chunks, $split, $break, $eval_code, $eval_all,
    $extract_ids, $grep_header, $grepv_header, $grep_seq, $grepv_seq,
    $wrap, $count, $translate, $seq_only, $nt_count, $length,
    $mapable_length, $total_length, $n50, $tab, $reverse, $rev_seq,
    $comp_seq, $rev_comp, $uniq, $uniq_sub, $shuffle_order,
    $shuffle_seq, $shuffle_codon, $shuffle_pick, $select_file,
    $remove_file, $print, $mRNAseq, $EST, $trim_maker_utr, $table,
    $map_ids, $fix_prot, $subseq, $tile, $filter_shorter,
    $filter_longer, $mask_fasta);

GetOptions('summary'          => \$summary,
	   'chunks=i'         => \$chunks,
	   'split'            => \$split,
	   'break=i'          => \$break,
	   'eval_code=s'      => \$eval_code,
	   'eval_all=s'       => \$eval_all,
	   'extract_ids=s'    => \$extract_ids,
	   'grep_header=s'    => \$grep_header,
	   'grep_seq=s'       => \$grep_seq,
	   'grepv_header=s'   => \$grepv_header,
	   'grepv_seq=s'      => \$grepv_seq,
	   'wrap=i'           => \$wrap,
	   'count'            => \$count,
	   'translate=s'      => \$translate,
	   'trim_maker_utr'   => \$trim_maker_utr,
	   'seq_only'         => \$seq_only,
	   'nt_count'         => \$nt_count,
	   'length'           => \$length,
	   'mapable_length'   => \$mapable_length,
	   'total_length'     => \$total_length,
	   'n50'              => \$n50,
	   'tab'              => \$tab,
	   'table'            => \$table,
	   'print'            => \$print,
	   'reverse'          => \$reverse,
	   'rev_seq'          => \$rev_seq,
	   'comp_seq'         => \$comp_seq,
	   'rev_comp'         => \$rev_comp,
	   'uniq'             => \$uniq,
	   'uniq_sub'         => \$uniq_sub,
	   'shuffle_order'    => \$shuffle_order,
	   'shuffle_seq'      => \$shuffle_seq,
	   'shuffle_codon'    => \$shuffle_codon,
	   'shuffle_pick=i'   => \$shuffle_pick,
	   'remove=s'         => \$remove_file,
	   'select=s'         => \$select_file,
	   'fix_prot'         => \$fix_prot,
	   'mRNAseq'          => \$mRNAseq,
	   'EST'              => \$EST,
	   'map_ids=s'        => \$map_ids,
	   'subseq=s'         => \$subseq,
	   'tile=s'           => \$tile,
	   'filter_shorter=i' => \$filter_shorter,
	   'filter_longer=i'  => \$filter_longer,
	   'mask_fasta=s'     => \$mask_fasta
	  );

my $file = shift;
unless ($file || ! -t STDIN){
    print $usage;
    exit;
}

if ($rev_comp) {$rev_seq++; $comp_seq++}

my @warning = ('WARN', 'method_not_thouroughly_tested', $0);

handle_message(@warning) if grep {$_} ($extract_ids,
				       $reverse,
				       $rev_seq,
				       $comp_seq,
				       $shuffle_order,
				       $shuffle_seq,
				       $shuffle_codon,
				       $shuffle_pick,
				       $mask_fasta
				      );

# These functions handle their own printing;
$print++ unless grep {$_} ($chunks,
			   $split,
			   $break,
			   $eval_code,
			   $eval_all,
			   $extract_ids,
			   $grep_header,
			   $grep_seq,
			   $grepv_header,
			   $grepv_seq,
			   $count,
			   $translate,
			   $seq_only,
			   $nt_count,
			   $length,
			   $mapable_length,
			   $total_length,
			   $n50,
			   $reverse,
			   $rev_seq,
			   $comp_seq,
			   $uniq,
			   $uniq_sub,
			   $shuffle_order,
			   $shuffle_seq,
			   $shuffle_codon,
			   $shuffle_pick,
			   $remove_file,
			   $select_file,
			   $mRNAseq,
			   $EST,
			   $map_ids,
			   $subseq,
			   $tile,
			   $filter_shorter,
			   $filter_longer,
			   $mask_fasta
			  );

$nt_count++ if $summary;

if(defined $translate && $translate !~ /^\d+$/ && $translate ne 'maker'){
    $translate = 0;
}

my $IN;
if (! $file && ! -t STDIN) {
  open ($IN, "<&=STDIN") or handle_message('FATAL', 'cant_open_stdin');
}
elsif (! -e $file) {
  handle_message('FATAL', 'file_does_not_exist', $file);
}
elsif (! -r $file) {
  handle_message('FATAL', 'file_is_not_readable', $file);
}
else {
	open ($IN, $file) or handle_message('FATAL', 'cant_open_file_for_reading', $file);
}

#Bioperl object for main fasta input file.
my $seq_io  = Bio::SeqIO->new(-fh => $IN,
			      -format => 'Fasta');

chunks($file, $chunks)	    if $chunks;
split_fasta()	            if $split;
break_fasta($break)         if $break;
eval_code($eval_code)       if $eval_code;
eval_all($eval_all)         if $eval_all;
extract_ids($extract_ids)   if $extract_ids;
grep_header($grep_header)   if $grep_header;
grep_seq($grep_seq)         if $grep_seq;
grepv_header($grepv_header) if $grepv_header;
grepv_seq($grepv_seq)       if $grepv_seq;
translate()                 if defined($translate);
trim_maker_utr()            if $trim_maker_utr;
seq_only()                  if $seq_only;
nt_count()	            if $nt_count;
seq_length()                if $length;
mapable_length()            if $mapable_length;
total_length()              if $total_length;
n50()                       if $n50;
tab()	                    if $tab;
reverse_order()             if $reverse;
rev_comp()                  if $rev_seq;
rev_comp()                  if $comp_seq;
uniq()                      if $uniq;
uniq_sub()                  if $uniq_sub;
shuffle_order()             if $shuffle_order;
shuffle_seq()               if $shuffle_seq;
shuffle_codon()             if $shuffle_codon;
shuffle_pick($shuffle_pick) if $shuffle_pick;
remove_ids($remove_file)    if $remove_file;
select_ids($select_file)    if $select_file;
map_ids($map_ids)           if $map_ids;
subseq($file, $subseq)      if $subseq;
fix_prot()                  if $fix_prot;
print_seq()                 if $print;
mRNAseq()                   if $mRNAseq;
EST()                       if $EST;
filter_shorter($filter_shorter) if $filter_shorter;
filter_longer($filter_longer) if $filter_longer;
mask_fasta($mask_fasta)		if $mask_fasta;


#-----------------------------------------------------------------------------
#-------------------------------- SUBROUTINES --------------------------------
#-----------------------------------------------------------------------------

#-----------------------------------------------------------------------------
#
#  --chunks <integer>
#
#      Split a single multi-fasta file into the given number of sub files.
#
#-----------------------------------------------------------------------------

sub chunks {
	my($file, $chunks) = @_;

	my $outfile_base; #Create a base name for the output file.
	($outfile_base = $file) =~ s/\.[^\.]*$//; #Input file name minus it's extension.

	my $file_size = io($file)->size; #What's the size of our input file.

	#How many chunks should the input file be split into?
	my $chunk_size = int($file_size/$chunks) + ($file_size % $chunks);

	#How many digits should the output file iterations be sprintf'ed to=?
	my $digits = int(log($chunks)/log(10)) + 1;

	#I felt like using a closure today.
	my $file_counter = make_counter();

	my $out;
	my $file_name;
	#Loop over each sequence
	while ( my $seq = $seq_io->next_seq() ) {
		#Get an Bio::SeqIO fh if we don't have one, or if the current output file
		#has grown too large.
		if (! $out || (io($file_name)->size > $chunk_size)) {
			($out, $file_name) = get_output_stream($outfile_base, $digits, $file_counter);
		}
		#Write it to the file.
		$out->write_seq($seq);
	}
}

#-----------------------------------------------------------------------------

sub get_output_stream{
    my ($outfile_base, $digits, $file_counter) = @_;
    my $file_count = $file_counter->();
    #Build/format the file_name.
    $file_count = sprintf "%0${digits}s", $file_count;
    my $file_name = $outfile_base . "_$file_count" . '.fasta';
    #Get Bio::SeqIO object
    my $out = Bio::SeqIO->new(-file   => ">$file_name",
			      -format => 'fasta');
    return ($out, $file_name);
}

#-----------------------------------------------------------------------------

sub make_counter {
    #Initialize the counter.
    my $file_counter = 0;

    #Increment the counter.
    return sub{$file_counter++}
}

#-----------------------------------------------------------------------------
#
#  --split
#
#      Split a multi-fasta into individual files.  One for each fasta.
#
#-----------------------------------------------------------------------------

sub split_fasta {
	while ( my $seq = $seq_io->next_seq() ) {
		my $file_out = $seq->display_id . ".fasta";

		#Get Bio::SeqIO object
		my $out = Bio::SeqIO->new(-file   => ">$file_out",
					  -format => 'fasta');
		#Write it to the file.
		$out->write_seq($seq);
	}
}

#-----------------------------------------------------------------------------
#
#   --break <integer>
#
#     Break a the sequences from a fasta file into subsequences of the
#     given size.
#
#-----------------------------------------------------------------------------

sub break_fasta {

  my ($break) = @_;

 SEQ:
  while ( my $seq_obj = $seq_io->next_seq() ) {

    my $header = get_header($seq_obj);
    my $seq    = $seq_obj->seq;
    my $length = length($seq);

    my $start = 0;
    my $counter;
    while ($start < $length) {
      $break = $length - $start if $start + $break > $length;
      my $sub_seq = substr($seq, $start, $break);
      #print join("\t", $start, $break, $length);
      #print "\n";
      print_this_seq($header, $sub_seq);
      $start += $break;
    }
  }
  exit(0);
}

#-----------------------------------------------------------------------------
#
#  --eval_code <code>
#
#      Run the given code on (\$seq_obj, \$seq or \$header).  If the code
#      block returns a positive value then the sequence is printed.  This can be
#      used to build complex and custom filters.
#
#-----------------------------------------------------------------------------


sub eval_code {
	my ($code) = @_;

	while (my $seq_obj = $seq_io->next_seq) {
		my $header = get_header($seq_obj);
		my $seq = $seq_obj->seq;

		my $return_value = eval $code;
		handle_message('FATAL', 'error_in_code_ref',
			       "$code : $@") if $@;
		next unless $return_value;
		print_this_seq($header, $seq);
	}

}

#-----------------------------------------------------------------------------
#
#  --eval_all <code>
#
#      Run the given code on (\$seq_obj, \$seq or \$header).  Prints all
#      sequences regardless of the return value of the evaled code.  This can
#      but used to perform operations (e.g. soft to hard masking with
#      s/[a-z]/N/g, but still print every sequence even if it's unaltered.
#
#-----------------------------------------------------------------------------


sub eval_all {
	my ($code) = @_;

	while (my $seq_obj = $seq_io->next_seq) {
		my $header = get_header($seq_obj);
		my $seq = $seq_obj->seq;

		eval $code;
		handle_message('FATAL', 'error_in_code_ref',
			       "$code : $@") if $@;
		print_this_seq($header, $seq);
	}
}

#-----------------------------------------------------------------------------
#
#  --extract_ids <id_file.txt>
#
#      Extract all of the sequences who's IDs are found in the given file.
#
#-----------------------------------------------------------------------------


sub extract_ids {

    my $id_file = shift;

    open(my $IN, '<', $id_file) or handle_message('FATAL',
						  'cant_open_file_for_reading',
						  $id_file);

    my %ids = map {$_ => 1 unless (/^\#/ || ! $_)} (<$IN>);

    while (my $seq_obj = $seq_io->next_seq) {
	my $id = $seq_obj->display_id;
	my $header = get_header($seq_obj);
	my $seq = $seq_obj->seq;

	if (exists $ids{$id}) {
	    print_this_seq($header, $seq);
	}
    }
}

#-----------------------------------------------------------------------------
#
#  --grep_header <pattern>
#
#      Grep through a multi fasta file and print out only the fasta
#      sequences that have a match in the header. Use grepv_header for
#      negation.
#
#-----------------------------------------------------------------------------

sub grep_header {
	my ($pattern) = @_;

	while (my $seq_obj = $seq_io->next_seq) {
		my $header = get_header($seq_obj);
		$header .= " " . $seq_obj->description;
		my $seq = $seq_obj->seq;

		if ($header =~ /$pattern/) {
			print_this_seq($header, $seq);
		}
	}
}

#-----------------------------------------------------------------------------
#
#  --grep_header <pattern>
#
#      Grep through a multi fasta file and print out only the fasta
#      sequences that DO NOT have a match in the header.
#
#-----------------------------------------------------------------------------

sub grepv_header {
	my ($pattern) = @_;

	while (my $seq_obj = $seq_io->next_seq) {
		my $header = get_header($seq_obj);
		my $seq = $seq_obj->seq;

		if ($header !~ /$pattern/) {
			print_this_seq($header, $seq);
		}
	}
}

#-----------------------------------------------------------------------------

{my $i = 0;
sub mRNAseq {
    my $size = 50;

    while (my $seq_obj = $seq_io->next_seq) {
	my $seq = $seq_obj->seq;

	my $len = length($seq);

	for (my $j = 0; $j < $len/5; $j++){
	    my $range = $len - $size;

	    my $start; my $end;
	    if($range < 0){
		$start = 0 ;
		$end = $len - 1;
	    }
	    else{
		$start = int(rand($range));
		$end = $start + $size - 1;
	    }

	    my $l = $end - $start + 1;

		my $header = "sequence_".$i++;
		print_this_seq($header, substr($seq, $start, $l));
	    }
	}
}

#-----------------------------------------------------------------------------

sub EST {

    while (my $seq_obj = $seq_io->next_seq) {
	my $seq = $seq_obj->seq;

	my $len = length($seq);


	my $range = $len - 500;
	my $min = 250;

	if($range < 0 || $min < 0){
	    my $header = "sequence_".$i++;
	    print_this_seq($header, $seq);
	    next;
	}

	my $A = int(rand($range) + $min);
	my $start = int(rand($range) + $min);
	my $end = int(rand($range));
	my $B = int(rand($range) + $min);

	my $l = abs($end - $start + 1);
	if($l > 250){
	    my $header = "sequence_".$i++;
	    print_this_seq($header, substr($seq, $start, $l));
	}

	$l = abs($A - 0 + 1);
	if($l > 250){
	    my $header = "sequence_".$i++;
	    print_this_seq($header, substr($seq, 0, $l));
	}

	$l = abs($len - $B + 1);
	if($l > 250){
	    my $header = "sequence_".$i++;
	    print_this_seq($header, substr($seq, $B, $l));
	}

    }
}
}

#-----------------------------------------------------------------------------
#
#  --grep_seq <pattern>
#
#      Grep through a multi fasta file and print out only the fasta
#      sequences that have a match in the sequence. Use grepv_seq for
#      negation.
#
#-----------------------------------------------------------------------------

sub grep_seq {
	my ($pattern) = @_;

	while (my $seq_obj = $seq_io->next_seq) {
		my $header = get_header($seq_obj);
		my $seq = $seq_obj->seq;
		$seq =~ s/\s//g;

		if ($seq =~ /$pattern/) {
			print_this_seq($header, $seq);
		}
	}
}

#-----------------------------------------------------------------------------
#
#  --grepv_seq <pattern>
#
#      Grep through a multi fasta file and print out only the fasta
#      sequences that DO NOT have a match in the sequence.
#
#-----------------------------------------------------------------------------

sub grepv_seq {
	my ($pattern) = @_;

	while (my $seq_obj = $seq_io->next_seq) {
		my $header = get_header($seq_obj);
		my $seq = $seq_obj->seq;
		$seq =~ s/\s//g;

		if ($seq !~ /$pattern/) {
			print_this_seq($header, $seq);
		}
	}
}

#-----------------------------------------------------------------------------
#
#  --fix_prot
#
#    Fix protein fasta files for use as blast database.  Removes spaces
#    and '*' and replaces any non amino acid codes with C.
#
#-----------------------------------------------------------------------------

sub fix_prot {
	while (my $seq_obj = $seq_io->next_seq) {
		my $header = get_header($seq_obj);
		my $seq = $seq_obj->seq;
		$seq =~ s/[\s\*]//g;
		$seq =~ s/[^abcdefghiklmnpqrstvwyzxABCDEFGHIKLMNPQRSTVWYZX\-\n]/C/g;
		next if($seq eq ''); #skip empty fasta entries
		print_this_seq($header, $seq);
	}
}

#-----------------------------------------------------------------------------
#
#  --translate <string>
#
#      Translate a given nucleotide sequence to protein sequence.
#      Accepts 0,1,2 (for the phase) or 'maker' if you want to use the
#      frame from MAKER produced headers
#
#-----------------------------------------------------------------------------

sub translate {
	while (my $seq_obj = $seq_io->next_seq) {
		my $header = get_header($seq_obj);
		my $frame;
		my $offset;
		if($translate eq 'maker'){
		    $header =~ /offset:(\d+)/;
		    $frame = ($1 % 3);
		    $offset = ($1 - $frame)/3;
		}
		else{
		    $frame = $translate % 3;
		    $offset = ($translate - $frame)/3;
		}
		my $pep_seq = $seq_obj->translate(-frame => $frame)->seq;
		$pep_seq = substr($pep_seq, $offset);
		$pep_seq =~ s/^([^\*]+).*/$1/;
		print_this_seq($header, $pep_seq);
	}
}

#-----------------------------------------------------------------------------
#
#  --trim_maker_utr
#
#      Prints MAKER produced transcipts without the leading and
#      trailing UTR sequence
#
#-----------------------------------------------------------------------------

sub trim_maker_utr {
	while (my $seq_obj = $seq_io->next_seq) {
		my $header = get_header($seq_obj);
		my $frame;
		my $offset;

		$header =~ /offset:(\d+)/;

		handle_message('WARN', 'non_maker_transcripts', $header)
		  if(! defined $1 || $1 eq '');
		$frame = ($1 % 3);
		$offset = ($1 - $frame)/3; #peptide offet without frame

		my $tra_seq = $seq_obj->seq;
		my $pep_seq = $seq_obj->translate(-frame => $frame)->seq;

		$pep_seq = substr($pep_seq, $offset);
		$pep_seq =~ s/^([^\*]+\*?).*/$1/;
		$offset = 3 * $offset + $frame; #make transcript offset
		my $length = 3 * length($pep_seq); #length of substring to get
		my $fix = $offset + $length - length($tra_seq);
		$length -= $fix	if($fix > 0);
		$tra_seq = substr($tra_seq, $offset, $length);

		print_this_seq($header, $tra_seq);
	}
}

#-----------------------------------------------------------------------------
#
#  --seq_only
#
#      Print only the sequence (without the header) to STDOUT.  This
#      can also be accomplished with grep -v '>' fasta_file.
#
#-----------------------------------------------------------------------------

sub seq_only {
	while (my $seq_obj = $seq_io->next_seq) {
		my $seq = $seq_obj->seq;
		$seq = wrap_seq($seq, $wrap) if $wrap;
		print $seq . "\n";
	}
}

#-----------------------------------------------------------------------------
#
#  --nt_count
#
#      Print the number and percentage of every nt/aa found in the
#      sequence.
#
#  --summary
#      For functions that can report data for every sequence (nt_count),
#      use this flag to report only summary data for all sequences combined.
#
#-----------------------------------------------------------------------------

sub nt_count {
	my %all_seq_count;
	my $total_count;

	while (my $seq_obj = $seq_io->next_seq) {
		my %this_seq_count;
		my $this_count;
		my $id = $seq_obj->display_id;
		my $seq = $seq_obj->seq;
		$seq =~ s/\s//g;
		my @nts = split //, $seq;
		for my $nt (@nts) {
			$all_seq_count{$nt}++;
			$this_seq_count{$nt}++;
			$this_count++;
			$total_count++;
		}

		next if $summary;
		print "$id:\n";
		print '-' x 80;
		print "\n";
		for my $nt (sort keys %this_seq_count) {
			my $round = sprintf ("%.4f", $this_seq_count{$nt} / $this_count * 100);
			print join "\t", ($nt,
					  $this_seq_count{$nt},
					  $round,
					 );
			print '%' . "\n";
		}

		my %this_report;
		map {$this_report{aA} += $this_seq_count{$_} if $this_seq_count{$_}} qw(a A);
		map {$this_report{tT} += $this_seq_count{$_} if $this_seq_count{$_}} qw(t T);
		map {$this_report{gG} += $this_seq_count{$_} if $this_seq_count{$_}} qw(g G);
		map {$this_report{cC} += $this_seq_count{$_} if $this_seq_count{$_}} qw(c C);

		map {$this_report{aAtT} += $this_report{$_} if $this_report{$_}} qw(aA tT);
		map {$this_report{gGcC} += $this_report{$_} if $this_report{$_}} qw(gG cC);
		map {$this_report{aAtTgGcC} += $this_report{$_} if $this_report{$_}} qw(aAtT gGcC);

		map {$this_report{atgc}   += $this_seq_count{$_} if $this_seq_count{$_}} qw(a t g c);
		map {$this_report{nN}     += $this_seq_count{$_} if $this_seq_count{$_}} qw(n N);
		map {$this_report{atgcnN} += $this_seq_count{$_} if $this_seq_count{$_}} qw(atgc nN);

		for my $key (sort keys %this_report) {

			print join "\t", ($key,
					  $this_report{$key},
					  sprintf ("%.4f", $this_report{$key} / $this_count * 100),
					 );
			print '%' . "\n";
		}
		print "\n\n";
	}

	print "All sequences combined:\n";
	print '-' x 80;
	print "\n";

	for my $nt (sort keys %all_seq_count) {
		print join "\t", ($nt,
				  $all_seq_count{$nt},
				  sprintf ("%.4f", $all_seq_count{$nt} / $total_count * 100),
				 );
		print '%' . "\n";
	}

	my %all_report;
	map {$all_report{aA} += $all_seq_count{$_} if $all_seq_count{$_}} qw(a A);
	map {$all_report{tT} += $all_seq_count{$_} if $all_seq_count{$_}} qw(t T);
	map {$all_report{gG} += $all_seq_count{$_} if $all_seq_count{$_}} qw(g G);
	map {$all_report{cC} += $all_seq_count{$_} if $all_seq_count{$_}} qw(c C);

	map {$all_report{aAtT} += $all_report{$_} if $all_report{$_}} qw(aA tT);
	map {$all_report{gGcC} += $all_report{$_} if $all_report{$_}} qw(gG cC);
	map {$all_report{aAtTgGcC} += $all_report{$_} if $all_report{$_}} qw(aAtT gGcC);

	map {$all_report{atgc}   += $all_seq_count{$_} if $all_seq_count{$_}} qw(a t g c);
	map {$all_report{nN}     += $all_seq_count{$_} if $all_seq_count{$_}} qw(n N);
	map {$all_report{atgcnN} += $all_seq_count{$_} if $all_seq_count{$_}} qw(atgc nN);

	for my $key (sort keys %all_report) {

		print join "\t", ($key,
				  $all_report{$key},
				  sprintf ("%.4f", $all_report{$key} / $total_count * 100),
				 );
		print '%' . "\n";
	}
	print "\n";
	print "Total nts\t$total_count\n";
}

#-----------------------------------------------------------------------------
#
#  --length
#
#      Print the length of each sequence.
#
#-----------------------------------------------------------------------------

sub seq_length {
    my $count = 0;
    my $total;
    while (my $seq_obj = $seq_io->next_seq) {
	my $id = $seq_obj->display_id;
	my $length = $seq_obj->length;
	$total += $length;
	$count++;
	print "$id\t$length\n";
    }
    print "Total\t$total\n" if $count > 1;
}

#-----------------------------------------------------------------------------
#
#  --mapable_length
#
#      Print the mapable length (all sequence not N) of each sequence.
#
#-----------------------------------------------------------------------------

sub mapable_length {
    my $count = 0;
    my $total;
    while (my $seq_obj = $seq_io->next_seq) {
	my $id = $seq_obj->display_id;
	my $seq = $seq_obj->seq;
	$seq =~ s/N+//gi;
	my $mapable_length = length($seq);
	$total += $mapable_length;
	$count++;
	print "$id\t$mapable_length\n";
    }
    print "Total\t$total\n" if $count > 1;
}

#-----------------------------------------------------------------------------
#
#  --total_length
#
#      Print the total length of all sequences.
#
#-----------------------------------------------------------------------------

sub total_length {
    my $total_length;
    while (my $seq_obj = $seq_io->next_seq) {
	$total_length += $seq_obj->length;
    }
    print $total_length . "\n";
}

#-----------------------------------------------------------------------------
#
#  --n50
#
#      Calculate the N-50 (http://en.wikipedia.org/wiki/N50_statistic)
#      of the sequences in the file.
#
#-----------------------------------------------------------------------------

sub n50 {
    my $total_length;
    my @lengths;
    while (my $seq_obj = $seq_io->next_seq) {
	my $length = $seq_obj->length;
	$total_length += $length;
	push @lengths, $length;
    }
    my $cumulative_length;
    my $last_length;
    my $n50;
    for my $length (sort {$b <=> $a} @lengths) {
	$cumulative_length += $length;
	if ($cumulative_length > $total_length / 2) {
	    $n50 = $length;
	    last;
	}
	elsif ($cumulative_length == $total_length / 2) {
	    $n50 = $length;
	    $last_length = $length;
	    last;
	}
	$last_length = $length;
    }
    $n50 = int((($n50 + $last_length) / 2) + 0.5);
    print $n50 . "\n";
}

#-----------------------------------------------------------------------------
#
#  --tab
#
#      Print the header and sequence on the same line separated by a
#      tab.
#
#-----------------------------------------------------------------------------

sub tab {
    while (my $seq_obj = $seq_io->next_seq) {
	my $header = get_header($seq_obj);
	my $seq = $seq_obj->seq;
		$seq =~ s/[\s\n\t]//g;
		print "$header\t$seq\n";
	}
}

#-----------------------------------------------------------------------------
#
#  --print
#
#      Print the sequence.  Use in conjuction with 'wrap' or other
#      formatting commands to reformat the sequence.
#
#-----------------------------------------------------------------------------

sub print_seq {
	while (my $seq_obj = $seq_io->next_seq) {
		my $header = get_header($seq_obj);
		my $seq = $seq_obj->seq;
		print_this_seq($header, $seq);

	}
}

#-----------------------------------------------------------------------------
#
#  --reverse
#
#      Reverse the order of the sequences in a fasta file.
#
#-----------------------------------------------------------------------------

sub reverse_order {
	my @seqs;
	while (my $seq_obj = $seq_io->next_seq) {
		my $header = get_header($seq_obj);
		my $seq = $seq_obj->seq;
		push @seqs, {seq => $seq,
			     header => $header,
			    };
	}

	@seqs = reverse @seqs;

	for my $seq (@seqs) {
		print_this_seq($seq->{header}, $seq->{seq});
	}
}

#-----------------------------------------------------------------------------
#
#  --rev_seq
#
#      Reverse the sequence (the order of the nt/aa).
#
#  --comp_seq
#
#      Complement the nucleotide sequence.
#
#  --rev_comp
#
#      Reverse compliment a sequence.  Same as --rev_seq && --comp_seq
#      together.
#
#-----------------------------------------------------------------------------

sub rev_comp{
	while (my $seq_obj = $seq_io->next_seq) {
		my $header = get_header($seq_obj);
		my $seq = $seq_obj->seq;
		$seq = reverse $seq   if $rev_seq;
		if ($comp_seq) {
			$seq =~ tr/acgtrymkswhdbvACGTRYMKSWHDBV
				  /tgcayrkmswdhvbTGCAYRKMSWDHVB/;
		}
		print_this_seq($header, $seq);
	}
}

#-----------------------------------------------------------------------------
#
#  --uniq
#
#    Print only uniq sequences.  This method only compares complete
#    sequences.
#
#-----------------------------------------------------------------------------

sub uniq{
  my %seen;
  while (my $seq_obj = $seq_io->next_seq) {
    my $header = get_header($seq_obj);
    my $seq = $seq_obj->seq;
    print_this_seq($header, $seq) unless exists $seen{$seq};
    $seen{$seq}++;
  }
}

#-----------------------------------------------------------------------------
#
#  --uniq_sub
#
#    Print only uniq sequences, but also check that shorter sequences
#    are not perfect substrings of longer sequences.
#
#-----------------------------------------------------------------------------

sub uniq_sub {
  my @seqs;
  while (my $seq_obj = $seq_io->next_seq) {
    my $header = get_header($seq_obj);
    my $seq = $seq_obj->seq;
    push @seqs, [$header, $seq];
  }

  @seqs = sort {length $a->[1] <=> length $b->[1]} @seqs;

 OUTER:
  for my $outer_idx (0 .. $#seqs) {
    my $start_idx = $outer_idx + 1;
    for my $inner_idx ($start_idx .. $#seqs) {
      if ($seqs[$inner_idx][1] =~ /$seqs[$outer_idx][1]/) {
	handle_message('WARN', 'skipping_sequence', "($seqs[$outer_idx][0]) " .
	  "$seqs[$outer_idx][1]\n");
	next OUTER;
      }
    }
    print_this_seq($seqs[$outer_idx][0], $seqs[$outer_idx][1]);
  }
}

#-----------------------------------------------------------------------------
#
#  --shuffle_order
#
#      Randomize the order of the sequences in a multi-fasta file.
#
#-----------------------------------------------------------------------------

sub shuffle_order {
	my @seqs;
	while (my $seq_obj = $seq_io->next_seq) {
		my $header = get_header($seq_obj);
		my $seq = $seq_obj->seq;
		push @seqs, {seq => $seq,
			     header => $header,
			    };
	}

	shuffle(\@seqs);

	for my $seq (@seqs) {
		print_this_seq($seq->{header}, $seq->{seq});
	}
}

#-----------------------------------------------------------------------------
#
#  --shuffle_seq
#
#      Randomize the sequence (the order of the nt/aa).
#
#
#-----------------------------------------------------------------------------

sub shuffle_seq {
	while (my $seq_obj = $seq_io->next_seq) {
		my $header = get_header($seq_obj);
		my @seq = split //, $seq_obj->seq;
		shuffle(\@seq);
		my $seq = join '', @seq;
		print_this_seq($header, $seq);
	}
}

#-----------------------------------------------------------------------------
#
#  --shuffle_codon
#
#      Randomize the order of the codons in a nucleotide sequence.
#
#-----------------------------------------------------------------------------

sub shuffle_codon {
	while (my $seq_obj = $seq_io->next_seq) {
		my $header = get_header($seq_obj);
		my $seq = $seq_obj->seq;
		my @codons = $seq =~ /(.{3})/g;
		shuffle(\@codons);
		$seq = join '', @codons;
		print_this_seq($header, $seq);
	}
}

#-----------------------------------------------------------------------------
#
#  --shuffle_pick
#
#      Pick a given number of sequences from a multi-fasta file.
#
#-----------------------------------------------------------------------------

sub shuffle_pick {
	my $shuffle_pick = shift;

	my @seqs;
	while (my $seq_obj = $seq_io->next_seq) {
		my $header = get_header($seq_obj);
		my $seq = $seq_obj->seq;
		push @seqs, {seq => $seq,
			     header => $header,
			    };
	}

	my @picks;
	for (1 .. $shuffle_pick) {
		push @picks, splice @seqs, int(rand(scalar @seqs)), 1;
	}

	for my $pick (@picks) {
		print_this_seq($pick->{header}, $pick->{seq});
	}
}

#-----------------------------------------------------------------------------
#
#  --remove
#
#      Pass in a file with IDs and remove sequences with these IDs.
#
#-----------------------------------------------------------------------------

sub remove_ids {

	my $remove_file = shift;

	open (my $IN, '<', $remove_file) or
	  handle_message('FATAL',
			 'cant_open_file_for_reading',
			 $file);

	my %ids = map {chomp;$_, 1} (<$IN>);
	while (my $seq_obj = $seq_io->next_seq) {
		my $id = $seq_obj->display_id;
		next if $ids{$id};
		my $header = get_header($seq_obj);
		my $seq = $seq_obj->seq;
		print_this_seq($header, $seq);
	}
}

#-----------------------------------------------------------------------------
#
#  --select
#
#      Pass in a file with IDs and return sequences with these IDs.
#
#-----------------------------------------------------------------------------

sub select_ids {

	my $select_file = shift;
	open (my $IN, '<', $select_file) or
	  handle_message('FATAL',
			 'cant_open_file_for_reading',
			 $file);
	my %ids = map {chomp;$_, 1} (<$IN>);
	while (my $seq_obj = $seq_io->next_seq) {
		my $id = $seq_obj->display_id;
		next unless $ids{$id};
		my $header = get_header($seq_obj);
		my $seq = $seq_obj->seq;
		print_this_seq($header, $seq);
	}
}

#-----------------------------------------------------------------------------
#
#  --table
#
#      Print in table format rather than fasta format.
#
#-----------------------------------------------------------------------------

sub print_this_seq {
	my ($header, $seq) = @_;

	if($table){
	    chomp $seq;
	    ($header) = $header =~ /^([^\s+]+)/;
	    print join("\t", $header, uc($seq))."\n";
	}
	else{
	    $seq = wrap_seq($seq, $wrap) if $wrap;
	    chomp $seq;
	    my $join = $tab ? "\t" : "\n";
	    print join $join, (">$header", "$seq\n");
	}
}

#-----------------------------------------------------------------------------
#
#  --wrap <integer>
#
#      Wrap the sequence output to a given number of columns.
#
#-----------------------------------------------------------------------------

sub wrap_seq {
	my ($seq, $wrap) = @_;

	if ($wrap > 0) {
		$seq =~ s/\s//g;
		$seq =~ s/(.{$wrap})/$1\n/g;
	}
	chomp $seq;
	return $seq;
}

#-----------------------------------------------------------------------------

sub get_header {
	my $seq_obj = shift;
	return $seq_obj->display_id . " " . $seq_obj->description;

}

#-----------------------------------------------------------------------------

sub shuffle {
	#Fisher-Yates Shuffle
	my $array = shift;

	my $n = scalar @{$array};
	while ($n > 1) {
		my $k = int rand($n--);
		($array->[$n], $array->[$k]) = ($array->[$k], $array->[$n]);
	}
}

#-----------------------------------------------------------------------------
#
#  --map_ids
#
#      Pass in a file with two columns of IDs and map the IDs in the
#      fasta headers from the first column of the ID file to the second
#      column of the ID file.  If an ID in the fasta header is not
#      found in the first column of the ID file then issue a warning,
#      but leave the ID unmapped.
#
#-----------------------------------------------------------------------------

sub map_ids {

    my $id_file = shift;
    open (my $IN, '<', $id_file) or
	  handle_message('FATAL',
			 'cant_open_file_for_reading',
			 $file);
    my %ids;
    while (<$IN>) {
	chomp;
	my($id1, $id2) = split /\t/, $_;
	# $id1 =~ s/\.\d+$//;
	$ids{$id1} = $id2;
    }
    while (my $seq_obj = $seq_io->next_seq) {
	my $id = $seq_obj->display_id;
	# gi|71999842|ref|NM_073020.2|
	# my ($x, $y, $z, $id) = split /\|/, $id_text;
	# $id =~ s/\.\d+//;
	my $header = get_header($seq_obj);
	if (exists $ids{$id}) {
	    $header = $ids{$id};
	}
	my $seq = $seq_obj->seq;
	print_this_seq($header, $seq);
    }
}

#-----------------------------------------------------------------------------
#
#  --subseq
#
#    Grab a sub-sequence from a fasta file based on coordinates.  The
#    requested coordinates are in the form seqid:start-end;
#
#-----------------------------------------------------------------------------

sub subseq {

    my ($file, $coordinates) = @_;

    require Bio::DB::Fasta;
    my $fasta = Bio::DB::Fasta->new($file);

    my ($seqid, $start, $end) = split /[:-]/, $coordinates;

    print $fasta->seq($seqid, $start, $end);
    print "\n";
}

#-----------------------------------------------------------------------------

sub tile_seq {

    my $tile = shift;

    my ($tile_length, $step) = split /,/, $tile;
    $tile_length ||= 50;
    $step ||= 1;

    while (my $seq_obj = $seq_io->next_seq) {
	my $id  = $seq_obj->display_id;
	my $seq = $seq_obj->seq;
	my $seq_length = length($seq);
	my $start;
	for ($start = 1;$start <= ($seq_length - $tile_length); $start += $step) {
	    my $header = "$id:$start-" . ($start + $tile_length - 1);
	    my $subseq = substr($seq, $start, $tile_length);
	    print ">$header\n$subseq\n";
	}
    }
}

#-----------------------------------------------------------------------------

sub handle_message {

    my ($level, $code, @comments) = @_;

    $level ||= 'FATAL';
    $code  ||= 'unknown_warning';
    my $comment = join ' ', @comments;

    my $message = join ' : ', ($level, $code, $comment);
    chomp $message;
    $message .= "\n";

    if ($level eq 'FATAL') {
      print STDERR $message;
      die;
    }
    else {
      print STDERR $message;
    }
  }

sub filter_shorter {
        my $shorter = shift;

        while (my $seq_obj = $seq_io->next_seq) {
                if($seq_obj->length > $shorter){
                        print_this_seq(get_header($seq_obj),$seq_obj->seq);
                }
        }

}

sub filter_longer {
        my $longer = shift;

        while(my $seq_obj = $seq_io->next_seq) {
                if($seq_obj->length <= $longer){
                        print_this_seq(get_header($seq_obj),$seq_obj->seq);
                }
        }
}

#-------------------------------------------------------------------------------
sub mask_fasta {

	my ($gff3_file) = @_;
	
	#load the coordinates from the gff3 file into a map
	#the map is seqid->list of (start,end) coords
	
	my %coord_map;
	open(GFF3, $gff3_file);
	while(<GFF3>){
		unless(/^\#/) {
		my ($seqID, $source, $type, $start, $end, @other_stuff)=split(/\t/);
		if(!defined($coord_map{$seqID})) {
			if($start > $end) {
				my $tmp = $start;
				$start = $end;
				$end = $tmp;
			}

			my @curr_list = ();
			my @tmp_list = ($start,$end);
			$coord_map{$seqID} = \@curr_list;
		}
		else {
			my @curr_list = @{ $coord_map{$seqID}};
			my @tmp_list = ($start,$end);
			push(@curr_list, \@tmp_list);
			$coord_map{$seqID} = \@curr_list;
		}

		}

	}
	close GFF3;

	#go through the sequences in seqIO
	while (my $seq_obj = $seq_io->next_seq) {
		my $id = $seq_obj->display_id;
		my $header = get_header($seq_obj);
		my $curr_seq = $seq_obj->seq;
	
		if($coord_map{$id}) {
			#mask that substring
			my @curr_list = @{ $coord_map{$id}};
			foreach my $tmp_list_ptr (@curr_list) {
				my ($start,$end) = @{ $tmp_list_ptr};
				#The way I determine begin and offset was copied from
				#Michael Campbell's gene_masker.pl script
				#DE 06/19/2014
				my $begin = $start - 1;
				my $offset = $end - $begin;
				substr($curr_seq, $begin, $offset, "N" x $offset);
			}
			$header = $header . " masked ";
		}

		print_this_seq($header, $curr_seq);
	}
}


