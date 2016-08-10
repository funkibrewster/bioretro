#!/usr/bin/perl
use strict;
use warnings FATAL => 'all';

use List::MoreUtils qw(uniq);

# read in patient table
my $patients = 'rsave/patients.csv';
open(my $fh, '<:encoding(UTF-8)', $patients)
  or die "Could not open file '$patients' $!";

chomp(my @lines = <$fh>);
close $fh;

shift @lines;

my %genes;
my @allgenes;
my @children;


foreach my $line (@lines) {
  my ($familyId, $childId, $paternalId, $maternalId, $gender, $md) = split(/,/, $line);
  if ($paternalId ne 'NA' && $maternalId ne 'NA') {
    my $trioChildFreqs = "../wgsresults/$childId.trio.freq.csv";
    if (-e $trioChildFreqs) {
      open(my $freqfh, '<:encoding(UTF-8)', $trioChildFreqs)
        or warn "Could not open file '$trioChildFreqs' $!";

      chomp(my @genelines = <$freqfh>);
      close $freqfh;

      shift @genelines;

      push @children, $childId;

      foreach my $geneline (@genelines) {
        my ($gene, $childCount, $fatherCount, $motherCount, $change) = split(/,/, $geneline);
        $genes{$gene}{$childId} = $childCount;
        $genes{$gene}{$childId."father"} = $fatherCount;
        $genes{$gene}{$childId."mother"} = $motherCount;
        $genes{$gene}{$childId."change"} = $change;
        push @allgenes, $gene;

      }

    }
  }
}

@allgenes = uniq @allgenes;
@allgenes = sort @allgenes;

my $trioOutput = "all.trio.freq.csv";
open(my $tfh, '>:encoding(UTF-8)', $trioOutput)
  or die "Could not open file '$trioOutput' \n";

printf $tfh "gene";
foreach my $child (@children) {
  printf $tfh ",$child,$child.father,$child.mother,change"
}
print $tfh "\n";
foreach my $gene (@allgenes) {
  printf $tfh "$gene";
  foreach my $child (@children) {
    my $childCount = (exists $genes{$gene}{$child} ? $genes{$gene}{$child} : 0);
    my $fatherCount = (exists $genes{$gene}{$child."father"} ? $genes{$gene}{$child."father"} : 0);
    my $mothercount = (exists $genes{$gene}{$child."mother"} ? $genes{$gene}{$child."mother"} : 0);
    my $change = (exists $genes{$gene}{$child."change"} ? $genes{$gene}{$child."change"} : "NA");
    printf $tfh ",$childCount,$fatherCount,$mothercount,$change";
  }
  print $tfh "\n";
}