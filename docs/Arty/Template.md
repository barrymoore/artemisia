# NAME

Arty::Template - Parse Template files

# VERSION

This document describes Arty::Template version 0.0.1

# SYNOPSIS

    use Arty::Template;
    my $template = Arty::Template->new('data.template');

    while (my $record = $parser->next_record) {
        print $record->{gene} . "\n";
    }

# DESCRIPTION

[Arty::Template](https://metacpan.org/pod/Arty::Template) provides Template parsing ability for the Artemisia suite
of genomics tools.

# CONSTRUCTOR

New [Arty::Template](https://metacpan.org/pod/Arty::Template) objects are created by the class method new.
Arguments should be passed to the constructor as a list (or reference)
of key value pairs.  If the argument list has only a single argument,
then this argument is applied to the 'file' attribute and thus
specifies the Template filename.  All attributes of the [Arty::Template](https://metacpan.org/pod/Arty::Template)
object can be set in the call to new. An simple example of object
creation would look like this:

    my $parser = Arty::Template->new('data.template');

    # This is the same as above
    my $parser = Arty::Template->new('file' => 'data.template');

The constructor recognizes the following parameters which will set the
appropriate attributes:

- `file => data.template`

    This optional parameter provides the filename for the file containing
    the data to be parsed. While this parameter is optional either it, or
    the following fh parameter must be set.

- `fh => $fh`

    This optional parameter provides a filehandle to read data from. While
    this parameter is optional either it, or the previous file parameter
    must be set.

## new

     Title   : new
     Usage   : Arty::Template->new();
     Function: Creates a Arty::Template object;
     Returns : An Arty::Template object
     Args    :

# PRIVATE METHODS

## \_initialize\_args

    Title   : _initialize_args
    Usage   : $self->_initialize_args($args);
    Function: Initialize the arguments passed to the constructor.  In particular
              set all attributes passed.  For most classes you will just need to
              customize the @valid_attributes array within this method as you add
              Get/Set methods for each attribute.
    Returns : N/A
    Args    : A hash or array reference of arguments.

## \_process\_header

    Title   : _process_header
    Usage   : $self->_process_header
    Function: Parse and store header data
    Returns : N/A
    Args    : N/A

# ATTRIBUTES

# METHODS

## next\_record

    Title   : next_record
    Usage   : $record = $vcf->next_record();
    Function: Return the next record from the Template file.
    Returns : A hash (or reference) of Template record data.
    Args    : N/A

## parse\_record

    Title   : parse_record
    Usage   : $record = $tempalte->parse_record($line);
    Function: Parse Template line into a data structure.
    Returns : A hash (or reference) of Template record data.
    Args    : A scalar containing a string of Tempalte record text.

# DIAGNOSTICS

[Arty::Template](https://metacpan.org/pod/Arty::Template) does not throw any warnings or errors.

# CONFIGURATION AND ENVIRONMENT

[Arty::Template](https://metacpan.org/pod/Arty::Template) requires no configuration files or environment variables.

# DEPENDENCIES

[Arty::Base](https://metacpan.org/pod/Arty::Base)

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
