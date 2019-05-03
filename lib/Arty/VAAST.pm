package Arty::VAAST;

use strict;
use warnings;
use vars qw($VERSION);

$VERSION = 0.0.1;
use base qw(Arty::Base);
use Arty::Utils qw(:all);

=head1 NAME

Arty::VAAST - Parse VAAST2 files

=head1 VERSION

This document describes Arty::VAAST version 0.0.1

=head1 SYNOPSIS

    use Arty::VAAST;
    my $vaast = Arty::VAAST->new('output.vaast');

    while (my $record = $parser->next_record) {
	print $record->{gene} . "\n";
    }

=head1 DESCRIPTION

L<Arty::VAAST> provides VAAST parsing ability for the artemisia suite
of genomics tools.

=head1 CONSTRUCTOR

New L<Arty::VAAST> objects are created by the class method new.
Arguments should be passed to the constructor as a list (or reference)
of key value pairs.  If the argument list has only a single argument,
then this argument is applied to the 'file' attribute and thus
specifies the VAAST filename.  All attributes of the L<Arty::VAAST>
object can be set in the call to new. An simple example of object
creation would look like this:

    my $parser = Arty::VAAST->new('output.vaast');

    # This is the same as above
    my $parser = Arty::VAAST->new('file' => 'output.vaast');

The constructor recognizes the following parameters which will set the
appropriate attributes:

=over

=item * C<< file => output.vaast >>

This optional parameter provides the filename for the file containing
the data to be parsed. While this parameter is optional either it, or
the following fh parameter must be set.

=item * C<< fh => $fh >>

This optional parameter provides a filehandle to read data from. While
this parameter is optional either it, or the previous file parameter
must be set.

=back

=cut

=head2 new

     Title   : new
     Usage   : Arty::VAAST->new();
     Function: Creates a Arty::VAAST object;
     Returns : An Arty::VAAST object
     Args    :

=cut

sub new {
	my ($class, @args) = @_;
	my $self = $class->SUPER::new(@args);
	$self->_process_header;
	return $self;
}

=head1 PRIVATE METHODS

=head2 _initialize_args

 Title   : _initialize_args
 Usage   : $self->_initialize_args($args);
 Function: Initialize the arguments passed to the constructor.  In particular
           set all attributes passed.
 Returns : N/A
 Args    : A hash or array reference of arguments.

=cut
    
sub _initialize_args {
  my ($self, @args) = @_;

  ######################################################################
  # This block of code handels class attributes.  Use the
  # @valid_attributes below to define the valid attributes for
  # this class.  You must have identically named get/set methods
  # for each attribute.  Leave the rest of this block alone!
  ######################################################################
  my $args = $self->SUPER::_initialize_args(@args);
  # Set valid class attributes here
  my @valid_attributes = qw();
  $self->set_attributes($args, @valid_attributes);
  ######################################################################
}

=head2 _process_header

  Title   : _process_header
  Usage   : $self->_process_header
  Function: Parse and store header data
  Returns : N/A
  Args    : N/A

=cut

 sub _process_header {
     my $self = shift @_;

   LINE:
     while (my $line = $self->readline) {
	 return undef if ! defined $line;
	 if ($line =~ /^\#/) {
	     chomp $line;
	     push @{$self->{header}}, $line;
	 }
	 else {
	     $self->_push_stack($line);
	     last LINE;
	 }
     }
}

=head1 ATTRIBUTES

=cut
    
# =head2 attribute
#
#   Title   : attribute
#   Usage   : $attribute = $self->attribute($attribute_value);
#   Function: Get/set attribute
#   Returns : An attribute value
#   Args    : An attribute value
#
# =cut
#
#  sub attribute {
#    my ($self, $attribute_value) = @_;
#
#    if ($attribute) {
#      $self->{attribute} = $attribute;
#    }
#
#    return $self->{attribute};
#  }

=head1 METHODS

=head2 next_record

 Title   : next_record
 Usage   : $record = $vaast->next_record();
 Function: Return the next record from the VAAST file.
 Returns : A hash (or reference) of VAAST record data.
 Args    : N/A

=cut

sub next_record {

  my $self = shift @_;

  my @record_lines;
 OUTER:
  while (my $outer = $self->readline) {
      last OUTER if ! defined $outer;
      next OUTER if $outer =~ /^\#[^\#]/;
      next OUTER if $outer =~ /^\s*$/;
      chomp $outer;
    if ($outer !~ /^>/) {
      throw_msg('invalid_file_structure', "Begining at: $outer");
    }
    push @record_lines, $outer;
  INNER:
    while (my $inner = $self->readline) {
      next INNER if $inner =~ /^\#[^\#]/;
      next INNER if $inner =~ /^\s*$/;
      chomp $inner;
      if ($inner =~ /^>/) {
	$self->_push_stack($inner);
	last OUTER;
      }
      push @record_lines, $inner;
    }
  }
  return undef unless defined $record_lines[0];
  my $record = $self->parse_vaast_record(\@record_lines);
  return wantarray ? %{$record} : $record;
}

#-----------------------------------------------------------------------------

=head2 all_records

 Title   : all_records
 Usage   : $record = $vaast->all_records();
 Function: Parse and return all records.
 Returns : An array (or reference) of all VAAST records.
 Args    : N/A

=cut

sub all_records {
	my $self = shift @_;

	my @records;
	while (my $record = $self->next_record) {
	    push @records, $record;
	}
	return wantarray ? @records : \@records;
}

#-----------------------------------------------------------------------------

=head2 parse_vaast_record

 Title    : parse_vaast_record
 Usage    : my $record = $self->parse_vaast($record_txt);
 Function : Parse a single VAAST record.
 Returns  : A hash reference containing the record data.
 Args     : An array reference with the line for a single VAAST record.

=cut

sub parse_vaast_record {

  my ($self, $record_lines) = @_;

  my %record;
  while (my $line = shift @{$record_lines}) {

    ## VAAST_VERSION 2.1.4
    ## COMMAND	VAAST --less_ram -q 40 -m lrt -k -d 10000000 -j 0.0000024 -fast_gp --iht r ...
    ## TOTAL_RUN_TIME	24171 seconds
    # >NM_005961	MUC6
    # chr11	-	1013456;1013633;-;chr11	1013899;1014001;-;chr11	...
    # TU:	168.82	1017981@chr11	T|H	N|0-6|A:A|L:L
    # T:        99.98   ins-chrX-101395783-1 ~ 0|!:G|!:AP 4|!:G|!:P 1|G:G|AP:AP 2-3,5-8|G:G|P:P
    # TR:	0.00	1018374@chr11	T|N	B|5|A:A|I:I	B|4|A:T|I:N
    # BR:	1013922@chr11	C|E	358,614,618,733,773,776,798,812,840,888,890,950,952-954,979,991|C:T|E:E
    # BR:	1013992@chr11	C|S	898|C:T|S:N
    # BR:	1015786@chr11	C|G	100,843,847,953|C:T|G:R
    # RANK:0
    # SCORE:168.82330347
    # genome_permutation_p:2.65314941903305e-18
    # genome_permutation_0.95_ci:2.65314941903305e-18,2.25166330953082e-06

    if ($line =~ /^(T|TR|TU|P|PR|B|BR):\s+/) {
      my @fields = split /\s+/, $line;
      my ($tag, $score, $lod_score, $locus, $ref_seqs, @genotype_data);

      my %type_map = (ins => 'insertion',
		      del => 'deletion',
		      mnp => 'MNP',
		      );

      if ($line =~ /^T[RU]?:\s+/) {
	($tag, $score, $locus, $ref_seqs, @genotype_data) = @fields;
	if ($score =~ /\(.*\)/) {
	  $score =~ s/\(.*\)//;
	  $lod_score = $1;
	}
      }
      elsif ($line =~ /^[BP]R?:\s+/) {
	($tag, $locus, $ref_seqs, @genotype_data) = @fields;
      }
      else {
	throw_msg('invalid_vaast_record', $line);
      }

      $tag =~ s/:$//;
      my ($type, $start, $seqid, $length);
      if ($tag =~ '^(T|P|B)$') {
	  ($type, $seqid, $start, $length) = split /\-/, $locus;
	  $type = exists $type_map{$type} ? $type_map{$type} : $type;
      }
      else {
	  ($start, $seqid) = split /\@/, $locus;
	  $type = 'SNV';
      }

      my ($reference_seq, $reference_aa) = split /\|/, $ref_seqs;
      # $reference_aa ||= '';
      my %genotypes;
      for my $genotype_datum (@genotype_data) {
	my @fields = split /\|/, $genotype_datum;
	my $flag = shift @fields if $tag =~ /^T[RU]/;
	$flag ||= '';
	my ($range, $var_seq_txt, $var_aa_txt) = @fields;
	$var_aa_txt ||= '';
	my @var_seqs = split /:/, $var_seq_txt;
	my @var_aas = split /:/, $var_aa_txt;
	my %genotype = (flag        => $flag,
			range       => $range,
			variant_seq => \@var_seqs,
			variant_aa  => \@var_aas,
			);
	$genotypes{$var_seq_txt} = \%genotype;
      }
      my $var_data = {start         => $start,
		      score         => $score,
		      reference_seq => $reference_seq,
		      reference_aa  => $reference_aa,
		      genotypes     => \%genotypes
		     };
      $var_data->{lod_score} = $lod_score if defined $lod_score;
      $var_data->{type}   = $type   if $type;
      $var_data->{length} = $length if $length;

      push @{$record{$tag}}, $var_data
    }
    # >NM_005961	MUC6
    elsif ($line =~ /^>/) {
      my ($feature_id, $gene) = split /\s+/, $line;
      $feature_id =~ s/^>//;
      $record{feature_id} = $feature_id;
      $record{gene} = $gene;
      # chr11	-	1013456;1013633;-;chr11	1013899;1014001;-;chr11	...
      $line = shift @{$record_lines};
      my ($seqid, $strand, @cds_text) = split /\s+/, $line;
      my @cds;
      for my $cds (@cds_text) {
	my ($start, $end, $strand, $seqid) = split /;/, $cds;
	$record{start} ||= $start;
	$record{end}   ||= $end;
	$record{start} = $start < $record{start} ? $start : $record{start};
	$record{end}   = $end   > $record{end}   ? $end   : $record{end};
	push @cds, [$start, $end];
      }
      $record{seqid} = $seqid;
      $record{strand} = $strand;
      $record{cds} = \@cds;
    }
    # RANK:0
    elsif ($line =~ /^RANK:/) {
      my ($tag, $value) = split /\s*:\s*/, $line;
      if (! defined $value) {
	warn_msg('missing_value', $line);
      }
      if ($value !~ /^\d+$/) {
	warn_msg('invalid_value', $line);
      }
      $record{rank} = $value;
    }
    # SCORE:168.82330347
    elsif ($line =~ /^SCORE:/) {
      my ($tag, $value) = split /\s*:\s*/, $line;
      if (! defined $value) {
	warn_msg('missing_value', $line);
	$value = '';
      }
      if ($value !~ /^\d+(\.\d+)?$/) {
	warn_msg('invalid_value', $line);
      }
      $record{score} = $value;
    }
    # UPF:0
    elsif ($line =~ /^UPF:/) {
      my ($tag, $value) = split /\s*:\s*/, $line;
      if (! defined $value) {
	warn_msg('missing_value', $line);
	$value = '';
      }
      if ($value !~ /^\d+$/) {
	warn_msg('invalid_value', $line);
      }
      $record{upf} = $value;
    }
    # genome_permutation_p:2.65314941903305e-18
    elsif ($line =~ /^genome_permutation_p:/) {
      my ($tag, $value) = split /\s*:\s*/, $line;
      if (! defined $value) {
	warn_msg('missing_value', $line);
	$value = '';
      }
      if ($value !~ /[0-9\.e\-]+/) {
	warn_msg('invalid_value', $line);
      }
      $record{p_value} = $value;
    }
    # genome_permutation_0.95_ci:2.65314941903305e-18,2.25166330953082e-06
    elsif ($line =~ /^genome_permutation_0\.95_ci:/) {
      my ($tag, $value) = split /\s*:\s*/, $line;
      if (! defined $value) {
	warn_msg('missing_value', $line);
	$value = '';
      }
      if ($value !~ /[0-9\.e\-]+,[0-9\.e\-]+/) {
	warn_msg('invalid_value', $line);
      }
      my @values = split /,/, $value;
      #@values ||= ('', '');
      $record{confidence_interval} = \@values;
    }
    # Running_time:14
    elsif ($line =~ /^Running_time:/) {
      my ($tag, $value) = split /\s*:\s*/, $line;
      if (! defined $value) {
	warn_msg('missing_value', $line);
	$value = '';
      }
      if ($value !~ /^\d+$/) {
	warn_msg('invalid_value', $line);
      }
      $record{running_time} = $value;
    }
    # num_permutations:1638301
    elsif ($line =~ /^num_permutations:/) {
      my ($tag, $value) = split /\s*:\s*/, $line;
      if (! defined $value) {
	warn_msg('missing_value', $line);
	$value = '';
      }
      if ($value !~ /^\d+$/) {
	warn_msg('invalid_value', $line);
      }
      $record{num_permutations} = $value;
    }
    # total_success:1
    elsif ($line =~ /^total_success:/) {
      my ($tag, $value) = split /\s*:\s*/, $line;
      if (! defined $value) {
	warn_msg('missing_value', $line);
	$value = '';
      }
      if ($value !~ /^\d+$/) {
	warn_msg('invalid_value', $line);
      }
      $record{total_success} = $value;
    }
    # LOD_SCORE:0.7269,0.0526315789473684
    elsif ($line =~ /^LOD_SCORE:/) {
      my ($tag, $value) = split /\s*:\s*/, $line;
      if (! defined $value) {
	warn_msg('missing_value', $line);
	$value = '';
      }
      if ($value !~ /^\d+/) {
	warn_msg('invalid_value', $line);
      }
      my @values = split /,/, $value;
      $record{lod_score} = \@values;
    }
    # Warn and skip on any line not recognized
    else {
      warn_msg('invalid_data_line', $line);
    }
  }
  return wantarray ? %record : \%record;
}

#-----------------------------------------------------------------------------

=head1 DIAGNOSTICS

L<Arty::VAAST> does not throw any warnings or errors.

=head1 CONFIGURATION AND ENVIRONMENT

L<Arty::VAAST> requires no configuration files or environment variables.

=head1 DEPENDENCIES

L<Arty::Base>

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
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT
WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER
PARTIES PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND,
EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE
SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME
THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE LIABLE
TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE
SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
DAMAGES.

=cut

1;
