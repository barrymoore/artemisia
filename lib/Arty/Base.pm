package Arty::Base;

use strict;
use vars qw($VERSION);
use Carp qw(croak cluck);
use Arty::Utils qw(:all);

$VERSION = 0.0.1;

=head1 NAME

L<Arty::Base> - Base class for the Artemisia library

=head1 VERSION

This document describes L<Arty::Base> version 0.0.1

=head1 SYNOPSIS

    use base qw(Arty::Base);

=head1 DESCRIPTION

L<Arty::Base> serves as a base class for all of the other classes in
Arty.  It is not intended to be instantiated directly, but rather to be
used with the 'use base' pragma by the other modules.  L<Arty::Base>
provides object instantiation, argument preparation and attribute
setting functions for other classes during object construction.  In
addition it provides a wide range of utility functions that are
expected to be applicable throughout the library.

=head1 INHERITS FROM

None

=head1 INHERITED BY

=over 4

=item L<Fasta.pm>

=item L<GFF3.pm>

=item L<Phevor.pm>

=back

=head1 USES

=over

=item * L<Carp>

=item * L<Scalar::Util>

=back

=cut

#-----------------------------------------------------------------------------
#-------------------------------- Constructor --------------------------------
#-----------------------------------------------------------------------------

=head1 CONSTRUCTOR

L<Arty::Base> is not intended to by instantiated on it's own.  It does
however, handle object creation for the rest of the library.  Each
class in Arty calls:

    my $self = $class->SUPER::new(@args);

This means that Arty::Base - at the bottom of the inheritance chain
does the actual object creation.  It creates the new object based on
the calling class.

=cut

#-----------------------------------------------------------------------------

=head2 new

     Title   : new
     Usage   : Arty::SomeClass->new();
     Function: Creates on object of the calling class
     Returns : An object of the calling class
     Args    : See the attributes described above.

=cut

sub new {
	my ($class, @args) = @_;
	$class = ref($class) || $class;
	my $self = bless {}, $class;

	my $args = $self->_prepare_args(@args);

	# Call attribute class first so that objects get reblessed
	# into the appropriate subclass before they set their
	# attributes.
	if ($args->{class}) {
	    $self = $self->class($args->{class});
	    delete $args->{class};
	}

	# Create the _readlin_stack array ref for use by $self->readline;
	$self->{_readline_stack} = [];

	$self->_initialize_args($args);
	return $self;
}

#-----------------------------------------------------------------------------
#------------------------------ Private Methods ------------------------------
#-----------------------------------------------------------------------------

=head1 PRIVATE METHODS

=cut

#-----------------------------------------------------------------------------

=head2 _prepare_args

 Title   : _prepare_args
 Usage   : $args = $self->_prepare_args(@_);
 Function: Take a list of key value pairs that may be structured as an
	   array, a hash or and array or hash reference and return
	   them as a hash or hash reference depending on calling
	   context.
 Returns : Hash or hash reference.
 Args    : An array, hash or reference to either.

=cut

sub _prepare_args {

	my ($self, @args) = @_;

	my %args_hash;

	if (! $args[0]) {
	  # If no args are passed, don't do anything just return an empty
	  # hash(ref).
	}
	elsif (scalar @args == 1 && ref $args[0] eq 'ARRAY') {
		%args_hash = @{$args[0]};
	}
	elsif (scalar @args == 1 && ref $args[0] eq 'HASH') {
		%args_hash = %{$args[0]};
	}
	elsif (scalar @args % 2 == 0) {
		%args_hash = @args;
	}
	else {
		my $class = ref($self);
		my $err_code = 'invalid_arguments_to_prepare_args';
		my $err_msg  = ("Bad arguments passed to $class. A list "   .
				"of key value pairs or a reference to "     .
				"such a list was expected, But we got:\n"   .
				join ' ', @args);
		throw_msg($err_code, $err_msg);
	}

	return wantarray ? %args_hash : \%args_hash;
}

#-----------------------------------------------------------------------------

=head2 _initialize_args

 Title   : _initialize_args
 Usage   : $self->_initialize_args($args);
 Function: Initialize the arguments passed to the constructor.  In particular
	   set all attributes passed.
 Returns : N/A
 Args    : A hash or array reference of arguments.

=cut

sub _initialize_args {
	my ($self, $args) = @_;

	######################################################################
	# This block of code handels class attributes.  Use the
	# @valid_attributes below to define the valid attributes for
	# this class.  You must have identically named get/set methods
	# for each attribute.  Leave the rest of this block alone!
	######################################################################
	my @valid_attributes = qw(file fh); # Set valid class attributes here
	$self->set_attributes($args, @valid_attributes);
	######################################################################
	return $args;
}

=head2 _push_stack

 Title   : _push_stack
 Usage   : $self->_push_stack($record_txt);
 Function: Push a string of text onto the _readline_stack. This is
	   used for adding a line read from a file handle back onto a
	   stack that will be read before the next call to the
	   filehandle.
 Returns : N/A
 Args    : A scalar

=cut

sub _push_stack {
	my ($self, @args) = @_;

	push @{$self->{_readline_stack}}, @args;

}

=head2 _shift_stack

 Title   : _shift_stack
 Usage   : $self->_shift_stack($record_txt);
 Function: Shift a string of text off of the _readlin_stack.
 Returns : A scalar
 Args    : N/A

=cut

sub _shift_stack {
	my $self = shift @_;
	return shift @{$self->{_readline_stack}};
}

#-----------------------------------------------------------------------------
#--------------------------------- Attributes --------------------------------
#-----------------------------------------------------------------------------

=head1  ATTRIBUTES

All attributes can be supplied as parameters to the constructor as a
list (or referenece) of key value pairs.

=cut

#-----------------------------------------------------------------------------

=head2 verbosity

 Title   : verbosity
 Usage   : $base->verbosity($level);
 Function: Set the level of verbosity written to STDERR by the code.
 Returns : None
 Args    : Arguments can be either the words debug, info, unique, warn,
	   fatal or their numerical equivalents as given below.

	   debug  | 1: Print all FATAL, WARN, INFO, and DEBUG messages.  Produces
		       a lot of output.
	   info   | 2: Print all FATAL, WARN, and INFO messages. This is the
		       default.
	   unique | 3: Print only the first occurence of each error/info code.
	   warn   | 4: Don't print INFO messages.
	   fatal  | 5: Don't print INFO or WARN messages. Still dies with
		       message on FATAL errors.

=cut

sub verbosity {
  my ($self, $verbosity) = @_;

  if ($verbosity) {
    $verbosity = lc $verbosity;
    $verbosity = ($verbosity =~ /^d/ ? 1 :
		  $verbosity =~ /^i/ ? 2 :
		  $verbosity =~ /^u/ ? 3 :
		  $verbosity =~ /^w/ ? 4 :
		  $verbosity =~ /^f/ ? 5 :
		  $verbosity);
    if (! grep {$verbosity eq $_} qw(1 2 3 4 5)) {
      warn_msg('invalid_verbosity_level',
	   "$verbosity - setting verbosity level to info");
      $verbosity = 2;
    }
    $self->{verbosity} = $verbosity;
  }
  $self->{verbosity} ||= '2';
  return $self->{verbosity};
}

#-----------------------------------------------------------------------------

=head2 file

 Title   : file
 Usage   : $file = $fasta->file('sequence.fa');
 Function: Get/Set the file for the object.
 Returns : The name of the Fasta file.
 Args    : N/A

=cut

sub file {
    my ($self, $file) = @_;

    if (defined $file) {
	if (! -e $file) {
	    throw_msg('file_does_not_exist', $file);
	}
	elsif (! -r $file) {
	    throw_msg('file_not_readable', $file);
	}

	if (exists $self->{file} && defined $self->{file}) {
	    warn_msg('file_attribute_is_being_reset', $file);
	}
	$self->{file} = $file;
	# Clear any existing filehandle
	delete $self->{fh};
    }

    if (! exists $self->{file} || ! defined $self->{file}) {
	warn_msg('file_attribute_undefined');
    }
    return $self->{file};
}

#-----------------------------------------------------------------------------

=head2 fh

 Title   : fh
 Usage   : $FH = $fasta->fh('sequence.fa');
 Function: Get/Set the filehandle for the object.
 Returns : A reference to the file handle.
 Args    : A reference to a file handle

=cut

sub fh {

  my ($self, $FH) = @_;

  if (defined $FH) {
      if (exists $self->{fh} && defined $self->{fh}) {
	  warn_msg('fh_attribute_is_being_reset', $FH);
      }
      $self->{fh} = $FH;
  }
  elsif (! exists $self->{fh}) {
      my $file = $self->file;
      my $FH;
      if (my $tabix = $self->tabix) {
	  open($FH, '-|', "tabix $file $tabix") or
	      throw_msg('cant_open_tabix_pipe_for_reading', $file);
      }
      elsif ($file =~ /\.b?gz/) {
	  open($FH, '-|', "gunzip -c $file") or
	      throw_msg('cant_open_gunzip_pipe_for_reading', $file);
      }
      else {
	  open($FH, '<', $file) or
	      throw_msg('cant_open_file_for_reading', $file);
      }

      # Set filehandle
      if (exists $self->{fh} && defined $self->{fh}) {
	  warn_msg('fh_attribute_is_being_reset', $FH);
      }
      $self->fh($FH);

      if (! exists $self->{fh} || ! defined $self->{fh}) {
	  warn_msg('fh_attribute_undefined');
      }
  }
  return $self->{fh};
}

#-----------------------------------------------------------------------------

=head2 tabix

 Title   : tabix
 Usage   : $tabix = $self->tabix($tabix_filter);
 Function: This attribute is an abstract method to return undef for classes
	   that do not impliment a tabix attribute.
 Returns : undef
 Args    : N/A

=cut

  sub tabix {
  my ($self, $tabix_value) = @_;

  if ($tabix_value) {
      throw('tabix_attribute_not_supported', 'tabix is not supported');
  }

  return undef
}

#-----------------------------------------------------------------------------

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

#-----------------------------------------------------------------------------
#---------------------------------- Methods ----------------------------------
#-----------------------------------------------------------------------------

=head1 METHODS

=cut

#-----------------------------------------------------------------------------

=head2 readline

 Title   : readline
 Usage   : my $line = $self->readline;
 Function: Read a line from the file handle, checking the
	   @{$self->{_readline_stack}} first.
 Returns : A line from the file or undef if the EOF is reached.
 Args    : N/A

=cut

sub readline {
    my $self = shift @_;
    my $FH = $self->fh;
    return ($self->_shift_stack || <$FH>);
}

#-----------------------------------------------------------------------------

=head2 set_attributes

 Title   : set_attributes
 Usage   : $base->set_attributes($args, @valid_attributes);
 Function: Take a hash reference of arguments and a list (or reference) of
	   valid attribute names and call the methods to set those
	   attribute values.
 Returns : None
 Args    : A hash reference of arguments and an array or array reference of
	   valid attributes names.

=cut

sub set_attributes {

	my $self = shift;
	my $args = shift;

	# Allow @valid_attributes to be passed as array or arrayref.
	my @valid_attributes = ref($_[0]) eq 'ARRAY' ? @{$_[0]} : @_;

	my $package = __PACKAGE__;
	my $caller = ref($self);

	$args = $self->_prepare_args($args);

	for my $attribute (@valid_attributes) {
		next unless exists $args->{$attribute};
		if (exists $self->{$attribute}) {
			my $package = __PACKAGE__;
			my $caller = ref($self);
			my $warning_message =
			  ("$package is about to reset the value of $attribute " .
			   "on behalf of a $caller object.  This may be "   .
			   "a bad idea.");
			warn_msg('resetting_attribute_values', $warning_message);
		}
		$self->$attribute($args->{$attribute});
		delete $args->{$attribute};
	}
}

#-----------------------------------------------------------------------------

=head2 all_records

 Title   : all_records
 Usage   : $record = $phevor->all_records();
 Function: Parse and return all records.
 Returns : An array (or reference) of all Template records.
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

=head1 DIAGNOSTICS

=over

=item C<< invalid_arguments_to_prepare_args >>

C<Arty::Base::_prepare_args> accepts an array, a hash or a reference to
either an array or hash, but it was passed something different.

=back

=head1 CONFIGURATION AND ENVIRONMENT

L<Arty::Base> requires no configuration files or environment variables.

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
