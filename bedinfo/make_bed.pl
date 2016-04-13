#!/usr/bin/perl
use strict;
use warnings;

my @lines = <>;
chomp @lines;

foreach my $line (@lines) {

  my ($chr, $pos, $reads) = split( /\t/, $line );

  if ($pos != 0) {
    printf "%s\t%d\t%d\t%d\n", $chr, $pos - 1, $pos, $reads;
  }

}
