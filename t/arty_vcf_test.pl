#!/usr/bin/perl
use strict;
use warnings;

use Test::More;

BEGIN {
  use FindBin;
  use lib "$FindBin::RealBin/../lib";
  use_ok('Arty::VCF');
}

my $path = $0;
$path =~ s/[^\/]+$//;
$path ||= '.';
chdir($path);

my $parser = Arty::::VCF->new(file => 'data/test.vcf');

isa_ok($parser, 'GAL::Parser::VCFv4_1');

ok(my $record = $parser->next_record, '$parser->next_record');

ok($parser->parse_record($record), '$parser->parse_record');

while (my $variant = $parser->next_feature_hash) {
  ok($variant, 'variant parses');
}

done_testing();
