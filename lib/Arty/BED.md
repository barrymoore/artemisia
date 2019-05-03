# NAME

Arty::BED - Parse BED files

# VERSION

This document describes Arty::BED version 0.0.1

# SYNOPSIS

    use Arty::BED;
    my $bed = Arty::BED->new('data.bed');

    while (my $record = $parser->next_record) {
        print $record->{gene} . "\n";
    }

# DESCRIPTION

[Arty::BED](https://metacpan.org/pod/Arty::BED) provides BED parsing ability for the Artemisia suite of
genomics tools.  The BED format supported is the first 5 columns of
the UCSC genome browsers [BED
format](https://genome.ucsc.edu/FAQ/FAQformat.html#format1).  BED files
with the full 12 columns described in the UCSC BED specification can
be used with this module, but all columns beyond the first 5 are
discarded.

# CONSTRUCTOR

New [Arty::BED](https://metacpan.org/pod/Arty::BED) objects are created by the class method new.
Arguments should be passed to the constructor as a list (or reference)
of key value pairs.  If the argument list has only a single argument,
then this argument is applied to the 'file' attribute and thus
specifies the BED filename.  All attributes of the [Arty::BED](https://metacpan.org/pod/Arty::BED)
object can be set in the call to new. An simple example of object
creation would look like this:

    my $parser = Arty::BED->new('data.bed');

    # This is the same as above
    my $parser = Arty::BED->new('file' => 'data.bed');

The constructor recognizes the following parameters which will set the
appropriate attributes:

- `file => data.bed`

    This optional parameter provides the filename for the file containing
    the data to be parsed. While this parameter is optional either it, or
    the following fh parameter must be set.

- `fh => $fh`

    This optional parameter provides a filehandle to read data from. While
    this parameter is optional either it, or the previous file parameter
    must be set.

## new

     Title   : new
     Usage   : Arty::BED->new();
     Function: Creates a Arty::BED object;
     Returns : An Arty::BED object
     Args    :

# PRIVATE METHODS

## \_initialize\_args

    Title   : _initialize_args
    Usage   : $self->_initialize_args($args);
    Function: Initialize the arguments passed to the constructor.  In particular
              set all attributes passed.
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
    Function: Return the next record from the BED file.
    Returns : A hash (or reference) of BED record data.
    Args    : N/A

## parse\_record

    Title   : parse_record
    Usage   : $record = $vcf->parse_record();
    Function: Parse BED line into a data structure.
    Returns : A hash (or reference) of BED record data.
    Args    : A scalar containing a string of BED record text.

# DIAGNOSTICS

[Arty::BED](https://metacpan.org/pod/Arty::BED) does not throw any warnings or errors.

# CONFIGURATION AND ENVIRONMENT

[Arty::BED](https://metacpan.org/pod/Arty::BED) requires no configuration files or environment variables.

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
