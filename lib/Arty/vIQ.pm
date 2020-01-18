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
         throw_msg('cant_open_file_for_reading', $file);

     my %footer;
   LINE:
     while (my $line = $fh->readline) {
         return undef if ! defined $line;
         chomp $line;
         if ($line =~ /^\#\#/) {
             chomp $line;

	     ##
	     ## GENOTYPE SKEW CHECK. P_value alpha = 0.00217391 based upon 90 previous observations.
	     ## CHR  	NUM_HET 	NUM_HOM 	%HOM_OBS	%HOM_EXP	P_VALUE      	 het <- SKEW -> hom
	     ## 1    	997     	483     	0.227294	0.274696	0.036451	          |
	     ## 10   	308     	211     	0.297960	0.291090	0.419939	          |
	     ## 11   	624     	356     	0.249404	0.301593	0.138652	          |
	     ## 12   	378     	259     	0.250310	0.303959	0.056605	          |
	     ## 13   	100     	86      	0.268353	0.263517	0.460651	          |
	     ## 14   	221     	192     	0.411432	0.303610	0.021162	          |
	     ## 15   	256     	189     	0.313465	0.311576	0.484459	          |
	     ## 16   	309     	157     	0.210225	0.260717	0.079425	          |
	     ## 17   	466     	311     	0.320673	0.297246	0.242981	          |
	     ## 18   	135     	92      	0.308609	0.293539	0.385453	          |
	     ## 19   	751     	388     	0.275261	0.292273	0.298386	          |
	     ## 2    	510     	319     	0.254488	0.293646	0.084042	          |
	     ## 20   	201     	92      	0.267919	0.289368	0.316484	          |
	     ## 21   	142     	68      	0.203445	0.288819	0.068075	          |
	     ## 22   	215     	96      	0.242973	0.306226	0.110561	          |
	     ## 3    	420     	231     	0.264814	0.297334	0.190794	          |
	     ## 4    	306     	193     	0.268066	0.307158	0.162067	          |
	     ## 5    	409     	178     	0.201248	0.303541	0.006367	          |
	     ## 6    	658     	278     	0.268690	0.281636	0.411322	          |
	     ## 7    	396     	216     	0.272805	0.280076	0.426349	          |
	     ## 8    	235     	175     	0.363392	0.295137	0.039244	          |
	     ## 9    	294     	200     	0.335630	0.292450	0.129483	          |
	     ## X    	48      	153     	0.616815	0.647167	0.459246	          |
	     ##
	     ## LOH DETECTED:NO
	     ## SKEW DETECTED:NO (0)
	     ## Estimated Consanguinity:6.84%
	     ## VARIANTS_IN:13917 NUMBER OF SVs:123 PASSING_FILTERS:20991 p_obs:0.5
	     ## Proband Ancestry:European(non-Finish)	Relative -Log Likelihoods:	European(non-Finish):9513,Finish:9549,Ashkenazi:9702,Other:9810,Asian:10878,African:11622
	     ## Proband Sex:m P(MALE):0.999229070239989
	     ## ADJ FOR INBREEDING:0.544641331565072
	     ## MODE:SINGLETON
	     ## Number of variants failing -e m  a:cov:5,bias:137,tot:174 x:cov:0,bias:16,tot:16
	     ## VAAST-VVP COOR:0.329363798096313
	     ## BLS-BND COOR:0.0283600493218249
	     ## BLS-NOA COOR:0.0184956843403206
	     ## PHEV-KPR COOR:0.763782068377952
	     ## COVERAGE-HETEROZYGOSITY COOR:-0.535448334928468
	     ## K_PRIOR:0.86772
	     ## K_PRIOR_PROB:0.26962179747865
	     ## U_PRIOR_PROB:0.0488741490661546
	     ## AVE DEPTH OF COVERAGE a MEAN:50.9793738489871 VARIANCE:330.698911177429
	     ## AVE DEPTH OF COVERAGE m MEAN:1 VARIANCE:1
	     ## AVE DEPTH OF COVERAGE x MEAN:27.4222222222222 VARIANCE:124.976767676768
	     ## AVE DEPTH OF COVERAGE y MEAN:1 VARIANCE:1
	     ## CMD:/home/ubuntu/vIQ/bin/vIQ2 -a /home/ubuntu/fabric_viq_workflow/snakemake/viq.config -c  -d  -e m -f 0.005 -g  -h  -k  -l VIQ/coding_dist.CT.244799.viq_list.txt -m s -o  -p 0.5 -q n -r n -v  -w  -x  -y  -z
	     ## VERSION:4.0
	     ## GMT:Wed Jan  8 04:52:25 2020
	     ## EOF
	     
             if ($line =~ /^\#\#\s+GENOTYPE SKEW CHECK/) {
                 ($self->{pval_alpha}) = ($line =~ /P_value\s+alpha\s+=\s+(\S+)\s+/);
             }
	     ## LOH DETECTED:NO
             elsif ($line =~ /^\#\#\s+LOH DETECTED:\s*(.*)/) {
                 $self->{loh_detected} = $1;
             }
	     ## SKEW DETECTED:NO (0)
             elsif ($line =~ /^\#\#\s+SKEW DETECTED:\s*(\S+)\s+\(.*?\)/) {
                 $self->{skew_detected} = $1;
                 $self->{skew_detected_score} = $2;
             }
	     ## Estimated Consanguinity:6.84%
             elsif ($line =~ /^\#\#\s+Estimated Consanguinity:\s*(.*)%/) {
                 $self->{estimated_consanguinity} = $1;
             }
	     ## VARIANTS_IN:13917 NUMBER OF SVs:123 PASSING_FILTERS:20991 p_obs:0.5
             elsif ($line =~ /^\#\#\s+VARIANTS_IN:\s*(\d+)\s+NUMBER OF SVs:(\d+)\s+PASSING_FILTERS:(\d+)\s+p_obs:(.*)/) {
                 $self->{variants_in}     = $1;
		 $self->{number_of_svs}   = $2;
		 $self->{passing_filters} = $3;
		 $self->{p_obs}           = $4;
             }
	     ## Proband Ancestry:European(non-Finish)	Relative -Log Likelihoods:	European(non-Finish):9513,Finish:9549,Ashkenazi:9702,Other:9810,Asian:10878,African:11622
             elsif ($line =~ /^\#\#\s+Proband Ancestry:\s*(.*)\s+Relative -Log Likelihoods:\s+(.*)/) {
                 $self->{proband_ancestry} = $1;
		 $self->{ancestry_relative_log_likelihoods} = $2;
             }
	     ## Proband Sex:m P(MALE):0.999229070239989
             elsif ($line =~ /^\#\#\s+Proband Sex:\s*(\S+)\s+P\(MALE\):(.*)/) {
                 $self->{proband_sex} = $1;
		 $self->{prob_proband_male} = $2
             }

	     # ## ADJ FOR INBREEDING:0.544641331565072
             # elsif ($line =~ /^\#\#\s+XXXX:\s*(.*)/) {
             #     $self->{xxxx} = $1;
             # }
	     # ## MODE:SINGLETON
             # elsif ($line =~ /^\#\#\s+XXXX:\s*(.*)/) {
             #     $self->{xxxx} = $1;
             # }
	     # ## Number of variants failing -e m  a:cov:5,bias:137,tot:174 x:cov:0,bias:16,tot:16
             # elsif ($line =~ /^\#\#\s+XXXX:\s*(.*)/) {
             #     $self->{xxxx} = $1;
             # }
	     # ## VAAST-VVP COOR:0.329363798096313
             # elsif ($line =~ /^\#\#\s+XXXX:\s*(.*)/) {
             #     $self->{xxxx} = $1;
             # }
	     # ## BLS-BND COOR:0.0283600493218249
             # elsif ($line =~ /^\#\#\s+XXXX:\s*(.*)/) {
             #     $self->{xxxx} = $1;
             # }
	     # ## BLS-NOA COOR:0.0184956843403206
             # elsif ($line =~ /^\#\#\s+XXXX:\s*(.*)/) {
             #     $self->{xxxx} = $1;
             # }
	     # ## PHEV-KPR COOR:0.763782068377952
             # elsif ($line =~ /^\#\#\s+XXXX:\s*(.*)/) {
             #     $self->{xxxx} = $1;
             # }
	     # ## COVERAGE-HETEROZYGOSITY COOR:-0.535448334928468
             # elsif ($line =~ /^\#\#\s+XXXX:\s*(.*)/) {
             #     $self->{xxxx} = $1;
             # }
	     # ## K_PRIOR:0.86772
             # elsif ($line =~ /^\#\#\s+XXXX:\s*(.*)/) {
             #     $self->{xxxx} = $1;
             # }
	     # ## K_PRIOR_PROB:0.26962179747865
             # elsif ($line =~ /^\#\#\s+XXXX:\s*(.*)/) {
             #     $self->{xxxx} = $1;
             # }
	     # ## U_PRIOR_PROB:0.0488741490661546
             # elsif ($line =~ /^\#\#\s+XXXX:\s*(.*)/) {
             #     $self->{xxxx} = $1;
             # }
	     # ## AVE DEPTH OF COVERAGE a MEAN:50.9793738489871 VARIANCE:330.698911177429
             # elsif ($line =~ /^\#\#\s+XXXX:\s*(.*)/) {
             #     $self->{xxxx} = $1;
             # }
	     # ## AVE DEPTH OF COVERAGE m MEAN:1 VARIANCE:1
             # elsif ($line =~ /^\#\#\s+XXXX:\s*(.*)/) {
             #     $self->{xxxx} = $1;
             # }
	     # ## AVE DEPTH OF COVERAGE x MEAN:27.4222222222222 VARIANCE:124.976767676768
             # elsif ($line =~ /^\#\#\s+XXXX:\s*(.*)/) {
             #     $self->{xxxx} = $1;
             # }
	     # ## AVE DEPTH OF COVERAGE y MEAN:1 VARIANCE:1
             # elsif ($line =~ /^\#\#\s+XXXX:\s*(.*)/) {
             #     $self->{xxxx} = $1;
             # }
	     # ## CMD:/home/ubuntu/vIQ/bin/vIQ2 -a /home/ubuntu/fabric_viq_workflow/snakemake/viq.config -c  -d  -e m -f 0.005 -g  -h  -k  -l VIQ/coding_dist.CT.244799.viq_list.txt -m s -o  -p 0.5 -q n -r n -v  -w  -x  -y  -z
             # elsif ($line =~ /^\#\#\s+XXXX:\s*(.*)/) {
             #     $self->{xxxx} = $1;
             # }
	     # ## VERSION:4.0
             # elsif ($line =~ /^\#\#\s+XXXX:\s*(.*)/) {
             #     $self->{xxxx} = $1;
             # }
	     # ## GMT:Wed Jan  8 04:52:25 2020
             # elsif ($line =~ /^\#\#\s+XXXX:\s*(.*)/) {
             #     $self->{xxxx} = $1;
             # }

	     ## EOF
             elsif ($line =~ /^\#\#\s+EOF/) {
                 $self->{eof}++;
             }
             else {
                 # $self->warn_message('unknown_viq_metadata', $line);
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
     else {
         my @cols = split /\t/, $line;
         map {$_ =~ s/\s+$//} @cols;
         my $col_count = scalar @cols;
         if ($col_count != 37) {
             handle_message('FATAL', 'incorrect_column_count', "(expected 37 got $col_count columns) $line");
         }
     }

     if (! $self->{eof}) {
	 throw_msg('missing_end_of_file_mark',
		   "File $file does not have '## EOF'")
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
    map {$_ =~ s/\s+$//} @cols;

    my $col_count = scalar @cols;
    if ($col_count != 37) {
        handle_message('FATAL', 'incorrect_column_count', "(expected 37 got $col_count columns) $line");
    }

    my %record;


    # Rank CHR Gene Transcript vID CSQ DIST Denovo Type Zygo CSN PLDY
    # SITES Par Loc Length GQS GFLG GFLpr PPP vPene breath FIX vIQscr
    # p_scor s_scor PHEV/K VVP/SVP VAAST RPROB G_tag p_mod s_mod
    # G_tag_scr ClinVar var_qual vID

    @record{qw(rank chr gene transcript vid csq dist denovo type zygo csn pldy
    sites par loc length gqs gflg gflpr ppp vpene breath fix viqscr
    p_scor s_scor phev_k vvp_svp vaast rprob g_tag p_mod s_mod
    g_tag_scr clinvar var_qual rid)} = @cols;

    # Parse denovo
    ($record{denovo}, $record{maf}) = split /\(/, $record{denovo};
    $record{maf} =~ s/\)$//;

    # Parse indendental
    $record{incendental} = 0;
    if ($record{clinvar} =~ /\*/) {
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
