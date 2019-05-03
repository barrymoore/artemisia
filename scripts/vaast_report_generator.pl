#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;

use FindBin;
use lib "$FindBin::RealBin/../lib";

use Arty::VAAST;
use Arty::Utils qw(:all);

#-----------------------------------------------------------------------------
#----------------------------------- MAIN ------------------------------------
#-----------------------------------------------------------------------------

my $usage = "

Synopsis:

vaast_report_generator.pl           \
    --phevor       phevor.txt       \
    --cdr          cases.cdr        \
    --gff3         genes.gff3       \
    --case_vcf     cases.vcf.gz     \
    --control_vcf  controls.vcf.gz  \
    output.vaast

vaast_report_generator.pl --config config.yaml

Description:

Genorate detailed reports for VAAST runs that incorporates data from a
variety of sources.

";

my ($help, $phevor_file, $cdr_file, $gff3_file, $case_vcf_file, $control_vcf_file, $config);

my $opt_success = GetOptions('help'            => \$help,
			     'phevor|p=s'      =>  \$phevor_file,
			     'cdr|c=s'         =>  \$cdr_file,
			     'gff3|g=s'        =>  \$gff3_file,
			     'case_vcf|a=s'    =>  \$case_vcf_file,
			     'control_vcf|o=s' =>  \$control_vcf_file,
			     'config|g=s'      =>  \$config_file,
    );

die $usage if $help || ! $opt_success;

my $vaast_file = shift;
die $usage unless $file;

my $phevor = Arty::Phevor->new(file => $phevor_file)->all;

my $vaast = Arty::VAAST->new(file => $vaast_file);

while (my $record = $vaast->next_record) {

    print join "\t", @{$record}{qw(rank gene feature_id score p_value)};
    print "\n";

}

#-----------------------------------------------------------------------------
#-------------------------------- SUBROUTINES --------------------------------
#-----------------------------------------------------------------------------
