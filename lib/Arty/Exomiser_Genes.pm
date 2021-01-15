package Arty::Exomiser_Genes;

use strict;
use warnings;
use vars qw($VERSION);

$VERSION = 0.0.1;
use base qw(Arty::Base);
use Arty::Utils qw(:all);

=head1 NAME

Arty::Exomiser_Genes - Parse Exomiser Genes TSV files

=head1 VERSION

This document describes Arty::Exomiser_Genes version 0.0.1

=head1 SYNOPSIS

    use Arty::Exomiser_Genes;
    my $parser = Arty::Exomiser_Genes->new('data.txt');

    while (my $record = $parser->next_record) {
	print $record->{gene} . "\n";
    }

=head1 DESCRIPTION

L<Arty::Exomiser_Genes> provides Exomiser Genes TSV file parsing
ability for the Artemisia suite of genomics tools.

=head1 CONSTRUCTOR

New L<Arty::Exomiser_Genes> objects are created by the class method
new.  Arguments should be passed to the constructor as a list (or
reference) of key value pairs.  If the argument list has only a single
argument, then this argument is applied to the 'file' attribute and
thus specifies the Exomiser Genes TSV filename.  All attributes of the
L<Arty::Exomiser_Genes> object can be set in the call to new. An
simple example of object creation would look like this:

    my $parser = Arty::Exomiser_Genes->new('exomiser_AD.genes.tsv');

    # This is the same as above
    my $parser = Arty::Exomiser_Genes->new('file' => 'exomiser_AD.genes.tsv');


The constructor recognizes the following parameters which will set the
appropriate attributes:

=over

=item * C<< file => exomiser_AD.genes.tsv >>

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
     Usage   : Arty::Exomiser_Genes->new();
     Function: Creates a Arty::Exomiser_Genes object;
     Returns : An Arty::Exomiser_Genes object
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
	     $line =~ s/^\#//;
             $self->{header} = $line;
	     @{$self->{cols}} = split /\t/, $self->{header};
	     map {$_ = lc $_} @{$self->{cols}};
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
 Usage   : $record = $parser->next_record();
 Function: Return the next record from the Exomiser_Genes file.
 Returns : A hash (or reference) of Exomiser_Genes record data.
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
 Usage   : $record = $parser->parse_record($line);
 Function: Parse Exomiser_Genes line into a data structure.
 Returns : A hash (or reference) of Exomiser_Genes record data.
 Args    : A scalar containing a string of Tempalte record text.

=cut

sub parse_record {
    my ($self, $line) = @_;
    chomp $line;

    my @cols = split /\t/, $line;

    my %record;

    @record{@{$self->{cols}}} = @cols;

    return wantarray ? %record : \%record;
}

#-----------------------------------------------------------------------------

=head2 get_header

 Title   : get_header
 Usage   : @header = $parser->get_header();
 Function: Get the Exomiser_Genes header lines as a list.
 Returns : An array (or reference) of Exomiser_Genes header lines.
 Args    : N/A

=cut

sub get_header {
 my $self = shift @_;

 return $self->{header};
}

#-----------------------------------------------------------------------------

=head1 DIAGNOSTICS

L<Arty::Exomiser_Genes> does not throw any warnings or errors.

=head1 CONFIGURATION AND ENVIRONMENT

L<Arty::Exomiser_Genes> requires no configuration files or environment variables.

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
