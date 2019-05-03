# NAME

Arty::Phevor - Parse Phevor files

# VERSION

This document describes Arty::Phevor version 0.0.1

# SYNOPSIS

    use Arty::Phevor;
    my $parser = Arty::Phevor->new('phevor.txt');

    while (my $record = $parser->next_record) {
        print $record->{gene}) . "\n";
    }

# DESCRIPTION

[Arty::Phevor](https://metacpan.org/pod/Arty::Phevor) provides Phevor parsing ability for the artemisia suite
of genomics tools.

# Constructor

New [Arty::Phevor](https://metacpan.org/pod/Arty::Phevor) objects are created by the class method new.
Arguments should be passed to the constructor as a list (or reference)
of key value pairs.  If the argument list has only a single argument,
then this argument is applied to the 'file' attribute and thus
specifies the Phevor filename.  All attributes of the [Arty::Phevor](https://metacpan.org/pod/Arty::Phevor)
object can be set in the call to new. An simple example of object
creation would look like this:

    my $parser = Arty::Phevor->new('phevor.txt');

    # This is the same as above
    my $parser = Arty::Phevor->new('file' => 'phevor.txt');

The constructor recognizes the following parameters which will set the
appropriate attributes:

- `file => phevor.txt`

    This optional parameter provides the filename for the file containing
    the data to be parsed. While this parameter is optional either it, or
    the following fh parameter must be set.

- `fh => $fh`

    This optional parameter provides a filehandle to read data from. While
    this parameter is optional either it, or the previous file parameter
    must be set.

## new

     Title   : new
     Usage   : Arty::Phevor->new();
     Function: Creates a Arty::Phevor object;
     Returns : An Arty::Phevor object
     Args    :

## \_process\_header

    Title   : _process_header
    Usage   : $self->_process_header
    Function: Parse and store header data
    Returns : N/A
    Args    : N/A

## next\_record

    Title   : next_record
    Usage   : $record = $phevor->next_record();
    Function: Return the next record from the Phevor file.
    Returns : A hash (or reference) of VAAST simple record data.
    Args    : N/A

## all\_records

    Title   : all_records
    Usage   : $record = $phevor->all_records();
    Function: Parse and return all records.
    Returns : An array (or reference) of all VAAST simple records.
    Args    : N/A

# DIAGNOSTICS

[Arty::Phevor](https://metacpan.org/pod/Arty::Phevor) does not throw any warnings or errors.

# CONFIGURATION AND ENVIRONMENT

[Arty::Phevor](https://metacpan.org/pod/Arty::Phevor) requires no configuration files or environment variables.

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
