#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;

use File::Path qw(make_path);
use FindBin;
use lib "$FindBin::RealBin/../lib";

use Arty::VAAST;
use Arty::Phevor;
use Arty::VCF;
use Arty::Utils qw(:all);
use Cirque::DataTable;

#-----------------------------------------------------------------------------
#----------------------------------- MAIN ------------------------------------
#-----------------------------------------------------------------------------

my $usage = "

Synopsis:

vaast_report_generator.pl      \
    --title     'Project Name' \
    --vcf       samples.vcf.gz \
    --gnomad    gnomad.vcf.gz  \
    --base_name html_files_dir \
    --id_map    id_map.txt     \
    --bam_dir /path/to/bams/   \
    output.vaast               \
    phevor.txt

Description:

Generate detailed reports for VAAST/Phevor runs that incorporates data from a
variety of sources.

Positional Arguments:

1) A VAAST2 full output file

2) A Phevor output file created by running the 'simple' version of
   file the VAAST file in #1 above, through Phevor with appropriate
   HPO terms.

Options:

  --title, -p

    A text string to be used as page titles etc.

  --vcf, -v

    A VCF file containing the target samples.

  --gnomad, -g

    A tabix-indexed Gnomad VCF file.

  --base_name, -b

    The directory name (or path) where gene and variant HTML files
    will be placed.

  --id_map, -i

    Provide a two-column, tab-delimited file with the following
    columns.

    1) CDR Index: the 0-based integer index for the individual in the
       CDR file.
    2) Sample_ID: A sample ID that corresponds to the Sample ID in the
       target VCF file.

    The id_map file can be made with:
      `grep FILE-INDEX cases.cdr | cut -f 3,4 > id_map.txt

  --bam_dir, -a

    Path to BAM files for use in makeing IGV snapshots.

";

my $CL = join ' ', $0, @ARGV;

my ($help, %data);

my $opt_success = GetOptions('help'          => \$help,
                             'title|p=s'     => \$data{title},
                             'vcf|v=s'       => \$data{vcf_file},
                             'gnomad|g=s'    => \$data{gnomad_file},
                             'base_name|b=s' => \$data{base_name},
                             'id_map|i=s'    => \$data{id_map},
                             'bam_dir|a=s'   => \$data{bam_dir},
    );

die $usage if $help || ! $opt_success;

$data{title} ||= 'VAAST Phevor Report';

@data{qw(vaast_file phevor_file)} = @ARGV;

if (! $data{vaast_file}) {
    die "$usage\n\nFATAL : missing_vaast_file : $CL\n";
}
if (! $data{phevor_file}) {
    die "$usage\n\nFATAL : missing_phevor_file : $CL\n";
}

$data{rel_base} = $data{base_name};
$data{rel_base} =~ s|.*\/||;

$data{vaast_data}  = Arty::VAAST->new(file   => $data{vaast_file},
                                      scored => 1);

$data{phevor_data} = Arty::Phevor->new(file => $data{phevor_file});

my %ID_MAP;
if ($data{id_map}) {
    open(my $IN, '<', $data{id_map}) or
        die "FATAL : cant_open_file_for_reading : $data{id_map}\n";
  LINE:
    while (my $line = <$IN>) {
        chomp $line;
        my ($idx, $sample_id) = split /\t/, $line;
        $ID_MAP{$idx} = $sample_id;
    }
    close $IN;
}

make_path($data{base_name});

process_data(\%data);

my $filename = $data{base_name} . '.html';

open(my $OUT, '>', $filename)
    or die "FATAL : cant_open_file_for_writing : $filename\n";


print $OUT build_table(\%data);
print $OUT "\n";
close $OUT;

#-----------------------------------------------------------------------------
#-------------------------------- SUBROUTINES --------------------------------
#-----------------------------------------------------------------------------

sub build_table {

  my $data = shift @_;

  my $html;
  #----------------------------------------
  # HTML page header
  #----------------------------------------
  $html  = "<!DOCTYPE html>\n";
  $html .= "<html>\n";
  $html .= "  <head>\n";
  $html .= "    <title>$data->{title}</title>\n";
  $html .= "    <link rel=\"stylesheet\" type=\"text/css\" href=\"https://cdn.datatables.net/1.10.19/css/jquery.dataTables.min.css\">\n";
  $html .= "    <link rel=\"stylesheet\" type=\"text/css\" href=\"https://cdn.datatables.net/fixedheader/3.1.5/css/fixedHeader.dataTables.min.css\">\n";
  $html .= "\n";
  $html .= "    <script src=\"https://code.jquery.com/jquery-3.4.1.js\"></script>\n";
  $html .= "    <script src=\"https://code.jquery.com/ui/1.12.1/jquery-ui.js\"></script>\n";
  $html .= "    <script src=\"https://cdn.datatables.net/1.10.19/js/jquery.dataTables.min.js\"></script>\n";
  $html .= "    <script src=\"https://cdn.datatables.net/fixedheader/3.1.5/js/dataTables.fixedHeader.min.js\"></script>\n";
# $html .= "    <script>\n";
# $html .= "      \$(function() {\n";
# $html .= "        \$(document).tooltip();\n";
# $html .= "      });\n";
# $html .= "    </script>\n";
  $html .= "\n";
  $html .= "    <script>\n";
  $html .= "      \$(document).ready(function() {\n";
  $html .= "        \$('#datatable').DataTable({\n";
  $html .= "          fixedHeader: true,\n";
  $html .= "          order : [[1, 'asc'], [4, 'asc']],\n";
  $html .= "          pageLength : 25,\n";
  $html .= "          });\n";
  $html .= "      });\n";
  $html .= "    </script>\n";
  $html .= "\n";
  $html .= "    <style>\n";
  $html .= "    label {\n";
  $html .= "      display: inline-block;\n";
  $html .= "      width: 5em;\n";
  $html .= "    }\n";
  $html .= "    </style>\n";
  $html .= "  </head>\n";
  $html .= "  <body>\n";
  $html .= "\n";
  $html .= "    <h1 style=\"text-align: center;\">$data->{title}</h1>\n";
  $html .= "    <h2 style=\"text-align: center;\">VAAST/Phevor Analysis Report</h2>\n";
  $html .= "\n";
  #----------------------------------------
  # Start table
  #----------------------------------------
  $html .= "    <table id=\"datatable\" class=\"display\" style=\"width:90%\">\n";
  $html .= "\n";
  #----------------------------------------
  # Add header row
  #----------------------------------------
  $html .= "      <thead>\n";
  $html .= "        <tr>\n";
  for my $column_head (@{$data->{columns}}) {
    $html .= "      <th>$column_head</th>\n";
  }
  $html .= "        </tr>\n";
  $html .= "      </thead>\n";

  #----------------------------------------
  # Add data rows
  #----------------------------------------
  $html .= "      <tbody>\n";
  for my $row (@{$data->{row_data}}) {
      $html .= "      <tr>\n";

      #----------------------------------------
      # Add each column
      #----------------------------------------
      for my $cell_data (@{$row}) {

          #----------------------------------------
          # Prep cell data
          #----------------------------------------
          my ($cell_text, $cell_format);
          if (ref $cell_data eq 'ARRAY') {
              ($cell_text, $cell_format) = @{$cell_data};
          }
          else {
              $cell_text = $cell_data;
          }
          $cell_text = ! defined $cell_text ? '' : $cell_text;
          $cell_format = ! defined $cell_format ? '' : $cell_format;

          #----------------------------------------
          # Prep cell format
          #----------------------------------------
          my $td_tag;
          if ($cell_format) {
              $td_tag = '<td ';
              my @cell_attrbs;
              for my $attrb (keys %{$cell_format}) {
                  my $attrb_value = $cell_format->{$attrb};
                  push @cell_attrbs, "${attrb}=\"$attrb_value\"";
              }
              $td_tag .= join ' ', @cell_attrbs;
              $td_tag .= '>';
          }
          else {
              $td_tag = '<td>';
          }
          $html .= "        ${td_tag}${cell_text}</td>\n";
      }
      $html .= "        </tr>\n"
  }

  $html .= "\n";
  #----------------------------------------
  # Add footer row
  #----------------------------------------
  $html .= "      <tfoot>\n";
  $html .= "        <tr>\n";
  for my $column_head (@{$data->{columns}}) {
    $html .= "      <th>$column_head</th>\n";
  }
  $html .= "        </tr>\n";
  $html .= "      </tfoot>\n";

  #----------------------------------------
  # End Table
  #----------------------------------------
  $html .= "      </tbody>\n";
  $html .= "    </table>\n";
  $html .= "\n";
  $html .= "\n";
  $html .= "  </body>\n";
  $html .= "</html>\n";
  $html .= "\n";

  return $html;
}

#-----------------------------------------------------------------------------

sub process_data {

    my ($data) = @_;

    my $vaast_data  = $data->{vaast_data};
    my $phevor_data = $data->{phevor_data};
    my $base_name   = $data->{base_name};

    #----------------------------------------
    # Map VAAST data to genes
    #----------------------------------------
    my %vaast_map;
    while (my $record = $vaast_data->next_record) {
        my $gene = $record->{gene};
        $vaast_map{$gene} = $record
            unless exists $vaast_map{$gene};
    }

    $data->{vaast_map} = \%vaast_map;

    #----------------------------------------
    # Prep columns
    #----------------------------------------
    $data->{columns} = ['Gene', 'Phevor Rank', 'Phevor Score',
		      'Phevor Prior', 'VAAST Rank', 'VAAST Score',
		      'VAAST Pval', 'Affected Count', 'No-call Count'];

    #----------------------------------------
    # Loop Phevor data
    #----------------------------------------

 GENE:
    while (my $phevor_record = $phevor_data->next_record) {
	
	# Clear any previous 'current' record data.
	my $crnt_gene = {};
	$data->{crnt_gene} = $crnt_gene;

	#----------------------------------------
	# Get Phevor data
	#----------------------------------------
	my ($phevor_rank, $phevor_gene, $phevor_score, $phevor_prior) =
	    @{$phevor_record}{qw(rank gene score prior orig_p)};
	$crnt_gene->{phevor_rank} = $phevor_rank + 1;

	#----------------------------------------
	# Skip boring data
	#----------------------------------------
	next GENE if $phevor_score <= 0;
	next GENE unless exists $vaast_map{$phevor_gene};

	#----------------------------------------
	# Get VAAST data
	#----------------------------------------
	my $vaast_record = $vaast_map{$phevor_gene};
	my ($vaast_rank, $vaast_gene, $vaast_feature, $vaast_score, $vaast_pval) = 
	    @{$vaast_record}{qw(rank gene feature_id score p_value)};
	$crnt_gene->{vaast_rank} = $vaast_rank + 1;;
	
	#----------------------------------------
	# Format floating points
	#----------------------------------------
	$phevor_score = sprintf '%.3g', $phevor_score;
	map {$_ =  sprintf '%.2g', $_} ($phevor_prior, $vaast_pval);

	#----------------------------------------
	# Add HTML formatting (gene annotations)
	#----------------------------------------

	# Phevor_Gene
	#--------------------
    	$crnt_gene->{phevor_gene_fmt} = "<a href=$data->{rel_base}/${phevor_gene}.html>$phevor_gene</a>";

	# Phevor_Rank
	#--------------------
	if ($phevor_rank <= 10) {
	    $crnt_gene->{phevor_rank_fmt} = 'background-color: LightGreen';
	}
	elsif ($phevor_rank <= 30) {
	    $crnt_gene->{phevor_rank_fmt} = 'background-color: LightYellow';
	}
	else {
	    $crnt_gene->{phevor_rank_fmt} = 'background-color: LightCoral';
	}

	# Phevor_Score
	#--------------------
	if ($phevor_score >= 2.3) {
	    $crnt_gene->{phevor_score_fmt} = 'background-color: LightGreen';
	}
	elsif ($phevor_score >= 1) {
	    $crnt_gene->{phevor_score_fmt} = 'background-color: LightYellow';
	}
	else {
	    $crnt_gene->{phevor_score_fmt} = 'background-color: LightCoral';
	}
	
	# Phevor_Prior
	#--------------------
	if ($phevor_prior >= .75) {
	    $crnt_gene->{phevor_prior_fmt} = 'background-color: LightGreen';
	}
	elsif ($phevor_prior >= 0.5) {
	    $crnt_gene->{phevor_prior_fmt} = 'background-color: LightYellow';
	}
	else {
	    $crnt_gene->{phevor_prior_fmt} = 'background-color: LightCoral';
	}

	# Vaast_Rank
	#--------------------
	if ($vaast_rank <= 25) {
	    $crnt_gene->{vaast_rank_fmt} = 'background-color: LightGreen';
	}
	elsif ($vaast_rank <= 100) {
	    $crnt_gene->{vaast_rank_fmt} = 'background-color: LightYellow';
	}
	else {
	    $crnt_gene->{vaast_rank_fmt} = 'background-color: LightCoral';
	}

	# Vaast_Score
	#--------------------
	if ($vaast_score >= 10) {
	    $crnt_gene->{vaast_score_fmt} = 'background-color: LightGreen';
	}
	elsif ($vaast_score >= 5) {
	    $crnt_gene->{vaast_score_fmt} = 'background-color: LightYellow';
	}
	else {
	    $crnt_gene->{vaast_score_fmt} = 'background-color: LightCoral';
	}

	# VAAST p-value
	#--------------------
	if ($vaast_pval <= 0.001) {
	    $crnt_gene->{vaast_pval_fmt} = 'background-color: LightGreen';
	}
	elsif ($vaast_pval <= 0.01) {
	    $crnt_gene->{vaast_pval_fmt} = 'background-color: LightYellow';
	}
	else {
	    $crnt_gene->{vaast_pval_fmt} = 'background-color: LightCoral';
	}
	    
	# Store current Phevor and VAAST records
	$crnt_gene->{phevor_record} = $phevor_record;
	$crnt_gene->{vaast_record}  = $vaast_record;

	#----------------------------------------
	# Preprocess all variant for current gene
	#----------------------------------------
	process_variant_data($data);

	#----------------------------------------
	# Create gene page
	#----------------------------------------
	create_gene_page($data);

	#----------------------------------------
	# Save data for each variant
	#----------------------------------------
	
	push @{$data->{row_data}}, [[$crnt_gene->{phevor_gene_fmt}],
				    [$phevor_rank,  {'style' => $crnt_gene->{phevor_rank_fmt}}],
				    [$phevor_score, {'style' => $crnt_gene->{phevor_score_fmt}}],
				    [$phevor_prior, {'style' => $crnt_gene->{phevor_prior_fmt}}],
				    [$vaast_rank,   {'style' => $crnt_gene->{vaast_rank_fmt}}],
				    [$vaast_score,  {'style' => $crnt_gene->{vaast_score_fmt}}],
				    [$vaast_pval,   {'style' => $crnt_gene->{vaast_pval_fmt}}],
				    [$crnt_gene->{affected_count}],
				    [$crnt_gene->{nc_count}]];       
	print '';
    }
    return;
}

#--------------------------------------------------------------------------------

sub process_variant_data {
    my ($data) = shift @_;

    #----------------------------------------
    # Get gene data
    #----------------------------------------
    my $crnt_gene = $data->{crnt_gene};

    #----------------------------------------
    # Get Phevor data
    #----------------------------------------
    my $phevor_record = $crnt_gene->{phevor_record};
    my $phevor_gene = $phevor_record->{gene};

    #----------------------------------------
    # Get VAAST data
    #----------------------------------------
    my $vaast_record = $crnt_gene->{vaast_record};
    my ($chrom, $vaast_rank, $vaast_gene, $vaast_feature, $vaast_score, $vaast_pval) =
        @{$vaast_record}{qw(chrom rank gene feature_id score p_value)};

  VAR:
    for my $var_key (sort {($vaast_record->{vars}{$b}{score}
			    <=> 
			    $vaast_record->{vars}{$a}{score})}
		     keys %{$vaast_record->{vars}}) {
	
	#----------------------------------------
	# Get current variant data
	#----------------------------------------
	my $var = $vaast_record->{vars}{$var_key};
	
	#----------------------------------------
	# Get data from current variant
	#----------------------------------------
	my ($chrom, $start) = split /:/, $var_key;
	my ($type, $ref_nt, $ref_aa, $alt_nt, $score)
	    = @{$var}{qw(type ref_nt ref_aa alt_nt score)};

	#----------------------------------------
	# Skip variants with 0 score
	#----------------------------------------
	next VAR if $score <= 0;
	
	#----------------------------------------
	# Build a formatted variant key.
	#----------------------------------------
	$var->{var_key} = join(':', $chrom, $start, $ref_nt);
	$var->{var_key_fmt} = $var->{var_key};
	$var->{var_key_fmt} =~ s/\-/ins/;
	$var->{var_key_fmt} =~ s/:/-/g;
	$var->{locus} = "${chrom}:${start}";
	
	#----------------------------------------
	# Create NT & AA genotype text strings
	#----------------------------------------
	my $gts = $var->{gts};
	for my $gt_key (keys %{$gts}) {
	    my $gt = $gts->{$gt_key};
	    my @ord_nts = grep {$_ eq $ref_nt} @{$gt->{gt_nt}};
	    push @ord_nts, sort grep {$_ ne $ref_nt} @{$gt->{gt_nt}};
	    my $nt_gt = join '|', @ord_nts;
	    push @{$vaast_record->{vars}{$var_key}{nt_gts}}, $nt_gt;
	    
	    my @ord_aas = grep {$_ eq $ref_aa} @{$gt->{gt_aa}};
	    push @ord_aas, sort grep {$_ ne $ref_aa} @{$gt->{gt_aa}};
	    my $aa_gt = join '|', @ord_aas;
	    push @{$vaast_record->{vars}{$var_key}{aa_gts}}, $aa_gt;
	}
	$vaast_record->{vars}{$var_key}{nt_gt_txt} =
	    join ', ', grep {$_ ne '^|^'} @{$vaast_record->{vars}{$var_key}{nt_gts}};
	$vaast_record->{vars}{$var_key}{aa_gt_txt} =
	    join ', ', grep {$_ ne '^|^'} @{$vaast_record->{vars}{$var_key}{aa_gts}};

	#----------------------------------------
	# Get Gnomad AF for variant
	#----------------------------------------
	my $gnomad_vcf = Arty::VCF->new(file  => $data->{gnomad_file},
					tabix => "$chrom:${start}-${start}");
	while (my $gnmd_record = $gnomad_vcf->next_record) {
	    $var->{gnomad_cmlt_af} += $gnmd_record->{info}{AF}[0];
	}
	
	$var->{gnomad_cmlt_af} ||= 0;
	
	#----------------------------------------
	# Format floating points
	#----------------------------------------
	$var->{gnomad_cmlt_af} =  sprintf '%.2g', $var->{gnomad_cmlt_af};
	
	#---------------------------------------
	# Loop genotype data
	#----------------------------------------
	$var->{gt_data} = {NC  => [],
			   HOM => [],
			   HET => []};
	
	for my $gt_key (sort keys %{$var->{gc}}) {
	    
	    #---------------------------------------
	    # Get genotype count data
	    #----------------------------------------
	    my $gt = $var->{gc}{$gt_key};
	    my $b_count = $gt->{B};
	    my $t_count = $gt->{T};
	    
	    #----------------------------------------
	    # Collect B & T count of each genotype
	    # by class (NC, HOM, HET)
	    #----------------------------------------
	    my ($A, $B) = split ':', $gt_key;
	    my $gt_txt = join ',', $gt_key, $b_count, $t_count;
	    if (grep {$_ eq '^'} ($A, $B)) {
		push @{$var->{gt_data}{NC}}, $gt_txt;
	    }
	    elsif ($A eq $B) {
		push @{$var->{gt_data}{HOM}}, $gt_txt;
	    }
	    else {
		push @{$var->{gt_data}{HET}}, $gt_txt;		    
	    }
	}
	
	#----------------------------------------
	# Prep genotype data
	#----------------------------------------
	$var->{het_gt_txt} = join '|', @{$var->{gt_data}{HET}};
	$var->{hom_gt_txt} = join '|', @{$var->{gt_data}{HOM}};
	$var->{nc_gt_txt}  = join '|', @{$var->{gt_data}{NC}};
	$var->{het_gt_txt} ||= '.';
	$var->{hom_gt_txt} ||= '.';
	$var->{nc_gt_txt}  ||= '.';
	
	#----------------------------------------
	# Create Affected Count
	#----------------------------------------
	
      GT:
        for my $gt (keys %{$var->{gc}}) {
                my $count = exists $var->{gc}{$gt}{T}
                  ? $var->{gc}{$gt}{T} : 0;
                if ($gt eq '^:^') {
                        $data->{crnt_gene}{nc_count} += $count;
                }
                else {
                        $data->{crnt_gene}{affected_count} += $count;
                }
        }
        $data->{crnt_gene}{nc_count} ||= 0;
        $data->{crnt_gene}{affected_count} ||= 0;

        print '';
}
    print '';
}

#--------------------------------------------------------------------------------

sub create_gene_page {
    my ($data) = shift @_;

    my $crnt_gene = $data->{crnt_gene};

    my $phevor_record = $crnt_gene->{phevor_record};
    my ($phevor_rank, $phevor_gene, $phevor_score, $phevor_prior) =
        @{$phevor_record}{qw(rank gene score prior orig_p)};

    my $vaast_record = $crnt_gene->{vaast_record};
    my ($chrom, $vaast_rank, $vaast_gene, $vaast_feature, $vaast_score, $vaast_pval) =
        @{$vaast_record}{qw(chrom rank gene feature_id score p_value)};

    $phevor_score = sprintf '%.3g', $phevor_score;
    map {$_ =  sprintf '%.2g', $_} ($phevor_prior, $vaast_pval);

    my $html;
    #----------------------------------------
    # Start Gene Page
    #----------------------------------------
    $html .= "<!DOCTYPE html>\n";
    $html .= "  <html>\n";
    $html .= "   <head>\n";
    $html .= "     <title>Page Title</title>\n";
    $html .= "     <link rel=\"stylesheet\" type=\"text/css\" href=\"https://cdn.datatables.net/1.10.19/css/jquery.dataTables.min.css\">\n";
    $html .= "     <script src=\"https://code.jquery.com/jquery-3.3.1.js\"></script>\n";
    $html .= "     <script src=\"https://cdn.datatables.net/1.10.19/js/jquery.dataTables.min.js\"></script>\n";
    $html .= "     <script>\n";
    $html .= "       \$(document).ready(function() {\n";
    $html .= "           \$('#datatable').DataTable({\n";
    $html .= "              searching: false,\n";
    $html .= "              info: false,\n";
    $html .= "              ordering: false,\n";
    $html .= "              paging: false,\n";
    $html .= "              });\n";
    $html .= "           \$('#vartable').DataTable({\n";
    $html .= "              order : [[3, 'dsc']],\n";
    $html .= "              pageLength: 25,\n";
    $html .= "              });\n";
    $html .= "       });\n";
    $html .= "     </script>\n";
    $html .= "   </head>\n";
    $html .= "  <body>\n";
    $html .= "\n";
    $html .= "    <h1 style=\"text-align: center;\">$data->{title}</h1>\n";
    $html .= "    <h2 style=\"text-align: center;\">$phevor_gene</h2>\n";
    #----------------------------------------
    # Gene Page - Gene Summary Table
    #----------------------------------------
    $html .= "    <table id=\"datatable\" class=\"display\" style=\"width:25%\">\n";
    $html .= "      <thead>\n";
    $html .= "        <tr>\n";
    $html .= "          <th>Key</th>\n";
    $html .= "          <th>Value</th>\n";
    $html .= "        </tr>\n";
    $html .= "      </thead>\n";
    $html .= "      <tbody>\n";
    $html .= "        <tr>\n";
    $html .= "          <th style='text-align: right'>Gene</th>\n";
    $html .= "          <td><a href=\"https://www.genecards.org/cgi-bin/carddisp.pl?gene=$phevor_gene\">$phevor_gene</a></td>\n";
    $html .= "        </tr>\n";
    $html .= "        <tr>\n";
    $html .= "          <th style='text-align: right'>Phevor Rank</th>\n";
    $html .= "          <td style='$crnt_gene->{phevor_rank_fmt}'>$phevor_rank</td>\n";
    $html .= "        </tr>\n";
    $html .= "        <tr>\n";
    $html .= "          <th style='text-align: right'>Phevor Score</th>\n";
    $html .= "          <td style='$crnt_gene->{phevor_score_fmt}'>$phevor_score</td>\n";
    $html .= "        </tr>\n";
    $html .= "        <tr>\n";
    $html .= "          <th style='text-align: right'>Phevor Prior</th>\n";
    $html .= "          <td style='$crnt_gene->{phevor_prior_fmt}'>$phevor_prior</td>\n";
    $html .= "        </tr>\n";
    $html .= "        <tr>\n";
    $html .= "          <th style='text-align: right'>VAAST Rank</th>\n";
    $html .= "          <td style='$crnt_gene->{vaast_rank_fmt}'>$vaast_rank</td>\n";
    $html .= "        </tr>\n";
    $html .= "        <tr>\n";
    $html .= "          <th style='text-align: right'>VAAST Score</th>\n";
    $html .= "          <td style='$crnt_gene->{vaast_score_fmt}'>$vaast_score</td>\n";
    $html .= "        </tr>\n";
    $html .= "        <tr>\n";
    $html .= "          <th style='text-align: right'>VAAST P-value</th>\n";
    $html .= "          <td style='$crnt_gene->{vaast_pval_fmt}'>$vaast_pval</td>\n";
    $html .= "        </tr>\n";
    $html .= "      </tbody>\n";
    $html .= "    </table>    \n";
    $html .= "\n";
    #----------------------------------------
    # Gene Page - Horizontal Rule
    #----------------------------------------
    $html .= "    <p></p>\n";
    $html .= "    <hr/>\n";
    $html .= "    <p></p>\n";
    $html .= "\n";
    #----------------------------------------
    # Gene Page - Variant Detail Table Head
    #----------------------------------------
    # 'Gnomad Cmlt AF', 'Variant Location', 'Variant Type',
    # 'Variant CLRT Score', 'NT GT', 'AA GT', 'Het', 'Hom', 'NC'
    $html .= "    <table id=\"vartable\" class=\"display\" style=\"width:90%\">\n";
    $html .= "      <thead>\n";
    $html .= "        <tr>\n";
    $html .= "    <th>Variant Key</th>\n";
    $html .= "    <th>Locus</th>\n";
    $html .= "    <th>Type</th>\n";
    $html .= "    <th>Variant CLRT Score</th>\n";
    $html .= "    <th>Gnomad AF</th>\n";
    $html .= "    <th>REF NT</th>\n";
    $html .= "    <th>NT Genotype</th>\n";
    $html .= "    <th>REF AA</th>\n";
    $html .= "    <th>AA Genotype</th>\n";
    $html .= "    <th>HET Genotype Count</th>\n";
    $html .= "    <th>HOM Genotype Count</th>\n";
    $html .= "    <th>No-call Genotype Count</th>\n";
    $html .= "        </tr>\n";
    $html .= "      </thead>\n";
    $html .= "      <tbody>\n";

  VAR:
    for my $var_key (keys %{$vaast_record->{vars}}) {

        #----------------------------------------
        # Set current variant data
        #----------------------------------------
        my $var = $vaast_record->{vars}{$var_key};

        #----------------------------------------
        # Skip variants with 0 score in main
        # table
        #----------------------------------------
        next VAR if $var->{score} <= 0;

        #----------------------------------------
        # Grab variant data
        #----------------------------------------
        my $var_href = "<a href=${phevor_gene}/$var->{var_key_fmt}.html>$var_key</a>";
        my $start = $var->{start};
        my $locus = $var->{locus};

        #----------------------------------------
        # Format score
        #----------------------------------------
        if ($var->{score} >= 3) {
            $var->{score_fmt} = 'background-color: LightGreen';
        }
        elsif ($var->{score} >= 1) {
            $var->{score_fmt} = 'background-color: LightYellow';
        }
        else {
            $var->{score_fmt} = 'background-color: LightCoral';
        }

        #----------------------------------------
        # Format gnomad_cmlt_af
        #----------------------------------------
        if ($var->{gnomad_cmlt_af} <= 0.001) {
            $var->{gnomad_cmlt_af_fmt} = 'background-color: LightGreen';
        }
        elsif ($var->{gnomad_cmlt_af} <= 0.01) {
            $var->{gnomad_cmlt_af_fmt} = 'background-color: LightYellow';
        }
        else {
            $var->{gnomad_cmlt_af_fmt} = 'background-color: LightCoral';
        }

        #----------------------------------------
        # Format HET/HOM/NC GT data
        #----------------------------------------
        my @het_data = split /,/, $var->{het_gt_txt};
        map{$het_data[$_] ||= 0} (0..2);
        my $het_gt_txt;
        if ($het_data[0] eq '.') {
            $het_gt_txt = $het_data[0];
        }
        else {
            $het_gt_txt = "B=$het_data[1] T=$het_data[2]";
        }

        my @hom_data = split /,/, $var->{hom_gt_txt};
        map{$hom_data[$_] ||= 0} (0..2);
        my $hom_gt_txt;
        if ($hom_data[0] eq '.') {
            $hom_gt_txt = $hom_data[0];
        }
        else {
            $hom_gt_txt = "B=$hom_data[1] T=$hom_data[2]";
        }

        my @nc_data = split /,/, $var->{nc_gt_txt};
        map{$nc_data[$_] ||= 0} (0..2);
        my $nc_gt_txt;
        if ($nc_data[0] eq '.') {
            $nc_gt_txt = $nc_data[0];
        }
        else {
            $nc_gt_txt = "B=$nc_data[1] T=$nc_data[2]";
        }

        #----------------------------------------
        # Gene Page - Variant Detail Table Rows
        #----------------------------------------
        $html .= "    <tr>\n";
        $html .= "      <td>$var_href</td>\n";
        $html .= ("      <td><a href=\"http://genome.ucsc.edu/cgi-bin/hgTracks?" .
                  "db=hg19&position=${chrom}%3A${start}-${start}\" " .
                  "target=\"_blank\">${locus}</a></td>\n");
        $html .= "      <td>$var->{type}</td>\n";
        $html .= "      <td style='$var->{score_fmt}'>$var->{score}</td>\n";
        $html .= "      <td style='$var->{gnomad_cmlt_af_fmt}'>$var->{gnomad_cmlt_af}</td>\n";
        $html .= "      <td>$var->{ref_nt}</td>\n";
        $html .= "      <td>$var->{nt_gt_txt}</td>\n";
        $html .= "      <td>$var->{ref_aa}</td>\n";
        $html .= "      <td>$var->{aa_gt_txt}</td>\n";
        $html .= "      <td>$het_gt_txt</td>\n";
        $html .= "      <td>$hom_gt_txt</td>\n";
        $html .= "      <td>$nc_gt_txt</td>\n";
        $html .= "    </tr>\n";

        #----------------------------------------
        # Create Variant Page & Write IGV Data
        #----------------------------------------

        $data->{crnt_var} = $var;
        create_variant_page($data);
    }

    #----------------------------------------
    # Gene Table - Finish Table
    #----------------------------------------
    $html .= "      </tbody>\n";
    $html .= "    </table>\n";
    $html .= "  </body>\n";
    $html .= "</html>\n";

    my $filename = join('/', $data->{base_name}, "${phevor_gene}.html");
    open(my $OUT, '>', $filename) ||
        die "FATAL : cant_open_file_for_writing : $filename\n";

    print $OUT $html;

    close $OUT;
}

#--------------------------------------------------------------------------------

sub create_variant_page {

    my $data = shift @_;

    #----------------------------------------
    # Get base level data
    #----------------------------------------
    my $base_name = $data->{base_name};

    #----------------------------------------
    # Get gene data
    #----------------------------------------
    my $crnt_gene = $data->{crnt_gene};
    
    #----------------------------------------
    # Get Phevor data
    #----------------------------------------
    my $phevor_record = $crnt_gene->{phevor_record};
    my $phevor_gene = $phevor_record->{gene};

    #----------------------------------------
    # Get VAAST data
    #----------------------------------------
    my $vaast_record = $crnt_gene->{vaast_record};
    my ($chrom, $vaast_rank, $vaast_gene, $vaast_feature, $vaast_score, $vaast_pval) = 
    	@{$vaast_record}{qw(chrom rank gene feature_id score p_value)};

    #----------------------------------------
    # Get variant data
    #----------------------------------------
    my $var = $data->{crnt_var};
    my ($var_key, $start, $type, $score, $ref_nt,
	$het_gt_txt, $hom_gt_txt, $nc_gt_txt, $nt_gt_txt, $ref_aa,
	$aa_gt_txt) = @{$var}{qw(var_key start type score ref_nt
	het_gt_txt hom_gt_txt nc_gt_txt nt_gt_txt ref_aa aa_gt_txt)};
    $nt_gt_txt =~ s/;/, /g;
    $aa_gt_txt =~ s/;/, /g;
    
    #----------------------------------------
    # Set up locus/region data
    #----------------------------------------
    my $range_locus =  "$chrom:$start-$start";
    my $roi       =  "$chrom:$start-" . ($start + 1);
    my $r_start   = $start - 150;
    my $r_end     = $start + 150;
    my $region    = "$chrom:$r_start-$r_end";
    my $locus     = $var->{locus};
    
    #----------------------------------------
    # Make dir paths
    #----------------------------------------
    my $path = "$base_name/${phevor_gene}";
    make_path($path);
    my $igv_path = "$base_name/igv_img";
    make_path($igv_path);

    #----------------------------------------
    # Format HET/HOM/NC GT data
    #----------------------------------------
    my @het_data = split /,/, $het_gt_txt;
    map{$het_data[$_] ||= 0} (0..2);
    if ($het_data[0] eq '.') {
	$het_gt_txt = $het_data[0];
    }
    else {
	$het_gt_txt = "$het_data[0] B=$het_data[1] T=$het_data[2]";
    }

    my @hom_data = split /,/, $hom_gt_txt;
    map{$hom_data[$_] ||= 0} (0..2);
    if ($hom_data[0] eq '.') {
	$hom_gt_txt = $hom_data[0];
    }
    else {
	$hom_gt_txt = "$hom_data[0] B=$hom_data[1] T=$hom_data[2]";
    }

    my @nc_data = split /,/, $nc_gt_txt;
    map{$nc_data[$_] ||= 0} (0..2);
    if ($nc_data[0] eq '.') {
	$nc_gt_txt = $nc_data[0];
    }
    else {
	$nc_gt_txt = "$nc_data[0] B=$nc_data[1] T=$nc_data[2]";
    }
    
    #----------------------------------------
    # Format variant key for use in filename
    #----------------------------------------
    my $var_key_fmt = $var_key;
    $var_key_fmt =~ s/\-/ins/;
    $var_key_fmt =~ s/:/-/g;

    my $html;
    #----------------------------------------
    # Start Variant Page
    #----------------------------------------
    $html .= "<!DOCTYPE html>\n";
    $html .= "  <html>\n";
    $html .= "   <head>\n";
    $html .= "     <title>Page Title</title>\n";
    $html .= "     <link rel=\"stylesheet\" type=\"text/css\" href=\"https://cdn.datatables.net/1.10.19/css/jquery.dataTables.min.css\">\n";
    $html .= "     <script src=\"https://code.jquery.com/jquery-3.3.1.js\"></script>\n";
    $html .= "     <script src=\"https://cdn.datatables.net/1.10.19/js/jquery.dataTables.min.js\"></script>\n";
    $html .= "     <script>\n";
    $html .= "       \$(document).ready(function() {";
    $html .= "       \$('#datatable').DataTable({";
    $html .= "          searching: false,\n";
    $html .= "          info: false,\n";
    $html .= "       	ordering: false,\n";
    $html .= "       	paging: false,\n";
    $html .= "          });\n";
    $html .= "       \$('#target_table').DataTable({";
    $html .= "          order : [[5, 'dsc'], [6, 'dsc']],\n";
    $html .= "          pageLength: 50,\n";
    $html .= "          });\n";
    $html .= "       });\n";
    $html .= "     </script>\n";
    $html .= "   </head>\n";
    $html .= "  <body>\n";
    $html .= "\n";
    $html .= "    <h1 style=\"text-align: center;\">$data->{title} - $phevor_gene</h1>\n";
    $html .= "    <h2 style=\"text-align: center;\">$var_key</h1>\n";
    #----------------------------------------
    # Variant Page - Variant Summary Table
    #----------------------------------------
    $html .= "    <table id=\"datatable\" class=\"display\" style=\"width:25%\">\n";
    $html .= "      <thead>\n";
    $html .= "        <tr>\n";
    $html .= "          <th>Key</th>\n";
    $html .= "          <th>Value</th>\n";
    $html .= "        </tr>\n";
    $html .= "      </thead>\n";
    $html .= "      <tbody>\n";
    $html .= "        <tr>\n";
    $html .= "          <th style='text-align: right'>Variant Key</th>\n";
    $html .= "	        <td>${var_key}</th>";
    $html .= "        </tr>\n";
    $html .= "        <tr>\n";
    $html .= "          <th style='text-align: right'>Locus</th>\n";
    $html .= ("         <td><a href=\"http://genome.ucsc.edu/cgi-bin/hgTracks?" .
	      "db=hg19&position=${chrom}%3A${start}-${start}\" " .
	      "target=\"_blank\">${locus}</a></td>\n");
    $html .= "        </tr>\n";
    $html .= "        <tr>\n";
    $html .= "          <th style='text-align: right'>Type</th>\n";
    $html .= "	        <td>${type}</th>";
    $html .= "        </tr>\n";
    $html .= "        <tr>\n";
    $html .= "          <th style='text-align: right'>Variant CLRT Score</th>\n";
    $html .= "	        <td style='$var->{score_fmt}'>${score}</th>";
    $html .= "        </tr>\n";
    $html .= "        <tr>\n";
    $html .= "          <th style='text-align: right'>Gnomad AF</th>\n";
    $html .= "	        <td style='$var->{gnomad_cmlt_af_fmt}'>$var->{gnomad_cmlt_af}</th>";
    $html .= "        </tr>\n";
    $html .= "        <tr>\n";
    $html .= "          <th style='text-align: right'>REF NT</th>\n";
    $html .= "	        <td>${ref_nt}</th>";
    $html .= "        </tr>\n";
    $html .= "        <tr>\n";
    $html .= "          <th style='text-align: right'>NT Genotype</th>\n";
    $html .= "	        <td>${nt_gt_txt}</th>";
    $html .= "        </tr>\n";
    $html .= "        <tr>\n";
    $html .= "          <th style='text-align: right'>REF AA</th>\n";
    $html .= "	        <td>${ref_aa}</th>";
    $html .= "        </tr>\n";
    $html .= "        <tr>\n";
    $html .= "          <th style='text-align: right'>AA Genotype</th>\n";
    $html .= "	        <td>${aa_gt_txt}</th>";
    $html .= "        </tr>\n";
    $html .= "        <tr>\n";
    $html .= "          <th style='text-align: right'>HET Genotype Count</th>\n";
    $html .= "          <td>${het_gt_txt}</td>";
    $html .= "        </tr>\n";
    $html .= "        <tr>\n";
    $html .= "          <th style='text-align: right'>HOM Genotype Count</th>\n";
    $html .= "          <td>${hom_gt_txt}</td>";
    $html .= "        </tr>\n";
    $html .= "        <tr>\n";
    $html .= "          <th style='text-align: right'>No-call Genotype Count</th>\n";
    $html .= "          <td>${nc_gt_txt}</td>";
    $html .= "        </tr>\n";
    $html .= "      </tbody>\n";
    $html .= "      </table>    \n";
    #----------------------------------------
    # Horizontal Rule
    #----------------------------------------
    $html .= "\n";
    $html .= "      <p></p>\n";
    $html .= "      <hr/>\n";
    $html .= "      <p></p>\n";
    #----------------------------------------
    # Variant Page - Sample Table
    #----------------------------------------
    $html .= "    <table id=\"target_table\" class=\"display\" style=\"width:90%\">\n";
    $html .= "      <thead>\n";
    $html .= "        <tr>\n";
    $html .= "          <th>Genotype in Background</th>\n";
    $html .= "	        <th>Individual Index</th>\n";
    $html .= "	        <th>Sample ID</th>\n";
    $html .= "          <th>NT GT</th>\n";
    $html .= "          <th>AA GT</th>\n";
    $html .= "	  	<th>GQ</th>\n";
    $html .= "	  	<th>DP</th>\n";
    $html .= "	  	<th>AD</th>\n";
    $html .= " 	  	<th>IGV Screenshot</th>" if $data->{bam_dir};
    $html .= "  </tr>\n";
    $html .= "  </thead>\n";
    $html .= "  <tbody>\n";

    #----------------------------------------
    # Prep Genotype Data
    #----------------------------------------
    my $gts = $var->{gts};
  GTS:
    for my $gt_key (keys %{$gts}) {
	next GTS if $gt_key eq '^:^';

	my $gt = $gts->{$gt_key};
	next GTS unless exists $gt->{T};

	my $gt_nt_txt = join ':', @{$gt->{gt_nt}};
	my $gt_aa_txt = join ':', @{$gt->{gt_aa}};
	my $flag = $gt->{T}{flag} eq 'N' ? 'N' : 'Y';

	#----------------------------------------
	# Prep Sample Data
	#----------------------------------------
	my $indvs = $gt->{T}{indvs};
	for my $indv (@{$indvs}) {
	    my $sample_id = exists $ID_MAP{$indv} ? $ID_MAP{$indv} : 'N/A';

	    my $gt = 'N/A';

	    my $gq = 'N/A';
	    my $gq_fmt = '';

	    my $dp = 'N/A';
	    my $dp_fmt = '';

	    my $ad = 'N/A';
	    my $ad_fmt = '';

	    #----------------------------------------
	    # Prep VCF FORMAT Data
	    #----------------------------------------
	    if ($data->{vcf_file}) {
		my $var_data_txt = `bcftools query -f '[\%GT\\t\%GQ\\t\%DP\\t\%AD\\n]' -s $sample_id -r $range_locus $data->{vcf_file}`;
		chomp $var_data_txt;
		($gt, $gq, $dp, $ad) = split /\t/, $var_data_txt;

		#----------------------------------------
		# Format Genotype Quality
		#----------------------------------------
		if ($gq >= 50) {
		    $gq_fmt = 'background-color: LightGreen';
		}
		elsif ($gq >= 30) {
		    $gq_fmt = 'background-color: LightYellow';
		}
		else {
		    $gq_fmt = 'background-color: LightCoral';
		}

		#----------------------------------------
		# Format Depth
		#----------------------------------------
		if ($dp >= 30) {
		    $dp_fmt = 'background-color: LightGreen';
		}
		elsif ($dp >= 15) {
		    $dp_fmt = 'background-color: LightYellow';
		}
		else {
		    $dp_fmt = 'background-color: LightCoral';
		}

		#----------------------------------------
		# Format Allelic Depth
		#----------------------------------------
		my ($ref_ad, $alt_ad) = split ',', $ad;
		my $alt_ratio;
		if (($ref_ad + $alt_ad) > 0) {
		    $alt_ratio = $alt_ad/($ref_ad + $alt_ad);
		}
		else {
		    $alt_ratio = 0;
		}

		my $abs_diff = abs(0.5 - $alt_ratio);
		if ($gt =~ /^0[\/\|]1$/) {
		    if ($abs_diff <= 0.15) {
			$ad_fmt = 'background-color: LightGreen';
		    }
		    elsif ($abs_diff <= 0.3) {
			$ad_fmt = 'background-color: LightYellow';
		    }
		    elsif ($abs_diff <= 0.5) {
			$ad_fmt = 'background-color: LightCoral';
		    }
		    else {
			$ad_fmt = 'background-color: Silver';
		    }
		}

		print '';
	    }

	    my $png_file = '';
	    #----------------------------------------
	    # Make IGV batch script
	    #----------------------------------------
	    if ($data->{bam_dir}) {
		# Make IGV Snapshot BAT files
		my $file_base = $locus;
		$file_base =~ s/[:\-]/_/g;
		$file_base .= "-${sample_id}";
		$file_base =~ s|\/|_|g;		

		my $bat_file = "${igv_path}/${file_base}.bat";
		$png_file = "${file_base}.png";

		my $bat = << "END_BAT";
new
maxPanelHeight 500
genome hg19
load $data->{bam_dir}/$sample_id.cram
goto $region
region $roi
snapshotDirectory $igv_path
snapshot $png_file
exit
END_BAT
		
		open(my $BAT, '>', $bat_file) ||
		    die "FATAL : cant_open_file_for_writing : $bat_file\n";
		
		print $BAT $bat;
		close $BAT;
		print '';
	    }

	    #----------------------------------------
	    # Variant Page - Sample Table Rows
	    #----------------------------------------
	    $html .= "        <tr>\n";
	    $html .= "          <td>$flag</th>\n";
	    $html .= "      	<td>$indv</td>\n";
	    $html .= "      	<td>$sample_id</td>\n";
	    $html .= "          <td>$gt_nt_txt</td>\n";
	    $html .= "          <td>$gt_aa_txt</td>\n";
	    $html .= "      	<td style='$gq_fmt'>$gq</td>\n";
	    $html .= "      	<td style='$dp_fmt'>$dp</td>\n";
	    $html .= "      	<td style='$ad_fmt'>$ad</td>\n";
	    $html .= "      	<td><a href=\"../../igv_img/${png_file}\" target=\"_blank\">IGV Screen Shot</a></td>\n" if $data->{bam_dir};
	    $html .= "        </tr>\n";
	}
	print '';
    }

    #----------------------------------------
    # Variant Page - Finish HTML Page
    #----------------------------------------
    $html .= "      </tbody>\n";
    $html .= "    </table>\n";
    $html .= "  </body>\n";
    $html .= "</html>\n";

    my $filename = "${path}/${var_key_fmt}.html";
    $filename =~ s/:/-/g;
    open(my $OUT, '>', $filename) ||
	die "FATAL : cant_open_file_for_writing : $filename\n";
 
    print $OUT $html;
    close $OUT;
    print '';
}
