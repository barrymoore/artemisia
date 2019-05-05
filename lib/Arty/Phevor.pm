package Arty::Phevor;

use strict;
use warnings;
use vars qw($VERSION);

$VERSION = 0.0.1;
use base qw(Arty::Base);

=head1 NAME

Arty::Phevor - Parse Phevor files

=head1 VERSION

This document describes Arty::Phevor version 0.0.1

=head1 SYNOPSIS

    use Arty::Phevor;
    my $parser = Arty::Phevor->new('phevor.txt');

    while (my $record = $parser->next_record) {
	print $record->{gene}) . "\n";
    }

=head1 DESCRIPTION

L<Arty::Phevor> provides Phevor parsing ability for the artemisia suite
of genomics tools.

=head1 Constructor

New L<Arty::Phevor> objects are created by the class method new.
Arguments should be passed to the constructor as a list (or reference)
of key value pairs.  If the argument list has only a single argument,
then this argument is applied to the 'file' attribute and thus
specifies the Phevor filename.  All attributes of the L<Arty::Phevor>
object can be set in the call to new. An simple example of object
creation would look like this:

    my $parser = Arty::Phevor->new('phevor.txt');

    # This is the same as above
    my $parser = Arty::Phevor->new('file' => 'phevor.txt');


The constructor recognizes the following parameters which will set the
appropriate attributes:

=over

=item * C<< file => phevor.txt >>

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
     Usage   : Arty::Phevor->new();
     Function: Creates a Arty::Phevor object;
     Returns : An Arty::Phevor object
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

     my $fh = $self->fh;

   LINE:
     while (my $line = $self->readline) {
	 return undef if ! defined $line;

	 if ($line =~ /^RANK\s+/) {
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

=head2 next_record

 Title   : next_record
 Usage   : $record = $phevor->next_record();
 Function: Return the next record from the Phevor file.
 Returns : A hash (or reference) of Phevor record data.
 Args    : N/A

=cut

sub next_record {
	my $self = shift @_;

	my $line;
      LINE:
	while (! $line) {
	    $line = $self->readline;
	    last LINE if ! defined $line;
	    if ($line =~ /^\#/) {
		push @{$self->{footer}}, $line;
		undef($line);
		next LINE;
	    }
	}
	return undef if ! defined $line;

	chomp $line;
	my @cols = split /\s+/, $line; my %record;

	@record{qw(rank gene score prior raw_score go ext_fnl_prior
		   cmbnd_prior fwrd_p orig_p p_disease p_healthy)} =
		   (@cols);

	return wantarray ? %record : \%record;
}

#-----------------------------------------------------------------------------

=head1 DIAGNOSTICS

L<Arty::Phevor> does not throw any warnings or errors.

=head1 CONFIGURATION AND ENVIRONMENT

L<Arty::Phevor> requires no configuration files or environment variables.

=head1 DEPENDENCIES

L<Arty>

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
