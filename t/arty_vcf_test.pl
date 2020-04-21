#!/usr/bin/perl
use strict;
use warnings;

use lib "$ENV{HOME}/artemisia/lib/";
use Arty::VCF;
use Test::More;

BEGIN {
  use FindBin;
  use lib "$FindBin::RealBin/../../";
  use_ok('GAL::Parser::VCFv4_1');
}

my $path = $0;
$path =~ s/[^\/]+$//;
$path ||= '.';
chdir($path);

my $parser = GAL::Parser::VCFv4_1->new(file => 'data/1KG_VCF4_1_test.vcf');

isa_ok($parser, 'GAL::Parser::VCFv4_1');

ok(my $record = $parser->next_record, '$parser->next_record');

ok($parser->parse_record($record), '$parser->parse_record');

while (my $variant = $parser->next_feature_hash) {
  ok($variant, 'variant parses');
}

done_testing();
