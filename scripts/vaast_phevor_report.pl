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
    --gnomad    gnomad.vcf.gz  \
    --base_name html_files_dir \
    output.vaast
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

  --gnomad, -g

    A tabix-indexed Gnomad VCF file.

  --base_name, -b

    The directory name (or path) where gene and variant HTML files
    will be placed.

";

my $CL = join ' ', $0, @ARGV;

my ($help, %data);

my $opt_success = GetOptions('help'          => \$help,
			     'gnomad|g=s'    => \$data{gnomad_file},
			     'base_name|b=s' => \$data{base_name},
    );

die $usage if $help || ! $opt_success;

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

make_path($data{base_name});

process_data(\%data);

my $table = Cirque::DataTable->new(data      => $data{row_data},
				   columns   => $data{columns},
				   full_page => 1,
				   order     => "[[1, 'asc'], [10, 'dsc']]");

my $filename = $data{base_name} . '.html';

open(my $OUT, '>', $filename)
    or die "FATAL : cant_open_file_for_writing : $filename\n";

print $OUT $table->build_table;
print $OUT "\n";
close $OUT;

#-----------------------------------------------------------------------------
#-------------------------------- SUBROUTINES --------------------------------
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

    $data{vaast_map} = \%vaast_map;
    
    #----------------------------------------
    # Prep columns
    #----------------------------------------
    my @columns = qw(gene phevor_rank phevor_score phevor_prior
                     vaast_rank vaast_score vaast_pval 
                     gnomad_cmlt_af variant
                     type score het hom nc);

    $data{columns} = \@columns;

    #----------------------------------------
    # Loop Phevor data
    #----------------------------------------

 GENE:
    while (my $phevor_record = $phevor_data->next_record) {
	
	# Clear any previous 'current' record data.
	delete $data->{crnt_gene} if exists $data->{crnt_gene};

	#----------------------------------------
	# Get Phevor data
	#----------------------------------------
	my ($phevor_rank, $phevor_gene, $phevor_score, $phevor_prior) =
	    @{$phevor_record}{qw(rank gene score prior orig_p)};
	$data{crnt_gene}{phevor_rank}++;

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
	$data{crnt_gene}{vaast_rank}++;
	
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
    	$data{crnt_gene}{phevor_gene_fmt} = "<a href=$data->{rel_base}/${phevor_gene}.html>$phevor_gene</a>";

	# Phevor_Rank
	#--------------------
	if ($phevor_rank <= 10) {
	    $data->{crnt_gene}{phevor_rank_fmt} = [$phevor_rank, {bgcolor => 'LightGreen'}];
	}
	elsif ($phevor_rank <= 30) {
	    $data->{crnt_gene}{phevor_rank_fmt} = [$phevor_rank, {bgcolor => 'LightYellow'}];
	}
	else {
	    $data->{crnt_gene}{phevor_rank_fmt} = [$phevor_rank, {bgcolor => 'LightCoral'}];
	}
	
	# Phevor_Score
	#--------------------
	if ($phevor_score >= 2.3) {
	    $data->{crnt_gene}{phevor_score_fmt} = [$phevor_score, {bgcolor => 'LightGreen'}];
	}
	elsif ($phevor_score >= 1) {
	    $data->{crnt_gene}{phevor_score_fmt} = [$phevor_score, {bgcolor => 'LightYellow'}];
	}
	else {
	    $data->{crnt_gene}{phevor_score_fmt} = [$phevor_score, {bgcolor => 'LightCoral'}];
	}
	
	# Phevor_Prior
	#--------------------
	if ($phevor_prior >= .75) {
	    $data->{crnt_gene}{phevor_prior_fmt} = [$phevor_prior, {bgcolor => 'LightGreen'}];
	}
	elsif ($phevor_prior >= 0.5) {
	    $data->{crnt_gene}{phevor_prior_fmt} = [$phevor_prior, {bgcolor => 'LightYellow'}];
	}
	else {
	    $data->{crnt_gene}{phevor_prior_fmt} = [$phevor_prior, {bgcolor => 'LightCoral'}];
	}
	
	# Vaast_Rank
	#--------------------
	if ($vaast_rank <= 25) {
	    $data->{crnt_gene}{vaast_rank_fmt} = [$vaast_rank, {bgcolor => 'LightGreen'}];
	}
	elsif ($vaast_rank <= 100) {
	    $data->{crnt_gene}{vaast_rank_fmt} = [$vaast_rank, {bgcolor => 'LightYellow'}];
	}
	else {
	    $data->{crnt_gene}{vaast_rank_fmt} = [$vaast_rank, {bgcolor => 'LightCoral'}];
	}
	
	# Vaast_Score
	#--------------------
	if ($vaast_score >= 10) {
	    $data->{crnt_gene}{vaast_score_fmt} = [$vaast_score, {bgcolor => 'LightGreen'}];
	}
	elsif ($vaast_score >= 5) {
	    $data->{crnt_gene}{vaast_score_fmt} = [$vaast_score, {bgcolor => 'LightYellow'}];
	}
	else {
	    $data->{crnt_gene}{vaast_score_fmt} = [$vaast_score, {bgcolor => 'LightCoral'}];
	}
	
	# VAAST p-value
	#--------------------
	if ($vaast_pval <= 0.001) {
	    $data->{crnt_gene}{vaast_pval_fmt} = [$vaast_pval, {bgcolor => 'LightGreen'}];
	}
	elsif ($vaast_pval <= 0.01) {
	    $data->{crnt_gene}{vaast_pval_fmt} = [$vaast_pval, {bgcolor => 'LightYellow'}];
	}
	else {
	    $data->{crnt_gene}{vaast_pval_fmt} = [$vaast_pval, {bgcolor => 'LightCoral'}];
	}
	    
	# Store current Phevor and VAAST records
	$data{crnt_gene}{phevor_record} = $phevor_record;
	$data{crnt_gene}{vaast_record}  = $vaast_record;

	# Create gene page
	create_gene_page($data);

	#----------------------------------------
	# Calculate allele counts
	# Sort variants by score
	#----------------------------------------
      VAR:
	for my $var_key (sort {($vaast_record->{Alleles}{$b}{score}
				<=> 
				$vaast_record->{Alleles}{$a}{score})}
			 keys %{$vaast_record->{Alleles}}) {

	    delete $data->{crnt_var} if exists $data->{crnt_var};

	    my $data->{crnt_var}{var_key} = $var_key;
	    my ($chrom, $start, $ref) = split /:/, $data->{crnt_var}{var_key};
	    my $gnomad_vcf = Arty::VCF->new(file  => $data{gnomad_file},
					    tabix => "$chrom:${start}-${start}");
	    while (my $gnmd_record = $gnomad_vcf->next_record) {
		$data->{crnt_var}{gnomad_cmlt_af} += $gnmd_record->{info}{AF}[0];
	    }

	    #----------------------------------------
	    # Format floating points
	    #----------------------------------------
	    $data->{crnt_var}{gnomad_cmlt_af} =  sprintf '%.2g', $data->{crnt_var}{gnomad_cmlt_af};
	    
	    #----------------------------------------
	    # Get variant data
	    #----------------------------------------
	    $data->{crnt_var}{var} = $vaast_record->{Alleles}{$data->{crnt_var}{var_key}};

	    #---------------------------------------
	    # Loop genotype data
	    #----------------------------------------
	    $data->{crnt_var}{gt_data} = {NC  => [],
					  HOM => [],
					  HET => []};

	    for my $gt_key (sort keys %{$data->{crnt_var}{var}{GT}}) {

		#---------------------------------------
		# Get genotype data
		#----------------------------------------
		my $gt = $data->{crnt_var}{var}{GT}{$gt_key};
		my $b_count = $gt->{B};
		my $t_count = $gt->{T};

		#----------------------------------------
		# Collect B & T count of each genotype
		# by class (NC, HOM, HET)
		#----------------------------------------
		my ($A, $B) = split ':', $gt_key;
		my $gt_txt = join ',', $gt_key, $b_count, $t_count;
		if (grep {$_ eq '^'} ($A, $B)) {
		    push @{$data->{crnt_var}{gt_data}{NC}}, $gt_txt;
		}
		elsif ($A eq $B) {
		    push @{$data->{crnt_var}{gt_data}{HOM}}, $gt_txt;
		}
		else {
		    push @{$data->{crnt_var}{gt_data}{HET}}, $gt_txt;		    
		}
	    }

	    #----------------------------------------
	    # Prep genotype data
	    #----------------------------------------
	    $data->{crnt_var}{het_gt_txt} = join '|', @{$data->{crnt_var}{gt_data}{HET}};
	    $data->{crnt_var}{hom_gt_txt} = join '|', @{$data->{crnt_var}{gt_data}{HOM}};
	    $data->{crnt_var}{nc_gt_txt}  = join '|', @{$data->{crnt_var}{gt_data}{NC}};
	    $data->{crnt_var}{het_gt_txt} ||= '.';
	    $data->{crnt_var}{hom_gt_txt} ||= '.';
	    $data->{crnt_var}{nc_gt_txt}  ||= '.';

	    #----------------------------------------
	    # Add HTML formatting (var annotations)
	    #----------------------------------------
	    
	    # Gnomad_Cmlt_AF
	    #--------------------
	    if ($data->{crnt_var}{gnomad_cmlt_af} <= 0.0001) {
		$data->{crnt_var}{gnomad_cmlt_af_fmt} = [$data->{crnt_var}{gnomad_cmlt_af}, {bgcolor => 'LightGreen'}];
	    }
	    elsif ($data->{crnt_var}{gnomad_cmlt_af} <= 0.01) {
		$data->{crnt_var}{gnomad_cmlt_af_fmt} = [$data->{crnt_var}{gnomad_cmlt_af}, {bgcolor => 'LightYellow'}];
	    }
	    else {
		$data->{crnt_var}{gnomad_cmlt_af_fmt} = [$data->{crnt_var}{gnomad_cmlt_af}, {bgcolor => 'LightCoral'}];
	    }
	
	    # Var_Type
	    #--------------------
	    if ($data->{crnt_var}{var_type} eq 'SNV') {
		$data->{crnt_var}{var_type_fmt} = [$data->{crnt_var}{var_type}, {bgcolor => 'LightGreen'}];
	    }
	    else {
		$data->{crnt_var}{var_type_fmt} = [$data->{crnt_var}{var_type}, {bgcolor => 'LightYellow'}];
	    }
	    
	    # Var_Score
	    #--------------------
	    if ($data->{crnt_var}{var_score} >= 8) {
		$data->{crnt_var}{var_score_fmt} = [$data->{crnt_var}{var_score}, {bgcolor => 'LightGreen'}];
	    }
	    elsif ($data->{crnt_var}{var_score} >= 2) {
		$data->{crnt_var}{var_score_fmt} = [$data->{crnt_var}{var_score}, {bgcolor => 'LightYellow'}];
	    }
	    else {
		$data->{crnt_var}{var_score_fmt} = [$data->{crnt_var}{var_score}, {bgcolor => 'LightCoral'}];
	    }
	    
	    # NC_GT_TXT
	    #--------------------
	    if ($data->{crnt_var}{nc_gt_txt} eq '.') {
		$data->{crnt_var}{nc_gt_txt_fmt} = [$data->{crnt_var}{nc_gt_txt}, {bgcolor => 'LightGreen'}];
	    }
	    else {
		$data->{crnt_var}{nc_gt_txt_fmt} = [$data->{crnt_var}{nc_gt_txt}, {bgcolor => 'LightCoral'}];
	    }
	    
	    
	    # #----------------------------------------
	    # # Create Variant Page & Write IGV Data
	    # #----------------------------------------
	    # 
	    # create_variant_page($data);
	    # write_igv_data($data);

	    #----------------------------------------
	    # Skip variants with 0 score in main table
	    #----------------------------------------
	    next VAR unless $data->{crnt_var}{score} > 0;

	    #----------------------------------------
	    # Save data for each variant
	    #----------------------------------------

	    push @{$data->{row_data}}, [$data->{phevor_gene_fmt},
					$data->{crnt}{phevor_rank_fmt},
					$data->{crnt}{phevor_score_fmt},
					$data->{crnt}{phevor_prior_fmt},
					$data->{crnt}{vaast_rank_fmt},
					$data->{crnt}{vaast_score_fmt},
					$data->{crnt}{vaast_pval_fmt},
					$data->{crnt_var}{gnomad_cmlt_af_fmt},
					$data->{crnt_var}{var_key},
					$data->{crnt_var}{var_type_fmt},
					$data->{crnt_var}{var_score_fmt},
					$data->{crnt_var}{het_gt_txt},
					$data->{crnt_var}{hom_gt_txt},
					$data->{crnt_var}{nc_gt_txt}];

	}
    }
    return;
}

#--------------------------------------------------------------------------------

sub create_gene_page {
    my ($data) = shift @_;

    my $phevor_record = $data->{crnt_gene}{phevor_record};
    my ($phevor_rank, $phevor_gene, $phevor_score, $phevor_prior) =
	@{$phevor_record}{qw(rank gene score prior orig_p)};

    my $vaast_record = $data->{crnt_gene}{vaast_record};
    my ($chrom, $vaast_rank, $vaast_gene, $vaast_feature, $vaast_score, $vaast_pval) = 
	@{$vaast_record}{qw(chrom rank gene feature_id score p_value)};

    my $html = << "END_HTML1";
<!DOCTYPE html>
  <html>
   <head>
     <title>Page Title</title>
     <link rel="stylesheet" type="text/css" href="https://cdn.datatables.net/1.10.19/css/jquery.dataTables.min.css">
     <script src="https://code.jquery.com/jquery-3.3.1.js"></script>
     <script src="https://cdn.datatables.net/1.10.19/js/jquery.dataTables.min.js"></script>
     <script>
       \$(document).ready(function() {
       \$('#datatable').DataTable();
       \$('#vartable').DataTable({
          \"order\" : [[10, 'dsc']]
          });
       });
     </script>
   </head>
  <body>

    <table id="datatable" class="display" style="width:25%">
      <thead>
        <tr>
          <th>Key</th>
          <th>Value</th>
        </tr>
      </thead>
      <tbody>
        <tr>
          <td>gene</th>
          <td><a href="https://www.genecards.org/cgi-bin/carddisp.pl?gene=$phevor_gene">$phevor_gene</a></td>
        </tr>
        <tr>
          <td>phevor_rank</th>
          <td>$phevor_rank</td>
        </tr>
        <tr>
          <td>phevorr_score</th>
          <td>$phevor_score</td>
        </tr>
        <tr>
          <td>phevor_prior</th>
          <td>$phevor_prior</td>
        </tr>
        <tr>
          <td>vaast_rank</th>
          <td>$vaast_rank</td>
        </tr>
        <tr>
          <td>vaast_score</th>
          <td>$vaast_score</td>
        </tr>
        <tr>
          <td>vaast_pval</th>
          <td>$vaast_pval</td>
        </tr>
      </tbody>
    </table>    

    <hr/>

    <table id="vartable" class="display" style="width:100%">
      <thead>
        <tr>
	  <td>code</th>
	  <td>var_key</th>
	  <td>chrom</th>
	  <td>start</th>
	  <td>type</th>
	  <td>ref_nt</th>
	  <td>nt_gt</th>
	  <td>ref_aa</th>
	  <td>aa_gt</th>
	  <td>score</th>
        </tr>
      </thead>
      <tbody>
END_HTML1

    for my $code (qw(TU T TR)) {
	for my $var (@{$vaast_record->{$code}}) {

	    
	    my ($start, $type, $ref_nt, $ref_aa, $alt_nt, $score)
		= @{$var}{qw(start type ref_nt ref_aa alt_nt score)};

	    my $var_key = join(':', $chrom, $start, $ref_nt);
	    my $var_key_fmt = $var_key;
	    $var_key_fmt =~ s/\-/ins/;
	    $var_key_fmt =~ s/:/-/g;
	    $var_key_fmt = "<a href=${phevor_gene}/$var_key_fmt.html>$var_key</a>";

	    push @{$vaast_record->{vars}{$var_key}}, $code;
	    
	    # Create nt & aa genotype text strings
	    my $gts = $var->{genotypes};
	    for my $gt (@{$gts}) {
		my @ord_nts = grep {$_ eq $ref_nt} @{$gt->{gt_nt}};
		push @ord_nts, sort grep {$_ ne $ref_nt} @{$gt->{gt_nt}};
		my $nt_gt = join '|', @ord_nts;
		push @{$vaast_record->{vars}{$var_key}{nt_gts}}, $nt_gt;

		my @ord_aas = grep {$_ eq $ref_aa} @{$gt->{gt_aa}};
		push @ord_aas, sort grep {$_ ne $ref_aa} @{$gt->{gt_aa}};
		my $aa_gt = join '|', @ord_aas;
		push @{$vaast_record->{vars}{$var_key}{aa_gts}}, $aa_gt;
	    }
	    $vaast_record->{vars}{$var_key}{nt_gt_txt} = join ';', @{$vaast_record->{vars}{$var_key}{nt_gts}};
	    $vaast_record->{vars}{$var_key}{aa_gt_txt} = join ';', @{$vaast_record->{vars}{$var_key}{aa_gts}};

	    $html .= "    <tr>\n";
	    $html .= "      <td>$code</th>\n";
	    $html .= "      <td>$var_key_fmt</th>\n";
	    $html .= "      <td>$chrom</th>\n";
	    $html .= "      <td>$start</th>\n";
	    $html .= "      <td>$type</th>\n";
	    $html .= "      <td>$ref_nt</th>\n";
	    $html .= "      <td>$vaast_record->{vars}{$var_key}{nt_gt_txt}</th>\n";
	    $html .= "      <td>$ref_aa</th>\n";
	    $html .= "      <td>vaast_record->{vars}{$var_key}{aa_gt_txt}</th>\n";
	    $html .= "      <td>$score</th>\n";
	    $html .= "    </tr>\n";

	    #----------------------------------------
	    # Create Variant Page & Write IGV Data
	    #----------------------------------------
	    
	    create_variant_page($data);
	    write_igv_data($data);
	}
    }
    
    $html .= << "END_HTML2";
      </tbody>
    </table>
  </body>
</html>      

END_HTML2

    my $filename = join '/', $data->{base_name} . ($phevor_gene . 'html');
    open(my $OUT, '>', $filename) ||
	die "FATAL : cant_open_file_for_writing : $filename\n";
    
    print $OUT $html;

    close $OUT;
}

#--------------------------------------------------------------------------------

sub create_variant_page {

    my $data = shift @_;

    # my $vaast_record = $data->{crnt_gene}{vaast_record};
    # 
    # # my ($phevor_record,
    # # 	  $vaast_record,
    # # 	  $var,
    # # 	  $base_name,
    # # 	  $code,
    # # 	  $var_key_fmt,
    # # 	  $chrom,
    # # 	  $start,
    # # 	  $type,
    # # 	  $ref_nt,
    # # 	  $ng_gt_txt,
    # # 	  $ref_aa,
    # # 	  $aa_gt_txt) =
    # # 	    @{$var_data}{qw(phevor_record
    # #                       vst_record
    # #                       var
    # #                       base_name
    # #                       code
    # #                       var_key_fmt
    # #                       chrom
    # # 	                    start
    # #                       type
    # # 			    ref_nt
    # # 			    nt_gt
    # # 			    ref_aa
    # # 			    aa_gt)};
    # 
    # # map {$_ = $_->[0] if ref $_ eq 'ARRAY'} ($var_key, $var_type,
    # # 					     $var_score, $het_gt_txt,
    # # 					     $hom_gt_txt, $nc_gt_txt);
    # #
    # 
    # my ($chrom, $vaast_rank, $vaast_gene, $vaast_feature, $vaast_score, $vaast_pval) = 
    # 	@{$vaast_record}{qw(chrom rank gene feature_id score p_value)};
    # 
    # my $html = << "END_HTML";
# <!DOCTYPE html>
#   <html>
#    <head>
#      <title>Page Title</title>
#      <link rel="stylesheet" type="text/css" href="https://cdn.datatables.net/1.10.19/css/jquery.dataTables.min.css">
#      <script src="https://code.jquery.com/jquery-3.3.1.js"></script>
#      <script src="https://cdn.datatables.net/1.10.19/js/jquery.dataTables.min.js"></script>
#      <script>
#        \$(document).ready(function() {
#        \$('#datatable').DataTable();
#        });
#      </script>
#    </head>
#   <body>
# 
#     <table id="datatable" class="display" style="width:25%">
#       <thead>
#         <tr>
#           <th>Key</th>
#           <th>Value</th>
#         </tr>
#       </thead>
#       <tbody>
#         <tr>
#           <th></th>
# 	  <td>$code</th>\n";
#         </tr>
#         <tr>
#           <th></th>
# 	  <td>$var_key_fmt</th>\n";
#         </tr>
#         <tr>
#           <th></th>
# 	  <td>$chrom</th>\n";
#         </tr>
#         <tr>
#           <th></th>
# 	  <td>$start</th>\n";
#         </tr>
#         <tr>
#           <th></th>
# 	  <td>$type</th>\n";
#         </tr>
#         <tr>
#           <th></th>
# 	  <td>$ref_nt</th>\n";
#         </tr>
#         <tr>
#           <td>het_gt_txt</th>
#           <td>$het_gt_txt</td>
#         </tr>
#         <tr>
#           <td>hom_gt_txt</th>
#           <td>$hom_gt_txt</td>
#         </tr>
#         <tr>
#           <td>nc_gt_txt</th>
#           <td>$nc_gt_txt</td>
#         </tr>
#         <tr>
#           <th>nt_gt_txt</th>
# 	  <td>$nt_gt_txt</th>\n";
#         </tr>
#         <tr>
#           <th>ref_aa</th>
# 	  <td>$ref_aa</th>\n";
#         </tr>
#         <tr>
#           <th>aa_gt_txt</th>
# 	  <td>$aa_gt_txt</th>\n";
#         </tr>
#         <tr>
#           <th>score</th>
# 	  <td>$score</th>\n";
#         </tr>
#       </tbody>
#     </table>    
# 
#     <hr/>
# 
# END_HTML
# 
#     # xmy $var_key_fmt = $var_key;
#     # $var_key_fmt =~ s/\-/ins/;
#     # $var_key_fmt =~ s/:/-/g;
#     # 	
#     # for my $code (qw(TU T TR)) {
#     # 	for my $var (@{$vaast_record->{$code}}) {
#     # 
#     # 	    my ($start, $type, $ref_nt, $ref_aa, $alt_nt, $score)
#     # 		= @{$var}{qw(start type ref_nt ref_aa alt_nt score)};
#     #     
#     # 	    my (@nt_gts, @aa_gts);
#     # 	    for my $gt_key (sort keys %{$var->{GT}}) {
#     # 		my $gt = $var->{GT}{$gt_key};
#     # 		#for my $gt (@{$var->{genotypes}}) {
#     # 		
#     # 		my @ord_nts = grep {$_ eq $ref_nt} @{$gt->{gt_nt}};
#     # 		push @ord_nts, sort grep {$_ ne $ref_nt} @{$gt->{gt_nt}};
#     # 		my $nt_gt = join '|', @ord_nts;
#     # 		push @nt_gts, $nt_gt;
#     # 		
#     # 		my @ord_aas = grep {$_ eq $ref_aa} @{$gt->{gt_aa}};
#     # 		push @ord_aas, sort grep {$_ ne $ref_aa} @{$gt->{gt_aa}};
#     # 		my $aa_gt = join '|', @ord_aas;
#     # 		push @aa_gts, $aa_gt;
#     # 	    }
#     # 	    my $nt_gt_txt = join ';', @nt_gts;
#     # 	    my $aa_gt_txt = join ';', @aa_gts;
#     # 
#     # 	    $html .= "    <tr>\n";
#     # 	    $html .= "      <td>TU</th>\n";
#     # 	    $html .= "      <td>$var_key_fmt</th>\n";
#     # 	    $html .= "      <td>$chrom</th>\n";
#     # 	    $html .= "      <td>$start</th>\n";
#     # 	    $html .= "      <td>$type</th>\n";
#     # 	    $html .= "      <td>$ref_nt</th>\n";
#     # 	    $html .= "      <td>$ref_aa</th>\n";
#     # 	    $html .= "      <td>$alt_nt</th>\n";
#     # 	    $html .= "      <td>$score</th>\n";
#     # 	    $html .= "    </tr>\n";
#     # 	}
#     #     }
# 	    
#     $html .= << "END_HTML2";
#       </tbody>
#     </table>
#   </body>
# </html>      
# 
# END_HTML2
# 
#     make_path("$base_name/$phevor_gene");
# 
#     my $filename = "${base_name}/${phevor_gene}/${var_key_fmt}.html";
#     $filename =~ s/:/-/g;
#     open(my $OUT, '>', $filename) ||
# 	die "FATAL : cant_open_file_for_writing : $filename\n";
#     
#     print $OUT $html;
#     close $OUT;

#     <table id="vartable" class="display" style="width:100%">
#       <thead>
#         <tr>
# 	  <td>code</th>
# 	  <td>var_key</th>
# 	  <td>chrom</th>
# 	  <td>start</th>
# 	  <td>type</th>
# 	  <td>ref_nt</th>
# 	  <td>nt_gt</th>
# 	  <td>ref_aa</th>
# 	  <td>aa_gt</th>
# 	  <td>score</th>
#         </tr>
#       </thead>
#       <tbody>
}

#--------------------------------------------------------------------------------

sub write_igv_data {
    my ($vaast_record, $var_key) = @_;

    
    
}
