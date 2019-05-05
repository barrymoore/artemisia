#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;

use FindBin;
use lib "$FindBin::RealBin/../lib";

use Arty::VAAST;
use Arty::Phevor;
use Arty::VCF;
use Arty::Utils qw(:all);

#-----------------------------------------------------------------------------
#----------------------------------- MAIN ------------------------------------
#-----------------------------------------------------------------------------

my $usage = "

Synopsis:

vaast_phevor_report.pl              \
    --phevor       phevor.txt       \
    --gnomad       gnomad.vcf.gz    \
    input_report.vaast

Description:

Generate detailed reports for combined VAAST/Phevor runs.

Options:

  --phevor, -p

    A phevor file associated with the VAAST run.

  --gnomad, -g

    A tabix-indexed Gnomad VCF file.

";

my ($help, $phevor_file, $gnomad_file);

my $opt_success = GetOptions('help'            => \$help,
			     'phevor|p=s'      =>  \$phevor_file,
			     'gnomad|g=s'      =>  \$gnomad_file,
    );

die $usage if $help || ! $opt_success;

my $vaast_file = shift;
die $usage unless $vaast_file;

my $vaast  = Arty::VAAST->new(file   => $vaast_file,
			      scored => 1);
my $phevor = Arty::Phevor->new(file => $phevor_file);

print_report($phevor, $vaast);

#-----------------------------------------------------------------------------
#-------------------------------- SUBROUTINES --------------------------------
#-----------------------------------------------------------------------------

sub print_report {

    my ($phevor, $vaast) = @_;

    #----------------------------------------
    # Map VAAST data to genes
    #----------------------------------------
    my %vaast_map;
    while (my $record = $vaast->next_record) {
	my $gene = $record->{gene};
	$vaast_map{$gene} = $record
	    unless exists $vaast_map{$gene};
    }

    #----------------------------------------
    # Print header
    #----------------------------------------
    print join "\t", qw(gene phv_rank phvr_score phv_prior
                        vaast_rank vaast_score vaast_pval 
                        gnomad_cmlt_af variant
                        type score het hom nc);
    print "\n";

    #----------------------------------------
    # Loop Phevor data
    #----------------------------------------
 GENE:
    while (my $record = $phevor->next_record) {
	
	#----------------------------------------
	# Get Phevor data
	#----------------------------------------
	my ($phv_rank, $phv_gene, $phv_score, $phv_prior) =
	    @{$record}{qw(rank gene score prior orig_p)};
	$phv_rank++;
	
	#----------------------------------------
	# Skip boring data
	#----------------------------------------
	next GENE if $phv_score <= 0;
	next GENE unless exists $vaast_map{$phv_gene};
	
	#----------------------------------------
	# Get VAAST data
	#----------------------------------------
	my $vaast_record = $vaast_map{$phv_gene};
	my ($vaast_rank, $vaast_gene, $vaast_feature, $vaast_score, $vaast_pval) = 
	    @{$vaast_record}{qw(rank gene feature_id score p_value)};
	$vaast_rank++;
	
	#----------------------------------------
	# Calculate allele counts
	# Sort variants by score
	#----------------------------------------
	my @allele_data;
      VAR:
	for my $var_key (sort {($vaast_record->{Alleles}{$b}{score}
				<=> 
				$vaast_record->{Alleles}{$a}{score})}
			 keys %{$vaast_record->{Alleles}}) {

	    my ($chrom, $start, $ref) = split /:/, $var_key;
	    my $gnomad_vcf = Arty::VCF->new(file  => $gnomad_file,
					    tabix => "$chrom:${start}-${start}");
	    my $gnomad_cmlt_af = 0;
	    while ($record = $gnomad_vcf->next_record) {
		$gnomad_cmlt_af += $record->{info}{AF}[0];
	    }
	    
	    #----------------------------------------
	    # Get variant data
	    #----------------------------------------
	    my $var = $vaast_record->{Alleles}{$var_key};
	    my ($var_type, $var_score) = @{$var}{qw{type score}};

	    #----------------------------------------
	    # Skip variants with 0 score
	    #----------------------------------------
	    next VAR unless $var->{score} > 0;

	    #---------------------------------------
	    # Loop genotype data
	    #----------------------------------------
	    my %gt_data = (NC  => [],
			   HOM => [],
			   HET => []);
	    for my $gt_key (sort keys %{$var->{GT}}) {

		#---------------------------------------
		# Get genotype data
		#----------------------------------------
		my $gt = $var->{GT}{$gt_key};
		my $b_count = $gt->{B};
		my $t_count = $gt->{T};

		#----------------------------------------
		# Collect B & T count of each genotype
		# by class (NC, HOM, HET)
		#----------------------------------------
		my ($A, $B) = split ':', $gt_key;
		my $gt_txt = join ',', $gt_key, $b_count, $t_count;
		if (grep {$_ eq '^'} ($A, $B)) {
		    push @{$gt_data{NC}}, $gt_txt;
		}
		elsif ($A eq $B) {
		    push @{$gt_data{HOM}}, $gt_txt;
		}
		else {
		    push @{$gt_data{HET}}, $gt_txt;		    
		}
	    }

	    #----------------------------------------
	    # Format floating points
	    #----------------------------------------
	    map {$_ =  sprintf '%.2g', $_} ($phv_prior, $vaast_pval, $gnomad_cmlt_af);
	    $phv_score = sprintf '%.3g', $phv_score;

	    #----------------------------------------
	    # Prep genotype data
	    #----------------------------------------
	    my $het_gt_txt = join '|', @{$gt_data{HET}};
	    my $hom_gt_txt = join '|', @{$gt_data{HOM}};
	    my $nc_gt_txt  = join '|', @{$gt_data{NC}};
	    $het_gt_txt ||= '.';
	    $hom_gt_txt ||= '.';
	    $nc_gt_txt  ||= '.';
	    
	    #----------------------------------------
	    # Print data for each variant
	    #----------------------------------------
	    print join("\t", $phv_gene, $phv_rank, $phv_score, $phv_prior,
		       $vaast_rank, $vaast_score, $vaast_pval, $gnomad_cmlt_af,
		       $var_key, $var_type, $var_score, $het_gt_txt,
		       $hom_gt_txt, $nc_gt_txt);
	    print "\n";
	    print '';
	}
    }
}
