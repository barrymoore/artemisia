# NAME

[Arty::Base](https://metacpan.org/pod/Arty::Base) - Base class for the Artemisia library

# VERSION

This document describes [Arty::Base](https://metacpan.org/pod/Arty::Base) version 0.0.1

# SYNOPSIS

    use base qw(Arty::Base);

# DESCRIPTION

[Arty::Base](https://metacpan.org/pod/Arty::Base) serves as a base class for all of the other classes in
Arty.  It is not intended to be instantiated directly, but rather to be
used with the 'use base' pragma by the other modules.  [Arty::Base](https://metacpan.org/pod/Arty::Base)
provides object instantiation, argument preparation and attribute
setting functions for other classes during object construction.  In
addition it provides a wide range of utility functions that are
expected to be applicable throughout the library.

# INHERITS FROM

None

# INHERITED BY

- [Fasta.pm](https://metacpan.org/pod/Fasta.pm)
- [GFF3.pm](https://metacpan.org/pod/GFF3.pm)
- [Phevor.pm](https://metacpan.org/pod/Phevor.pm)

# USES

- [Carp](https://metacpan.org/pod/Carp)
- [Scalar::Util](https://metacpan.org/pod/Scalar::Util)

# CONSTRUCTOR

[Arty::Base](https://metacpan.org/pod/Arty::Base) is not intended to by instantiated on it's own.  It does
however, handle object creation for the rest of the library.  Each
class in Arty calls:

    my $self = $class->SUPER::new(@args);

This means that Arty::Base - at the bottom of the inheritance chain
does the actual object creation.  It creates the new object based on
the calling class.

## new

     Title   : new
     Usage   : Arty::SomeClass->new();
     Function: Creates on object of the calling class
     Returns : An object of the calling class
     Args    : See the attributes described above.

# PRIVATE METHODS

## \_prepare\_args

    Title   : _prepare_args
    Usage   : $args = $self->_prepare_args(@_);
    Function: Take a list of key value pairs that may be structured as an
              array, a hash or and array or hash reference and return
              them as a hash or hash reference depending on calling
              context.
    Returns : Hash or hash reference.
    Args    : An array, hash or reference to either.

## \_initialize\_args

    Title   : _initialize_args
    Usage   : $self->_initialize_args($args);
    Function: Initialize the arguments passed to the constructor.  In particular
              set all attributes passed.
    Returns : N/A
    Args    : A hash or array reference of arguments.

## \_push\_stack

    Title   : _push_stack
    Usage   : $self->_push_stack($record_txt);
    Function: Push a string of text onto the _readline_stack. This is
              used for adding a line read from a file handle back onto a
              stack that will be read before the next call to the
              filehandle.
    Returns : N/A
    Args    : A scalar

## \_shift\_stack

    Title   : _shift_stack
    Usage   : $self->_shift_stack($record_txt);
    Function: Shift a string of text off of the _readlin_stack.
    Returns : A scalar
    Args    : N/A

# ATTRIBUTES

All attributes can be supplied as parameters to the constructor as a
list (or referenece) of key value pairs.

## verbosity

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

## file

    Title   : file
    Usage   : $file = $fasta->file('sequence.fa');
    Function: Get/Set the file for the object.
    Returns : The name of the Fasta file.
    Args    : N/A

## fh

    Title   : fh
    Usage   : $FH = $fasta->fh('sequence.fa');
    Function: Get/Set the filehandle for the object.
    Returns : A reference to the file handle.
    Args    : A reference to a file handle

# METHODS

## readline

    Title   : readline
    Usage   : my $line = $self->readline;
    Function: Read a line from the file handle, checking the
              @{$self->{_readline_stack}} first.
    Returns : A line from the file or undef if the EOF is reached.
    Args    : N/A

## set\_attributes

    Title   : set_attributes
    Usage   : $base->set_attributes($args, @valid_attributes);
    Function: Take a hash reference of arguments and a list (or reference) of
              valid attribute names and call the methods to set those
              attribute values.
    Returns : None
    Args    : A hash reference of arguments and an array or array reference of
              valid attributes names.

# DIAGNOSTICS

- `invalid_arguments_to_prepare_args`

    `Arty::Base::_prepare_args` accepts an array, a hash or a reference to
    either an array or hash, but it was passed something different.

# CONFIGURATION AND ENVIRONMENT

[Arty::Base](https://metacpan.org/pod/Arty::Base) requires no configuration files or environment variables.

# DEPENDENCIES

- [Carp](https://metacpan.org/pod/Carp) qw(croak cluck)

# INCOMPATIBILITIES

None reported.

# BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to:
barry.moore@genetics.utah.edu

# AUTHOR

Barry Moore <barry.moore@genetics.utah.edu>

# LICENCE AND COPYRIGHT

Copyright (c) 2019, Barry Moore <barry.moore@genetics.utah.edu>.
All rights reserved.

    This module is free software; you can redistribute it and/or
    modify it under the same terms as Perl itself (See LICENSE).

# DISCLAIMER OF WARRANTY

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
