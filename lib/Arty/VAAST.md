# NAME

Arty::VAAST - Parse VAAST2 files

# VERSION

This document describes Arty::VAAST version 0.0.1

# SYNOPSIS

    use Arty::VAAST;
    my $vaast = Arty::VAAST->new('output.vaast');

    while (my $record = $parser->next_record) {
        print $record->{gene} . "\n";
    }

# DESCRIPTION

[Arty::VAAST](https://metacpan.org/pod/Arty::VAAST) provides VAAST parsing ability for the artemisia suite
of genomics tools.

# CONSTRUCTOR

New [Arty::VAAST](https://metacpan.org/pod/Arty::VAAST) objects are created by the class method new.
Arguments should be passed to the constructor as a list (or reference)
of key value pairs.  If the argument list has only a single argument,
then this argument is applied to the 'file' attribute and thus
specifies the VAAST filename.  All attributes of the [Arty::VAAST](https://metacpan.org/pod/Arty::VAAST)
object can be set in the call to new. An simple example of object
creation would look like this:

    my $parser = Arty::VAAST->new('output.vaast');

    # This is the same as above
    my $parser = Arty::VAAST->new('file' => 'output.vaast');

The constructor recognizes the following parameters which will set the
appropriate attributes:

- `file => output.vaast`

    This optional parameter provides the filename for the file containing
    the data to be parsed. While this parameter is optional either it, or
    the following fh parameter must be set.

- `fh => $fh`

    This optional parameter provides a filehandle to read data from. While
    this parameter is optional either it, or the previous file parameter
    must be set.

## new

     Title   : new
     Usage   : Arty::VAAST->new();
     Function: Creates a Arty::VAAST object;
     Returns : A Arty::VAAST object
     Args    :

# PRIVATE METHODS

sub \_initialize\_args {
  my ($self, @args) = @\_;

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

## \_process\_header

    Title   : _process_header
    Usage   : $self->_process_header
    Function: Parse and store header data
    Returns : N/A
    Args    : N/A

# ATTRIBUTES

\# =head2 attribute
\#
\#   Title   : attribute
\#   Usage   : $attribute = $self->attribute($attribute\_value);
\#   Function: Get/set attribute
\#   Returns : An attribute value
\#   Args    : An attribute value
\#
\# =cut
\#
\#  sub attribute {
\#    my ($self, $attribute\_value) = @\_;
\#
\#    if ($attribute) {
\#      $self->{attribute} = $attribute;
\#    }
\#
\#    return $self->{attribute};
\#  }

# METHODS

## next\_record

    Title   : next_record
    Usage   : $record = $vaast->next_record();
    Function: Return the next record from the VAAST file.
    Returns : A hash (or reference) of VAAST record data.
    Args    : N/A

## all\_records

    Title   : all_records
    Usage   : $record = $vaast->all_records();
    Function: Parse and return all records.
    Returns : An array (or reference) of all VAAST records.
    Args    : N/A

## parse\_vaast\_record

    Title    : parse_vaast_record
    Usage    : my $record = $self->parse_vaast($record_txt);
    Function : Parse a single VAAST record.
    Returns  : A hash reference containing the record data.
    Args     : An array reference with the line for a single VAAST record.

# DIAGNOSTICS

[Arty::VAAST](https://metacpan.org/pod/Arty::VAAST) does not throw any warnings or errors.

# CONFIGURATION AND ENVIRONMENT

[Arty::VAAST](https://metacpan.org/pod/Arty::VAAST) requires no configuration files or environment variables.

# DEPENDENCIES

[Arty](https://metacpan.org/pod/Arty)

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
