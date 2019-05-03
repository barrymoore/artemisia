package Arty::Utils;

use strict;
use warnings;

our (@ISA, @EXPORT_OK, %EXPORT_TAGS);
BEGIN {
    require Exporter;
    @ISA = qw(Exporter);
    @EXPORT_OK = qw (handle_message throw_msg warn_msg info_msg debug_msg wrap_text
    		     trim_whitespace expand_iupac_nt_codes revcomp
    		     translate genetic_code amino_acid_data time_stamp
    		     random_string float_lt float_le float_gt float_ge
    		     open_file);
    %EXPORT_TAGS = (all =>     [qw(handle_message throw_msg warn_msg info_msg debug_msg
                     	       	   wrap_text trim_whitespace
                     	       	   expand_iupac_nt_codes revcomp
                     	       	   translate genetic_code
                     	       	   amino_acid_data time_stamp
                     	       	   random_string float_lt float_le
                     	       	   float_gt float_ge open_file)],

		    message => [qw(handle_message throw_msg warn_msg info_msg debug_msg)]);
}

use vars qw($VERSION);
use Carp qw(croak cluck);

$VERSION = 0.0.1;

=head1 NAME

L<Arty::Utils> - Utility functions for the Artemisia library

=head1 VERSION

This document describes L<Arty::Utils> version 0.0.1

=head1 SYNOPSIS

    use Arty::Utils qw(all);

=head1 DESCRIPTION

L<Arty::Utils> provides utility functions for the Artemisia library.
It does not export any functions by default.

=head1 Export OK

=over 4

=item handle_message

=item throw_msg

=item warn_msg

=item info_msg

=item debug_msg

=item wrap_text

=item trim_whitespace

=item expand_iupac_nt_codes

=item revcomp

=item translate

=item genetic_code

=item amino_acid_data

=item time_stamp

=item random_string

=item float_lt

=item float_le

=item float_gt

=item float_ge

=item open_file

=item load_module

=cut

=head1 Export Tags

=over 4

==item :all imports all of the functions above

==item :message (handle_message throw warn_msg info_msg debug_msg)

=head1 USES

=over 4

=item * L<Carp>

=item * L<Scalar::Util>

=back

#-----------------------------------------------------------------------------
#----------------------------- Private Functions -----------------------------
#-----------------------------------------------------------------------------

=head1 Private Functions

=head2 _private_function

 Title   : _private_function
 Usage   : $args = _private_function(@_);
 Function: Take a list of key value pairs that may be structured as an
           array, a hash or and array or hash reference and return
	   them as a hash or hash reference depending on calling
	   context.
 Returns : Hash or hash reference.
 Args    : An array, hash or reference to either.

=cut

sub _private_function {

	my ($args) = @_;

	return '_Hello_Private_World';
}

#-----------------------------------------------------------------------------
#----------------------------------- Functions -------------------------------
#-----------------------------------------------------------------------------

=head1 Functions

=head2 handle_message

 Title   : handle_message
 Usage   : handle_message($level, $code, $message, $verbosity, $caller);
 Function: Handle a message and print to STDERR accordingly.
 Returns : None
 Args    : level    : FATAL, WARN, INFO, DEBUG
	   code     : $info_code # single_word_code_for_info
	   message  : $info_msg  # Free text description of info
           caller   : Arrayref of list returned by Perl's caller
                      function. Defaults to calling caller() within
                      the handle_message function.
           verbosity: An integer 1-5 corresponding to the levels of
                      verbosity described int the table below.

		      debug  | 1: Print all FATAL, WARN, INFO, and
		                  DEBUG messages.  Produces a lot of
		                  output.
		      info   | 2: Print all FATAL, WARN, and INFO
		                  messages. This is the default.
		      unique | 3: Print only the first occurence of
		                  each error/info code.
		      warn   | 4: Don't print INFO messages.
        	      fatal  | 5: Don't print INFO or WARN
		                  messages. Still dies with message on
		                  FATAL errors.

          Note that the 'code' above should not contain whitespace,
          should generally by lowercase unless uppercase is needed for
          clarity, and should be standardized throughout the library
          such that a code like 'file_not_found' is used consistently
          rather than 'file_not_found' in one place and
          'file_does_not_exist' in another.  All codes should be
          documented in the module and in Manual.pm

          The 'message' above can be arbitrary text and should provide
          details that will help explain this instance of the error,
          such as "Expected an integer but got the text 'ABCDEFG'
          instead".

=cut

sub handle_message {
	my ($level, $code, $message, $verbosity, $caller) = @_;

	# VERBOSITY

	$verbosity ||= 2;
	
	my ($package, $filename, $line) =
	    defined $caller ? @{$caller} : caller();

	$level ||= 'UNKNOWN';
	$message ||= "$package in $filename line $line";
	if (! $code) {
	  $code = 'unspecified_code';

	  $message = join '', ("Arty::Utils is handling a message " .
			       "for $package without an error code. " .
			       "Complain to the author of $package " .
			       "in $filename line $line!");

	}
	chomp $message;
	$message .= "\n";

	if ($level eq 'FATAL') {
	  $message = join ' : ', ('FATAL', $code, $message);
	  croak $message;
	}
	elsif ($level eq 'WARN') {
	  return if ($verbosity > 4);
	  $message = join ' : ', ('WARN', $code, $message);
	  print STDERR $message;
	}
	elsif ($level eq 'INFO') {
	  return if ($verbosity > 3);
	  $message = join ' : ', ('INFO', $code, $message);
	  print STDERR $message;
	}
	elsif ($level eq 'DEBUG') {
	  return if ($verbosity != 1);
	  $message = join ' : ', ('DEBUG', $code, "($package $filename line $line) $message");
	  print STDERR $message;
	  print '';
	}
	else {
	  $message = join '', ("Arty::Utils is handling a message " .
			       "for $package without an error level.  "  .
			       "Complain to the author of $package " .
                               "in $filename line $line!\n");
	  chomp $message;
	  $message = join ' : ', ('UNKNOWN', $code, $message);
	  croak $message;
	}
}

#-----------------------------------------------------------------------------

=head2 throw_msg

 Title   : throw_msg
 Usage   : throw_msg($error_code, $error_message, $verbosity);
 Function: Throw_Msg an error - print an error message to STDERR and die.
 Returns : None
 Args    : A text string for the error code and a text string for the
           error message. See the documentation for the function
           handle_message in this module for more details.

=cut

sub throw_msg {
    my ($code, $message, $verbosity) = @_;
	handle_message('FATAL', $code, $message, $verbosity, [caller()]);
}

#-----------------------------------------------------------------------------

=head2 warn_msg

 Title   : warn_msg
 Usage   : warn_msg($warning_code, $warning_message, $verbosity);
 Function: Send a warning message to STDERR.
 Returns : None
 Args    : A text string for the error code and a text string for the
           error message. See the documentation for the function
           handle_message in this module for more details.

=cut

sub warn_msg {
    my ($code, $message, $verbosity) = @_;
	handle_message('WARN', $code, $message, $verbosity, [caller()]);
}

#-----------------------------------------------------------------------------

=head2 info_msg

 Title   : info_msg
 Usage   : info_msg($info_code, $info_message, $verbosity);
 Function: Send a INFO message.
 Returns : None
 Args    : A text string for the info code and a text string for the
           info message. See the documentation for the function
           handle_message in this module for more details.

=cut

sub info_msg {
    my ($code, $message, $verbosity) = @_;
	handle_message('INFO', $code, $message, $verbosity, [caller()]);
}

#-----------------------------------------------------------------------------

=head2 debug_msg

 Title   : debug_msg
 Usage   : debug_msg($debug_code, $debug_message, $verbosity);
 Function: Send a DEBUG message.
 Returns : None
 Args    : A text string for the debug code and a text string for the
           debug message. See the documentation for the functionl
           handle_message in this module for more details.

=cut

sub debug_msg {
    my ($code, $message, $verbosity) = @_;
	handle_message('DEBUG', $code, $message, $verbosity, [caller()]);
      }

#-----------------------------------------------------------------------------

=head2 wrap_text

 Title   : wrap_text
 Usage   : $text = wrap_text($text, 50);
 Function: Wrap text to the specified column width.  Default width is 50
           characters.
 Returns : Returns wrapped text as a string.
 Args    : A string of text and an optional integer value for the wrapped
           width.

=cut

sub wrap_text {
	my ($text, $cols) = @_;
	$cols ||= 50;
	$text =~ s/(.{0,$cols})/$1\n/g;
	$text =~ s/\n+$//;
	return $text;
}

#-----------------------------------------------------------------------------

=head2 trim_whitespace

 Title   : trim_whitespace
 Usage   : $trimmed_text = trim_whitespace($text);
 Function: Trim leading and trailing whitespace from text;
 Returns : Returns trimmed text as a string.
 Args    : A text string.

=cut

sub trim_whitespace {
	my ($text) = @_;
	$text =~ s/^\s+//;
	$text =~ s/\s+$//;
	return $text;
}

#-----------------------------------------------------------------------------

=head2 expand_iupac_nt_codes

 Title   : expand_iupac_nt_codes
 Usage   : @nucleotides = expand_iupac_nt_codes('W');
 Function: Expands an IUPAC ambiguity codes to an array of nucleotides
 Returns : An array or array ref of nucleotides (ATGC-);
 Args    : An IUPAC Nucleotide ambiguity code (ACGTUMRWSYKVHDBNX-) or an
           array (or ref) of such.

=cut

sub expand_iupac_nt_codes {
	my (@codes) = @_;

	my %iupac_code_map = ('A' => ['A'],
			      'C' => ['C'],
			      'G' => ['G'],
			      'T' => ['T'],
			      'U' => ['T'],
			      'M' => ['A', 'C'],
			      'R' => ['A', 'G'],
			      'W' => ['A', 'T'],
			      'S' => ['C', 'G'],
			      'Y' => ['C', 'T'],
			      'K' => ['G', 'T'],
			      'V' => ['A', 'C', 'G'],
			      'H' => ['A', 'C', 'T'],
			      'D' => ['A', 'G', 'T'],
			      'B' => ['C', 'G', 'T'],
			      'N' => ['A', 'C', 'G', 'T'],
			      'X' => ['A', 'C', 'G', 'T'],
			      '-' => ['-'],
			     );

	my @nts;
	for my $code (@codes) {
	  my $nts = $iupac_code_map{$code};
	  throw_msg('invalid_ipuac_nucleotide_code', $code)
	    unless $nts;
	  push @nts, @{$nts};
	}


	return wantarray ? @nts : \@nts;
}

#-----------------------------------------------------------------------------

=head2 revcomp

 Title   : revcomp
 Usage   : revcomp($sequence);
 Function: Get the reverse compliment of a nucleotide sequence
 Returns : The reverse complimented sequence
 Args    : A nucleotide sequence (ACGTRYMKSWHBVDNX).  Input sequence is case
           insensitive and case is maintained.

=cut

sub revcomp {

  my ($sequence) = @_;

  my $revcomp_seq = reverse $sequence;
  $revcomp_seq =~ tr/acgtrymkswhbvdnxACGTRYMKSWHBVDNX/tgcayrkmswdvbhnxTGCAYRKMSWDVBHNX/;
  return $revcomp_seq;
}

#-----------------------------------------------------------------------------

=head2 translate

 Title   : translate
 Usage   : translate($sequence, $offset, $length);
 Function: Translate a nucleotide sequence to an amino acid sequence
 Returns : An amino acid sequence
 Args    : The sequence as a scalar, an integer offset from which to begin
           translation (default 0), and an integer length to translate
           (default is full length of input sequence).

=cut

sub translate {
  my ($sequence, $offset, $length) = @_;

  my $genetic_code = genetic_code();

  $offset ||= 0;
  $sequence =~ s/\s+|\d+//g;
  $length ||= length($sequence);

  my $polypeptide;
  for (my $i = (0 + $offset); $i < $length; $i += 3) {
    my $codon = uc substr($sequence, $i, 3);
    my $aa = $genetic_code->{$codon};
    $polypeptide .= $aa;
  }
  return $polypeptide;
}

#-----------------------------------------------------------------------------

=head2 genetic_code

 Title   : genetic_code
 Usage   : genetic_code;
 Function: Returns a hash reference of the genetic code.  Currently only
           supports the standard genetic code without ambiguity codes.
 Returns : A hash reference of the genetic code
 Args    : None

=cut

sub genetic_code {

  #TODO: Need to add ambiguity codes to codons.

  return {AAA => 'K',
	  AAC => 'N',
	  AAG => 'K',
	  AAT => 'N',
	  ACA => 'T',
	  ACC => 'T',
	  ACG => 'T',
	  ACT => 'T',
	  AGA => 'R',
	  AGC => 'S',
	  AGG => 'R',
	  AGT => 'S',
	  ATA => 'I',
	  ATC => 'I',
	  ATG => 'M',
	  ATT => 'I',
	  CAA => 'Q',
	  CAC => 'H',
	  CAG => 'Q',
	  CAT => 'H',
	  CCA => 'P',
	  CCC => 'P',
	  CCG => 'P',
	  CCT => 'P',
	  CGA => 'R',
	  CGC => 'R',
	  CGG => 'R',
	  CGT => 'R',
	  CTA => 'L',
	  CTC => 'L',
	  CTG => 'L',
	  CTT => 'L',
	  GAA => 'E',
	  GAC => 'D',
	  GAG => 'E',
	  GAT => 'D',
	  GCA => 'A',
	  GCC => 'A',
	  GCG => 'A',
	  GCT => 'A',
	  GGA => 'G',
	  GGC => 'G',
	  GGG => 'G',
	  GGT => 'G',
	  GTA => 'V',
	  GTC => 'V',
	  GTG => 'V',
	  GTT => 'V',
	  TAA => '*',
	  TAC => 'Y',
	  TAG => '*',
	  TAT => 'Y',
	  TCA => 'S',
	  TCC => 'S',
	  TCG => 'S',
	  TCT => 'S',
	  TGA => '*',
	  TGC => 'C',
	  TGG => 'W',
	  TGT => 'C',
	  TTA => 'L',
	  TTC => 'F',
	  TTG => 'L',
	  TTT => 'F',
	 };
}

#-----------------------------------------------------------------------------

=head2 amino_acid_data

 Title   : amino_acid_data
 Usage   : amino_acid_data($aa, $value);
 Function: Returns data about an amino acid - either a specific value or a
           hash reference of all data for that amino acid.
 Returns : A string representing a data point about an given amino acid or a
           hash reference with all data points about the given amino acid.
 Args    : 1) An amino acid in either:
	      a) single-letter code
	      b) three-letter
	   2) Optionally a code for the value to return.  Any of:
	      a) name : The full name of the amino acid.
	      b) one_letter : The one-letter code for the amino acid.
	      c) three_letter : The three-letter code for the amino acid.
	      d) polarity : The polarity of the amino acid.
	      e) charge : The charge of the amino acid's side chain (at pH 7.4).
	      f) hydropathy : The hydropathy index of the amino acid.
	      g) weight : The molecular weight of the amino acid in g/mol.
	      h) size : Returns small or large.
	      i) h_bond : return 1 or 0 indicating if the amino acid can form hydrogen bonds
	      j) aromaticity : Returns aromatic, aliphatic or undef.

=cut

sub amino_acid_data {

  my ($aa, $datum) = @_;

  my %aa321 = (Ala => 'A',
	       Arg => 'R',
	       Asn => 'N',
	       Asp => 'D',
	       Cys => 'C',
	       Glu => 'E',
	       Gln => 'Q',
	       Gly => 'G',
	       His => 'H',
	       Ile => 'I',
	       Leu => 'L',
	       Lys => 'K',
	       Met => 'M',
	       Phe => 'F',
	       Pro => 'P',
	       Ser => 'S',
	       Thr => 'T',
	       Trp => 'W',
	       Tyr => 'Y',
	       Val => 'V',
	       Sec => 'U',
	       Pyl => 'O',
	      );

  if (length($aa) == 3) {
    $aa = $aa321{$aa}
  }

  my %aa_data = (A => {name         => 'Alanine',
		       one_letter   => 'A',
		       three_letter => 'Ala',
		       polarity     => 'nonpolar',
		       charge       => 'neutral',
		       hydropathy   => 1.8,
		       weight       => 71.09,
		       size         => 'small',
		       h_bond       => 0,
		       aromaticity  => 'aliphatic',
		      },
		 R => {name         => 'Arginine',
		       one_letter   => 'R',
		       three_letter => 'Arg',
		       polarity     => 'polar',
		       charge       => 'positive',
		       hydropathy   => -4.5,
		       weight       => 156.19,
		       size         => 'large',
		       h_bond       => 1,
		       aromaticity  => undef,
		      },
		 N => {name         => 'Asparagine',
		       one_letter   => 'N',
		       three_letter => 'Asn',
		       polarity     => 'polar',
		       charge       => 'neutral',
		       hydropathy   => -3.5,
		       weight       => 114.11,
		       size         => 'small',
		       h_bond       => 1,
		       aromaticity  => undef,
		      },
		 D => {name         => 'Aspartic acid',
		       one_letter   => 'D',
		       three_letter => 'Asp',
		       polarity     => 'polar',
		       charge       => 'negative',
		       hydropathy   => -3.5,
		       weight       => 115.09,
		       size         => 'small',
		       h_bond       => 1,
		       aromaticity  => undef,
		      },
		 C => {name         => 'Cysteine',
		       one_letter   => 'C',
		       three_letter => 'Cys',
		       polarity     => 'polar',
		       charge       => 'neutral',
		       hydropathy   => 2.5,
		       weight       => 103.15,
		       size         => 'small',
		       h_bond       => 1,
		       aromaticity  => undef,
		      },
		 E => {name         => 'Glutamic acid',
		       one_letter   => 'E',
		       three_letter => 'Glu',
		       polarity     => 'polar',
		       charge       => 'negative',
		       hydropath    => -3.5,
		       weight       => 129.12,
		       size         => 'large',
		       h_bond       => 1,
		       aromaticity  => undef,
		     },
		 Q => {name         => 'Glutamine',
		       one_letter   => 'Q',
		       three_letter => 'Gln',
		       polarity     => 'polar',
		       charge       => 'neutral',
		       hydropathy   => -3.5,
		       weight       => 128.14,
		       size         => 'large',
		       h_bond       => 1,
		       aromaticity  => undef,
		      },
		 G => {name         => 'Glycine',
		       one_letter   => 'G',
		       three_letter => 'Gly',
		       polarity     => 'nonpolar',
		       charge       => 'neutral',
		       hydropathy   => -0.4,
		       weight       => 57.05,
		       size         => 'small',
		       h_bond       => 0,
		       aromaticity  => 'aliphatic',
		      },
		 H => {name         => 'Histidine',
		       one_letter   => 'H',
		       three_letter => 'His',
		       polarity     => 'polar',
		       charge       => 'positive',
		       hydropathy   => -3.2,
		       weight       => 137.14,
		       size         => 'large',
		       h_bond       => 1,
		       aromaticity  => 'aromatic',
		      },
		 I => {name         => 'Isoleucine',
		       one_letter   => 'I',
		       three_letter => 'Ile',
		       polarity     => 'nonpolar',
		       charge       => 'neutral',
		       hydropathy   => 4.5,
		       weight       => 113.16,
		       size         => 'large',
		       h_bond       => 0,
		       aromaticity  => 'aliphatic',
		      },
		 L => {name         => 'Leucine',
		       one_letter   => 'L',
		       three_letter => 'Leu',
		       polarity     => 'nonpolar',
		       charge       => 'neutral',
		       hydropathy   => 3.8,
		       weight       => 113.16,
		       size         => 'large',
		       h_bond       => 0,
		       aromaticity  => 'aliphatic',
		      },
		 K => {name         => 'Lysine',
		       one_letter   => 'K',
		       three_letter => 'Lys',
		       polarity     => 'polar',
		       charge       => 'positive',
		       hydropathy   => -3.9,
		       weight       => 128.17,
		       size         => 'large',
		       h_bond       => 1,
		       aromaticity  => undef,
		      },
		 M => {name         => 'Methionine',
		       one_letter   => 'M',
		       three_letter => 'Met',
		       polarity     => 'nonpolar',
		       charge       => 'neutral',
		       hydropathy   => 1.9,
		       weight       => 131.19,
		       size         => 'large',
		       h_bond       => 0,
		       aromaticity  => undef,
		      },
		 F => {name         => 'Phenylalanine',
		       one_letter   => 'F',
		       three_letter => 'Phe',
		       polarity     => 'nonpolar',
		       charge       => 'neutral',
		       hydropathy   => 2.8,
		       weight       => 147.18,
		       size         => 'large',
		       h_bond       => 0,
		       aromaticity  => 'aromatic',
		      },
		 P => {name         => 'Proline',
		       one_letter   => 'P',
		       three_letter => 'Pro',
		       polarity     => 'nonpolar',
		       charge       => 'neutral',
		       hydropathy   => -1.6,
		       weight       => 97.12,
		       size         => 'small',
		       h_bond       => 0,
		       aromaticity  => 'aliphatic',
		      },
		 S => {name         => 'Serine',
		       one_letter   => 'S',
		       three_letter => 'Ser',
		       polarity     => 'polar',
		       charge       => 'neutral',
		       hydropathy   => -0.8,
		       weight       => 87.08,
		       size         => 'small',
		       h_bond       => 1,
		       aromaticity  => undef,
		      },
		 T => {name         => 'Threonine',
		       one_letter   => 'T',
		       three_letter => 'Thr',
		       polarity     => 'polar',
		       charge       => 'neutral',
		       hydropathy   => -0.7,
		       size         => 'small',
		       h_bond       => 1,
		       aromaticity  => undef,
		      },
		 W => {name         => 'Tryptophan',
		       one_letter   => 'W',
		       three_letter => 'Trp',
		       polarity     => 'nonpolar',
		       charge       => 'neutral',
		       hydropathy   => -0.9,
		       weight       => 186.21,
		       size         => 'large',
		       h_bond       => 1,
		       aromaticity  => 'aromatic',
		      },
		 Y => {name         => 'Tyrosine',
		       one_letter   => 'Y',
		       three_letter => 'Tyr',
		       polarity     => 'polar',
		       charge       => 'neutral',
		       hydropathy   => -1.3,
		       weight       => 163.18,
		       size         => 'large',
		       h_bond       => 1,
		       aromaticity  => 'aromatic',
		      },
		 V => {name         => 'Valine',
		       one_letter   => 'V',
		       three_letter => 'Val',
		       polarity     => 'nonpolar',
		       charge       => 'neutral',
		       hydropathy   => 4.2,
		       weight       => 99.14,
		       size         => 'small',
		       h_bond       => 0,
		       aromaticity  => 'aliphatic',
		      },
		 U => {name         => 'Selenocysteine',
		       one_letter   => 'U',
		       three_letter => 'Sec',
		       polarity     => undef,
		       charge       => undef,
		       hydropathy   => undef,
		       weight       => undef,
		       size         => undef,
		       h_bond       => undef,
		       aromaticity  => undef,
		      },
		 O => {name         => 'Pyrrolysine',
		       one_letter   => 'O',
		       three_letter => 'Pyl',
		       polarity     => undef,
		       charge       => undef,
		       hydropathy   => undef,
		       weight       => undef,
		       size         => undef,
		       h_bond       => undef,
		       aromaticity  => undef,
		      }
		);


  if (defined $datum) {
    if (exists $aa_data{$aa}{$datum}) {
      return $aa_data{$aa}{$datum};
    }
    else {
      throw_msg('invalid_aa_datum_code',
		   "$datum passed to Arty::Utils::amino_acid_data");
    }
  }
  else {
      return $aa_data{$aa};
  }
}

#-----------------------------------------------------------------------------

=head2 time_stamp

 Title   : time_stamp
 Usage   : time_stamp;
 Function: Returns a YYYYMMDD time_stamp
 Returns : A YYYYMMDD time_stamp
 Args    : None

=cut

sub time_stamp {

  my ($sec,$min,$hour,$mday,$mon,$year,$wday,
      $yday,$isdst) = localtime(time);
  my $time_stamp = sprintf("%02d%02d%02d", $year + 1900,
			   $mon + 1, $mday);
  return $time_stamp;
}

#-----------------------------------------------------------------------------

=head2 random_string

 Title   : random_string
 Usage   : random_string(8);
 Function: Returns a random alphanumeric string
 Returns : A random alphanumeric string of a given length.  Default length is
           8 charachters.
 Args    : The length of the string to be returned [8]

=cut

sub random_string {
  my ($length) = @_;
  $length ||= 8;
  my $random_string = join "", map { unpack "H*", chr(rand(256)) } (1 .. $length);
  return substr($random_string, 0, $length);
}

#-----------------------------------------------------------------------------

=head2 float_lt

 Title   : float_lt
 Usage   : float_lt(0.0000123, 0.0000124, 7);
 Function: Return true if the first number given is less than (<) the
	   second number at a given level of accuracy.  Default accuracy
           length is 6 decimal places.
 Returns : 1 if the first number is less than the second, otherwise 0.
 Args    : The two values to compare and optionally a integer value for
	   the accuracy.  Accuracy defaults to 6 decimal places.

=cut

sub float_lt {
	my ($A, $B, $accuracy) = @_;

	$accuracy ||= 6;
	$A = sprintf("%.${accuracy}f", $A);
	$B = sprintf("%.${accuracy}f", $B);
	$A =~ s/\.//;
	$B =~ s/\.//;
	return $A < $B;
}

#-----------------------------------------------------------------------------

=head2 float_le

 Title   : float_le
 Usage   : float_le(0.0000123, 0.0000124, 7);
 Function: Return true if the first number given is less than or equal to
	   (<=) the second number at a given level of accuracy.  Default
           accuracy length is 6 decimal places.
 Returns : 1 if the first number is less than or equal to the second,
	   otherwise 0.
 Args    : The two values to compare and optionally a integer value for
	   the accuracy.  Accuracy defaults to 6 decimal places.

=cut

sub float_le {
	my ($A, $B, $accuracy) = @_;

	$accuracy ||= 6;
	$A = sprintf("%.${accuracy}f", $A);
	$B = sprintf("%.${accuracy}f", $B);
	$A =~ s/\.//;
	$B =~ s/\.//;
	return $A <= $B;
}

#-----------------------------------------------------------------------------

=head2 float_gt

 Title   : float_gt
 Usage   : float_gt(0.0000123, 0.0000124, 7);
 Function: Return true if the first number given is greater than (>) the
	   second number at a given level of accuracy.  Default accuracy
           length is 6 decimal places.
 Returns : 1 if the first number is greater than the second, otherwise 0
 Args    : The two values to compare and optionally a integer value for
	   the accuracy.  Accuracy defaults to 6 decimal places.

=cut

sub float_gt {
	my ($A, $B, $accuracy) = @_;

	$accuracy ||= 6;
	$A = sprintf("%.${accuracy}f", $A);
	$B = sprintf("%.${accuracy}f", $B);
	$A =~ s/\.//;
	$B =~ s/\.//;
	return $A > $B;
}

#-----------------------------------------------------------------------------

=head2 float_ge

 Title   : float_ge
 Usage   : float_ge(0.0000123, 0.0000124, 7);
 Function: Return true if the first number given is greater than or equal
	   to (>=) the second number at a given level of accuracy.  Default
           accuracy length is 6 decimal places.
 Returns : 1 if the first number is greater than or equal to the second,
	   otherwise 0.
 Args    : The two values to compare and optionally a integer value for
	   the accuracy.  Accuracy defaults to 6 decimal places.

=cut

sub float_ge {
	my ($A, $B, $accuracy) = @_;

	$accuracy ||= 6;
	$A = sprintf("%.${accuracy}f", $A);
	$B = sprintf("%.${accuracy}f", $B);
	$A =~ s/\.//;
	$B =~ s/\.//;
	return $A >= $B;
}

#-----------------------------------------------------------------------------

=head2 open_file

 Title   : open_file
 Usage   : open_file($file);
 Function: Open a given file for reading and return a filehandle.
 Returns : A filehandle
 Args    : A file path/name

=cut

sub open_file {

  my ($file) = @_;

  if (! defined $file) {
    throw_msg('file_does_not_exist', $file);
  }
  if (! -e $file) {
    throw_msg('file_does_not_exist', $file);
  }
  if (! -r $file) {
    throw_msg('cant_read_file', $file);
  }
  open(my $FH, '<', $file) || throw_msg('cant_open_file_for_reading', $file);

  return $FH;
}

#-----------------------------------------------------------------------------

=head2 load_module

 Title   : load_module
 Usage   : load_module(Some::Module);
 Function: Do runtime loading (require) of a module/class.
 Returns : 1 on success - throws exception on failure
 Args    : A valid module name.

=cut

sub load_module {

    my ($module_name) = @_;
    eval "require $module_name";
    if ($@) {
	my ($package, $filename, $line) = caller;
	my $err_code = 'failed_to_load_module';
	my $err_msg  = "$package in $filename, line $line\n$@";
	throw_msg($err_code, $err_msg);
    }
    return 1;
}

#-----------------------------------------------------------------------------

=head1 DIAGNOSTICS

=over

=item C<< invalid_ipuac_nucleotide_code >>

C<Arty::Utils::expand_iupac_nt_codes> was passed a charachter that is
not a valid IUPAC nucleotide code
(http://en.wikipedia.org/wiki/Nucleic_acid_notation).

=item C<< failed_to_load_module >>

C<Arty::Utils::load_module> was unable to load (require) the specified
module.  The module may not be installed or it may have a compile time
error.

=item C<< invalid_aa_datum_code >>

An invalid amino acid code was passed to
C<Arty::Utils::amino_acid_data>.  Single-letter or three-letter amino
acid codes are required.

=back

=head1 CONFIGURATION AND ENVIRONMENT

L<Arty::Utils> requires no configuration files or environment variables.

=head1 DEPENDENCIES

=over

=item L<Carp> qw(croak cluck)

=back

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to:
barry.moore@genetics.utah.edu

=head1 AUTHOR

Barry Moore <barry.moore@genetics.utah.edu>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2019, Barry Moore <barry.moore@genetics.utah.edu>.
All rights reserved.

    This module is free software; you can redistribute it and/or
    modify it under the same terms as Perl itself (See LICENSE).

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut

1;
