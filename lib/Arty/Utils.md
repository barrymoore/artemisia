# NAME

[Arty::Utils](https://metacpan.org/pod/Arty::Utils) - Utility functions for the Artemisia library

# VERSION

This document describes [Arty::Utils](https://metacpan.org/pod/Arty::Utils) version 0.0.1

# SYNOPSIS

    use Arty::Utils qw(all);

# DESCRIPTION

[Arty::Utils](https://metacpan.org/pod/Arty::Utils) provides utility functions for the Artemisia library.
It does not export any functions by default.

# Export OK

- handle\_message
- throw\_msg
- warn\_msg
- info\_msg
- debug\_msg
- wrap\_text
- trim\_whitespace
- expand\_iupac\_nt\_codes
- revcomp
- translate
- genetic\_code
- amino\_acid\_data
- time\_stamp
- random\_string
- float\_lt
- float\_le
- float\_gt
- float\_ge
- open\_file
- load\_module

# Export Tags

> &#x3d;=item :all imports all of the functions above
>
> &#x3d;=item :message (handle\_message throw warn\_msg info\_msg debug\_msg)

# USES

- [Carp](https://metacpan.org/pod/Carp)
- [Scalar::Util](https://metacpan.org/pod/Scalar::Util)

\#-----------------------------------------------------------------------------
\#----------------------------- Private Functions -----------------------------
\#-----------------------------------------------------------------------------

# Private Functions

## \_private\_function

    Title   : _private_function
    Usage   : $args = _private_function(@_);
    Function: Take a list of key value pairs that may be structured as an
              array, a hash or and array or hash reference and return
              them as a hash or hash reference depending on calling
              context.
    Returns : Hash or hash reference.
    Args    : An array, hash or reference to either.

# Functions

## handle\_message

    Title   : handle_message
    Usage   : handle_message($level, $code, $message, $verbosity, $caller);
    Function: Handle a message and print to STDERR accordingly.
    Returns : None
    Args    : level    : FATAL, WARN, INFO, DEBUG
              code     : $info_code # single_word_code_for_info
              message  : $info_msg  # Free text description of info
              caller   : Arrayref of list returned by Perl's caller
                         function. Defaults to calling caller() within
                         the handle_message function.
              verbosity: An integer 1-5 corresponding to the levels of
                         verbosity described int the table below.

                         debug  | 1: Print all FATAL, WARN, INFO, and
                                     DEBUG messages.  Produces a lot of
                                     output.
                         info   | 2: Print all FATAL, WARN, and INFO
                                     messages. This is the default.
                         unique | 3: Print only the first occurence of
                                     each error/info code.
                         warn   | 4: Don't print INFO messages.
                         fatal  | 5: Don't print INFO or WARN
                                     messages. Still dies with message on
                                     FATAL errors.

             Note that the 'code' above should not contain whitespace,
             should generally by lowercase unless uppercase is needed for
             clarity, and should be standardized throughout the library
             such that a code like 'file_not_found' is used consistently
             rather than 'file_not_found' in one place and
             'file_does_not_exist' in another.  All codes should be
             documented in the module and in Manual.pm

             The 'message' above can be arbitrary text and should provide
             details that will help explain this instance of the error,
             such as "Expected an integer but got the text 'ABCDEFG'
             instead".

## throw\_msg

    Title   : throw_msg
    Usage   : throw_msg($error_code, $error_message, $verbosity);
    Function: Throw_Msg an error - print an error message to STDERR and die.
    Returns : None
    Args    : A text string for the error code and a text string for the
              error message. See the documentation for the function
              handle_message in this module for more details.

## warn\_msg

    Title   : warn_msg
    Usage   : warn_msg($warning_code, $warning_message, $verbosity);
    Function: Send a warning message to STDERR.
    Returns : None
    Args    : A text string for the error code and a text string for the
              error message. See the documentation for the function
              handle_message in this module for more details.

## info\_msg

    Title   : info_msg
    Usage   : info_msg($info_code, $info_message, $verbosity);
    Function: Send a INFO message.
    Returns : None
    Args    : A text string for the info code and a text string for the
              info message. See the documentation for the function
              handle_message in this module for more details.

## debug\_msg

    Title   : debug_msg
    Usage   : debug_msg($debug_code, $debug_message, $verbosity);
    Function: Send a DEBUG message.
    Returns : None
    Args    : A text string for the debug code and a text string for the
              debug message. See the documentation for the functionl
              handle_message in this module for more details.

## wrap\_text

    Title   : wrap_text
    Usage   : $text = wrap_text($text, 50);
    Function: Wrap text to the specified column width.  Default width is 50
              characters.
    Returns : Returns wrapped text as a string.
    Args    : A string of text and an optional integer value for the wrapped
              width.

## trim\_whitespace

    Title   : trim_whitespace
    Usage   : $trimmed_text = trim_whitespace($text);
    Function: Trim leading and trailing whitespace from text;
    Returns : Returns trimmed text as a string.
    Args    : A text string.

## expand\_iupac\_nt\_codes

    Title   : expand_iupac_nt_codes
    Usage   : @nucleotides = expand_iupac_nt_codes('W');
    Function: Expands an IUPAC ambiguity codes to an array of nucleotides
    Returns : An array or array ref of nucleotides (ATGC-);
    Args    : An IUPAC Nucleotide ambiguity code (ACGTUMRWSYKVHDBNX-) or an
              array (or ref) of such.

## revcomp

    Title   : revcomp
    Usage   : revcomp($sequence);
    Function: Get the reverse compliment of a nucleotide sequence
    Returns : The reverse complimented sequence
    Args    : A nucleotide sequence (ACGTRYMKSWHBVDNX).  Input sequence is case
              insensitive and case is maintained.

## translate

    Title   : translate
    Usage   : translate($sequence, $offset, $length);
    Function: Translate a nucleotide sequence to an amino acid sequence
    Returns : An amino acid sequence
    Args    : The sequence as a scalar, an integer offset from which to begin
              translation (default 0), and an integer length to translate
              (default is full length of input sequence).

## genetic\_code

    Title   : genetic_code
    Usage   : genetic_code;
    Function: Returns a hash reference of the genetic code.  Currently only
              supports the standard genetic code without ambiguity codes.
    Returns : A hash reference of the genetic code
    Args    : None

## amino\_acid\_data

    Title   : amino_acid_data
    Usage   : amino_acid_data($aa, $value);
    Function: Returns data about an amino acid - either a specific value or a
              hash reference of all data for that amino acid.
    Returns : A string representing a data point about an given amino acid or a
              hash reference with all data points about the given amino acid.
    Args    : 1) An amino acid in either:
                 a) single-letter code
                 b) three-letter
              2) Optionally a code for the value to return.  Any of:
                 a) name : The full name of the amino acid.
                 b) one_letter : The one-letter code for the amino acid.
                 c) three_letter : The three-letter code for the amino acid.
                 d) polarity : The polarity of the amino acid.
                 e) charge : The charge of the amino acid's side chain (at pH 7.4).
                 f) hydropathy : The hydropathy index of the amino acid.
                 g) weight : The molecular weight of the amino acid in g/mol.
                 h) size : Returns small or large.
                 i) h_bond : return 1 or 0 indicating if the amino acid can form hydrogen bonds
                 j) aromaticity : Returns aromatic, aliphatic or undef.

## time\_stamp

    Title   : time_stamp
    Usage   : time_stamp;
    Function: Returns a YYYYMMDD time_stamp
    Returns : A YYYYMMDD time_stamp
    Args    : None

## random\_string

    Title   : random_string
    Usage   : random_string(8);
    Function: Returns a random alphanumeric string
    Returns : A random alphanumeric string of a given length.  Default length is
              8 charachters.
    Args    : The length of the string to be returned [8]

## float\_lt

    Title   : float_lt
    Usage   : float_lt(0.0000123, 0.0000124, 7);
    Function: Return true if the first number given is less than (<) the
              second number at a given level of accuracy.  Default accuracy
              length is 6 decimal places.
    Returns : 1 if the first number is less than the second, otherwise 0.
    Args    : The two values to compare and optionally a integer value for
              the accuracy.  Accuracy defaults to 6 decimal places.

## float\_le

    Title   : float_le
    Usage   : float_le(0.0000123, 0.0000124, 7);
    Function: Return true if the first number given is less than or equal to
              (<=) the second number at a given level of accuracy.  Default
              accuracy length is 6 decimal places.
    Returns : 1 if the first number is less than or equal to the second,
              otherwise 0.
    Args    : The two values to compare and optionally a integer value for
              the accuracy.  Accuracy defaults to 6 decimal places.

## float\_gt

    Title   : float_gt
    Usage   : float_gt(0.0000123, 0.0000124, 7);
    Function: Return true if the first number given is greater than (>) the
              second number at a given level of accuracy.  Default accuracy
              length is 6 decimal places.
    Returns : 1 if the first number is greater than the second, otherwise 0
    Args    : The two values to compare and optionally a integer value for
              the accuracy.  Accuracy defaults to 6 decimal places.

## float\_ge

    Title   : float_ge
    Usage   : float_ge(0.0000123, 0.0000124, 7);
    Function: Return true if the first number given is greater than or equal
              to (>=) the second number at a given level of accuracy.  Default
              accuracy length is 6 decimal places.
    Returns : 1 if the first number is greater than or equal to the second,
              otherwise 0.
    Args    : The two values to compare and optionally a integer value for
              the accuracy.  Accuracy defaults to 6 decimal places.

## open\_file

    Title   : open_file
    Usage   : open_file($file);
    Function: Open a given file for reading and return a filehandle.
    Returns : A filehandle
    Args    : A file path/name

## load\_module

    Title   : load_module
    Usage   : load_module(Some::Module);
    Function: Do runtime loading (require) of a module/class.
    Returns : 1 on success - throws exception on failure
    Args    : A valid module name.

# DIAGNOSTICS

- `invalid_ipuac_nucleotide_code`

    `Arty::Utils::expand_iupac_nt_codes` was passed a charachter that is
    not a valid IUPAC nucleotide code
    (http://en.wikipedia.org/wiki/Nucleic\_acid\_notation).

- `failed_to_load_module`

    `Arty::Utils::load_module` was unable to load (require) the specified
    module.  The module may not be installed or it may have a compile time
    error.

- `invalid_aa_datum_code`

    An invalid amino acid code was passed to
    `Arty::Utils::amino_acid_data`.  Single-letter or three-letter amino
    acid codes are required.

# CONFIGURATION AND ENVIRONMENT

[Arty::Utils](https://metacpan.org/pod/Arty::Utils) requires no configuration files or environment variables.

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

# POD ERRORS

Hey! **The above document had some coding errors, which are explained below:**

- Around line 94:

    You forgot a '=back' before '=head1'

- Around line 102:

    You forgot a '=back' before '=head1'
