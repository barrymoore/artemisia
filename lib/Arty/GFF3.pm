package Arty::GFF3;

use strict;
use warnings;
use vars qw($VERSION);

$VERSION = 0.0.1;
use base qw(Arty::Base);
use Arty::Utils qw(:all);

=head1 NAME

Arty::GFF3 - Parse GFF3 files

=head1 VERSION

This document describes Arty::GFF3 version 0.0.1

=head1 SYNOPSIS

    use Arty::GFF3;
    my $gff3 = Arty::GFF3->new('data.txt');

    while (my $record = $parser->next_record) {
	print $record->{gene} . "\n";
    }

=head1 DESCRIPTION

L<Arty::GFF3> provides GFF3 parsing ability for the Artemisia suite
of genomics tools.

=head1 CONSTRUCTOR

New L<Arty::GFF3> objects are created by the class method new.
Arguments should be passed to the constructor as a list (or reference)
of key value pairs.  If the argument list has only a single argument,
then this argument is applied to the 'file' attribute and thus
specifies the GFF3 filename.  All attributes of the L<Arty::GFF3>
object can be set in the call to new. An simple example of object
creation would look like this:

    my $parser = Arty::GFF3->new('gff3.txt');

    # This is the same as above
    my $parser = Arty::GFF3->new('file' => 'gff3.txt');


The constructor recognizes the following parameters which will set the
appropriate attributes:

=over

=item * C<< file => gff3.txt >>

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
     Usage   : Arty::GFF3->new();
     Function: Creates a Arty::GFF3 object;
     Returns : An Arty::GFF3 object
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
        my @valid_attributes = qw();
        $self->set_attributes($args, @valid_attributes);
        ######################################################################
        return $args;
}

#-----------------------------------------------------------------------------

=head2 _process_header

  Title   : _process_header
  Usage   : $self->_process_header
  Function: Parse and store header lines
  Returns : N/A
  Args    : N/A

=cut

 sub _process_header {
     my $self = shift @_;

     my $fh = $self->fh;
     $self->{header} ||= [];

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

#-----------------------------------------------------------------------------
#-------------------------------- Attributes ---------------------------------
#-----------------------------------------------------------------------------

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

#-----------------------------------------------------------------------------
#---------------------------------- Methods ----------------------------------
#-----------------------------------------------------------------------------

=head1 METHODS

=head2 next_record

 Title   : next_record
 Usage   : $record = $gff3->next_record();
 Function: Return the next record from the GFF3 file.
 Returns : A hash (or reference) of GFF3 record data.
 Args    : N/A

=cut

sub next_record {
 my $self = shift @_;

 my $line = $self->readline;
 return undef if ! defined $line;

 my $record = $self->parse_record($line);

 return wantarray ? %{$record} : $record;
}

#-----------------------------------------------------------------------------

=head2 parse_record

 Title   : parse_record
 Usage   : $record = $gff3->parse_record($line);
 Function: Parse GFF3 line into a data structure.
 Returns : A hash (or reference) of GFF3 record data.
 Args    : A scalar containing a string of Tempalte record text.

=cut

sub parse_record {
    my ($self, $line) = @_;
    chomp $line;

    my @cols = split /\s+/, $line;

    my %record;

    @record{qw(chrom source type start end score strand phase
               attributes)} = @cols;

    $record{attributes} =
	$self->parse_attributes($record{attributes});

    return wantarray ? %record : \%record;
}

#-----------------------------------------------------------------------------

=head2 parse_attributes

 Title   : parse_attributes
 Usage   : $gff3->parse_attributes($attrb_txt);
 Function: Parse a GFF3 ATTRIBUTES string into a data structure.
 Returns : A hash (or reference) of GFF3 ATTRIBUTES data.
 Args    : A scalar containing a string of GFF3 ATTRIBUTES text.

=cut

sub parse_attributes {
 my ($self, $attributes) = @_;
 chomp $attributes;

 my @pairs = split /;/, $attributes;

 my %attributes;
 for my $pair (@pairs) {
     my ($key, $value) = split(/=/, $pair);
     $value ||= '';
    my @values = split /,/, $value;
    push @{$attributes{$key}}, @values;
 }
 return wantarray ? %attributes : \%attributes;
}

#-----------------------------------------------------------------------------

=head2 format_gff3_record

 Title   : format_gff3_record
 Usage   : $gff3->format_gff3_record($gff3_record);
 Function: Format a Arty::GFF3 record as a GFF3 text string (basically this
           is the opposite of parse_record).
 Returns : A string of GFF3 record text.
 Args    : A Arty::GFF3 structured record.

=cut

sub format_gff3_record {
    my ($self, $record) = @_;

    my @attrb_pairs;
    for my $key (sort keys %{$record->{attributes}}) {
	my $values = $record->{attributes}{$key};
	my $values_txt = join ',', @{$values};
	push @attrb_pairs, "$key=$values_txt";
    }
    my $attrb_txt = join ';', @attrb_pairs;
    my $record_txt = join "\t", @{$record}{qw(chrom source type start end score strand phase)}, $attrb_txt;
    return $record_txt;
}

#-----------------------------------------------------------------------------

=head2 get_header

 Title   : get_header
 Usage   : @header = $gff3->get_header();
 Function: Get the GFF3 header lines as a list.
 Returns : An array (or reference) of GFF3 header lines.
 Args    : N/A

=cut

sub get_header {
 my $self = shift @_;

 return wantarray ? @{$self->{header}} : $self->{header};
}

#-----------------------------------------------------------------------------

=head1 DIAGNOSTICS

L<Arty::GFF3> does not throw any warnings or errors.

=head1 CONFIGURATION AND ENVIRONMENT

L<Arty::GFF3> requires no configuration files or environment variables.

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
