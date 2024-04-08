#!/usr/bin/env perl
use strict;
use warnings;
use Getopt::Long;

#-----------------------------------------------------------------------------
#----------------------------------- MAIN ------------------------------------
#-----------------------------------------------------------------------------
my $usage = "

Synopsis:

format_clinvar_gnomad.pl --ids clinvar_filtered.CLNID.txt \
      clinvar_gnomad_primary_data.tsv > clinvar_gnomad_formatted.tsv

Description:

A script to reformat Clinvar/Gnomad data for consumption by vIQ and to
optionally limit the Clinvar variants to a given list of approved
variants.

Script originally came from Projects/22-10-08_vIQ_CLNREVSTAT

### Get current ClinVar data

```
wget https://ftp.ncbi.nlm.nih.gov/pub/clinvar/vcf_GRCh37/clinvar_20230826.vcf.gz
wget https://ftp.ncbi.nlm.nih.gov/pub/clinvar/vcf_GRCh37/clinvar_20230826.vcf.gz.tbi
```

### Add Gnomad data to ClinVar

```
nohup vcfanno -p 4 vcfanno.conf clinvar_20230826.vcf.gz > clinvar_20230826_GNOMAD.vcf 2> clinvar_20230826_GNOMAD.error &
```

### Create ClinVar/Gnomad data file

```
bcftools query -f '%CHROM\t%POS\t%END\t%REF\t%ALT\t%ID\t%GENEINFO\t%CLNDN\t%CLNVC\t%MC\t%CLNSIG\t%CLNREVSTAT\t%gnomad_AF_afr\t%gnomad_AF_amr\t%gnomad_AF_as\
j\t%gnomad_AF_eas\t%gnomad_AF_fin\t%gnomad_AF_nfe\t%gnomad_AF_oth\t%gnomad_AF\n' clinvar_20230826_GNOMAD.vcf.gz > clinvar_gnomad_primary_data_20230826.tsv
./format_clinvar_gnomad.pl clinvar_gnomad_primary_data.tsv > clinvar_gnomad_formatted_20230826.tsv
```

### Format Clinvar/Gnomad data file

```
./format_clinvar_gnomad.pl --ids clinvar_filtered_20230629.CLNID.txt clinvar_gnomad_primary_data_20230826.tsv > clinvar_gnomad_formatted_20230826.tsv
```

";

my ($help, $id_file);
my $opt_success = GetOptions('help'    => \$help,
                             'ids|i=s' => \$id_file,
                            );

die $usage if ! $opt_success;
print $usage if $help;

my $file = shift;
die $usage unless $file;

my %ids;
if ($id_file) {
        open (my $IDS, '<', $id_file) or die "FATAL : cant_open_file_for_reading : $id_file\n$!\n";
      ID_LINE:
        while (my $id = <$IDS>) {
                chomp $id;
                $ids{$id}++;
        }
}

open (my $IN, '<', $file) or die "FATAL : cant_open_file_for_reading : $file\n$!\n";

my @cols = qw/chrom pos end ref alt id geneinfo clndn clnvc mc
    clnsig clnrevstat gnomad_afr gnomad_amr gnomad_asj
    gnomad_eas gnomad_fin gnomad_nfe gnomad_oth
    gnomad_af/;

print join "\t", @cols[0..11], 'gnomad_afs';
print "\n";

LINE:
while (my $line = <$IN>) {

    # bcftools query -f
    # '%CHROM\t%POS\t%END\t%REF\t%ALT\t%ID\t%GENEINFO\t%CLNDN\t%CLNVC\t%MC\t%CLNSIG\t%CLNREVSTAT\t
    # '%gnomad_AF_afr:%gnomad_AF_amr:%gnomad_AF_asj:%gnoma_AF_eas:%gnomad_AF_fin:%gnomad_AF_nfe:
    # '%gnomad_AF_oth:%gnomad_AF'

    chomp $line;

    my %record;

    @record{@cols} = split /\t/, $line;

    if ($id_file) {
            if ($ids{$record{id}}) {

            }
            else {
                    next LINE;
            }
    }

    my ($crs_rank, $crs_code);

    my $revstat = $record{'clnrevstat'};

    # 6	4	30	guide	practice_guideline
    # 5	3	10505	panel	reviewed_by_expert_panel
    # 4	2	100623	multi	criteria_provided_multiple_submitters_no_conflicts
    # 3	1	470387	singl	criteria_provided_single_submitter
    # 2	1	33472	cnflt	criteria_provided_conflicting_interpretations
    # 1	0	44380	nocrt	no_assertion_criteria_provided
    # 0	0	11284	noasr	no_assertion_provided
    # 0	0	539	nifsv	no_interpretation_for_the_single_variant
    if ($revstat eq 'practice_guideline') {
	$crs_rank = 6;
	$crs_code = 'guide';
    }
    elsif ($revstat eq 'reviewed_by_expert_panel') {
	$crs_rank = 5;
	$crs_code = 'panel';
    }
    elsif ($revstat eq 'criteria_provided,_multiple_submitters,_no_conflicts') {
	$crs_rank = 4;
	$crs_code = 'multi';
    }
    elsif ($revstat eq 'criteria_provided,_single_submitter') {
	$crs_rank = 3;
	$crs_code = 'single';
    }
    elsif ($revstat eq 'criteria_provided,_conflicting_interpretations') {
	$crs_rank = 2;
	$crs_code = 'cnflt';
    }
    elsif ($revstat eq 'no_assertion_criteria_provided') {
	$crs_rank = 1;
	$crs_code = 'nocrt';
    }
    elsif ($revstat eq 'no_assertion_provided') {
	$crs_rank = 0;
	$crs_code = 'noasr';
    }
    elsif ($revstat eq 'no_interpretation_for_the_single_variant') {
	$crs_rank = 0;
	$crs_code = 'nifsv';
    }
    else {
	die "FATAL : cant_parse_clnrevstat : ($revstat) $line\n";
    }

    $record{'clnrevstat'} = join ':', $crs_rank, $crs_code;

    $record{'gnomad_fmt'} = 
	join ':', @record{qw/gnomad_amr gnomad_afr gnomad_fin
			     gnomad_nfe gnomad_eas gnomad_asj
			     gnomad_oth gnomad_af/};

    print join "\t", @record{qw/chrom pos end ref alt id geneinfo
				clndn clnvc mc clnsig clnrevstat
				gnomad_fmt/};
    print "\n";
}
