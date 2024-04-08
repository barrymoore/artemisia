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

     my $bfh = File::ReadBackwards->new($file) ||
         throw_msg('cant_open_file_for_reading', $file);

     my %footer;
   LINE:
     while (my $line = $bfh->readline) {
         return undef if ! defined $line;
         if ($line !~ /^\#A/) {
             chomp $line;

             ##------------------------------------------------------------------------------
             ##------------------------ POSSIBLE MENDELIAN DIAGNOSES ------------------------
             ##------------------------------------------------------------------------------
             ##  RANK  MIM     GENE    PHEV_GENE  PHEV_MIM  MIM_MPR  IMPRM  vIQscr  mIQscr  mIQcdf  INC  DISEASE
             #B  0     118450  JAG1    0.961      0.992     0.987    0.5    1.578   2.678   0.916   N    AWS
             #B  1     617140  SON     0.957      0.979     0.975    0.5    0.585   1.123   0.914   N    ZTTK SYNDROME
             #B  2     618786  SUZ12   0.944      0.904     0.9      0.5    1.528   0.891   0.913   N    Imagawa-Matsumoto syndrome
             #B  3     614607  ARID1A  0.948      0.964     0.959    0.5    0.381   0.643   0.912   N    COFFIN-SIRIS SYNDROME 2
             #B  4     617159  CHD4    0.895      0.836     0.832    0.5    0.706   0.161   0.91    N    SIFRIM-HITZ-WEISS SYNDROME
             ##------------------------------------------------------------------------------
             ##------------------------ POSSIBLE MULTIGENIC DIAGNOSES -----------------------
             ##------------------------------------------------------------------------------
             ##  RANK  MIM     VID              NUM_G  TYPE  ZYG  CSQS  PLOIDY  PHEV_GENE  PHEV_MIM  MIM_MPR  vIQscr  mIQscr  mIQcdf
             #C  0  113100  BadgeGrp40344.2  2  4  1  1  1  0.923  0.662  0.66   -0.907  -2.718  0.858
             #C  1  NO_MIM  BadgeGrp35612.2  2  4  1  1  1  0.232  0.012  0.002  -1.298  -7.197  VNF
             #C  2  NO_MIM  BadgeGrp20236.2  2  4  1  1  1  0.297  0.001  0.002  -1.348  -7.028  VNF
             #C  3  NO_MIM  BadgeGrp27188.3  3  6  1  8  3  0.234  0      0.002  -1.712  -7.614  VNF
             ##------------------------------------------------------------------------------
             ##------------------------------------ HPO -------------------------------------
             ##------------------------------------------------------------------------------
             ##	0	HP:0003115	Abnormal EKG
             ##	1	HP:0031547	Abnormal QT interval
             ##	2	HP:0011994	Abnormal atrial septum morphology
             ##	3	HP:0012440	Abnormal biliary tract morphology
             ##	4	HP:0005120	Abnormal cardiac atrium morphology
             ##	5	HP:0001671	Abnormal cardiac septum morphology
             ##------------------------------------------------------------------------------
             ## GENOTYPE SKEW CHECK. P_value alpha = 0.00217391 based upon 90 previous observations.
             ## CHR     NUM_HET         NUM_HOM         %HOM_OBS	%HOM_EXP	P_VALUE          het <- SKEW -> hom
             ## 1       989             475             0.307122	0.274696	0.107468                  |
             ## 10      279             172             0.307092	0.291090	0.317974                  |
             ## 11      460             360             0.361816	0.301593	0.103433                  |
             ## 12      397             256             0.258878	0.303959	0.089466                  |
             ## 13      154             83              0.223900	0.263517	0.209185                  |
             ## 14      221             136             0.257753	0.303610	0.190588                  |
             ## 15      269             148             0.242351	0.311576	0.071857                  |
             ## 16      245             174             0.383414	0.260717	0.000274                  |+++
             ## 17      451             273             0.268743	0.297246	0.197559                  |
             ## 18      101             96              0.381859	0.293539	0.043265                  |
             ## 19      672             386             0.287421	0.292273	0.439947                  |
             ## 2       511             320             0.327274	0.293646	0.116324                  |
             ## 20      212             89              0.233125	0.289368	0.104478                  |
             ## 21      134             43              0.137459	0.288819	0.003829                  |
             ## 22      171             93              0.260173	0.306226	0.184831                  |
             ## 3       407             255             0.283468	0.297334	0.353994                  |
             ## 4       277             232             0.444243	0.307158	0.000250                  |+++
             ## 5       310             225             0.349154	0.303541	0.128416                  |
             ## 6       644             323             0.254281	0.281636	0.317448                  |
             ## 7       433             173             0.199651	0.280076	0.019431                  |
             ## 8       227             152             0.290023	0.295137	0.446953                  |
             ## 9       263             184             0.295424	0.292450	0.468794                  |
             ## X       20              126             0.872348	0.647167	0.223214                  |
             ##
             ## LOH DETECTED:YES
             ## SKEW DETECTED:YES (7.16236527310748)
             ## Estimated Consanguinity:4.49%
             ## CSN PRIOR:0.522450468914974
             ## VARIANTS_IN:13088 NUMBER OF SVs (rows):1 PASSING_FILTERS:1585 p_obs:0.499999999999997
             ## NTK0, number of SNVs in play:13088
             ## NTK1, number of SNVs kept:668
             ## NTK2, number of Badges possible:20101
             ## NTK3, number of Badges in play:917
             ## NTK4, number of Badges kept:95
             ## NTK2, number of Ext SVs considered:0
             ## NTK5, number of Ext SVs in play:0
             ## NTK6, number of Ext SVs kept:0
             ## NTKT, total number of VARs in play:1585
             ## NTKP, Pval of number of VARs in play:0.439754406734651
             ## NTKR, renormalized number of VARs in play:2552.93388430661
             ## Proband Ancestry:Other	Relative -Log Likelihoods:	Other:8917,Asian:9761,Finish:9891,European(non-Finish):10013,Ashkenazi:10049,African:11255
             ## Proband Sex:m P(MALE):0.999620371976135
             ## NUM HPO TERMS:133
             ## ADJ FOR INBREEDING:0.553521316925857
             ## MODE:TRIO
             ## Number of variants failing -e m  a:cov:47,bias:102,tot:143
             ## VAAST-VVP COOR:0.53
             ## BLS-BND COOR:0
             ## BLS-NOA COOR:0
             ## PHEV-KPR COOR:0.72
             ## CLIN-VVP-VAAST:-1
             ## COVERAGE-HETEROZYGOSITY COOR:0.05
             ## PHEV-GENE-MIM COOR:0.75
             ## K_PRIOR:0.87084
             ## K_PRIOR_PROB:0.24248417721519
             ## U_PRIOR_PROB:0.0454545454545455
             ## AVE DEPTH OF COVERAGE a MEAN:51.7116350985698 VARIANCE:321.153472460763
             ## AVE DEPTH OF COVERAGE m MEAN:1 VARIANCE:1
             ## AVE DEPTH OF COVERAGE x MEAN:28.09375 VARIANCE:166.990927419355
             ## AVE DEPTH OF COVERAGE y MEAN:1 VARIANCE:1
             ## CSQS
             ##	12	0.000391706187985203
             ##	2,18,23	0.000391706187985203
             ##	5,13	0.000391706187985203
             ##	6	0.000391706187985203
             ##	7	0.000391706187985203
             ##	13,20	0.000783412375970406
             ##	13,21	0.000783412375970406
             ##	4,5	0.000783412375970406
             ##	2	0.00117511856395561
             ##	33	0.00235023712791122
             ##	4	0.00235023712791122
             ##	35	0.00274194331589642
             ##	3	0.00313364950388162
             ##	11,13	0.00352535569186683
             ##	13,17	0.00352535569186683
             ##	10	0.00587559281977804
             ##	1	0.00822582994768926
             ##	5	0.00979265469963007
             ##	9	0.0109677732635857
             ##	8	0.0180184846473193
             ##	13,23	0.0313364950388162
             ##	11	0.184885320729016
             ##
             ## TYPE FRQUENCIES:	1:0.782534246575342	2:0.0804794520547945	4:0.0479452054794521	6:0.0684931506849315	8:0.0205479452054795	SUM:584
             ## TFA (INDEL) ADJUSTMENT	STATUS:off	TFA:0.46003933494999	Pval:0.149636422086162
             ## CMD:/home/ubuntu/vIQ6/bin/vIQ2 -a /home/ubuntu/fabric_viq_workflow/snakemake/rady_benchmarks/viq6.config -c  -d  -T WGS -e m -f 0.005 -g  -h  -i  -k  -l VIQ/coding_dist.CT.204560.viq_list.txt -m t -M Phevor/phv_renorm_mim.CT.204560.txt -o  -p 0.5 -Q h -q n -r n -s Phevor/phv_renorm.CT.204560.txt -v  -w  -x  -y  -z
             ## Threshold for SV support (BFT):0.698970004336019
             ## VERSION:6.1.2d
             ## GMT:Tue Sep  1 19:04:47 2020
             ## EOF

             ##------------------------------------------------------------------------------
             ##------------------------ POSSIBLE MENDELIAN DIAGNOSES ------------------------
             ##------------------------------------------------------------------------------
             ##  RANK  MIM     GENE    PHEV_GENE  PHEV_MIM  MIM_MPR  IMPRM  vIQscr  mIQscr  mIQcdf  INC  DISEASE
             #B  0     118450  JAG1    0.961      0.992     0.987    0.5    1.578   2.678   0.916   N    AWS
             #B  1     617140  SON     0.957      0.979     0.975    0.5    0.585   1.123   0.914   N    ZTTK SYNDROME
             #B  2     618786  SUZ12   0.944      0.904     0.9      0.5    1.528   0.891   0.913   N    Imagawa-Matsumoto syndrome
             #B  3     614607  ARID1A  0.948      0.964     0.959    0.5    0.381   0.643   0.912   N    COFFIN-SIRIS SYNDROME 2
             #B  4     617159  CHD4    0.895      0.836     0.832    0.5    0.706   0.161   0.91    N    SIFRIM-HITZ-WEISS SYNDROME
             if ($line =~ s/^\#B\s+//) {
                 my %data;
                 @data{qw(rank mim gene phev_gene phev_mim mim_mpr imprm viqscr miqscr
                          inc disease)} = split /\t/, $line;
                 map {$_ =~ s/\s+$// if defined $_} values %data;
                 push @{$self->{mendelian_diagnoses}}, \%data;
             }
             ##------------------------------------------------------------------------------
             ##------------------------ POSSIBLE MULTIGENIC DIAGNOSES -----------------------
             ##------------------------------------------------------------------------------
             ##  RANK  MIM     VID              NUM_G  TYPE  ZYG  CSQS  PLOIDY  PHEV_GENE  PHEV_MIM  MIM_MPR  vIQscr  mIQscr  mIQcdf
             #C  0     113100  BadgeGrp40344.2  2      4     1    1     1       0.923      0.662     0.66     -0.907  -2.718  0.858
             #C  1     NO_MIM  BadgeGrp35612.2  2      4     1    1     1       0.232      0.012     0.002    -1.298  -7.197  VNF
             #C  2     NO_MIM  BadgeGrp20236.2  2      4     1    1     1       0.297      0.001     0.002    -1.348  -7.028  VNF
             #C  3     NO_MIM  BadgeGrp27188.3  3      6     1    8     3       0.234      0         0.002    -1.712  -7.614  VNF
             elsif ($line =~ s/^\#C\s+//) {
                 my %data;
                 @data{qw(rank mim vid num_g type zyg csqs ploidy
                          phev_gene phev_mim mim_mpr viqscr miqscr miqcdf)} =
                     split /\t/, $line;
                 map {$_ =~ s/\s+$//} values %data;
                 push @{$self->{multigenic_diagnoses}}, \%data;
             }
             ##------------------------------------------------------------------------------
             ##------------------------------------ HPO -------------------------------------
             ##------------------------------------------------------------------------------
             ##	0	HP:0003115	Abnormal EKG
             ##	1	HP:0031547	Abnormal QT interval
             ##	2	HP:0011994	Abnormal atrial septum morphology
             ##	3	HP:0012440	Abnormal biliary tract morphology
             ##	4	HP:0005120	Abnormal cardiac atrium morphology
             ##	5	HP:0001671	Abnormal cardiac septum morphology
             ##------------------------------------------------------------------------------

             ## GENOTYPE SKEW CHECK. P_value alpha = 0.00217391 based upon 90 previous observations.
             elsif ($line =~ /^\#\#\s+GENOTYPE SKEW CHECK/) {
                 ($self->{skew_pval_alpha}) = ($line =~ /P_value\s+alpha\s+=\s+(\S+)\s+/);
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
             ## CSN PRIOR:0.522450468914974

             ## VARIANTS_IN:13088 NUMBER OF SVs (rows):1 PASSING_FILTERS:1585 p_obs:0.499999999999997
             elsif ($line =~ /^\#\#\s+VARIANTS_IN:\s*(\d+)\s+NUMBER OF SVs\s+\(rows\):(\d+)\s+PASSING_FILTERS:(\d+)\s+p_obs:(.*)/) {
                 $self->{variants_in}     = $1;
                 $self->{number_of_svs}   = $2;
                 $self->{passing_filters} = $3;
                 $self->{p_obs}           = $4;
             }
             ## NTK0, number of SNVs in play:13088
             elsif ($line =~ /^\#\#\s+XXX:\s*(.*)/) {
                 $self->{xxx} = $1;
             }
             ## NTK1, number of SNVs kept:668
             elsif ($line =~ /^\#\#\s+XXX:\s*(.*)/) {
                 $self->{xxx} = $1;
             }
             ## NTK2, number of Badges possible:20101
             elsif ($line =~ /^\#\#\s+XXX:\s*(.*)/) {
                 $self->{xxx} = $1;
             }
             ## NTK3, number of Badges in play:917
             elsif ($line =~ /^\#\#\s+XXX:\s*(.*)/) {
                 $self->{xxx} = $1;
             }
             ## NTK4, number of Badges kept:95
             elsif ($line =~ /^\#\#\s+XXX:\s*(.*)/) {
                 $self->{xxx} = $1;
             }
             ## NTK2, number of Ext SVs considered:0
             elsif ($line =~ /^\#\#\s+XXX:\s*(.*)/) {
                 $self->{xxx} = $1;
             }
             ## NTK5, number of Ext SVs in play:0
             elsif ($line =~ /^\#\#\s+XXX:\s*(.*)/) {
                 $self->{xxx} = $1;
             }
             ## NTK6, number of Ext SVs kept:0
             elsif ($line =~ /^\#\#\s+XXX:\s*(.*)/) {
                 $self->{xxx} = $1;
             }
             ## NTKT, total number of VARs in play:1585
             elsif ($line =~ /^\#\#\s+XXX:\s*(.*)/) {
                 $self->{xxx} = $1;
             }
             ## NTKP, Pval of number of VARs in play:0.439754406734651
             elsif ($line =~ /^\#\#\s+XXX:\s*(.*)/) {
                 $self->{xxx} = $1;
             }
             ## NTKR, renormalized number of VARs in play:2552.93388430661
             elsif ($line =~ /^\#\#\s+XXX:\s*(.*)/) {
                 $self->{xxx} = $1;
             }
             ## Proband Ancestry:European(non-Finish)	Relative -Log Likelihoods:	European(non-Finish):9513,Finish:9549,Ashkenazi:9702,Other:9810,Asian:10878,African:11622
             elsif ($line =~ /^\#\#\s+Proband Ancestry:\s*(.*)\s+Relative -Log Likelihoods:\s+(.*)/) {
                 $self->{proband_ancestry} = $1;
                 $self->{ancestry_relative_log_likelihoods} = $2;
             }
             ## Proband Sex:m P(MALE):0.999620371976135
             elsif ($line =~ /^\#\#\s+Proband Sex:\s*(\S+)\s+P\(MALE\):(.*)/) {
                 $self->{proband_sex} = $1;
                 $self->{prob_proband_male} = $2
             }
             ## NUM HPO TERMS:133
             elsif ($line =~ /^\#\#\s+ NUM HPO TERMS:\s*(.*)/) {
                 $self->{num_hpo_terms} = $1;
             }
             ## ADJ FOR INBREEDING:0.553521316925857
             elsif ($line =~ /^\#\#\s+ADJ FOR INBREEDING:\s*(.*)/) {
                 $self->{adj_for_inbreeding} = $1;
             }
             ## MODE:TRIO
             elsif ($line =~ /^\#\#\s+MODE:\s*(.*)/) {
                 $self->{mode} = $1;
             }
             ## Number of variants failing -e m  a:cov:47,bias:102,tot:143
             elsif ($line =~ /^\#\#\s+Number of variants failing -e m\s+(.*)/) {
                 $self->{number_variants_failing_e_m} = $1;
             }
             ## VAAST-VVP COOR:0.53
             elsif ($line =~ /^\#\#\s+VAAST-VVP COOR:\s*(.*)/) {
                 $self->{vaast_vvp_coor} = $1;
             }
             ## BLS-BND COOR:0
             elsif ($line =~ /^\#\#\s+BLS-BND COOR:\s*(.*)/) {
                 $self->{bls_bnd_coor} = $1;
             }
             ## BLS-NOA COOR:0
             elsif ($line =~ /^\#\#\s+BLS-NOA COOR:\s*(.*)/) {
                 $self->{bls_noa_coor} = $1;
             }
             ## PHEV-KPR COOR:0.72
             elsif ($line =~ /^\#\#\s+PHEV-KPR:\s*(.*)/) {
                 $self->{phev_kpr} = $1;
             }
             ## CLIN-VVP-VAAST:-1
             elsif ($line =~ /^\#\#\s+CLIN-VVP-VAAST:\s*(.*)/) {
                 $self->{clin_vvp_vaast} = $1;
             }
             ## COVERAGE-HETEROZYGOSITY COOR:0.05
             elsif ($line =~ /^\#\#\s+COVERAGE-HETEROZYGOSITY:\s*(.*)/) {
                 $self->{coverage_heterozygosity} = $1;
             }
             ## PHEV-GENE-MIM COOR:0.75
             elsif ($line =~ /^\#\#\s+PHEV-GENE-MIM COOR:\s*(.*)/) {
                 $self->{phev_gene_mim} = $1;
             }
             ## K_PRIOR:0.87084
             elsif ($line =~ /^\#\#\s+K_PRIOR:\s*(.*)/) {
                 $self->{k_prior} = $1;
             }
             ## K_PRIOR_PROB:0.24248417721519
             elsif ($line =~ /^\#\#\s+K_PRIOR_PROB:\s*(.*)/) {
                 $self->{k_prior_prob} = $1;
             }
             ## U_PRIOR_PROB:0.0454545454545455
             elsif ($line =~ /^\#\#\s+U_PRIOR_PROB:\s*(.*)/) {
                 $self->{u_prior_prob} = $1;
             }
             ## AVE DEPTH OF COVERAGE a MEAN:51.7116350985698 VARIANCE:321.153472460763
             elsif ($line =~ /^\#\#\s+AVE DEPTH OF COVERAGE a MEAN:(.*)\s+VARIANCE:(.*)/) {
                 $self->{ave_depth_of_coverage_a_mean} = $1;
                 $self->{ave_depth_of_coverage_a_variance} = $2;
             }
             ## AVE DEPTH OF COVERAGE m MEAN:51.7116350985698 VARIANCE:321.153472460763
             elsif ($line =~ /^\#\#\s+AVE DEPTH OF COVERAGE m MEAN:(.*)\s+VARIANCE:(.*)/) {
                 $self->{ave_depth_of_coverage_m_mean} = $1;
                 $self->{ave_depth_of_coverage_m_variance} = $2;
             }
             ## AVE DEPTH OF COVERAGE x MEAN:51.7116350985698 VARIANCE:321.153472460763
             elsif ($line =~ /^\#\#\s+AVE DEPTH OF COVERAGE x MEAN:(.*)\s+VARIANCE:(.*)/) {
                 $self->{ave_depth_of_coverage_x_mean} = $1;
                 $self->{ave_depth_of_coverage_x_variance} = $2;
             }
             ## AVE DEPTH OF COVERAGE y MEAN:51.7116350985698 VARIANCE:321.153472460763
             elsif ($line =~ /^\#\#\s+AVE DEPTH OF COVERAGE y MEAN:(.*)\s+VARIANCE:(.*)/) {
                 $self->{ave_depth_of_coverage_y_mean} = $1;
                 $self->{ave_depth_of_coverage_y_variance} = $2;
             }
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

     # Handle vIQ2X data
     if ($line =~ /\# CSQ_PRB/) {
	 # CSQ_PRB       NUM_OBS         MEAN            VARIANCE        CSQ_STRNG
	 # VAR_SCR       CSQ_SCR         CMB_SCR         CNT_ADJ         FREQ            NUM_OBS         CSQ             ZYG     PLDY    TYPE            SYM
	 my $tag_count = 0;
       LINE2:
	 while ($line = $self->readline) {
	     if ($line =~ /\# VAR_SCR/) {
		 $tag_count++
	     }
	     if ($tag_count == 2) {
		 $line = $self->readline;
		 last LINE2;
	     }
       }
     }

     if ($line !~ /^\#/) {
         throw_msg('missing_header_row', "First line: $line\n");
     }
     else {
         my @cols = split /\t/, $line;
         map {$_ =~ s/\s+$//} @cols;
         my $col_count = scalar @cols;
         if ($col_count != 39 &&
	     $col_count != 40 &&
	     $col_count != 42) {
             handle_message('FATAL', 'incorrect_column_count', "(expected 39, 40 or 42 got $col_count\ncolumns)\n$line\n\n");
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
    return undef if ! defined $line || $line !~ /^\#A/;

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
    map {$_ =~ s/\s+$//;$_ = '' unless defined $_} @cols;

    my $col_count = scalar @cols;
    if ($col_count != 39 &&
	$col_count != 40 &&
	$col_count != 42) {
	handle_message('FATAL', 'incorrect_column_count', "(expected 39, 40 or 42 got $col_count\ncolumns)\n$line\n\n");
    }

    my %record;

    # Rank CHR Gene Transcript vID CSQ DIST Denovo Type Zygo CSN PLDY
    # SITES Par Loc Length GQS GFLG GFLpr PPP vPene breath FIX vIQscr
    # p_scor s_scor PHEV/K VVP/SVP VAAST RPROB G_tag p_mod s_mod
    # G_tag_scr ClinVar var_qual vID CHR;BEG;END

    @record{qw(section rank chr gene transcript vid csq dist denovo type zygo
               csn pldy sites par loc length gqs gflg gflpr ppp vpene
               breath fix viqscr p_scor s_scor phev_k vvp_svp vaast
               rprob g_tag p_mod s_mod g_tag_scr clinvar var_qual
               rid loc payload)} = @cols;

    # Parse denovo
    ($record{denovo}, $record{maf}) = split /\(/, $record{denovo};
    $record{maf} =~ s/\)$//;

    # Parse indendental
    $record{incendental} = 0;
    if ($record{clinvar} =~ /\*/) {
        $record{incendental}++
    }

    # Parse var_qual
    # 24:14|0.5|0.1197 - SNV/Indel
    # (83|54|0.00068|25) 8/15.3946097|25.0000|0.50000|14.0113 - Badges/SVs
    # my ($bayesf, $prob);
    # my %var_qual_hash;
    # @var_qual_hash{qw(ad bayesf prob)} = split /\|/, $record{var_qual};
    # $record{var_qual} = \%var_qual_hash;
    # $record{var_qual}{ad} = [split /:/, $record{var_qual}{ad}];

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
