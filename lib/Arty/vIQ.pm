package Arty::vIQ;

use strict;
use warnings;
use vars qw($VERSION);

$VERSION = 0.0.1;
use base qw(Arty::Base);
use Arty::Utils qw(:all);
use File::ReadBackwards;

=head1 NAME

Arty::vIQ - Parse vIQ files

=head1 VERSION

This document describes Arty::vIQ version 0.0.1

=head1 SYNOPSIS

    use Arty::vIQ;
    my $viq = Arty::vIQ->new('sample.viq_output.txt');

    while (my $record = $parser->next_record) {
	print $record->{gene} . "\n";
    }

=head1 DESCRIPTION

L<Arty::vIQ> provides vIQ parsing ability for the Artemisia suite
of genomics tools.

=head1 DATA STRUCTURE

Arty::vIQ returns records as a complex datastructure which has the
following format.

=head1 CONSTRUCTOR

New L<Arty::vIQ> objects are created by the class method new.
Arguments should be passed to the constructor as a list (or reference)
of key value pairs.  If the argument list has only a single argument,
then this argument is applied to the 'file' attribute and thus
specifies the vIQ filename.  All attributes of the L<Arty::vIQ>
object can be set in the call to new. An simple example of object
creation would look like this:

    my $parser = Arty::vIQ->new('sample.viq_output.txt');

    # This is the same as above
    my $parser = Arty::vIQ->new('file' => 'sample.viq_output.txt');

The constructor recognizes the following parameters which will set the
appropriate attributes:

=over

=item * C<< file => sample.viq_output.txt >>

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
     Usage   : Arty::vIQ->new();
     Function: Creates a Arty::vIQ object;
     Returns : An Arty::vIQ object
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
	 
         if ($line =~ /^\#\#/) {
             chomp $line;
	     ## GENOTYPE SKEW CHECK. P_value alpha = 0.00217391 based upon 90 previous observations.
	     ## CHR  	NUM_HET 	NUM_HOM 	%HOM_OBS	%HOM_EXP	P_VALUE      	 het <- SKEW -> hom
	     ## 1    	1513    	1049    	0.365898	0.274696	0.000375	          |+++
	     ## 10   	553     	358     	0.272690	0.291090	0.294297	          |
	     ## 11   	1003    	619     	0.278609	0.301593	0.315838	          |
	     ## 12   	791     	449     	0.277184	0.303959	0.213623	          |
	     ## 13   	215     	156     	0.240319	0.263517	0.318720	          |
	     ## 14   	435     	267     	0.355716	0.303610	0.160983	          |
	     ## 15   	463     	275     	0.250233	0.311576	0.099184	          |
	     ## 16   	495     	408     	0.386705	0.260717	0.000310	          |+++
	     ## 17   	764     	496     	0.361983	0.297246	0.028264	          |
	     ## 18   	244     	145     	0.243623	0.293539	0.167482	          |
	     ## 19   	1452    	632     	0.245067	0.292273	0.072342	          |
	     ## 2    	900     	642     	0.344192	0.293646	0.038069	          |
	     ## 20   	325     	226     	0.404374	0.289368	0.005903	          |
	     ## 21   	206     	121     	0.258498	0.288819	0.297080	          |
	     ## 22   	313     	211     	0.381979	0.306226	0.071771	          |
	     ## 3    	701     	410     	0.293620	0.297334	0.459768	          |
	     ## 4    	453     	386     	0.367176	0.307158	0.065433	          |
	     ## 5    	521     	455     	0.414578	0.303541	0.003495	          |
	     ## 6    	1183    	574     	0.253819	0.281636	0.314976	          |
	     ## 7    	749     	391     	0.274987	0.280076	0.448544	          |
	     ## 8    	486     	300     	0.303923	0.295137	0.410013	          |
	     ## 9    	555     	380     	0.325267	0.292450	0.194712	          |
	     ## X    	221     	191     	0.457104	0.647167	0.261059	          |
	     ##
	     ## LOH DETECTED:YES
	     ## SKEW DETECTED:YES (6)
	     ## VARIANTS_IN:638785 PASSING_FILTERS:240 p_obs:0.5
	     ## Proband Ancestry:Latino	Relative -Log Likelihoods:	Latino:446305,Asian:489299,Finish:503990,European(non-Finish):505357,Ashkenazi:510663,African:560289
	     ## Proband Sex:f P(MALE):0.630563534956827
	     ## MODE:TRIO
	     ## Number of variants failing -e m  a:cov:2,bias:36,tot:44 x:cov:0,bias:1,tot:1
	     ## CMD:/home/ubuntu/vIQ/bin/vIQ2 -a /home/ubuntu/vIQ_Workflow/snakemake/viq.config -c  -d  -e m -f 0.005 -g  -h  -k  -l VIQ/coding_dist.304059.viq_list.txt -m t -o  -p 0.5 -q n -r n -t 1 -v  -w  -x  -y  -z
	     ## VERSION:1.0
	     ## GMT:Wed Aug 28 03:56:04 2019
	     ## EOF
	     
	     ## GENOTYPE SKEW CHECK. P_value alpha = 0.00217391 based upon 90 previous observations.
	     ## CHR  	NUM_HET 	NUM_HOM 	%HOM_OBS	%HOM_EXP	P_VALUE      	 het <- SKEW -> hom
	     ## 1    	1513    	1049    	0.365898	0.274696	0.000375	          |+++
	     ## 10   	553     	358     	0.272690	0.291090	0.294297	          |

	     
	     if ($line =~ /^\#\#\s+GENOTYPE SKEW CHECK/) {
	     	 ($self->{pval_alpha}) = ($line =~ /P_value\s+alpha\s+=\s+(\S+)\s+/);
	     }
	     elsif ($line) {
		 # Do something
	     }
	     else {
	     	 warn('unknown_viq_metadata', $line);
	     }
	 }
	 else {
             last LINE;
         }
     }
     $self->{footer} = \%footer;

     my $line = $self->readline;
     if ($line !~ /^\#/) {
	 throw_msg('missing_header_row', "First line: $line\n");
     }
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
 Function: Return the next record from the vIQ file.
 Returns : A hash (or reference) of vIQ record data.
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
 Function: Parse vIQ line into a data structure.
 Returns : A hash (or reference) of vIQ record data.
 Args    : A scalar containing a string of Tempalte record text.

=cut

sub parse_record {
    my ($self, $line) = @_;
    chomp $line;
    
    my @cols = split /\t/, $line;
    
    my %record;

    #  #Rank  Gene   Transcript       vID       Coding  Denovo     Type  Zygo  Par  Loc  breath   vIQscr  p_scor  s_scor  PHEV   VVP    VAAST  G_tag  p_mod  s_mod  G_tag_scr  ClinVar  var_qual          vID
    #  1      MVK    ENST00000228510  CM990888  0       0(0.0000)  1     1     F    a    0.50000  1.8490  1.8490  3.2640  0.987  0.239  0.989  null   ad     ar     null       6*       24:14|0.5|0.1197  riq:00419550
    #  2      EFHC1  ENST00000371068  CM042021  0       0(0.0000)  1     1     F    a    0.50000  1.7844  1.7844  2.0536  0.959  0.639  0.989  null   ad     ar     null       6*       29:32|0.5|0.2297  riq:00225118
    
    @record{qw(rank gene transcript vid coding denovo type zygo par
    	       loc breath viqscr p_scor s_scor phev vvp vaast g_tag
    	       p_mod s_mod g_tag_scr clinvar var_qual vid)} = @cols;

    # Parse denovo
    ($record{denovo}, $record{maf}) = split /\(/, $record{denovo};
    $record{maf} =~ s/\)$//;

    # Parse indendental
    $record{incendental} = 0;
    if ($record{clinvar} =~ s/\*$//) {
	$record{incendental}++
    }
    
    # Parse var_qual
    # 24:14|0.5|0.1197
    my ($bayesf, $prob);
    my %var_qual_hash;
    @var_qual_hash{qw(ad bayesf prob)} = split /\|/, $record{var_qual};
    $record{var_qual} = \%var_qual_hash;
    $record{var_qual}{ad} = [split /:/, $record{var_qual}{ad}];
    
    return wantarray ? %record : \%record;
}

#-----------------------------------------------------------------------------

=head1 DIAGNOSTICS

L<Arty::vIQ> does not throw any warnings or errors.

=head1 CONFIGURATION AND ENVIRONMENT

L<Arty::vIQ> requires no configuration files or environment variables.

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
