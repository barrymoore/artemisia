package Arty::vIQ_List;

use strict;
use warnings;
use vars qw($VERSION);

$VERSION = 0.0.1;
use base qw(Arty::Base);
use Arty::Utils qw(:all);

=head1 NAME

Arty::vIQ_List - Parse vIQ List (input) files

=head1 VERSION

This document describes Arty::vIQ_List version 0.0.1

=head1 SYNOPSIS

    use Arty::vIQ_List;
    my $viq = Arty::vIQ_List->new('sample.viq_list.txt');

    while (my $record = $parser->next_record) {
        print $record->{gene} . "\n";
    }

=head1 DESCRIPTION

L<Arty::vIQ_List> provides vIQ List file parsing ability for the
Artemisia suite of genomics tools.

=head1 DATA STRUCTURE

Arty::vIQ_List returns records as a datastructure which has the
following format:

0  HASH(0x1831270)
   'alt_count' => 1
   'chrom' => 1
   'chrom_code' => 'a'
   'clinvar' => 'null'
   'coverage' => '13:19'
   'csq' => 27
   'distance' => 5370
   'end' => 133160
   'gnomad_code' => '1,4,6'
   'gnomad_af' => '0.2163;0.1387;0.0554;0.0512;0.02;0.1321;0.0682;0.0796'
   'gq' => 99
   'parentage' => 'M'
   'phevor' => 'null'
   'pos' => 133160
   'rid' => 00000001
   'transcript' => 'ENST00000423372'
   'type' => 1
   'vaast_dom_p' => 0.001597
   'vaast_rec_p' => 0.000399
   'vid' => '1:133160:G:A'
   'vvp_gene' => 'ENSG00000237683'
   'vvp_hemi' => '7;13'
   'vvp_het' => '3;6'
   'vvp_hom' => '17;33'
   'zygosity' => 1

=head1 CONSTRUCTOR

New L<Arty::vIQ_List> objects are created by the class method new.
Arguments should be passed to the constructor as a list (or reference)
of key value pairs.  If the argument list has only a single argument,
then this argument is applied to the 'file' attribute and thus
specifies the vIQ_List filename.  All attributes of the L<Arty::vIQ_List>
object can be set in the call to new. An simple example of object
creation would look like this:

    my $parser = Arty::vIQ_List->new('sample.viq_list.txt');

    # This is the same as above
    my $parser = Arty::vIQ_List->new('file' => 'sample.viq_list.txt');

The constructor recognizes the following parameters which will set the
appropriate attributes:

=over

=item * C<< file => sample.viq_list.txt >>

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
     Usage   : Arty::vIQ_List->new();
     Function: Creates a Arty::vIQ_List object;
     Returns : An Arty::vIQ_List object
     Args    :

=cut

sub new {
        my ($class, @args) = @_;
        my $self = $class->SUPER::new(@args);
        $self->columns;
        $self->_process_header;
        return $self;
}

#-----------------------------------------------------------------------------
#----------------------------- Private Methods -------------------------------
#-----------------------------------------------------------------------------

=head1 PRIVATE METHODS

=head2 _initialize_args

 Title   : _initialize_args
 Usage   : $self->_initialize_args($args);
 Function: Initialize the arguments passed to the constructor.  In particular
           set all attributes passed.  For most classes you will just need to
           customize the @valid_attributes array within this method as you add
           Get/Set methods for each attribute.
 Returns : N/A
 Args    : A hash or array reference of arguments.

=cut

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
        return $args;
}

#-----------------------------------------------------------------------------

=head2 _process_header

  Title   : _process_header
  Usage   : $self->_process_header
  Function: Parse and store header lines
  Returns : N/A
  Args    : N/A

=cut

 sub _process_header {
     my $self = shift @_;

     my $fh = $self->fh;
     $self->{header} ||= [];

   LINE:
     while (my $line = $self->readline) {
         return undef if ! defined $line;

         if ($line =~ /^\#/) {
             chomp $line;
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

=head1 ATTRIBUTES

=cut

=head2 columns

  Title   : columns
  Usage   : $columns = $self->columns($columns_value);
  Function: Get columns
  Returns : An list of columns for vIQ list files
  Args    : No arguments accepted.  The columns attribute is get only.

=cut

 sub columns {
   my ($self) = shift @_;

   $self->{columns} ||= [qw(chrom pos end rid vid vvp_gene transcript
                            type parentage zygosity phevor coverage
                            vvp_hemi vvp_het vvp_hom clinvar
                            chrom_code gnomad_af vaast_dom_p
                            vaast_rec_p distance alt_count gnomad_code
                            gq csq)];

   return wantarray ? @{$self->{columns}} : $self->{columns};
 }

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

=head1 METHODS

=head2 next_record

 Title   : next_record
 Usage   : $record = $vcf->next_record();
 Function: Return the next record from the vIQ_List file.
 Returns : A hash (or reference) of vIQ_List record data.
 Args    : N/A

=cut

sub next_record {
    my $self = shift @_;

    my $line = $self->readline;
    return undef if ! defined $line;

    my $record = $self->parse_record($line);

    return wantarray ? %{$record} : $record;
}

#-----------------------------------------------------------------------------

=head2 parse_record

 Title   : parse_record
 Usage   : $record = $tempalte->parse_record($line);
 Function: Parse vIQ_List line into a data structure.
 Returns : A hash (or reference) of vIQ_List record data.
 Args    : A scalar containing a string of Tempalte record text.

=cut

sub parse_record {
    my ($self, $line) = @_;
    chomp $line;

    my @cols = split /\t/, $line;
    map {$_ = '' unless defined $_} @cols;

    my $col_count = scalar @cols;
    if ($col_count != 25) {
        handle_message('FATAL', 'incorrect_column_count', "(expected 25 got $col_count columns) $line");
    }

    my %record;

    # chrom pos end id vid gene transcript type parentage zygosity
    # phevor coverage vvp_hemi vvp_het vvp_hom clinvar chrom_code
    # gnomad_af vaast_dom_p vaast_rec_p distance alt_count gnomad_code
    # gq csq

    @record{($self->columns)} = @cols;

    # 12,13,14,15
    # coverage vvp_hemi vvp_het vvp_hom
    # 0:8      0;0      0;2     0;0
    # $record{coverage} = [split(/:/, $record{coverage})];
    # $record{vvp_hemi} = [split(/;/, $record{vvp_hemi})];
    # $record{vvp_het}  = [split(/;/, $record{vvp_het})];
    # $record{vvp_hom}  = [split(/;/, $record{vvp_hom})];

    # 18,23
    # gnomad_af, gnomad_code
    # 0.9375;0.5863;0.9926;0.9648;1;0.9655;0.9438;0.8435
    # $record{gnomad_af}   = [split(/;/, $record{gnomad_af})];
    # $record{gnomad_code} = [split(/,/, $record{gnomad_code})];

    return wantarray ? %record : \%record;
}

#-----------------------------------------------------------------------------

=head2 get_record_text

 Title   : get_record_text
 Usage   : $record_txt = $parser->get_record_text($record);
 Function: Format vIQ List record into a text format for printing.
 Returns : A tab-separated string of text representing the given vIQ record.
 Args    : A scalar containing a string of Tempalte record text.

=cut

# sub get_record_text {
#     my ($self, $record) = @_;
# 
#     # chrom pos end id vid gene transcript type parentage zygosity
#     # phevor coverage vvp_hemi vvp_het vvp_hom clinvar chrom_code
#     # gnomad_af vaast_dom_p vaast_rec_p distance alt_count gnomad_code
#     # gq csq
# 
#     $record->{coverage}    = join ':', @{$record->{coverage}};
#     $record->{vvp_hemi}    = join ';', @{$record->{vvp_hemi}};
#     $record->{vvp_het}     = join ';', @{$record->{vvp_het}};
#     $record->{vvp_hom}     = join ';', @{$record->{vvp_hom}};
#     $record->{gnomad_af}   = join ',', @{$record->{gnomad_af}};
#     $record->{gnomad_code} = join ',', @{$record->{gnomad_code}};
# 
#     my $record_txt = join "\t", @{$record}{($self->columns)};
#     return $record_txt;
# }

#-----------------------------------------------------------------------------

=head1 DIAGNOSTICS

L<Arty::vIQ_List> does not throw any warnings or errors.

=head1 CONFIGURATION AND ENVIRONMENT

L<Arty::vIQ_List> requires no configuration files or environment variables.

=head1 DEPENDENCIES

L<Arty::Base>

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
