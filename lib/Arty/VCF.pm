package Arty::VCF;

use strict;
use warnings;
use vars qw($VERSION);

$VERSION = 0.0.1;
use base qw(Arty::Base);

=head1 NAME

Arty::VCF - Parse VCF files

=head1 VERSION

This document describes Arty::VCF version 0.0.1

=head1 SYNOPSIS

    use Arty::VCF;
    my $vcf = Arty::VCF->new('samples.vcf');

    while (my $record = $parser->next_record) {
	print $record->{ref}) . "\n";
    }

=head1 DESCRIPTION

L<Arty::VCF> provides VCF parsing ability for the artemisia suite
of genomics tools.

=head1 Constructor

New L<Arty::VCF> objects are created by the class method new.
Arguments should be passed to the constructor as a list (or reference)
of key value pairs.  If the argument list has only a single argument,
then this argument is applied to the 'file' attribute and thus
specifies the VCF filename.  All attributes of the L<Arty::VCF>
object can be set in the call to new. An simple example of object
creation would look like this:

    my $parser = Arty::VCF->new('samples.vcf.gz');

    # This is the same as above
    my $parser = Arty::VCF->new('file' => 'samples.vcf.gz');


The constructor recognizes the following parameters which will set the
appropriate attributes:

=over

=item * C<< file => samples.vcf.gz >>

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
     Usage   : Arty::VCF->new();
     Function: Creates a Arty::VCF object;
     Returns : A Arty::VCF object
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
}

=head2 _process_header

  Title   : _process_header
  Usage   : $self->_process_header
  Function: Parse and store header data
  Returns : N/A
  Args    : N/A

=cut

 sub _process_header {
     my $self = shift @_;

     my $fh = $self->fh;

   LINE:
     while (my $line = $self->readline) {
	 return undef if ! defined $line;

	 if ($line =~ /^\#\#/) {
	     chomp $line;
	     push @{$self->{meta_data}}, $line;
	 }
	 elsif ($line =~ /^\#/) {
	     chomp $line;
	     push @{$self->{header}}, $line;
	     my @cols = split /\t/, $line;
	     my @samples = @cols[9..$#cols];
	     $self->{samples} = \@samples;
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

=head2 parse_record

 Title   : parse_record
 Usage   : $record = $vcf->parse_record();
 Function: Parse VCF line into a data structure.
 Returns : A hash (or reference) of VCF record data.
 Args    : A scalar containing a string of VCF record text.

=cut

sub parse_record {
	my ($self, $line) = @_;
	chomp $line;

	my @cols = split /\s+/, $line;

	my %record;
	@record{qw(chrom pos id ref alt qual filter info format)} = splice(@cols, 0, 9);
	$record{gt} = \@cols;

	$record{info} = $self->parse_info($record{info});
	$record{format} = $self->parse_format($record{format});
	$record{gt} = $self->parse_gt($record{format}, $record{gt});

	return wantarray ? %record : \%record;
}

#-----------------------------------------------------------------------------

=head2 parse_info

 Title   : parse_info
 Usage   : $vcf = $vcf->parse_info($record->{info});
 Function: Parse a VCF INFO string into a data structure.
 Returns : A hash (or reference) of VCF INFO data.
 Args    : A scalar containing a string of VCF INFO text.

=cut

sub parse_info {
	my ($self, $info) = @_;
	chomp $info;

	my @pairs = split /;/, $info;

	my %info;
	for my $pair (@pairs) {
	    my ($key, $value) = split(/=/, $pair);
	    $value ||= '';
	   my @values = split /,/, $value;
	   push @{$info{$key}}, @values;
	}
	return wantarray ? %info : \%info;
}

#-----------------------------------------------------------------------------

=head2 parse_format

 Title   : parse_format
 Usage   : $record = $vcf->parse_format($record->{format});
 Function: Parse a VCF FORMAT string into a data structure.
 Returns : A hash (or reference) of VCF FORMAT data.
 Args    : A scalar containing a string of VCF FORMAT text.

=cut

sub parse_format {
	my ($self, $format) = @_;
	chomp $format;

	my @values = split /:/, $format;

	return wantarray ? @values : \@values;
}

#-----------------------------------------------------------------------------

=head2 parse_gt

 Title   : parse_gt
 Usage   : $vcf = $vcf->parse_gt($record->{gt});
 Function: Parse a VCF GT string into a data structure.
 Returns : A hash (or reference) of VCF GT data.
 Args    : A scalar containing a string of VCF GT text.

=cut

sub parse_gt {
    my ($self, $format, $gts) = @_;
    
    for my $gt_ref (@{$gts}) {
	chomp $gt_ref;
	my @values = split /:/, $gt_ref;
	map {$_ = [split /,/, $_]} @values;
	
	my %gt_data;
	@gt_data{@{$format}} = @values;
	$gt_ref = \%gt_data;
    }
    return wantarray ? %{$gts} : $gts;
}

#-----------------------------------------------------------------------------

=head2 next_record

 Title   : next_record
 Usage   : $record = $vcf->next_record();
 Function: Return the next record from the VCF file.
 Returns : A hash (or reference) of VCF record data.
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

=head2 all_records

 Title   : all_records
 Usage   : $record = $vcf->all_records();
 Function: Parse and return all records.
 Returns : An array (or reference) of all VCF records.
 Args    : N/A

=cut

sub all_records {
	my $self = shift @_;

	my @records;
	while (my $record = $self->next_record) {
	    push @records, $record;
	}
	return wantarray ? @records : \@records;
}

#-----------------------------------------------------------------------------

=head1 DIAGNOSTICS

L<Arty::VCF> does not throw any warnings or errors.

=head1 CONFIGURATION AND ENVIRONMENT

L<Arty::VCF> requires no configuration files or environment variables.

=head1 DEPENDENCIES

L<Arty>

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
