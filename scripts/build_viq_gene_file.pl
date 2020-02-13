#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;

use Arty::GFF3;

#-----------------------------------------------------------------------------
#----------------------------------- MAIN ------------------------------------
#-----------------------------------------------------------------------------

my $usage = "

Synopsis:

build_viq_gene_file.pl -type mRNA,snRNA,snoRNA genes.gff3

Description:

Build the VIQ gene file.  The file has the following columns:

1. Chromosome
2. Start (transcript)
3. End (transcript)
4. Gene ID/Name
5. Transcript ID/Name

Options:

  --type, -t [mRNA]

    The transcript types that should be printed.

  --pad, -t [2000]

    Subtract/add the given padding (number nucleotides) to the start/end of each
    transcript.

";

my ($help, $type_txt, $pad);
my $opt_success = GetOptions('help|h'   => \$help,
                             'type|t=s' => \$type_txt,
                             'pad|p=i'  => \$pad,
    );

die $usage if $help || ! $opt_success;

$type_txt ||= 'mRNA';
$pad = 2000 unless defined $pad;

my %types;

map {$types{$_}++} split /,/, $type_txt;

my ($gff3_file) = @ARGV;
die $usage unless $gff3_file;


my $gff3 = Arty::GFF3->new(file => $gff3_file);

RECORD:
while (my $record = $gff3->next_record) {
        # Store transcripts
        if (exists $types{$record->{type}}) {

                my $id = $record->{attributes}{ID}[0];
                my $parent = $record->{attributes}{Parent}[0];
                my $type  = $record->{attributes}{biotype}[0];
                $type = $type eq 'protein_coding' ? 1 : 0;

                $record->{start} -= $pad;
                $record->{start} = 0 if $record->{start} < 0;
                $record->{end} += $pad;
                print join "\t", @{$record}{qw(chrom start end)}, $parent, $id, $type;
                print "\n";
                print '';
        }
        print '';
}
