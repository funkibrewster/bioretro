#!/usr/bin/perl
use strict;
use warnings FATAL => 'all';

# read in known genes
my $known = 'known.retrogenes.csv';
open(my $fh, '<:encoding(UTF-8)', $known)
  or die "Could not open file '$known' $!";

chomp(my @genes = <$fh>);
close $fh;
my %hGenes = map { lc $_ => 1 } @genes;

my @lines = <>;
chomp @lines;

my @matchedKnown;

foreach my $line (@lines) {
  if ($line =~ /\s*([\d]+)\s([\w]+)/) {
    my $gene = $2;

    if (!exists($hGenes{(lc $gene)})) {
      print $line."\n";
    } else {
      push @matchedKnown, $gene;
    }
  }
}

if (scalar @matchedKnown > 0) {
  print STDERR "Found known retrogenes:\n";
  print STDERR join(', ', @matchedKnown);
  print STDERR "\n";
}