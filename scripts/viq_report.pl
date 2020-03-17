#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;

use lib "$ENV{HOME}/artemisia/lib/";
use Arty::vIQ;
use Arty::PED;

#-----------------------------------------------------------------------------
#----------------------------------- MAIN ------------------------------------
#-----------------------------------------------------------------------------

my $usage = "

Synopsis:

viq_benchmark_report.pl --hpo_source CT --viq_opts stdn family_genes_files.txt

Description:

A script to produce summary tables and statistics for the vIQ
benchmarking project.  The single command line argument is a
two column tab-delimited file with the following columns.

      1) A Kindred ID for each family in the test data.

      2) A gene name (or regular expression to match multiple gene
         names) for genes designated as diagnostic for the proband.

Options:

  --ped, -p

    Peidgree file with all families.

  --viq_class, -c

    Use to process viq_singleton and viq_nosv class runs.

  --hpo_source, -h

    The HPO source file used for the VIQ analysis (CT, Manual, Root,
    RndSet, RndTerm)

  --viq_opts, -v stdn

    The viq_opts flag to use (see snakemakes config.yaml in this
    workflow).

  --first_hit, -f

    Only print the first matching gene hit per sample.

  --first_hit_sv, s

    Only print the first matching hit for gene or variant.  For cases
    where the same variant is hitting multiple genes (e.g. SVs) this
    will only print the first, but allow multiple hits for the same
    gene as long as it's a different variant (coumpound hets).

";

my ($help, $ped_file, $viq_class, $hpo_source, $viq_opts, $first_hit,
    $first_hit_var);

my $opt_success = GetOptions('help'            => \$help,
			     'ped|p=s'         => \$ped_file,
			     'viq_class|c=s'   => \$viq_class,
			     'hpo_source|h=s'  => \$hpo_source,
			     'viq_opts|v=s'    => \$viq_opts,
			     'first_hit|f'     => \$first_hit,
			     'first_hit_var|a' => \$first_hit_var,
    );

die $usage if $help || ! $opt_success;

my $file = shift @ARGV;

die "$usage\n\nFATAL : missing_family_gene_file\n" unless $file;
die "$usage\n\nFATAL : missing_file\n" unless $ped_file;

my %ped_data;
my $ped = Arty::PED->new(file => $ped_file);

while (my $record = $ped->next_record) {
    print '';
    my $kindred = $record->{kindred};
    my $sample  = $record->{sample};
    my $father  = $record->{father};
    my $mother  = $record->{mother};
    my $sex     = $record->{sex};
    my $pheno   = $record->{phenotype};
    # $ped_data{graph}{$kindred}{$sample}{father} = $father if $father;
    # $ped_data{graph}{$kindred}{$sample}{mother} = $mother if $mother;
    # $ped_data{data}{$kindred}{$sample} = $record;

    if ($ped_data{$kindred}{samples}{$sample}++ > 1) {
	print STDERR "WARN : sample_id_seen_before_in_family : $kindred $sample\n";
    }
    if ($record->{father} ne '0') {
    	$ped_data{$kindred}{father} = $father;
	$ped_data{$kindred}{children}{$sample}++;
    }
    if ($record->{mother} ne '0') {
    	$ped_data{$kindred}{mother} = $mother;
	$ped_data{$kindred}{children}{$sample}++;
    }

    if ($record->{phenotype} eq '2') {
    	$ped_data{$kindred}{affected}{$sample}++;
    	$ped_data{$kindred}{affected_count}++
    }
    elsif ($record->{phenotype} eq '1') {
    	$ped_data{$kindred}{unaffected}{$sample}++;
    	$ped_data{$kindred}{unaffected_count}++
    }    
    $ped_data{$kindred}{samples}{$sample} = $record;
    print '';
}    

my %ped_summary;
for my $kindred (keys %ped_data) {
    my $fam = $ped_data{$kindred};
    my $father = $fam->{father};
    my $mother = $fam->{mother};
    my $samples = $fam->{samples};
    
    my @member_types;
    my $child_count = 0;
  SAMPLE:
    for my $sample (sort {$fam->{samples}{$b}{phenotype} <=> $fam->{samples}{$a}{phenotype}} keys %{$samples}) {
	# Skip the parents here and process them separately below
	next SAMPLE if exists $fam->{father} && $fam->{father} eq $sample;
	next SAMPLE if exists $fam->{mother} && $fam->{mother} eq $sample;
	my $child_type = ++$child_count > 1 ? 'S' : 'P';
	push @member_types, ($fam->{samples}{$sample}{phenotype} == 2 ? "${child_type}2" :
			     $fam->{samples}{$sample}{phenotype} == 1 ? '${child_type}1' :
			     '${child_type}0');
  }
    if (exists $fam->{father}) {
	push @member_types, ($fam->{samples}{$fam->{father}}{phenotype} == 2 ? 'F2' :
			     $fam->{samples}{$fam->{father}}{phenotype} == 1 ? 'F1' :
			     'F0');
  }
    else {
	push @member_types, 'F-';
  }
    
    if (exists $fam->{mother}) {
	push @member_types, ($fam->{samples}{$fam->{mother}}{phenotype} == 2 ? 'M2' :
			     $fam->{samples}{$fam->{mother}}{phenotype} == 1 ? 'M1' :
			     'M0');
  }
    else {
	push @member_types, 'M-';
  }
    
    
    $ped_summary{$kindred} = join ':', @member_types;
}
print '';
    
my %fam_gene_data;
open(my $FAM, '<', $file) or
    die "FATAL : cant_open_file_for_reading : $file\n";

 FAMILY:
    while (my $line = <$FAM>) {
	chomp $line;
	next FAMILY unless $line;
	next FAMILY if $line =~ /^\#/;
	my ($fam_id, $gene_pattern) = split /\t/, $line;
	$fam_gene_data{$fam_id}{gene} = $gene_pattern;
	# "VIQ/viq.CT.219954.output.txt"
	$fam_gene_data{$fam_id}{file} = "VIQ/viq_{class}.{hpo_source}.{viq_opts}.$fam_id.output.txt";

	if ($hpo_source) {
	    $fam_gene_data{$fam_id}{file} =~ s/\{hpo_source\}/$hpo_source/;
	}
	else {
	    $fam_gene_data{$fam_id}{file} =~ s/\.\{hpo_source\}//;
	}

	if ($viq_opts) {
	    $fam_gene_data{$fam_id}{file} =~ s/\{viq_opts\}/$viq_opts/;
	}
	else {
	    $fam_gene_data{$fam_id}{file} =~ s/\.\{viq_opts\}//;
	}

	if ($viq_class) {
	    # viq_singleton.CT.204560.output.txt
	    $fam_gene_data{$fam_id}{file} =~ s/\{class\}/$viq_class/;
	}
	else {
	    $fam_gene_data{$fam_id}{file} =~ s/_\{class\}//;
	}
}

print join "\t", qw(ID
    Rady_Gene
    GEM_RANK
    GEM_SCORE
    Hit_Count
    ClinVar
    VAR_Type
    GEM_Ihr
    Parental_GT
    Fam_Type);

print "\n";

 FAM_DATA:
for my $fam_id (keys %fam_gene_data) {
    my $gene_pattern     = $fam_gene_data{$fam_id}{gene};
    my $viq_file = $fam_gene_data{$fam_id}{file};

    my $viq1 = Arty::vIQ->new(file => $viq_file);
    my $candidate_count  = 0;
    my %seen_vid;
    my %seen_gene;
    my $fam_type = $ped_summary{$fam_id};
    # Count candidate genes
  RECORD1:
    while (my $record = $viq1->next_record) {
	next RECORD1 if $record->{clinvar} =~ /\*/;    # Unless incendental
	next RECORD1 if $seen_gene{$record->{gene}}++; # Unless seen gene
	next RECORD1 if $seen_vid{$record->{vid}}++;   # Unless seen variant
	last RECORD1 if $record->{viqscr} < 1;         # End
	$candidate_count++;
  }

    # $candidate_count ||= 1;

    my $viq = Arty::vIQ->new(file => $viq_file);    
    my $gene_rank = 1;
    %seen_vid  = ();
    %seen_gene = ();
    my %variant_rank;
    my $found_target = 0;
  RECORD:
    while (my $record = $viq->next_record) {
	my $is_target = 0;
	if ($record->{gene} =~ /\b($gene_pattern)\b/) {
	    my $rady_gene = $1;

	    $is_target++;
	    $found_target++;
	    $variant_rank{$record->{vid}} ||= $gene_rank;
	    $record->{par} ||= '-';
	    
	    print join "\t", ($fam_id,             	     # ID
			      $rady_gene,          	     # Rady_Gene
			      $variant_rank{$record->{vid}}, # GEM_RANK
			      $record->{viqscr},   	     # GEM_SCORE
			      $candidate_count,    	     # Hit_Count
			      $record->{clinvar},  	     # ClinVar
			      $record->{type},     	     # VAR_Type
			      $record->{p_mod},    	     # GEM_Ihr
			      $record->{par},      	     # Parental_GT
			      $fam_type,           	     # Famiily Type code
		);
	    
	    print "\n";
	    print '';
	    next FAM_DATA if $first_hit;
	    next FAM_DATA if $first_hit_var && $seen_vid{$record->{vid}} >= 1;
	}

	# Increment gene rank
	if ($record->{clinvar} !~ /\*/          &&   # unless incendental
	    ! $seen_gene{$record->{gene}}++ > 0 &&   # see this gene before
	    ! $seen_vid{$record->{vid}}++       &&   # unless seen this vid before
	    ! $is_target                             # unless is target gene
	    ) {
	    $gene_rank++;
	}
  }
    if (! $found_target) {
	print join "\t", ($fam_id,           # ID
			  $gene_pattern,     # Rady_Gene
			  'N/A',             # GEM_RANK
			  0,                 # GEM_SCORE
			  $candidate_count,  # Hit_Count
			  'NULL',            # ClinVar
			  'NULL',            # VAR_Type
			  'NULL',            # GEM_Ihr
			  'NULL',            # Parental_GT
			  $fam_type,         # Famiily Type code
	    );
	print "\n";
	print '';
  }
}
