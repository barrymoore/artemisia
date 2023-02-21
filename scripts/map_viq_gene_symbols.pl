#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
use FindBin;
use lib "$FindBin::RealBin/../lib";
use Arty::TSV;

#-----------------------------------------------------------------------------
#----------------------------------- MAIN ------------------------------------
#-----------------------------------------------------------------------------
my $usage = "

Synopsis:

map_viq_gene_symbols.pl --hgnc hgnc_complete_set.txt --fabric gene_synonym_2020_08.tsv gene_data.txt

Description:

A script to map gene aliases to valid HGNC symbols.  The script uses
an optional supplemental mapping file (see discussion below), an HGNC
mapping file hgnc_complete_set.txt and a mapping file supplied by
Fabric Genomics to map a column of existing symbols/aliases to
official HGNC symbols.

Options:

  --supp, -s

    A supplemental mapping file that is used to disambiguate
    multimapping aliases in the HGNC and Fabric mapping files.  It
    should be to columns with the first column a gene alias and the
    second column an official HGNC gene symbol.  In some cases the
    HGNC and Fabric mapping files both have a one-to-many mapping that
    can't be resolved without resorting to external information
    (i.e. genomic position or phenotype association).  This file can
    be used to force the choice of a alias->symbol mapping.  The
    provided file can only have a one-to-one or many-to-one mapping.
    The mappings in this file will be used before consulting the HGNC
    or Fabric data and thus will effectively override mappings in
    those two file.

  --hgnc, -h

    The HGCN official data file hgnc_complete_set.txt.  This file can
    be found at:

    ftp://ftp.ebi.ac.uk/pub/databases/genenames/hgnc/tsv/hgnc_complete_set.txt

  --fabric, -f

    The Fabric Genomics mapping file provided by the Fabric team.

  --column, -c

    The 0-based number for the alias/symbol column to be mapped.

  --help, -h

    Help me I'm melting!
";

my ($help, $supp_file, $hgnc_file, $fabric_file, $column);
my $opt_success = GetOptions('help'          => \$help,
			     'supp_file|s=s' => \$supp_file,
			     'hgnc|h=s'      => \$hgnc_file,
			     'column|c=s'    => \$column,
			     'fabric|f=s'    => \$fabric_file,
    );

die $usage if ! $opt_success;
print $usage if $help;

die "$usage\n\nFATAL : missing_required_column_option : $0 @ARGV\n" unless defined $column;

my $file = shift @ARGV;

die "$usage\n\nFATAL : missing_required_data_file :  $0 @ARGV\n"
    unless $file;

my %map_data;

if ($supp_file) {
    my $supp = Arty::TSV->new(file => $supp_file);

  SUPP_LINE:
    while (my $supp_record = $supp->next_record) {
	my ($alias, $symbol) = @{$supp_record->{data}};

	next SUPP_LINE if $alias eq $symbol;
	if (exists $map_data{supp}{$alias}) {
	    my $new = join ',', $map_data{supp}{$alias}, $symbol;
	    die "FATAL : multi_mapped_supp_alias_not_allowed : $alias => $new)\n";
	    print '';
	}
	$map_data{supp}{$alias} = $symbol;
  }

    print '';
}
else {
    $map_data{supp} = {};
}

my $hgnc = Arty::TSV->new(file => $hgnc_file);

my @hgnc_cols = qw(hgnc_id
		   symbol
		   name
		   locus_group
		   locus_type
		   status
		   location
		   location_sortable
		   alias_symbol
		   alias_name
		   prev_symbol
		   prev_name
		   gene_family
		   gene_family_id
		   date_approved_reserved
		   date_symbol_changed
		   date_name_changed
		   date_modified
		   entrez_id
		   ensembl_gene_id
		   vega_id
		   ucsc_id
		   ena
		   refseq_accession
		   ccds_id
		   uniprot_ids
		   pubmed_id
		   mgd_id
		   rgd_id
		   lsdb
		   cosmic
		   omim_id
		   mirbasehomeodb
		   snornabase
		   bioparadigms_slc
		   orphanet
		   pseudogene.org
		   horde_id
		   merops
		   imgt
		   iuphar
		   kznf_gene_catalog
		   mamit-trnadb
		   cd
		   lncrnadb
		   enzyme_id
		   intermediate_filament_db
		   rna_central_ids
		   lncipedia
		   gtrnadb
		   agr
		   mane_select
		   gencc
    );

 HGNC_LINE:
    while (my $arty_record = $hgnc->next_record) {
	my %record;
	@record{@hgnc_cols} = @{$arty_record->{data}};
	map {next unless defined $_;s/^"//;s/"$//} values %record;
	$map_data{hgnc_symbols}{$record{symbol}}++;
	print '';

	my @aliases = split /\|/, $record{alias_symbol};
	my @prev_symbols = split /\|/, $record{prev_symbol};
	my ($loc) = $record{location} =~ /^(\d+|X|Y|mitochondria)/i;
	$loc ||= 'ALL';

      HGNC_ALT:
	for my $alternate (@aliases, @prev_symbols) {
	    next HGNC_ALT if $alternate eq $record{symbol};
	    if (exists $map_data{hgnc}{$alternate}{$loc}) {
		my $current = join ',', keys(%{$map_data{hgnc}{$alternate}{$loc}});
		my $new = join ',', keys(%{$map_data{hgnc}{$alternate}{$loc}}), $record{symbol};
		print STDERR "WARN : multi_mapped_hgnc_alias : $alternate => $new)\n";
		print '';
	    }
	    $map_data{hgnc}{$alternate}{$loc}{$record{symbol}}++;
	    $map_data{hgnc}{$alternate}{ALL}{$record{symbol}}++;
      }
}
print '';

if ($fabric_file) {
    my $fabric = Arty::TSV->new(file => $fabric_file);

  FABRIC_LINE:
    while (my $fabric_record = $fabric->next_record) {
	my ($gene_id, $alias, $symbol) = @{$fabric_record->{data}};

	$map_data{fabric_symbols}{$symbol}++;
	next FABRIC_LINE if $alias eq $symbol;
	if (exists $map_data{fabric}{$alias}) {
	    my $new = join ',', keys(%{$map_data{fabric}{$alias}}), $symbol;
	    print STDERR "WARN : multi_mapped_fabric_alias : $alias => $new)\n";
	    print '';
	}
	$map_data{fabric}{$alias}{$symbol}++;
  }
     print '';
}
else {
    $map_data{fabric} = {};
    $map_data{fabric_symbols} = {};
}
print '';

my $data = Arty::TSV->new(file => $file);

if (exists $data->{header}) {
    print join "\n", @{$data->{header}};
    print "\n";
}

 DATA_LINE:
    while (my $data_record = $data->next_record) {
	my @cols = @{$data_record->{data}};
	my $gene = $cols[$column];

	if (exists $map_data{fabric_symbols}{$gene}) {
	    print STDERR "INFO : fabric_symbol_exists : Not mapping $gene\n";
	    print join "\t", @cols;
	    print "\n";
	    print '';
	}
	elsif (exists $map_data{supp}{$gene}) {
	    $cols[$column] = $map_data{supp}{$gene};
	    print STDERR "WARN : supplemental_mapped_symbol : $gene => $cols[$column]\n";
	    print join "\t", @cols;
	    print "\n";
	    print '';
	}
	else {
	    if (exists $map_data{fabric}{$gene}) {
		my @symbols = keys %{$map_data{fabric}{$gene}};
		if (scalar @symbols > 1) {
		    print STDERR "WARN : multi_mapped_fabric_alias_error : Not mapping $gene => @symbols\n";
		    print join "\t", @cols;
		    print "\n";
		    print '';
		}
		else {
		    ($cols[$column]) = keys %{$map_data{fabric}{$gene}};
		    print STDERR "WARN : fabric_mapped_symbol : $gene => $cols[$column]\n";
		    print join "\t", @cols;
		    print "\n";
		    print '';
		}
		print ''
	    }
	    elsif (exists $map_data{hgnc}{$gene}) {
		my @locs = keys %{$map_data{hgnc}{$gene}};
		my @symbols = keys %{$map_data{hgnc}{$gene}{ALL}};
		if (scalar @symbols > 1) {
		    print STDERR "WARN : multi_mapped_hgnc_alias_error : Not mapping $gene => @symbols\n";
		    if (scalar @locs > 2) {
			print STDERR "WARN : multi_mapped_hgnc_alias_has_locs : $gene => @locs\n";
		    }
		    print join "\t", @cols;
		    print "\n";
		    print '';
		}
		else {
		    ($cols[$column]) = keys %{$map_data{hgnc}{$gene}{ALL}};
		    print STDERR "WARN : hgnc_mapped_symbol : $gene => $cols[$column]\n";
		    print join "\t", @cols;
		    print "\n";
		    print '';
		}
	    }
	    else {
		print STDERR "WARN : unable_to_map_invalid_symbol : $gene\n";
		print join "\t", @cols;
		print "\n";
		print '';
	    }
	}
	print '';
}
print '';
