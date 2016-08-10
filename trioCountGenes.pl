#!/usr/bin/perl -w
use strict;
use warnings FATAL => 'all';

use List::Util qw[max min];

sub writeTrioGenes;

# read in patient table
my $patients = 'rsave/patients.csv';
open(my $fh, '<:encoding(UTF-8)', $patients)
  or die "Could not open file '$patients' $!";

chomp(my @lines = <$fh>);
close $fh;

shift @lines;

my %allfreq;

foreach my $line (@lines) {
  my ($familyId, $childId, $paternalId, $maternalId, $gender, $md) = split(/,/, $line);
  if ($paternalId ne 'NA' && $maternalId ne 'NA') {
    writeTrioGenes($childId, $paternalId, $maternalId);
  }
}


sub writeTrioGenes($$$) {
  my ($childId, $paternalId, $maternalId) = ($_[0], $_[1], $_[2]);
  # printf "Processing: Child[%s]: Father[%s], Mother[%s] ......\n", $childId, $paternalId, $maternalId;
  my $childFile = "../wgsresults/$childId.genes.txt";
  my $paternalFile = "../wgsresults/$paternalId.genes.txt";
  my $maternalFile = "../wgsresults/$maternalId.genes.txt";
  if (-e $childFile && -e $paternalFile && -e $maternalFile) {

  } else {
    warn "Trio files not complete\n";
  }

  open(my $fh, '<:encoding(UTF-8)', $childFile)
    or die "Could not open file '$childFile' \n";
  chomp(my @childGenes = <$fh>);
  close $fh;
  open($fh, '<:encoding(UTF-8)', $paternalFile)
    or die "Could not open file '$paternalFile' \n";
  chomp(my @fatherGenes = <$fh>);
  close $fh;
  open($fh, '<:encoding(UTF-8)', $maternalFile)
    or die "Could not open file '$maternalFile' \n";
  chomp(my @motherGenes = <$fh>);
  close $fh;

  my %child = readGeneFreq(@childGenes);
  my %father = readGeneFreq(@fatherGenes);
  my %mother = readGeneFreq(@motherGenes);

  my $trioOutput = "../wgsresults/$childId.trio.freq.csv";
  open($fh, '>:encoding(UTF-8)', $trioOutput)
    or die "Could not open file '$trioOutput' \n";

  printf $fh "#gene,$childId,$paternalId,$maternalId,change\n";

  foreach my $geneEl (sort keys %child) {
    my $freq = (exists $child{$geneEl} ? $child{$geneEl} : 0);
    my $fatherGeneFreq = (exists $father{$geneEl} ? $father{$geneEl} : 0);
    my $motherGeneFreq = (exists $mother{$geneEl} ? $mother{$geneEl} : 0);
    my $parentMax = max($fatherGeneFreq, $motherGeneFreq);
    my $parentMin = min($fatherGeneFreq, $motherGeneFreq);
    my $change;
    if ($parentMax == $freq) {
      $change = 'SAME';
    } elsif ($parentMax == 0 && $freq > 0) {
      $change = 'NEw';
    } elsif ($freq > $parentMax) {
      $change = 'INCREASE';
    } elsif ($freq < $parentMin) {
      $change = 'DECREASE';
    } else {
      $change = 'SAME';
    }
    printf $fh "$geneEl,$freq,$fatherGeneFreq,$motherGeneFreq,$change\n";
  }
  close $fh;
}

sub readGeneFreq {
  my @genelines = @_;
  my %genes;
  foreach my $geneline (@genelines) {
    $geneline =~ s/^\s+//;
    my ($freq, $gene) = split(/ /, $geneline);
    $genes{$gene} = $freq;
  }
  return %genes;
}