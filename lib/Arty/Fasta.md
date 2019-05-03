# NAME

Arty::Fasta - Parse Fasta files

# VERSION

This document describes Arty::Fasta version 0.0.1

# SYNOPSIS

    use Arty::Fasta;
    my $fasta = Arty::Fasta->new('sequence.fa');

    while (my $seq = $parser->next_seq) {
        print '>' . $seq->{header} . "\n";
        print wrap_text($seq->{sequence}) . \n;
    }

# DESCRIPTION

[Arty::Fasta](https://metacpan.org/pod/Arty::Fasta) provides Fasta parsing ability for the artemisia suite
of genomics tools.

# Constructor

New [Arty::Fasta](https://metacpan.org/pod/Arty::Fasta) objects are created by the class method new.
Arguments should be passed to the constructor as a list (or reference)
of key value pairs.  If the argument list has only a single argument,
then this argument is applied to the 'file' attribute and thus
specifies the Fasta filename.  All attributes of the [Arty::Fasta](https://metacpan.org/pod/Arty::Fasta)
object can be set in the call to new. An simple example of object
creation would look like this:

    my $parser = Arty::Fasta->new('sequence.fa');

    # This is the same as above
    my $parser = Arty::Fasta->new('file' => 'sequence.fa');

The constructor recognizes the following parameters which will set the
appropriate attributes:

- `file => sequence.fa`

    This optional parameter provides the filename for the file containing
    the data to be parsed. While this parameter is optional either it, or
    the following fh parameter must be set.

- `fh => $fh`

    This optional parameter provides a filehandle to read data from. While
    this parameter is optional either it, or the previous file parameter
    must be set.

## new

     Title   : new
     Usage   : Arty::Fasta->new();
     Function: Creates a Arty::Fasta object;
     Returns : A Arty::Fasta object
     Args    :

## file

    Title   : file
    Usage   : $file = $fasta->file('sequence.fa');
    Function: Get/Set the file for the object.
    Returns : The name of the Fasta file.
    Args    : N/A

## fh

    Title   : fh
    Usage   : $fh = $fasta->fh('sequence.fa');
    Function: Get/Set the filehandle for the object.
    Returns : A reference to the file handle.
    Args    : A reference to a file handle

## next\_seq

    Title   : next_seq
    Usage   : $seq = $fasta->next_seq();
    Function: Return the next sequence from the file.
    Returns : A hash (or reference) of sequence data.
    Args    : N/A

# DIAGNOSTICS

[Arty::Fasta](https://metacpan.org/pod/Arty::Fasta) does not throw any warnings or errors.

# CONFIGURATION AND ENVIRONMENT

[Arty::Fasta](https://metacpan.org/pod/Arty::Fasta) requires no configuration files or environment variables.

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
