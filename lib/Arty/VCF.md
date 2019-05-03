# NAME

Arty::VCF - Parse VCF files

# VERSION

This document describes Arty::VCF version 0.0.1

# SYNOPSIS

    use Arty::VCF;
    my $vcf = Arty::VCF->new('samples.vcf');

    while (my $record = $parser->next_record) {
        print $record->{ref}) . "\n";
    }

# DESCRIPTION

[Arty::VCF](https://metacpan.org/pod/Arty::VCF) provides VCF parsing ability for the artemisia suite
of genomics tools.

# Constructor

New [Arty::VCF](https://metacpan.org/pod/Arty::VCF) objects are created by the class method new.
Arguments should be passed to the constructor as a list (or reference)
of key value pairs.  If the argument list has only a single argument,
then this argument is applied to the 'file' attribute and thus
specifies the VCF filename.  All attributes of the [Arty::VCF](https://metacpan.org/pod/Arty::VCF)
object can be set in the call to new. An simple example of object
creation would look like this:

    my $parser = Arty::VCF->new('samples.vcf.gz');

    # This is the same as above
    my $parser = Arty::VCF->new('file' => 'samples.vcf.gz');

The constructor recognizes the following parameters which will set the
appropriate attributes:

- `file => samples.vcf.gz`

    This optional parameter provides the filename for the file containing
    the data to be parsed. While this parameter is optional either it, or
    the following fh parameter must be set.

- `fh => $fh`

    This optional parameter provides a filehandle to read data from. While
    this parameter is optional either it, or the previous file parameter
    must be set.

## new

     Title   : new
     Usage   : Arty::VCF->new();
     Function: Creates a Arty::VCF object;
     Returns : A Arty::VCF object
     Args    :

## \_process\_header

    Title   : _process_header
    Usage   : $self->_process_header
    Function: Parse and store header data
    Returns : N/A
    Args    : N/A

## parse\_record

    Title   : parse_record
    Usage   : $record = $vcf->parse_record();
    Function: Parse VCF line into a data structure.
    Returns : A hash (or reference) of VCF record data.
    Args    : A scalar containing a string of VCF record text.

## parse\_info

    Title   : parse_info
    Usage   : $vcf = $vcf->parse_info($record->{info});
    Function: Parse a VCF INFO string into a data structure.
    Returns : A hash (or reference) of VCF INFO data.
    Args    : A scalar containing a string of VCF INFO text.

## parse\_format

    Title   : parse_format
    Usage   : $record = $vcf->parse_format($record->{format});
    Function: Parse a VCF FORMAT string into a data structure.
    Returns : A hash (or reference) of VCF FORMAT data.
    Args    : A scalar containing a string of VCF FORMAT text.

## parse\_gt

    Title   : parse_gt
    Usage   : $vcf = $vcf->parse_gt($record->{gt});
    Function: Parse a VCF GT string into a data structure.
    Returns : A hash (or reference) of VCF GT data.
    Args    : A scalar containing a string of VCF GT text.

## next\_record

    Title   : next_record
    Usage   : $record = $vcf->next_record();
    Function: Return the next record from the VCF file.
    Returns : A hash (or reference) of VCF record data.
    Args    : N/A

## all\_records

    Title   : all_records
    Usage   : $record = $vcf->all_records();
    Function: Parse and return all records.
    Returns : An array (or reference) of all VCF records.
    Args    : N/A

# DIAGNOSTICS

[Arty::VCF](https://metacpan.org/pod/Arty::VCF) does not throw any warnings or errors.

# CONFIGURATION AND ENVIRONMENT

[Arty::VCF](https://metacpan.org/pod/Arty::VCF) requires no configuration files or environment variables.

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
