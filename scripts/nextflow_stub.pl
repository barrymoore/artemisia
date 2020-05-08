#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;

#-----------------------------------------------------------------------------
#----------------------------------- MAIN ------------------------------------
#-----------------------------------------------------------------------------
my $usage = "

Synopsis:

nextflow_stub
nextflow_stub --output filename
nextflow_stub -c

Description:

This script will produce a stub nextflow file for use with Nextflow
pipelines.  Output is written to a file named nextflow file unless the
--output option is given below.

Options:

  --output, -o filename

    The script writes it's output to a file named nextflow file unless an
    value is provided to this option in which case that value will be
    used as the filename.  If the value to this option is '-', then
    output will be written to STDOUT.

  --config, -c

    Write a stub config file in addition to the nextflow file stub.  The
    output will be written to nextflow.cfg unless an option is given
    to --output in which case output will be written to filename.cfg
    where filename is the value given to --output.

";


my ($help, $output, $config);
my $opt_success = GetOptions('help'     => \$help,
			     'output=s' => \$output,
			     'config'   => \$config,
    );

die $usage if $help || ! $opt_success;

$output ||= 'pipeline.nf';
$config = lc "$output.cfg" if $config;

if (-e $output) {
    die("FATAL : pipeline_exists : $output exists and this script will " .
	"not overwite an existing file.  Please use the --output "   .
	"option to provide a unique filename.\n");
}
if ($config && -e $config) {
    die("FATAL : config_file_exists : ${output}.cfg exists and this script will " .
	"not overwite an existing config file.  Please use the --output "   .
	"option to provide a filename that is unique for the config file.\n");
}

open(my $OUT, '>', $output) or die "FATAL : cant_open_file_for_writing : $output\n";

my $CFG;
if ($config) {
    open($CFG, '>', $config) or die "FATAL : cant_open_file_for_writing : $config\n";
}

if ($CFG) {
    print $OUT 'configfile: "nextflow.config"';
    print $OUT "\n\n";
}

print $OUT '#!/usr/bin/env nextflow

projects = Channel.from(\'Project_ID1\', \'Project_ID2\')

// Project Data
params = \'/usr/local/GenomeAnalysisTK-3.6/GenomeAnalysisTK.jar\'
fastq_pairs = Channel.fromFilePairs(\'./FastQ/*_chr19_{1,2}.fastq.gz\')

// Pipeline Data
reference_genome = file(\'/archive04/data/GATK/bundle/2.8/b37/human_g1k_v37_decoy.fasta\')
mills_indel = file(\'/archive04/data/GATK/bundle/2.8/b37/Mills_and_1000G_gold_standard.indels.b37.vcf\')
g1k_indel = file(\'/archive04/data/GATK/bundle/2.8/b37/1000G_phase1.indels.b37.vcf\')
g1k_snp = file(\'/archive04/data/GATK/bundle/2.8/b37/1000G_phase1.snps.high_confidence.b37.vcf\')
dbsnp = file(\'/archive04/data/GATK/bundle/2.8/b37/dbsnp_137.b37.vcf\')
omni = file(\'/archive04/data/GATK/bundle/2.8/b37/1000G_omni2.5.b37.vcf\')
hapmap = file(\'/archive04/data/GATK/bundle/2.8/b37/hapmap_3.3.b37.vcf\')

process bwa_mem {
  tag {sample_id}

  input:
  set sample_id, file(fastq_pair) from fastq_pairs
  
  output:
  set sample_id, file(\'aligned_deduped.bam\') into aligned_bam
  
  cpus 18
  
  """
  bwa mem \\
  -R \'@RG	ID:${sample_id}	SM:${sample_id}	PL:ILLUMINA\' \\
  -t ${task.cpus} ${reference} ${fastq_pair} \\
  | samblaster --addMateTags \\
  | sambamba view -f bam -l 0 -S /dev/stdin \\
  | sambamba sort -m 50G -o aligned_deduped.bam /dev/stdin
  """
}

// Create duplicate channels because the files will be consumed by two
// processes.
aligned_bam.into {aligned_bam_for_targets; aligned_bam_for_realigner}

process RealignerTargetCreator {
  tag {sample_id}

  input:
  set sample_id, file(\'aligned_deduped.bam\') from aligned_bam_for_targets
  
  output:
  set sample_id, file(\'target.intervals\') into realign_intervals
  
  cpus 18
  
  """
  java -jar -Xmx20g -Djava.io.tmpdir=/dev/shm ${gatk_jar} \\
  -T RealignerTargetCreator \\
  -R ${reference} \\
  -L 19 \\
  -I aligned_deduped.bam \\
  --num_threads ${task.cpus} \\
  --known ${mills_indel} \\
  --known ${g1k_indel} \\
  -o target.intervals
  """
}

process IndelRealigner {
  tag {sample_id}
  
  input:
  set sample_id, file(\'aligned_deduped.bam\') from aligned_bam_for_realigner
  set sample_id_ignore, file(\'target.intervals\') from realign_intervals
  
  output:
  set sample_id, file(\'realigned.bam\') into realigned_bams
  
  """
  java -jar -Xmx4g -Djava.io.tmpdir=/dev/shm ${gatk_jar} \\
  -T IndelRealigner \\
  -R ${reference} \\
  -L 19 \\
  -I aligned_deduped.bam \\
  -targetIntervals target.intervals \\
  -known ${mills_indel} \\
  -known ${g1k_indel} \\
  -o realigned.bam
  """
}

realigned_bams.into {realigned_bams_for_table; realigned_bams_for_printreads}

process BaseRecalibrator {
  tag {sample_id}
  
  input:
  set sample_id, file(\'realigned.bam\') from realigned_bams_for_table
  
  output:
  set sample_id, file(\'recalibration.table\') into recalibration_tables
  
  cpus 8
  
  """
  java -jar -Xmx8g -Djava.io.tmpdir=/dev/shm ${gatk_jar} \\
  -T BaseRecalibrator \\
  -R ${reference} \\
  -I realigned.bam \\
  --num_cpu_threads_per_data_thread ${task.cpus} \\
  --knownSites ${dbsnp} \\
  --knownSites ${mills_indel} \\
  --knownSites ${g1k_indel} \\
  -o recalibration.table
  """
}

process PrintReads {
  tag {sample_id}

  input:
  set sample_id, file(\'realigned.bam\') from realigned_bams_for_printreads
  set sample_id_ignore, file(\'recalibration.table\') from recalibration_tables

  output:
  set sample_id, file(\'recalibrated.bam\') into recalibrated_bams

  cpus 8
  
  """
  java -jar -Xmx8g -Djava.io.tmpdir=/dev/shm ${gatk_jar} \\
  -T PrintReads \\
  --num_cpu_threads_per_data_thread ${task.cpus} \\
  -R ${reference} \\
  -I realigned.bam \\
  -BQSR recalibration.table \\
  -o recalibrated.bam
  """
}

process HaplotypeCaller {
  tag {sample_id}
  
  input:
  set sample_id, file(\'recalibrated.bam\') from recalibrated_bams

  output:
  file(\'variants.gvcf\') into sample_gvcfs
  
  """
  java -jar -Xmx8g -Djava.io.tmpdir=/dev/shm ${gatk_jar} \\
  -T HaplotypeCaller \\
  -R ${reference} \\
  --min_base_quality_score 20 \\
  --variant_index_parameter 128000 \\
  --standard_min_confidence_threshold_for_calling 30.0 \\
  --variant_index_type LINEAR \\
  --standard_min_confidence_threshold_for_emitting 30.0 \\
  --num_cpu_threads_per_data_thread 8 \\
  -ERC GVCF \\
  -L 19 \\
  -I recalibrated.bam \\
  -o variants.gvcf
  """
}

process GenotypeGVCFs {
  tag {project_id}

  input:
  // Note the toList call here pulls the gVCF files into a single list
  // to be processed all at once.
  file(\'variants??.gvcf\') from sample_gvcfs.toList()
  val project_id from projects
  
  output:
  set project_id, file(\'project.vcf\') into project_vcf_for_snps, project_vcf_for_indels
  
  """
  java -jar -Xmx8g -Djava.io.tmpdir=/dev/shm ${gatk_jar} \\
  -T GenotypeGVCFs \\
  -R ${reference} \\
  -L 19 \\
  --num_threads ${task.cpus} \\
  --dbsnp ${dbsnp} \\
  -o project.vcf \\
  -V variants01.gvcf \\
  -V variants02.gvcf \\
  -V variants03.gvcf \\
 """
}

process VariantRecalibrator_SNP {
  tag {project_id}

  input:
  set project_id, file(\'project.vcf\') from project_vcf_for_snps

  output:
  set project_id, file(\'snp_recal\'), file(\'snp_tranches\'), file(\'snp_plots.R\') into vqsr_output_snps

  """
  java -jar -Xmx8g -Djava.io.tmpdir=/dev/shm ${gatk_jar} \\
  -T VariantRecalibrator \\
  -R ${reference} \\
  --minNumBadVariants 5000 \\
  --num_threads ${task.cpus} \\
  -resource:hapmap,known=false,training=true,truth=true,prior=15.0 ${hapmap} \\
  -resource:omni,known=false,training=true,truth=true,prior=12.0 ${omni} \\
  -resource:1000G,known=false,training=true,truth=false,prior=10.0 ${g1k_snp} \\
  -L 19 \\
  -an QD \\
  -an MQRankSum \\
  -an ReadPosRankSum \\
  -an FS \\
  -input project.vcf \\
  -recalFile snp_recal \\
  -tranchesFile snp_tranches \\
  -rscriptFile snp_plots.R \\
  -mode SNP
  """  
}

process VariantRecalibrator_INDEL {
  tag {project_id}

  input:
  set project_id, file(\'project.vcf\') from project_vcf_for_indels

  output:
  set project_id, file(\'indel_recal\'), file(\'indel_tranches\'), file(\'indel_plots.R\') into vqsr_output_indels

  cpus 24

  """
  java -jar -Xmx8g -Djava.io.tmpdir=/dev/shm ${gatk_jar} \\
  -T VariantRecalibrator \\
  -R ${reference} \\
  --minNumBadVariants 5000 \\
  --num_threads ${task.cpus} \\
  -resource:mills,known=false,training=true,truth=true,prior=12.0 ${mills_indel} \\
  -resource:1000G,known=false,training=true,truth=true,prior=10.0 ${g1k_indel} \\
  -L 19 \\
  -an MQRankSum \\
  -an ReadPosRankSum \\
  -an FS \\
  -input project.vcf \\
  -recalFile indel_recal_data \\
  -tranchesFile indel_tranches \\
  -rscriptFile indel_plots.R \\
  -mode INDEL
  """
}
';

exit 0 unless $CFG;

print $CFG '// Comment

/*
Multiline
comment
*/

name = value

process.executor = \'sge\'

// Config Scope
alpha.x  = 1
alpha.y  = \'string value..\'

beta {
     p = 2
     q = \'another string ..\'
}

// Config env

env.ALPHA = \'some value\'
env.BETA = "$HOME/some/path"

env {
     DELTA = \'one more\'
     GAMMA = "/my/path:$PATH"
}

// Config params
params.custom_param = 123
params.another_param = \'string value .. \'

params {

   alpha_1 = true
   beta_2 = \'another string ..\'

}

// Scope process
process {
  executor=\'sge\'
  queue=\'long\'
  clusterOptions = \'-pe smp 10 -l virtual_free=64G,h_rt=30:00:00\'
}

includeConfig \'path/foo.config\'

';
