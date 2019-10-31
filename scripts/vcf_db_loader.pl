#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
use Digest::MD5 qw(md5_hex);

use Arty::VCF;
use Arty::Schema;

#-----------------------------------------------------------------------------
#----------------------------------- MAIN ------------------------------------
#-----------------------------------------------------------------------------
my $usage = "

Synopsis:

vcf_db_loader.pl variants.vcf vcf_db.sqlite

Description:

Load VCF files to an SQLite database.

";

my ($help);
my $opt_success = GetOptions('help'    => \$help,
			    );

die $usage if ! $opt_success;
print $usage if $help;

my ($vcf_file, $db_name) = @ARGV;
die $usage unless ($vcf_file && $db_name);

my $vcf = Arty::VCF->new(file => $vcf_file);

my $dbi_dsn = "dbi:SQLite:$db_name";

print STDERR "INFO : connecting_to_db : $dbi_dsn\n";
my $schema = Arty::Schema->connect($dbi_dsn);

my $gt_rs     = $schema->resultset('genotype');
my $sample_rs = $schema->resultset('sample');
my $var_rs    = $schema->resultset('variant');

# Load sample
my $samples = $vcf->{samples};
for my $sample_id (@{$samples}) {
  my $sample_row = $sample_rs->update_or_create({sample_id => $sample_id});
  print "INFO : loaded_sample: $sample_count ($sample_id)\n";
}

my $sample_idx = 0;
my %sample_key = map {$sample_idx++ => $_} @{$samples};


my $counter = 1;
RECORD:
while (my $record = $vcf->next_record) {

  my ($chrom, $pos, $ref, $alt) = @{$record}{qw(chrom pos ref alt)};
  my $key_txt = join ':', ($chrom, $pos, $ref, $alt);
  my $end = $pos + (length($ref) - 1);
  my $var_key = md5_hex($key_txt);
  my $bin = get_feature_bin($chrom, $pos, $end);

  # Load variant
  my %var_row_data = (bin      => $bin,
		      var_key  => $var_key,
		      chrom    => $record->{chrom},
		      start    => $record->{pos},
		      end      => $end,
		      ref      => $record->{ref},
		      alt      => $record->{alt},
		     );


  # Load info
  for my $key (qw(AA DB)) {
    my $lc_key = lc $key;
    $var_row_data{$lc_key} = $record->{info}{$key}
      if exists $record->{info}{$key};
  }

  my $var_row = $var_rs->update_or_create(\%var_row_data);

  Load genotype
  my $gt = $record->{gt};
  for my $gt_idx (0 .. $#{$gt}) {
    my $gt_data = $gt->[$gt_idx];
    my @keys = qw(GT DP AD FT GL GLE PL GP GQ HQ PS PQ);

    my %gt_row_data;
    for my $key (@keys) {
      my $lc_key = lc $key;
      next unless exists $gt_data->{$key};
      $gt_row_data{$lc_key} = join ',', @{$gt_data->{$key}}
    }
    my $gt_row = $gt_rs->update_or_create(\%gt_row_data);
  }

  print "INFO : loaded_variant: $counter ($chrom:$record->{pos})\n";
  $counter++;

}

#-----------------------------------------------------------------------------
#-------------------------------- SUBROUTINES --------------------------------
#-----------------------------------------------------------------------------

sub get_feature_bin {

  my ($chrom, $pos, $end) = @_;

  # my @feature_bins;
    my $count;
    my $bin;
  BIN:
    for my $bin_size (128_000, 1_000_000, 8_000_000, 64_000_000,
		      512_000_000) {
      $count++;
      my $start_bin = int($pos/$bin_size);
      my $end_bin   = int($end/$bin_size);
      my @these_bins = map {$_ = join ':', ($chrom, $count, $_)} ($start_bin .. $end_bin);
	if (! $bin && scalar @these_bins == 1) {
	  $bin = shift @these_bins;
	  last BIN;
	}
	#unshift @feature_bins, @these_bins;
    }
    #unshift @feature_bins, $bin;
    # return wantarray ? @feature_bins : \@feature_bins;
    return $bin;
}
