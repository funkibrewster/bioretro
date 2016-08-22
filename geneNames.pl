#!/usr/bin/perl
use strict;
use warnings FATAL => 'all';

use List::MoreUtils qw(uniq);
use GeneData;

my @lines = <>;
foreach my $line (@lines) {
  if ($line =~ /\s*([\d]+)\s([\S]+)/) {
    my $count = $1;
    my $gene = $2;
    my $genename = GeneData::GetGeneName($gene);
    print "$gene|$genename\n";
  }
}
