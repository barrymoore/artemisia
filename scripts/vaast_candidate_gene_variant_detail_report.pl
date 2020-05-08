#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;

use Arty::VAAST;
use Arty::VCF;
use Arty::TSV;

#-----------------------------------------------------------------------------
#----------------------------------- MAIN ------------------------------------
#-----------------------------------------------------------------------------

my $usage = "

Synopsis:

a1ad_table_report.pl --vcf Guthery-A1AD_VAAST.concat_cases_anno.vcf.gz \
                     --map ensg2enst2refseq.txt Guthery-A1AD_VAAST.vaast

Description:

A script to produce a table of candidate gene/variants for A1AD paper.

Options:

  --vcf, -v <variants.vcf>

    The VCF file to use.

  --map, -m <id_map.txt>

    A ENS/RefSeq maping file.

";

my ($help, $vcf_file, $map_file);

my $opt_success = GetOptions('help'    => \$help,
                             'vcf|v=s' => \$vcf_file,
			     'map|m=s' => \$map_file,
    );

die $usage if $help || ! $opt_success;

my $vaast_file = shift @ARGV;

die "$usage\n\nFATAL : missing_vaast_file(s)\n" unless $vaast_file;

my $vaast  = Arty::VAAST->new(file => $vaast_file);
my $mapper = Arty::TSV->new(file => $map_file);

my %map;
while (my $record = $mapper->next_record) {

    # #ensg            enst             ensp             refseq        refseq2
    # ENSG00000281230  ENST00000630425  ENSP00000486369  NM_001354173
    # ENSG00000281230  ENST00000630425  ENSP00000486369  NM_019605
    # ENSG00000281230  ENST00000630425  ENSP00000486369  NM_001375428
    
    my ($refseq, $ensp) = @{$record->{data}}[0,1];
    $map{$refseq}{$ensp}++;
}

print join "\t", qw(#gene transcript var_id rsid hgvs_txt exon_txt case_af controls_af gnmd_nfe_af var_score);
print "\n";

 VAAST:
    while (my $record = $vaast->next_record) {

	next VAAST if $record->{p_value} > 0.1;

	my ($chrom, $start, $end, $ref) = @{$record}{qw(chrom start end ref)};

	my $gene = $record->{gene};
	my $transcript = $record->{feature_id};
	$transcript =~ s/\..*//;
	my $locus = "$chrom:$start-$end";
	my $vcf_data = parse_vcf_region($locus);
	
      VAR:
	for my $var_key (keys %{$record->{vars}}) {
	    my $var = $record->{vars}{$var_key};
	    my $var_score = $var->{score};
	    next VAR unless $var_score > 0;

	    my $var_id = join ':', $chrom, @{$var}{qw(start ref_nt alt_nt)};
	    my ($rsid, $hgvs_txt, $exon_txt, $case_af, $controls_af, $gnmd_nfe_af);
	    if (exists $vcf_data->{$var_id}) {
		my $var_vcf_data = $vcf_data->{$var_id};
		$rsid = exists $var_vcf_data->{info}{rsID} ? $var_vcf_data->{info}{rsID}[0] : '.';
		my @hgvs_set;
		my @exons;
	      CSQ:
		for my $csq (@{$var_vcf_data->{info}{CSQ}}) {
		    my $hgvs = exists $csq->{hgvsp} ? $csq->{hgvsp} : '';
		    my $ensp = $hgvs;
		    $ensp =~ s/[\.:].*//;
		    next CSQ unless exists $map{$transcript}{$ensp};
		    $hgvs =~ s/.*?://;
		    my $exon = $csq->{exon};
		    push @hgvs_set, $hgvs;
		    push @exons, $exon;
		}
		$hgvs_txt = join ',', @hgvs_set;
		$hgvs_txt ||= 'NA';
		$exon_txt = join ',', @exons;
		$exon_txt ||= 'NA';
		
		$case_af     = $var_vcf_data->{info}{AF}[0];
		$controls_af = exists $var_vcf_data->{info}{controls_AF}    ? $var_vcf_data->{info}{controls_AF}[0]   : 0;
		$controls_af ||= 0;
		$gnmd_nfe_af = exists $var_vcf_data->{info}{gnomad_AF_nfe}  ? $var_vcf_data->{info}{gnomad_AF_nfe}[0] : 0;
		$gnmd_nfe_af ||= 0;
		print '';
	    }
	    else {
		($rsid, $hgvs_txt, $exon_txt, $case_af, $controls_af, $gnmd_nfe_af) = qw(NA NA NA NA NA NA);
	    }
	    print join "\t", $gene, $transcript, $var_id, $rsid, $hgvs_txt, $exon_txt, $case_af, $controls_af, $gnmd_nfe_af, $var_score;
	    print "\n";
	    print '';

	}
	print '';
}

#-------------------------------------------------------------------------------

sub parse_vcf_region {

    my $locus = shift @_;

    my $vcf = Arty::VCF->new(file =>  $vcf_file,
			     tabix => $locus);

    my %vcf_data;
    while (my $record = $vcf->next_record) {
	my ($chrom, $pos, $ref, $alt) = @{$record}{qw(chrom pos ref alt)};
	if (length $alt != length $ref) {
	  POP:
	    while (length($ref) && length($alt)) {
		if (substr($ref, 0, 1) eq substr($alt, 0, 1)) {
		    substr($ref, 0, 1, '');
		    substr($alt, 0, 1, '');
		}
		else {
		    last POP;
		}
	    }
	    $ref ||= '-';
	    $alt ||= '-';
	}
	my $var_key = join ':', ($chrom, $pos, $ref, $alt);
	$vcf_data{$var_key} = $record;
    }

    return wantarray ? %vcf_data : \%vcf_data;
    
}
