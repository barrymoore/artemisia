package Arty::VAAST_Simple;

use strict;
use warnings;
use vars qw($VERSION);

$VERSION = 0.0.1;
use base qw(Arty::Base);

=head1 NAME

Arty::VAAST_Simple - Parse VAAST_Simple files

=head1 VERSION

This document describes Arty::VAAST_Simple version 0.0.1

=head1 SYNOPSIS

    use Arty::VAAST_Simple;
    my $vaast = Arty::VAAST_Simple->new('vaast.simple');

    while (my $record = $parser->next_record) {
	print $record->{gene} . "\n";
    }

=head1 DESCRIPTION

L<Arty::VAAST_Simple> provides VAAST_Simple parsing ability for the artemisia suite
of genomics tools.

=head1 Constructor

New L<Arty::VAAST_Simple> objects are created by the class method new.
Arguments should be passed to the constructor as a list (or reference)
of key value pairs.  If the argument list has only a single argument,
then this argument is applied to the 'file' attribute and thus
specifies the VAAST_Simple filename.  All attributes of the L<Arty::VAAST_Simple>
object can be set in the call to new. An simple example of object
creation would look like this:

    my $parser = Arty::VAAST_Simple->new('vaast.simple');

    # This is the same as above
    my $parser = Arty::VAAST_Simple->new('file' => 'vaast.simple');

The constructor recognizes the following parameters which will set the
appropriate attributes:

=over

=item * C<< file => vaast.simple >>

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
     Usage   : Arty::VAAST_Simple->new();
     Function: Creates a Arty::VAAST_Simple object;
     Returns : An Arty::VAAST_Simple object
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
	 if ($line =~ /^\#/) {
	     chomp $line;
	     push @{$self->{header}}, $line;
	 }
	 elsif ($line =~ /^RANK\t/) {
	     chomp $line;
	     if ($line =~ /\tLOD\t/) {
		 $self->{_pvaast}++;
		 $self->{_cols} = [qw(rank gene pval pval_ci score lod)];
		 $self->{_col_count} = 6;
	     }
	     else {
		 $self->{_cols} = [qw(rank gene pval pval_ci score)];
		 $self->{_col_count} = 5;
	     }
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
 Usage   : $record = $vaast->next_record();
 Function: Return the next record from the VAAST simple file.
 Returns : A hash (or reference) of VAAST simple record data.
 Args    : N/A

=cut

sub next_record {
	my $self = shift @_;

	my $line = $self->readline;
	return undef if ! defined $line;
	chomp $line;

	my @cols = split /\t/, $line;
	my @data = splice(@cols, 0, $self->{_col_count});
	
	my %record;
	@record{@{$self->{_cols}}} = (@data, \@cols);

	return wantarray ? %record : \%record;
}

#-----------------------------------------------------------------------------

=head1 DIAGNOSTICS

L<Arty::VAAST_Simple> does not throw any warnings or errors.

=head1 CONFIGURATION AND ENVIRONMENT

L<Arty::VAAST_Simple> requires no configuration files or environment variables.

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
