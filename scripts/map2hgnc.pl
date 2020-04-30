#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;

#-----------------------------------------------------------------------------
#----------------------------------- MAIN ------------------------------------
#-----------------------------------------------------------------------------
my $usage = "

Synopsis:

# Map IDs to HGNC gene symbols by default
map2hgnc --cols 0,5 --hgnc hgnc_complete_set.txt input_data.txt

# Use scripts hard coded mapping and output HGNC gene name rather than symbol.
map2hgnc --cols 0,5 --name input_data.txt

Description:

This script will map a variety of gene IDs from the HGNC data mapping
file to HGNC gene symbols.

Options:

  --cols, -i 0,1,2

    A comma separated list of (0-based) column IDs to map.  Default is
    to map the first column.

  --hgnc, -h hgnc_complete_set.txt

    The HGNC data file.  Can be downloaded from:
    (ftp://ftp.ebi.ac.uk/pub/databases/genenames/new/tsv/hgnc_complete_set.txt)
    Default will use the file at the above network location as long as
    there is an internet connection.

  --id, -i

    Map the provided comma separated list of IDs rather than data from
    a provided file or STDIN.

  --name

    Output the HGNC gene name instead of the HGNC gene symbol.

  --summary, -s

    Print a formatted summary of all HGNC information for each gene.

  --html, -h

    Open a browser to an HTML page summary of HGNC information for
    each gene.  Not implimented yet.

  --cards, -d

    Open a browser to Gene Cards page for the first gene in the
    list. Not implimented yet.

  --open, -o

    Provide the name of a browser to view HTML based output and the
    script will exit by opening the browser with the data loaded. Not
    implimented yet.

";


my ($help, $col_txt, $hgnc, $id, $name, $summary, $html, $cards,
    $open);

my $opt_success = GetOptions('help'      => \$help,
			     'cols|c=s'  => \$col_txt,
			     'hgnc|h=s'  => \$hgnc,
			     'id|i=s'    => \$id,
			     'name|n'    => \$name,
			     'summary|s' => \$summary,
			     'html|t'    => \$html,
			     'cards|d'   => \$cards,
			     'open|o=s'  => \$open,
			    );

die $usage if $help || ! $opt_success;

$col_txt ||= '0';

my ($data, $map) = get_map($hgnc);

my $file = shift;
die $usage unless $file || $id;

if ($summary) {
  print_summary($id, $file, $data, $map, $col_txt);
}
elsif ($html) {
  print_html($id, $file, $data, $map, $col_txt, $open);
}
elsif ($cards) {
  print_cards($id, $file, $data, $map, $col_txt, $open);
}
else {
  map_ids($id, $file, $data, $map, $col_txt);
}

exit 0;

#-----------------------------------------------------------------------------
#-------------------------------- SUBROUTINES --------------------------------
#-----------------------------------------------------------------------------

sub get_map {

  my $hgnc = shift;

  my $mode = '<';

  if (! $hgnc) {
    my $local_file = "$ENV{HOME}/.hgnc/hgnc_complete_set.txt";
    if (-e $local_file) {
      $hgnc = $ENV{HOME} . '/.hgnc/hgnc_complete_set.txt';
    }
  }

  if (! $hgnc) {
    warn "WARN : downloading_hgnc_file : ftp://ftp.ebi.ac.uk/pub/databases/genenames/new/tsv/hgnc_complete_set.txt\n";
    warn "INFO : save_local_copy : To avoid downloads do: mkdir -p $ENV{HOME}/.hgnc && curl ftp://ftp.ebi.ac.uk/pub/databases/genenames/new/tsv/hgnc_complete_set.txt > $ENV{HOME}/.hgnc/hgnc_complete_set.txt";
    $mode = '-|';
    $hgnc = 'curl -s ftp://ftp.ebi.ac.uk/pub/databases/genenames/new/tsv/hgnc_complete_set.txt';
  }

  open(my $IN, $mode, $hgnc) or die "FATAL : cant_open_file_for_reading : $hgnc\n";

  my $header = <$IN>;

  my (%data, %map);
  while (my $line = <$IN>) {

    chomp $line;
    my @columns = split /\t/, $line;

    my $hgnc_symb = $columns[1];

    @{$data{$hgnc_symb}}{qw(hgnc_id symbol name locus_group locus_type
			    status location location_sortable
			    alias_symbol alias_name prev_symbol
			    prev_name gene_family gene_family_id
			    date_approved_reserved date_symbol_changed
			    date_name_changed date_modified entrez_id
			    ensembl_gene_id vega_id ucsc_id ena
			    refseq_accession ccds_id uniprot_ids
			    pubmed_id mgd_id rgd_id lsdb cosmic
			    omim_id mirbase homeodb snornabase
			    bioparadigms_slc orphanet pseudogene.org
			    horde_id merops imgt iuphar
			    kznf_gene_catalog mamit-trnadb cd lncrnadb
			    enzyme_id intermediate_filament_db)} =
			    @columns;

    map {$_ ||= '';s/\"//g;$_ = [split /\|/, $_]} values %{$data{$hgnc_symb}};

    for my $ids (@{$data{$hgnc_symb}}{qw(hgnc_id name alias_symbol
					   alias_name prev_symbol prev_name entrez_id
					   ensembl_gene_id vega_id ucsc_id ena
					   refseq_accession ccds_id uniprot_ids pubmed_id
					   mgd_id rgd_id lsdb cosmic omim_id mirbase homeodb
					   snornabase bioparadigms_slc orphanet
					   pseudogene.org horde_id merops imgt iuphar
					   kznf_gene_catalog mamit-trnadb cd lncrnadb
					   enzyme_id intermediate_filament_db)}) {
      next unless scalar @{$ids};
      for my $id (@{$ids}) {
	push @{$map{$id}}, $hgnc_symb;
      }
    }
    print '';
  }
  return \%data, \%map;
}

#-----------------------------------------------------------------------------

sub map_ids {

  my ($id, $file, $data, $map, $col_txt) = @_;

  my @cols = split /,/, $col_txt;

  my $IN;
  if ($id) {
    my @ids = split /,/, $id;
    my $id_txt;
    map {$id_txt .= "$_\t$_\n"} @ids;
    @cols = (1);
    open ($IN, '<', \$id_txt) or die "FATAL : cant_open_scalar_for_reading : $id\n";
  }
  else {
    open ($IN, '<', $file) or die "Can't open $file for reading\n$!\n";
  }

  while (my $line = <$IN>) {

    chomp $line;
    my @columns = split /\t/, $line;
    my @ids = @columns[@cols];
    my @mapped_ids;
    for my $id (@ids) {
      if (exists $map->{$id}) {
	my $new_id = join "|", @{$map->{$id}};
	push @mapped_ids, $new_id;
      }
      else {
	push @mapped_ids, $id;
      }
    }
    @columns[@cols] = @mapped_ids;
    print join "\t", @columns;
    print "\n";
    print '';
  }
}

#-----------------------------------------------------------------------------

sub print_summary {
  my ($id, $file, $data, $map, $col_txt) = @_;

  my @cols = split /,/, $col_txt;

  my $IN;
  if ($id) {
    my @ids = split /,/, $id;
    my $id_txt;
    map {$id_txt .= "$_\t$_\n"} @ids;
    @cols = (1);
    open ($IN, '<', \$id_txt) or die "FATAL : cant_open_scalar_for_reading : $id\n";
  }
  else {
    open ($IN, '<', $file) or die "Can't open $file for reading\n$!\n";
  }

  while (my $line = <$IN>) {

    chomp $line;
    my @columns = split /\t/, $line;
    my @ids = @columns[@cols];
    my @mapped_ids;
    for my $id (@ids) {
      if (exists $map->{$id}) {
	my @mapped_ids = @{$map->{$id}};
	for my $mapped_id (@mapped_ids) {
	  my $gene_data = $data->{$mapped_id};
	  for my $key (qw(hgnc_id
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
			  mirbase
			  homeodb
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
			)) {
	    print "$key: ";
	    print join " | ", @{$gene_data->{$key}};
	    print "\n";
	    print '';
	  }
	}
      }
    }
    print '';
  }
}

#-----------------------------------------------------------------------------

sub print_html {
  my ($id, $file, $data, $map, $col_txt, $open) = @_;
  die "FATAL : not_yet_implimented : print_summary\n";
}

#-----------------------------------------------------------------------------

sub print_cards {
  my ($id, $file, $data, $map, $col_txt, $open) = @_;
  die "FATAL : not_yet_implimented : print_summary\n";
}

#-----------------------------------------------------------------------------

# hgnc_id
# symbol
# name
# locus_group
# locus_type
# status
# location
# location_sortable
# alias_symbol
# alias_name
# prev_symbol
# prev_name
# gene_family
# gene_family_id
# date_approved_reserved
# date_symbol_changed
# date_name_changed
# date_modified
# entrez_id
# ensembl_gene_id
# vega_id
# ucsc_id
# ena
# refseq_accession
# ccds_id
# uniprot_ids
# pubmed_id
# mgd_id
# rgd_id
# lsdb
# cosmic
# omim_id
# mirbase
# homeodb
# snornabase
# bioparadigms_slc
# orphanet
# pseudogene.org
# horde_id
# merops
# imgt
# iuphar
# kznf_gene_catalog
# mamit-trnadb
# cd
# lncrnadb
# enzyme_id
# intermediate_filament_db
