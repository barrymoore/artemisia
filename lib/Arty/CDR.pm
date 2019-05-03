package Arty::CDR;

use strict;
use warnings;
use vars qw($VERSION);

$VERSION = 0.0.1;
use base qw(Arty::Base);
use Arty::Utils qw(:all);
use File::ReadBackwards;

=head1 NAME

Arty::CDR - Parse CDR files

=head1 VERSION

This document describes Arty::CDR version 0.0.1

=head1 SYNOPSIS

    use Arty::CDR;
    my $cdr = Arty::CDR->new('cases.cdr');

    while (my $record = $parser->next_record) {
	print $record->{gene} . "\n";
    }

=head1 DESCRIPTION

L<Arty::CDR> provides CDR parsing ability for the Artemisia suite
of genomics tools.

=head1 DATA STRUCTURE

   HASH(0x2a78530)
   'chrom' => 1
   'effect' => ARRAY(0x2d40440)
      0  'exon_variant'
      1  'transcript_variant'
      2  'missense_variant'
      3  'coding_sequence_variant'
      4  'sequence_variant'
      5  'gene_variant'
      6  'amino_acid_substitution'
   'end' => 69428
   'gts' => ARRAY(0x2d404b8)
      0  HASH(0x2a3b068)
         'aa' => ARRAY(0x2a3afa8)
            0  'C'
            1  'C'
         'indvs' => ARRAY(0x2a78b18)
            0  7
            1  27
            2  73
         'nt' => ARRAY(0x2a3aee8)
            0  'G'
            1  'G'
      1  HASH(0x29e5de0)
         'aa' => ARRAY(0x280e3e8)
            0  '^'
            1  '^'
         'indvs' => ARRAY(0x2d40b60)
            0  2
            1  3
            2  4
            3  6
            ... 
            32  86
            33  87
            34  90
            35  91
            36  103
            37  104
         'nt' => ARRAY(0x2d405f0)
            0  '^'
            1  '^'
   'ref' => HASH(0x2d40458)
      'aa' => 'F'
      'nt' => 'T'
   'start' => 69428
   'type' => 'SNV'


=head1 CONSTRUCTOR

New L<Arty::CDR> objects are created by the class method new.
Arguments should be passed to the constructor as a list (or reference)
of key value pairs.  If the argument list has only a single argument,
then this argument is applied to the 'file' attribute and thus
specifies the CDR filename.  All attributes of the L<Arty::CDR>
object can be set in the call to new. An simple example of object
creation would look like this:

    my $parser = Arty::CDR->new('cases.cdr');

    # This is the same as above
    my $parser = Arty::CDR->new('file' => 'cases.cdr');


The constructor recognizes the following parameters which will set the
appropriate attributes:

=over

=item * C<< file => cases.cdr >>

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
     Usage   : Arty::CDR->new();
     Function: Creates a Arty::CDR object;
     Returns : An Arty::CDR object
     Args    :

=cut

sub new {
	my ($class, @args) = @_;
	my $self = $class->SUPER::new(@args);
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
  Function: Parse and store header data
  Returns : N/A
  Args    : N/A

=cut

 sub _process_header {
     my $self = shift @_;

     my $file = $self->file;

     my $fh = File::ReadBackwards->new($file) ||
         throw('cant_open_file_for_reading', $file);

     my %footer;
   LINE:
     while (my $line = $fh->readline) {
         return undef if ! defined $line;
	 
         if ($line =~ /^\#/) {
             chomp $line;
	     my ($hash, $key, $value) = split(/\t/, $line, 3);
	     if ($key eq 'COMMAND-LINE') {
		 $footer{$key} = $value;
	     }
	     elsif ($key eq 'FILE-INDEX') {
		 my ($idx, $id) = split /\t/, $value;
		 $footer{$key}{$idx} = $id;
	     }
	     elsif ($key eq 'GENOME-COUNT') {
		 $footer{$key} = $value;
	     }
	     elsif ($key eq 'GENOME-LENGTH') {
		 $footer{$key} = $value;
	     }
	     elsif ($key eq 'GFF3-FEATURE-FILE') {
		 my ($file, $md5) = split /\t/, $value;
		 $footer{$key} = {file => $file,
				  md5  => $md5};
	     }
	     elsif ($key eq 'PROGRAM-VERSION') {
		 $footer{$key} = $value;
	     }
	     elsif ($key eq 'SEX') {
		 my @sexes = split /\t/, $value;
		 my %sex_data;
		 for my $sex (@sexes) {
		     my ($sex_key, $set) = split /:/, $sex;
		     my @indvs;
		     for my $indv (split /,/, $set) {
			 if ($indv =~ /(\d+)\-(\d+)/) {
			     push @indvs, ($1..$2);
			 }
			 else {
			     push @indvs, $indv;
			 }
		     }
		     push @{$footer{$key}{$sex_key}}, @indvs;
		 }
	     }
	     else {
		 warn('unknown_cdr_metadata', $line);
	     }
	 }
	 else {
             last LINE;
         }
     }
     $self->{footer} = \%footer;
}

#-----------------------------------------------------------------------------
#-------------------------------- Attributes ---------------------------------
#-----------------------------------------------------------------------------

=head1 ATTRIBUTES

=cut

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
 Function: Return the next record from the CDR file.
 Returns : A hash (or reference) of CDR record data.
 Args    : N/A

=cut

sub next_record {
    my $self = shift @_;

    my $line = $self->readline;
    return undef if ! defined $line || $line =~ /^\#/;

    my $record = $self->parse_record($line);
    
    return wantarray ? %{$record} : $record;
}

#-----------------------------------------------------------------------------

=head2 parse_record

 Title   : parse_record
 Usage   : $record = $tempalte->parse_record($line);
 Function: Parse CDR line into a data structure.
 Returns : A hash (or reference) of CDR record data.
 Args    : A scalar containing a string of Tempalte record text.

=cut

sub parse_record {
    my ($self, $line) = @_;
    chomp $line;
    
    my @cols = split /\t/, $line;
    
    my %record;
    
    @record{qw(chrom start end type effect ref)} = splice(@cols, 0, 6);

    my ($nt_ref, $aa_ref) = split /\|/, $record{ref};

    # Parse Effects column
    $record{effect} = [split /,/, $record{effect}];
    
    # Parse REF column
    $record{ref} = {nt => $nt_ref,
		    aa => $aa_ref};

    # Parse GT columns
    for my $gt (@cols) {
	my ($set, $nt, $aa) = split /\|/, $gt;
	$nt ||= '';
	$aa ||= '';
	my @indvs;
	for my $indv (split /,/, $set) {
	    if ($indv =~ /(\d+)\-(\d+)/) {
		push @indvs, ($1..$2);
	    }
	    else {
		push @indvs, $indv;
	    }
	}
	my @nts = split /:/, $nt;
	my @aas = split /:/, $aa;
	my %gt_data = (indvs => \@indvs,
		       nt    => \@nts,
		       aa    => \@aas);
	push @{$record{gts}}, \%gt_data;
    }
    
    return wantarray ? %record : \%record;
}

#-----------------------------------------------------------------------------

=head1 DIAGNOSTICS

L<Arty::CDR> does not throw any warnings or errors.

=head1 CONFIGURATION AND ENVIRONMENT

L<Arty::CDR> requires no configuration files or environment variables.

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
