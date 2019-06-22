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
    --phevor    phevor.txt     \
    --gnomad    gnomad.vcf.gz  \
    --base_name html_files_dir \
    output.vaast

Description:

Generate detailed reports for VAAST/Phevor runs that incorporates data from a
variety of sources.

Options:

  --phevor, -p

    A phevor file associated with the VAAST run.

  --gnomad, -g

    A tabix-indexed Gnomad VCF file.

  --base_name, -b

    The directory name (or path) where gene and variant HTML files
    will be placed.

";

my ($help, $phevor_file, $gnomad_file, $base_name);

my $opt_success = GetOptions('help'          => \$help,
			     'phevor|p=s'    => \$phevor_file,
			     'gnomad|g=s'    => \$gnomad_file,
			     'base_name|b=s' => \$base_name,
    );

die $usage if $help || ! $opt_success;

my $vaast_file = shift;
die $usage unless $vaast_file;

my $vaast  = Arty::VAAST->new(file   => $vaast_file,
			      scored => 1);
my $phevor = Arty::Phevor->new(file => $phevor_file);

make_path($base_name);

my ($data, $columns) = process_data($phevor, $vaast, $base_name);

my $table = Cirque::DataTable->new(data      => $data,
				   columns   => $columns,
				   full_page => 1,
				   order     => "[[1, 'asc'], [10, 'dsc']]");

my $filename = "$base_name.html";

open(my $OUT, '>', $filename)
    or die "FATAL : cant_open_file_for_writing : $filename\n";

print $OUT $table->build_table;
print $OUT "\n";
close $OUT;

#-----------------------------------------------------------------------------
#-------------------------------- SUBROUTINES --------------------------------
#-----------------------------------------------------------------------------

sub process_data {

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
	
	create_gene_page($record, $vaast_record, $base_name);

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
	my $rel_base = $base_name;
	$rel_base =~ s|.*\/||;
    	my $phv_gene_fmt = "<a href=${rel_base}/${phv_gene}.html>$phv_gene</a>";
	
	# Phv_Rank
	#--------------------
	my $phv_rank_fmt;
	if ($phv_rank <= 10) {
	    $phv_rank_fmt = [$phv_rank, {bgcolor => 'LightGreen'}];
	}
	elsif ($phv_rank <= 30) {
	    $phv_rank_fmt = [$phv_rank, {bgcolor => 'LightYellow'}];
	}
	else {
	    $phv_rank_fmt = [$phv_rank, {bgcolor => 'LightCoral'}];
	}
	
	# Phevor_Score
	#--------------------
	my $phv_score_fmt;
	if ($phv_score >= 2.3) {
	    $phv_score_fmt = [$phv_score, {bgcolor => 'LightGreen'}];
	}
	elsif ($phv_score >= 1) {
	    $phv_score_fmt = [$phv_score, {bgcolor => 'LightYellow'}];
	}
	else {
	    $phv_score_fmt = [$phv_score, {bgcolor => 'LightCoral'}];
	}
	
	# Phv_Prior
	#--------------------
	my $phv_prior_fmt;
	if ($phv_prior >= .75) {
	    $phv_prior_fmt = [$phv_prior, {bgcolor => 'LightGreen'}];
	}
	elsif ($phv_prior >= 0.5) {
	    $phv_prior_fmt = [$phv_prior, {bgcolor => 'LightYellow'}];
	}
	else {
	    $phv_prior_fmt = [$phv_prior, {bgcolor => 'LightCoral'}];
	}
	
	# Vaast_Rank
	#--------------------
	my $vaast_rank_fmt;
	if ($vaast_rank <= 25) {
	    $vaast_rank_fmt = [$vaast_rank, {bgcolor => 'LightGreen'}];
	}
	elsif ($vaast_rank <= 100) {
	    $vaast_rank_fmt = [$vaast_rank, {bgcolor => 'LightYellow'}];
	}
	else {
	    $vaast_rank_fmt = [$vaast_rank, {bgcolor => 'LightCoral'}];
	}
	
	# Vaast_Score
	#--------------------
	my $vaast_score_fmt;
	if ($vaast_score >= 10) {
	    $vaast_score_fmt = [$vaast_score, {bgcolor => 'LightGreen'}];
	}
	elsif ($vaast_score >= 5) {
	    $vaast_score_fmt = [$vaast_score, {bgcolor => 'LightYellow'}];
	}
	else {
	    $vaast_score_fmt = [$vaast_score, {bgcolor => 'LightCoral'}];
	}
	
	# VAAST p-value
	#--------------------
	my $vaast_pval_fmt;
	if ($vaast_pval <= 0.001) {
	    $vaast_pval_fmt = [$vaast_pval, {bgcolor => 'LightGreen'}];
	}
	elsif ($vaast_pval <= 0.01) {
	    $vaast_pval_fmt = [$vaast_pval, {bgcolor => 'LightYellow'}];
	}
	else {
	    $vaast_pval_fmt = [$vaast_pval, {bgcolor => 'LightCoral'}];
	}
	    
	#----------------------------------------
	# Calculate allele counts
	# Sort variants by score
	#----------------------------------------
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
	    my $gnomad_cmlt_af_fmt;
	    if ($gnomad_cmlt_af <= 0.0001) {
		$gnomad_cmlt_af_fmt = [$gnomad_cmlt_af, {bgcolor => 'LightGreen'}];
	    }
	    elsif ($gnomad_cmlt_af <= 0.01) {
		$gnomad_cmlt_af_fmt = [$gnomad_cmlt_af, {bgcolor => 'LightYellow'}];
	    }
	    else {
		$gnomad_cmlt_af_fmt = [$gnomad_cmlt_af, {bgcolor => 'LightCoral'}];
	    }
	
	    # Var_Type
	    #--------------------
	    my $var_type_fmt;
	    if ($var_type eq 'SNV') {
		$var_type_fmt = [$var_type, {bgcolor => 'LightGreen'}];
	    }
	    else {
		$var_type_fmt = [$var_type, {bgcolor => 'LightYellow'}];
	    }
	    
	    # Var_Score
	    #--------------------
	    my $var_score_fmt;
	    if ($var_score >= 8) {
		$var_score_fmt = [$var_score, {bgcolor => 'LightGreen'}];
	    }
	    elsif ($var_score >= 2) {
		$var_score_fmt = [$var_score, {bgcolor => 'LightYellow'}];
	    }
	    else {
		$var_score_fmt = [$var_score, {bgcolor => 'LightCoral'}];
	    }
	    
	    # NC_GT_TXT
	    #--------------------
	    my $nc_gt_txt_fmt;
	    if ($nc_gt_txt eq '.') {
		$nc_gt_txt_fmt = [$nc_gt_txt, {bgcolor => 'LightGreen'}];
	    }
	    else {
		$nc_gt_txt_fmt = [$nc_gt_txt, {bgcolor => 'LightCoral'}];
	    }
	    
	    
	    #----------------------------------------
	    # Create Variant Page & Write IGV Data
	    #----------------------------------------
	    create_variant_page($base_name, $phv_gene, $vaast_record,
				$var, $var_key, $var_type, $var_score,
				$het_gt_txt, $hom_gt_txt, $nc_gt_txt);

	    write_igv_data($vaast_record, $var_key);

	    #----------------------------------------
	    # Skip variants with 0 score in main table
	    #----------------------------------------
	    next VAR unless $var->{score} > 0;

	    #----------------------------------------
	    # Save data for each variant
	    #----------------------------------------
	    
	    push @data, [$phv_gene_fmt, $phv_rank_fmt, $phv_score_fmt, $phv_prior_fmt,
			 $vaast_rank_fmt, $vaast_score_fmt, $vaast_pval_fmt, $gnomad_cmlt_af_fmt,
			 $var_key, $var_type_fmt, $var_score_fmt, $het_gt_txt,
			 $hom_gt_txt, $nc_gt_txt];

	}
    }
    return (\@data, \@columns);
}

#--------------------------------------------------------------------------------

sub create_gene_page {
    my ($record, $vaast_record, $base_name) = @_;

    my ($phv_rank, $phv_gene, $phv_score, $phv_prior) =
	@{$record}{qw(rank gene score prior orig_p)};
    $phv_rank++;

    my ($chrom, $vaast_rank, $vaast_gene, $vaast_feature, $vaast_score, $vaast_pval) = 
	@{$vaast_record}{qw(chrom rank gene feature_id score p_value)};
    $vaast_rank++;

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
          <td><a href="https://www.genecards.org/cgi-bin/carddisp.pl?gene=$phv_gene">$phv_gene</a></td>
        </tr>
        <tr>
          <td>phv_rank</th>
          <td>$phv_rank</td>
        </tr>
        <tr>
          <td>phvr_score</th>
          <td>$phv_score</td>
        </tr>
        <tr>
          <td>phv_prior</th>
          <td>$phv_prior</td>
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

	    # Create nt & aa genotype text strings
	    my (@nt_gts, @aa_gts);
	    my $gts = $var->{genotypes};
	    for my $gt (@{$gts}) {
		my @ord_nts = grep {$_ eq $ref_nt} @{$gt->{gt_nt}};
		push @ord_nts, sort grep {$_ ne $ref_nt} @{$gt->{gt_nt}};
		my $nt_gt = join '|', @ord_nts;
		push @nt_gts, $nt_gt;

		my @ord_aas = grep {$_ eq $ref_aa} @{$gt->{gt_aa}};
		push @ord_aas, sort grep {$_ ne $ref_aa} @{$gt->{gt_aa}};
		my $aa_gt = join '|', @ord_aas;
		push @aa_gts, $aa_gt;
	    }
	    my $nt_gt_txt = join ';', @nt_gts;
	    my $aa_gt_txt = join ';', @aa_gts;

	    my $var_key = join(':', $chrom, $start, $ref_nt);
	    my $var_key_fmt = $var_key;
	    $var_key_fmt =~ s/\-/ins/;
	    $var_key_fmt =~ s/:/-/g;
	    $var_key_fmt = "<a href=${phv_gene}/$var_key_fmt.html>$var_key</a>";

	    $html .= "    <tr>\n";
	    $html .= "      <td>$code</th>\n";
	    $html .= "      <td>$var_key_fmt</th>\n";
	    $html .= "      <td>$chrom</th>\n";
	    $html .= "      <td>$start</th>\n";
	    $html .= "      <td>$type</th>\n";
	    $html .= "      <td>$ref_nt</th>\n";
	    $html .= "      <td>$nt_gt_txt</th>\n";
	    $html .= "      <td>$ref_aa</th>\n";
	    $html .= "      <td>$aa_gt_txt</th>\n";
	    $html .= "      <td>$score</th>\n";
	    $html .= "    </tr>\n";

	    
	    my %var_data = (phv_record  =>  $record,   	       
			    vst_record  =>  $vaast_record,     
			    var         =>  $var,      	       
			    base_name   =>  $base_name,
			    code        =>  $code,
			    var_key_fmt =>  $var_key_fmt,
			    chrom       =>  $chrom,    	       
			    start       =>  $start,    	       
			    type        =>  $type,     	       
			    ref_nt      =>  $ref_nt,   	       
			    nt_gt       =>  $ng_gt_txt,	       
			    ref_aa      =>  $ref_aa,   	       
			    aa_gt       =>  $aa_gt_txt,
		);
	    create_variant_page(\%var_data);
	}
    }
    
    $html .= << "END_HTML2";
      </tbody>
    </table>
  </body>
</html>      

END_HTML2

    my $filename = "$base_name/$phv_gene.html";
    open(my $OUT, '>', $filename) ||
	die "FATAL : cant_open_file_for_writing : $filename\n";
    
    print $OUT $html;

    close $OUT;
}

#--------------------------------------------------------------------------------

sub create_variant_page {

    my $var_data = shift @_;

    my ($record,
	$vaast_record,
	$var,
	$base_name,
	$code,
	$var_key_fmt,
	$chrom,
	$start,
	$type,
	$ref_nt,
	$ng_gt_txt,
	$ref_aa,
	$aa_gt_txt) =
	    @{$var_data}{qw(phv_record
                            vst_record
                            var
                            base_name
                            code
                            var_key_fmt
                            chrom
	                    start
                            type
			    ref_nt
			    nt_gt
			    ref_aa
			    aa_gt)};

    map {$_ = $_->[0] if ref $_ eq 'ARRAY'} ($var_key, $var_type,
					     $var_score, $het_gt_txt,
					     $hom_gt_txt, $nc_gt_txt);

    my ($chrom, $vaast_rank, $vaast_gene, $vaast_feature, $vaast_score, $vaast_pval) = 
	@{$vaast_record}{qw(chrom rank gene feature_id score p_value)};
    $vaast_rank++;

    my $html = << "END_HTML";
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
          <th></th>
	  <td>$code</th>\n";
        </tr>
        <tr>
          <th></th>
	  <td>$var_key_fmt</th>\n";
        </tr>
        <tr>
          <th></th>
	  <td>$chrom</th>\n";
        </tr>
        <tr>
          <th></th>
	  <td>$start</th>\n";
        </tr>
        <tr>
          <th></th>
	  <td>$type</th>\n";
        </tr>
        <tr>
          <th></th>
	  <td>$ref_nt</th>\n";
        </tr>
        <tr>
          <td>het_gt_txt</th>
          <td>$het_gt_txt</td>
        </tr>
        <tr>
          <td>hom_gt_txt</th>
          <td>$hom_gt_txt</td>
        </tr>
        <tr>
          <td>nc_gt_txt</th>
          <td>$nc_gt_txt</td>
        </tr>
        <tr>
          <th>nt_gt_txt</th>
	  <td>$nt_gt_txt</th>\n";
        </tr>
        <tr>
          <th>ref_aa</th>
	  <td>$ref_aa</th>\n";
        </tr>
        <tr>
          <th>aa_gt_txt</th>
	  <td>$aa_gt_txt</th>\n";
        </tr>
        <tr>
          <th>score</th>
	  <td>$score</th>\n";
        </tr>
      </tbody>
    </table>    

    <hr/>

END_HTML

    # xmy $var_key_fmt = $var_key;
    # $var_key_fmt =~ s/\-/ins/;
    # $var_key_fmt =~ s/:/-/g;
    # 	
    # for my $code (qw(TU T TR)) {
    # 	for my $var (@{$vaast_record->{$code}}) {
    # 
    # 	    my ($start, $type, $ref_nt, $ref_aa, $alt_nt, $score)
    # 		= @{$var}{qw(start type ref_nt ref_aa alt_nt score)};
    #     
    # 	    my (@nt_gts, @aa_gts);
    # 	    for my $gt_key (sort keys %{$var->{GT}}) {
    # 		my $gt = $var->{GT}{$gt_key};
    # 		#for my $gt (@{$var->{genotypes}}) {
    # 		
    # 		my @ord_nts = grep {$_ eq $ref_nt} @{$gt->{gt_nt}};
    # 		push @ord_nts, sort grep {$_ ne $ref_nt} @{$gt->{gt_nt}};
    # 		my $nt_gt = join '|', @ord_nts;
    # 		push @nt_gts, $nt_gt;
    # 		
    # 		my @ord_aas = grep {$_ eq $ref_aa} @{$gt->{gt_aa}};
    # 		push @ord_aas, sort grep {$_ ne $ref_aa} @{$gt->{gt_aa}};
    # 		my $aa_gt = join '|', @ord_aas;
    # 		push @aa_gts, $aa_gt;
    # 	    }
    # 	    my $nt_gt_txt = join ';', @nt_gts;
    # 	    my $aa_gt_txt = join ';', @aa_gts;
    # 
    # 	    $html .= "    <tr>\n";
    # 	    $html .= "      <td>TU</th>\n";
    # 	    $html .= "      <td>$var_key_fmt</th>\n";
    # 	    $html .= "      <td>$chrom</th>\n";
    # 	    $html .= "      <td>$start</th>\n";
    # 	    $html .= "      <td>$type</th>\n";
    # 	    $html .= "      <td>$ref_nt</th>\n";
    # 	    $html .= "      <td>$ref_aa</th>\n";
    # 	    $html .= "      <td>$alt_nt</th>\n";
    # 	    $html .= "      <td>$score</th>\n";
    # 	    $html .= "    </tr>\n";
    # 	}
    #     }
	    
    $html .= << "END_HTML2";
      </tbody>
    </table>
  </body>
</html>      

END_HTML2

    make_path("$base_name/$phv_gene");

    my $filename = "${base_name}/${phv_gene}/${var_key_fmt}.html";
    $filename =~ s/:/-/g;
    open(my $OUT, '>', $filename) ||
	die "FATAL : cant_open_file_for_writing : $filename\n";
    
    print $OUT $html;
    close $OUT;

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
