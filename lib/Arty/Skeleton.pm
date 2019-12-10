package Arty::Skeleton;

use strict;
use warnings;
use vars qw($VERSION);

$VERSION = 0.0.1;
use base qw(Arty::Base);
use Arty::Utils qw(:all);

=head1 NAME

Arty::Skeleton - Parse vIQ List (input) files

=head1 VERSION

This document describes Arty::Skeleton version 0.0.1

=head1 SYNOPSIS

    use Arty::Skeleton;
    my $viq = Arty::Skeleton->new('sample.viq_list.txt');

    while (my $record = $parser->next_record) {
        print $record->{gene} . "\n";
    }

=head1 DESCRIPTION

L<Arty::Skeleton> provides vIQ skeleton file parsing ability for the
Artemisia suite of genomics tools.

=head1 DATA STRUCTURE

Arty::Skeleton returns records as a datastructure which has the
following format:



=head1 CONSTRUCTOR

New L<Arty::Skeleton> objects are created by the class method new.
Arguments should be passed to the constructor as a list (or reference)
of key value pairs.  If the argument list has only a single argument,
then this argument is applied to the 'file' attribute and thus
specifies the Skeleton filename.  All attributes of the L<Arty::Skeleton>
object can be set in the call to new. An simple example of object
creation would look like this:

    my $parser = Arty::Skeleton->new('sample.viq_list.txt');

    # This is the same as above
    my $parser = Arty::Skeleton->new('file' => 'sample.viq_list.txt');

The constructor recognizes the following parameters which will set the
appropriate attributes:

=over

=item * C<< file => sample.viq_list.txt >>

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
     Usage   : Arty::Skeleton->new();
     Function: Creates a Arty::Skeleton object;
     Returns : An Arty::Skeleton object
     Args    :

=cut

sub new {
        my ($class, @args) = @_;
        my $self = $class->SUPER::new(@args);
        $self->columns;
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

=head2 columns

  Title   : columns
  Usage   : $columns = $self->columns($columns_value);
  Function: Get columns
  Returns : An list of columns for vIQ list files
  Args    : No arguments accepted.  The columns attribute is get only.

=cut

 sub columns {
   my ($self) = shift @_;

   # chrom  pos     ref  alt  gene    transcript       csq_so overlap          distance af
   # 1      856436  TG   T    SAMD11  ENST00000342066  26      .               0      0.258865;0.0732858;0.163977;0.1817;0.0423077;0.234483;0.185767;0.145429

   $self->{columns} ||= [qw(chrom pos end ref alt gene transcript
                            csq_so overlap distance af)];

   return wantarray ? @{$self->{columns}} : $self->{columns};
}

#-----------------------------------------------------------------------------

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
 Usage   : $record = $vcf->next_record();
 Function: Return the next record from the Skeleton file.
 Returns : A hash (or reference) of Skeleton record data.
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
 Usage   : $record = $tempalte->parse_record($line);
 Function: Parse Skeleton line into a data structure.
 Returns : A hash (or reference) of Skeleton record data.
 Args    : A scalar containing a string of Tempalte record text.

=cut

sub parse_record {
    my ($self, $line) = @_;
    chomp $line;

    my @cols = split /\t/, $line;
    map {$_ = '' unless defined $_} @cols;

    my $col_count = scalar @cols;
    if ($col_count != 11) {
        handle_message('FATAL', 'incorrect_column_count', "(expected 11 got $col_count columns) $line");
    }

    my %record;

    @record{($self->columns)} = @cols;

    return wantarray ? %record : \%record;
}

#-----------------------------------------------------------------------------

=head1 DIAGNOSTICS

L<Arty::Skeleton> does not throw any warnings or errors.

=head1 CONFIGURATION AND ENVIRONMENT

L<Arty::Skeleton> requires no configuration files or environment variables.

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
