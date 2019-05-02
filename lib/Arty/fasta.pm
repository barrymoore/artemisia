package Arty::fasta;

use strict;
use warnings;
use vars qw($VERSION);


$VERSION = 0.0.1;

=head1 NAME

Arty::fasta - Parse Fasta files

=head1 VERSION

This document describes Arty::fasta version 0.0.1

=head1 SYNOPSIS

    use Arty::fasta;
    my $fasta = Arty::fasta->new('sequence.fa');

    while (my $seq = $parser->next_seq) {
	print '>' . $seq->{header} . "\n";
	print wrap_text($seq->{sequence}) . \n;
    }

=head1 DESCRIPTION

L<Arty::fasta> provides Fasta parsing ability for the artemisia suite
of genomics tools.

=head1 Constructor

New L<Arty::fasta> objects are created by the class method new.
Arguments should be passed to the constructor as a list (or reference)
of key value pairs.  If the argument list has only a single argument,
then this argument is applied to the 'file' attribute and thus
specifies the fasta filename.  All attributes of the L<Arty::fasta>
object can be set in the call to new. An simple example of object
creation would look like this:

    my $parser = Arty::fasta->new('sequence.fa');

    # This is the same as above
    my $parser = Arty::fasta->new('file' => 'sequence.fa');


The constructor recognizes the following parameters which will set the
appropriate attributes:

=over

=item * C<< file => sequence.fa >>

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
     Usage   : Arty::fasta->new();
     Function: Creates a Arty::fasta object;
     Returns : A Arty::fasta object
     Args    :

=cut

sub new {
	my ($class, @args) = @_;
	my $self = $class->SUPER::new(@args);
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
  my @valid_attributes = qw(file fh); # Set valid class attributes here
  $self->set_attributes($args, @valid_attributes);
  ######################################################################
}

#-----------------------------------------------------------------------------
#-------------------------------- Attributes ---------------------------------
#-----------------------------------------------------------------------------

=head2 file

 Title   : file
 Usage   : $file = $fasta->file('sequence.fa');
 Function: Get/Set the file for the object.
 Returns : The name of the fasta file.
 Args    : N/A

=cut

sub file {
	my ($self, $file) = @_;

	if (defined $file) {
	  if (! -e $file) {
	    $self->send_message('FATAL', 'file_does_not_exist', $file);
	  }
	  elsif (! -r $file) {
	    $self->send_message('FATAL', 'file_not_readable', $file);
	  }

	  if (exists $self->{file} && defined $self->{file}) {
	    $self->send_message('WARN', 'file_attribute_is_being_reset', $file);
	  }
	  $self->{file} = $file;
	  open(my $fh, '<', $file) or
	    $self->send_message('FATAL', 'cant_open_file_for_reading', $file);
	  $self->fh($fh);
	}

	if (! exists $self->{file} || ! defined $self->{file}) {
	  $self->send_message('WARN', 'file_attribute_undefined');
	}

	return $self->{file};
}

#-----------------------------------------------------------------------------

=head2 fh

 Title   : fh
 Usage   : $fh = $fasta->fh('sequence.fa');
 Function: Get/Set the filehandle for the object.
 Returns : A reference to the file handle.
 Args    : A reference to a file handle

=cut

sub fh {

  my ($self, $fh) = @_;

  if (defined $fh) {
    if (exists $self->{fh} && defined $self->{fh}) {
      $self->send_message('WARN', 'fh_attribute_is_being_reset', $fh);
    }
    $self->{fh} = $fh;
  }

  if (! exists $self->{fh} || ! defined $self->{fh}) {
    $self->send_message('WARN', 'fh_attribute_undefined');
  }

  return $self->{fh};
}

#-----------------------------------------------------------------------------
#---------------------------------- Methods ----------------------------------
#-----------------------------------------------------------------------------

=head2 next_seq

 Title   : next_seq
 Usage   : $seq = $fasta->next_seq();
 Function: Return the next sequence from the file.
 Returns : A hash (or reference) of sequence data.
 Args    : N/A

=cut

sub next_seq {
	my $self = shift @_;

	my $seq = {header => '>xyq',
		   seq    => 'ATG'};

	return wantarray ? %seq : \%seq;
}

#-----------------------------------------------------------------------------

=head1 DIAGNOSTICS

L<Arty::fasta> does not throw any warnings or errors.

=head1 CONFIGURATION AND ENVIRONMENT

L<Arty::fasta> requires no configuration files or environment variables.

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

Copyright (c) 2010-2014, Barry Moore <barry.moore@genetics.utah.edu>.
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
