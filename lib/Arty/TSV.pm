package Arty::TSV;

use strict;
use warnings;
use vars qw($VERSION);

$VERSION = 0.0.1;
use base qw(Arty::Base);
use Arty::Utils qw(:all);

=head1 NAME

Arty::TSV - Parse TSV files

=head1 VERSION

This document describes Arty::TSV version 0.0.1

=head1 SYNOPSIS

    use Arty::TSV;
    my $tsv = Arty::TSV->new(file => 'data.tsv');

    while (my $record = $parser->next_record) {
	print $record->{data}[1] . "\n";
    }
    my $tsv2 = Arty::TSV->new(file => 'data2.tsv',
                              has_header => 1,
                              as_hash);

    while (my $record = $parser->next_record) {
	print $record->{gene} . "\n";
    }

=head1 DESCRIPTION

L<Arty::TSV> provides TSV (tab-separated values) parsing ability for
the Artemisia suite of genomics tools.

By default, any row that begins with a # is a header row.  Setting the
has_header attribute to a true value will parse the first row of the
file as a header row regardless.  By default record data is returned
as a hash(ref) with a single key 'data' and value is an array ref of
column values (i.e. @column_values = @{$record->{data}}).  Setting the
as_hash attribute to a true value will return records as a hash(ref)
whith column headers as the hash keys and column values as the hash
values (i.e. $column_value = $record->{column_header} where column
header is one of the values parsed from the header row or provided via
the cols attribute.)


=head1 CONSTRUCTOR

New L<Arty::TSV> objects are created by the class method new.
Arguments should be passed to the constructor as a list (or reference)
of key value pairs.  If the argument list has only a single argument,
then this argument is applied to the 'file' attribute and thus
specifies the TSV filename.  All attributes of the L<Arty::TSV>
object can be set in the call to new. An simple example of object
creation would look like this:

    my $parser = Arty::TSV->new('data.tsv');

    # This is the same as above
    my $parser = Arty::TSV->new('file' => 'data.tsv');


The constructor recognizes the following parameters which will set the
appropriate attributes:

=over

=item * C<< file => data.tsv >>

This optional parameter provides the filename for the file containing
the data to be parsed. While this parameter is optional either it, or
the following fh parameter must be set.

=item * C<< fh => $fh >>

This optional parameter provides a filehandle to read data from. While
this parameter is optional either it, or the previous file parameter
must be set.

=back

=cut

#-----------------------------------------------------------------------------
#-------------------------------- Constructor --------------------------------
#-----------------------------------------------------------------------------

=head2 new

     Title   : new
     Usage   : Arty::TSV->new();
     Function: Creates a Arty::TSV object;
     Returns : An Arty::TSV object
     Args    :

=cut

sub new {
	my ($class, @args) = @_;
	my $self = $class->SUPER::new(@args);
	$self->_process_header;
	return $self;
}

#-----------------------------------------------------------------------------
#----------------------------- Private Methods -------------------------------
#-----------------------------------------------------------------------------

=head1 PRIVATE METHODS

=head2 _initialize_args

 Title   : _initialize_args
 Usage   : $self->_initialize_args($args);
 Function: Initialize the arguments passed to the constructor.  In particular
           set all attributes passed.  For most classes you will just need to
           customize the @valid_attributes array within this method as you add
           Get/Set methods for each attribute.
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
        my @valid_attributes = qw(has_header as_hash cols);
        $self->set_attributes($args, @valid_attributes);
        ######################################################################
        return $args;
}

#-----------------------------------------------------------------------------

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
	 if ($self->has_header) {
             chomp $line;
             push @{$self->{header}}, $line;
	     $line =~ s/^\#//;
	     my @cols = split /\t/, $line;
	     $self->cols(@cols);
	     last LINE;
	 }
         elsif ($line =~ /^\#/) {
             chomp $line;
             push @{$self->{header}}, $line;
	     $line =~ s/^\#//;
	     my @cols = split /\t/, $line;
	     $self->cols(@cols);
         }
         else {
	     $self->_push_stack($line);
             last LINE;
         }
     }
}

#-----------------------------------------------------------------------------
#-------------------------------- Attributes ---------------------------------
#-----------------------------------------------------------------------------

=head1 ATTRIBUTES

=cut

#  =head2 attribute
# 
#   Title   : attribute
#   Usage   : $attribute = $self->attribute($attribute_value);
#   Function: Get/set attribute
#   Returns : An attribute value
#   Args    : An attribute value
# 
#  =cut
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

=head2 has_header

 Title   : has_header
 Usage   : $has_header = $self->has_header($has_header_value);
 Function: Get/set has_header
 Returns : Value of has_header (0=False or 1=True) 
 Args    : Value for has_header

=cut

 sub has_header {
   my ($self, $value) = @_;

   $self->{has_header} ||= 0;
   if (defined $value) {
     $self->{has_header} = $value;
   }

   return $self->{has_header};
 }

#-----------------------------------------------------------------------------

=head2 as_hash

 Title   : as_hash
 Usage   : $as_hash = $self->as_hash($as_hash_value);
 Function: Get/set as_hash.  When as_hash is set to true the parser
           returns records as a hash(ref).  Hash keys are determined
           by column headers, so file must have one of 1) a header row
           begining with #, 2) a header row and the has_header
           attribute set on the parser, 3) no header row, but he cols
           attribute set on the parser with the column headers.
 Returns : Value of as_hash (0=False or 1=True) 
 Args    : Value for as_hash

=cut

 sub as_hash {
   my ($self, $value) = @_;

   if (defined $value) {
     $self->{as_hash} = $value;
   }

   return $self->{as_hash};
 }

#-----------------------------------------------------------------------------

=head2 cols

 Title   : cols
 Usage   : $cols = $self->cols($cols_value);
 Function: Get/set cols
 Returns : An array(ref) of column headers
 Args    : An array of column headers;

=cut

 sub cols {
   my ($self, @cols) = @_;

   $self->{cols} = [] unless exists $self->{cols};

   if (@cols) {
     $self->{cols} = \@cols;
   }

   return wantarray ? @{$self->{cols}} : $self->{cols};
 }

#-----------------------------------------------------------------------------
#---------------------------------- Methods ----------------------------------
#-----------------------------------------------------------------------------

=head1 METHODS

=head2 next_record

 Title   : next_record
 Usage   : $record = $vcf->next_record();
 Function: Return the next record from the TSV file.
 Returns : A hash (or reference) of TSV record data.
 Args    : N/A

=cut

sub next_record {
    my $self = shift @_;

    my $line = $self->readline;
    return undef if ! defined $line;

    my $record = $self->parse_record($line);
    
    if ($self->as_hash) {
	my %hash;
	my $header_cols = $self->cols;
	if (! defined $header_cols) {
	    $self->throw('missing_header_columns',
			 'Make sure you set has_header or cols attribute');
	}
	my $data = $record->{data};
	delete $record->{data};
	@{$record}{@{$header_cols}} = @{$data};
    }
    return wantarray ? %{$record} : $record;
}

#-----------------------------------------------------------------------------

=head2 parse_record

 Title   : parse_record
 Usage   : $record = $tempalte->parse_record($line);
 Function: Parse TSV line into a data structure.
 Returns : A hash (or reference) of TSV record data.
 Args    : A scalar containing a string of Tempalte record text.

=cut

sub parse_record {
    my ($self, $line) = @_;
    chomp $line;
    
    my @cols_data = split /\t/, $line;
    
    my %record;
    
    $record{data} = \@cols_data;

    return wantarray ? %record : \%record;
}

#-----------------------------------------------------------------------------

=head1 DIAGNOSTICS

L<Arty::TSV> does not throw any warnings or errors.

=head1 CONFIGURATION AND ENVIRONMENT

L<Arty::TSV> requires no configuration files or environment variables.

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
