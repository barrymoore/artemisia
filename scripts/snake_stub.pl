#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;

#-----------------------------------------------------------------------------
#----------------------------------- MAIN ------------------------------------
#-----------------------------------------------------------------------------
my $usage = "

Synopsis:

snake_stub
snake_stub --output filename
snake_stub -c

Description:

This script will produce a stub Snakefile for use with Snakemake
pipelines.  Output is written to a file named Snakefile unless the
--output option is given below.

Options:

  --output, -o filename

    The script writes it's output to a file named Snakefile unless an
    value is provided to this option in which case that value will be
    used as the filename.  If the value to this option is '-', then
    output will be written to STDOUT.

  --config, -c

    Write a stub config file in addition to the Snakefile stub.  The
    output will be written to config.yaml unless an option is given
    to --output in which case output will be written to config.yaml
    where filename is the value given to --output.

";


my ($help, $output, $config);
my $opt_success = GetOptions('help'     => \$help,
			     'output=s' => \$output,
			     'config'   => \$config,
    );

die $usage if $help || ! $opt_success;

$output ||= 'Snakefile';
$config = "config.yaml" if $config;

if ($config) {
        if ($output) {
                $config = lc "$output.yaml";
        }
        else {
                $config = 'snakefile.yaml';
        }
}

if (-e $output) {
    die("FATAL : snakefile_exists : $output exists and this script will " .
	"not overwite an existing snakefile.  Please use the --output "   .
	"option to provide a unique filename.\n");
}

if ($config && -e $config) {
    die("FATAL : config_file_exists : $config exists and this script will " .
	"not overwite an existing config file.\n");
}

open(my $OUT, '>', $output) or die "FATAL : cant_open_file_for_writing : $output\n";

my $CFG;
if ($config) {
    open($CFG, '>', $config) or die "FATAL : cant_open_file_for_writing : $config\n";
}

if ($CFG) {
    print $OUT "configfile: \"$config\"";
    print $OUT "\n\n";
}

print $OUT '#--------------------------------------------------------------------------------
# TargetRule all
#--------------------------------------------------------------------------------

rule all:
    input:
        expand("file_{variable}.txt", variable=config["variable"]),
        "file_name.txt",

#--------------------------------------------------------------------------------
# rule_name
#--------------------------------------------------------------------------------

rule rule_name:
    input:
        var=config["config_value1"],
        f1="filename_{pattern}_1.txt",
        f2="filename_{pattern}_2.txt",
    output:
        "filename_{pattern}_2.output",
    log:
        "logs/rule_name_{pattern}.log",
    benchmark:
        "benchmarks/rule_name_{pattern}.txt",
    threads: config["threads"]
    shell:
      	"command "
      	"--option1 "
      	"-t {threads} "
      	"--output {output} "
      	"2> {log}"

';

exit 0 unless $CFG;

print $CFG '# Comment
scalar: value
array:
    - value1
    - value2
    - value3

list_of_hashes:
    - key1 : value1
      key2 : value2
    - key1 : value1
      key2 : value2
';

