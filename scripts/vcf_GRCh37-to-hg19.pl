#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;

use Arty::VCF;

#-----------------------------------------------------------------------------
#----------------------------------- MAIN ------------------------------------
#-----------------------------------------------------------------------------
my $usage = "

Name:

vcf_GRCh37-hg19

Synopsis:

# All three commands below map GRCh37 chromosome names to hg19 convention
vcf_GRCh37-hg19 variants_grch37.vcf.gz | bgzip > variant_hg19.vcf.gz
vcf_GRCh37-hg19 --ts2nt variants_grch37.vcf.gz | bgzip > variant_hg19.vcf.gz

# Read from STDIN
zcat variants_grch37.vcf.gz | vcf_GRCh37-hg19 - | bgzip > variant_hg19.vcf.gz

# Round tripped files are identical
vcf_GRCh37-hg19 -t variants_grch37.vcf.gz | vcf_GRCh37-hg19 -n - | bgzip > variant_hg19.vcf.gz

# Don't drop the mito chromosome (caveat emptor - see below).
vcf_GRCh37-hg19 --nt2ts -k variants_hg19.vcf.gz | bgzip > variant_GRCh37.vcf.gz

Description:

Convert a VCF file in GRCh37 format (i.e. chrmosome names like 1, 2,
3...X, Y, MT) to hg19 format (i.e. chromosome names like chr1, chr2,
chr3...chrX, chrY, chrM) and vise versa.  The GRCh37 assembly sequence
is distributed by the Genome Reference Consortium whereas the hg19
assembly sequence is distributed by the UCSC Genomics Institute.

Note that this tool does not do anything to address other differences
between the two assemblies including:

The two assemblies use a different mitochondrial genome.  According
the the UCSC Genome Browser:
\(https://genome.ucsc.edu/cgi-bin/hgGateway\)

    'Since the release of the UCSC hg19 assembly, the Homo sapiens
    mitochondrion sequence (represented as 'chrM' in the Genome
    Browser) has been replaced in GenBank with the record
    NC_012920. We have not replaced the original sequence, NC_001807,
    in the hg19 Genome Browser. We plan to use the Revised Cambridge
    Reference Sequence (rCRS) in the next human assembly release.'

The differences in the two mitochrondrial genomes assemblies include
differences in both sequence and coordinates, so the two assemblies
are not interchangable.  This tool will simply drop the mitochrondrial
chromosome during converstion (but see the --keep_mito option).

The GRC has released a number of patches to the GRCh37 assembly over
time which makes coordinate conservative sequence updates.  The hg19
assembly does not have these updates and this tool does not address
those changes in anyway.

Options:

  --ts2nt, t

    Map a GRCh37 VCF file to an hg19 VCF file by adding chr before the
    chromosome name in the ##contig header tags and in column 1 of
    variant lines.  This is the default behavior, so you only need to
    provide this command line option if you want to command line to
    explicitly show this.

  --nt2th, n

    Map a hg19 VCF file to a GRCh37 VCF file by removing chr from
    chromosome name in the ##contig header tags and in column 1 of the
    VCF file.

  --keep_mito, -k

    Keep the mitochondrial chromosome and ignore differences in the
    mitochondrial genome assembly sequenes.

";

my ($help, $ts2nt, $nt2ts, $keep_mito);
my $opt_success = GetOptions('help'        => \$help,
			     'ts2nt|t'     => \$ts2nt,
			     'nt2ts|n'     => \$nt2ts,
			     'keep_mito|k' => \$keep_mito,
			     );

die $usage if $help || ! $opt_success;

my $file = shift;
die $usage unless $file;

my $file_descriptor = ($file =~ /\.b?gz$/ ?
		       "gunzip -c $file |" :
		       "< $file");

open (my $IN, $file_descriptor) or die ("FATAL : cant_open_file_or_" .
					"pipe_for_reading : " .
					"$file_descriptor\n");

my %map;
if ($nt2ts) {
    %map = (
	'chr1'   =>  '1',
	'chr2'   =>  '2',
	'chr3'   =>  '3',
	'chr4'   =>  '4',
	'chr5'   =>  '5',
	'chr6'   =>  '6',
	'chr7'   =>  '7',
	'chr8'   =>  '8',
	'chr9'   =>  '9',
	'chr10'  =>  '10',
	'chr11'  =>  '11',
	'chr12'  =>  '12',
	'chr13'  =>  '13',
	'chr14'  =>  '14',
	'chr15'  =>  '15',
	'chr16'  =>  '16',
	'chr17'  =>  '17',
	'chr18'  =>  '18',
	'chr19'  =>  '19',
	'chr20'  =>  '20',
	'chr21'  =>  '21',
	'chr22'  =>  '22',
	'chrX'   =>  'X',
	'chrY'   =>  'Y',
	'chrM'   =>  'MT',
	);
}
else {
    %map = (
	'1'   =>  'chr1',
	'2'   =>  'chr2',
	'3'   =>  'chr3',
	'4'   =>  'chr4',
	'5'   =>  'chr5',
	'6'   =>  'chr6',
	'7'   =>  'chr7',
	'8'   =>  'chr8',
	'9'   =>  'chr9',
	'10'  =>  'chr10',
	'11'  =>  'chr11',
	'12'  =>  'chr12',
	'13'  =>  'chr13',
	'14'  =>  'chr14',
	'15'  =>  'chr15',
	'16'  =>  'chr16',
	'17'  =>  'chr17',
	'18'  =>  'chr18',
	'19'  =>  'chr19',
	'20'  =>  'chr20',
	'21'  =>  'chr21',
	'22'  =>  'chr22',
	'X'   =>  'chrX',
	'Y'   =>  'chrY',
	'MT'  =>  'chrM',
	);
}

 LINE:
    while (my $line = <$IN>) {
	if ($line !~ /^\#/) {
	    my ($chr, $line_part) =
		split(/\t/, $line, 2);
	    next LINE if (! $keep_mito && ($chr eq 'chrM' || $chr eq 'MT'));
	    $chr = (exists $map{$chr} ? $map{$chr} : $chr);
	    $line = join "\t", $chr, $line_part;
	}
	elsif ($line =~ /^\#\#contig=<ID=(.*?),/) {
	    my $chr = exists $map{$1} ? $map{$1} : $1;
	    $line =~ s/^\#\#contig=<ID=(.*?),/\#\#contig=<ID=${chr},/;
	}
	print $line;
}
