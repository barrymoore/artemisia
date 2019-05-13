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
use Cirque::TableFilter;

#-----------------------------------------------------------------------------
#----------------------------------- MAIN ------------------------------------
#-----------------------------------------------------------------------------

my $usage = "

Synopsis:

vaast_report_generator.pl           \
    --phevor       phevor.txt       \
    --gnomad       gnomad.vcf.gz    \
    output.vaast

vaast_report_generator.pl --config config.yaml

Description:

Generate detailed reports for VAAST runs that incorporates data from a
variety of sources.

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

my ($data, $columns) = prep_data($phevor, $vaast);

my $table = Cirque::TableFilter->new(data    => $data,
				     columns => $columns);

print $table->build_table;
print "\n";
print '';

#-----------------------------------------------------------------------------
#-------------------------------- SUBROUTINES --------------------------------
#-----------------------------------------------------------------------------

sub prep_data {

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
    # Prep columns
    #----------------------------------------
    my @columns = qw(gene phv_rank phvr_score phv_prior
                     vaast_rank vaast_score vaast_pval 
                     gnomad_cmlt_af variant
                     type score het hom nc);

    #----------------------------------------
    # Loop Phevor data
    #----------------------------------------
    my @data;
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
	# Format floating points
	#----------------------------------------
	$phv_score = sprintf '%.3g', $phv_score;
	map {$_ =  sprintf '%.2g', $_} ($phv_prior, $vaast_pval);

	#----------------------------------------
	# Add HTML formatting (gene annotations)
	#----------------------------------------

	# Phv_Gene
	#--------------------
	$phv_gene = "<a href=\"https://www.genecards.org/cgi-bin/carddisp.pl?gene=$phv_gene\">$phv_gene</a>";
	
	# Phv_Rank
	#--------------------
	if ($phv_rank <= 10) {
	    $phv_rank = [$phv_rank, {bgcolor => 'LightGreen'}];
	}
	elsif ($phv_rank <= 30) {
	    $phv_rank = [$phv_rank, {bgcolor => 'LightYellow'}];
	}
	else {
	    $phv_rank = [$phv_rank, {bgcolor => 'LightCoral'}];
	}
	
	# Phevor_Score
	#--------------------
	if ($phv_score >= 2.3) {
	    $phv_score = [$phv_score, {bgcolor => 'LightGreen'}];
	}
	elsif ($phv_score >= 1) {
	    $phv_score = [$phv_score, {bgcolor => 'LightYellow'}];
	}
	else {
	    $phv_score = [$phv_score, {bgcolor => 'LightCoral'}];
	}
	
	# Phv_Prior
	#--------------------
	if ($phv_prior >= .75) {
	    $phv_prior = [$phv_prior, {bgcolor => 'LightGreen'}];
	}
	elsif ($phv_prior >= 0.5) {
	    $phv_prior = [$phv_prior, {bgcolor => 'LightYellow'}];
	}
	else {
	    $phv_prior = [$phv_prior, {bgcolor => 'LightCoral'}];
	}
	
	# Vaast_Rank
	#--------------------
	if ($vaast_rank <= 25) {
	    $vaast_rank = [$vaast_rank, {bgcolor => 'LightGreen'}];
	}
	elsif ($vaast_rank <= 100) {
	    $vaast_rank = [$vaast_rank, {bgcolor => 'LightYellow'}];
	}
	else {
	    $vaast_rank = [$vaast_rank, {bgcolor => 'LightCoral'}];
	}
	
	# Vaast_Score
	#--------------------
	if ($vaast_score >= 10) {
	    $vaast_score = [$vaast_score, {bgcolor => 'LightGreen'}];
	}
	elsif ($vaast_score >= 5) {
	    $vaast_score = [$vaast_score, {bgcolor => 'LightYellow'}];
	}
	else {
	    $vaast_score = [$vaast_score, {bgcolor => 'LightCoral'}];
	}
	
	# VAAST p-value
	#--------------------
	if ($vaast_pval <= 0.001) {
	    $vaast_pval = [$vaast_pval, {bgcolor => 'LightGreen'}];
	}
	elsif ($vaast_pval <= 0.01) {
	    $vaast_pval = [$vaast_pval, {bgcolor => 'LightYellow'}];
	}
	else {
	    $vaast_pval = [$vaast_pval, {bgcolor => 'LightCoral'}];
	}
	    
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
	    # Format floating points
	    #----------------------------------------
	    $gnomad_cmlt_af =  sprintf '%.2g', $gnomad_cmlt_af;
	    
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
	    # Prep genotype data
	    #----------------------------------------
	    my $het_gt_txt = join '|', @{$gt_data{HET}};
	    my $hom_gt_txt = join '|', @{$gt_data{HOM}};
	    my $nc_gt_txt  = join '|', @{$gt_data{NC}};
	    $het_gt_txt ||= '.';
	    $hom_gt_txt ||= '.';
	    $nc_gt_txt  ||= '.';

	    #----------------------------------------
	    # Add HTML formatting (var annotations)
	    #----------------------------------------
	    
	    # Gnomad_Cmlt_AF
	    #--------------------
	    if ($gnomad_cmlt_af <= 0.0001) {
		$gnomad_cmlt_af = [$gnomad_cmlt_af, {bgcolor => 'LightGreen'}];
	    }
	    elsif ($gnomad_cmlt_af <= 0.01) {
		$gnomad_cmlt_af = [$gnomad_cmlt_af, {bgcolor => 'LightYellow'}];
	    }
	    else {
		$gnomad_cmlt_af = [$gnomad_cmlt_af, {bgcolor => 'LightCoral'}];
	    }
	
	    # Var_Type
	    #--------------------
	    if ($var_type eq 'SNV') {
		$var_type = [$var_type, {bgcolor => 'LightGreen'}];
	    }
	    else {
		$var_type = [$var_type, {bgcolor => 'LightYellow'}];
	    }
	    
	    # Var_Score
	    #--------------------
	    if ($var_score >= 8) {
		$var_score = [$var_score, {bgcolor => 'LightGreen'}];
	    }
	    elsif ($var_score >= 2) {
		$var_score = [$var_score, {bgcolor => 'LightYellow'}];
	    }
	    else {
		$var_score = [$var_score, {bgcolor => 'LightCoral'}];
	    }
	    
	    # NC_GT_TXT
	    #--------------------
	    if ($nc_gt_txt eq '.') {
		$nc_gt_txt = [$nc_gt_txt, {bgcolor => 'LightGreen'}];
	    }
	    else {
		$nc_gt_txt = [$nc_gt_txt, {bgcolor => 'LightCoral'}];
	    }
	    
	    #----------------------------------------
	    # Print data for each variant
	    #----------------------------------------
	    push @data, [$phv_gene, $phv_rank, $phv_score, $phv_prior,
			 $vaast_rank, $vaast_score, $vaast_pval, $gnomad_cmlt_af,
			 $var_key, $var_type, $var_score, $het_gt_txt,
			 $hom_gt_txt, $nc_gt_txt];
	}
    }
    return (\@data, \@columns);
}
