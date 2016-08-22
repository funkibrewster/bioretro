#!/usr/bin/perl
use strict;
use warnings FATAL => 'all';

use List::MoreUtils qw(uniq);
use PatientData;
use GeneData;

sub filterGeneFile;
sub filterGenes;
sub filterBedFile;

my @diseasedchildren = PatientData::GetDiseasedChildren();
my @matchedKnown;
my @filteredGenes;
my $RATIO = 0.5; # minimum ratio of retrogene insertion to exons

# process all *.genes.txt files for diseased children
foreach my $id (@diseasedchildren) {
  filterGeneFile($id);
  print STDERR filterBedFile($id);
}

# create a list of genes to be filtered out
sub filterGeneFile($) {
  my $id = $_[0];
  @matchedKnown = ();
  @filteredGenes = ();
  my $log = "data/$id.filtered.log";
  unless(open LOG, '>'.$log) {
    warn "\nUnable to create '$log'\n";
  }

  printf LOG "ID: $id\n";
  printf LOG "De-novo Insertions:\n";
  my $denovoGeneFile = "data/$id.denovo.genes.txt";
  printf LOG filterGenes($denovoGeneFile);
  printf LOG "Heterozygous Insertions:\n";
  my $heteroGeneFile = "data/$id.heterozygous.genes.txt";
  printf LOG filterGenes($heteroGeneFile);
  printf LOG "Homozygous Insertions:\n";
  my $homoGeneFile = "data/$id.homozygous.genes.txt";
  printf LOG filterGenes($homoGeneFile);

  if (scalar @matchedKnown > 0) {
    print LOG "Retrogenes removed: ";
    print LOG join(', ', @matchedKnown);
    print LOG "\n";
    print STDERR "Retrogenes found in $id: ".join(', ', @matchedKnown)."\n";
  }
  close LOG;
  my $numFiltered = scalar @filteredGenes;
  if ($numFiltered > 0) {
    print STDERR "Filtered out from $id: $numFiltered genes\n";
  }

  my $filter = "data/$id.filtered.txt";
  unless(open OUTPUT, '>'.$filter) {
    die "\nUnable to create '$filter'\n";
  }
  push @filteredGenes, @matchedKnown;
  print OUTPUT join("\n", @filteredGenes);
  close OUTPUT;
}

# filter out genes from $id.[denovo|heterozygous|homozygous].genes.txt
sub filterGenes($) {
  my $file = $_[0];
  my @lines;
  my $output = "";
  if (-e $file) {
    open(my $fh, '<:encoding(UTF-8)', $file)
      or warn "Could not open file '$file' $!";
    chomp(@lines = <$fh>);
    close $fh;
  }
  if (scalar @lines == 0) {
    return;
  }
  foreach my $line (@lines) {
    if ($line =~ /\s*([\d]+)\s([\S]+)/) {
      my $count = $1;
      my $gene = $2;
      my $genename = GeneData::GetGeneName($gene);
      my $geneexons = GeneData::GetGeneExons($gene);
      my $ratio = ($geneexons != 0 ? ($count/$geneexons) : '0');
      my $fratio = sprintf("%.2f", $ratio);
      if (!GeneData::IsKnownRetrogene($gene)) {
        if ($fratio >= $RATIO) {
          $output .= "$count|$fratio|$gene|$genename\n";
        } else {
          push @filteredGenes, $gene;
        }
      } else {
        push @matchedKnown, $gene;
      }
    }
  }
  return $output;
}

# filter out lines from bedfile from $id.filtered.txt
sub filterBedFile($) {
  my $id = $_[0];
  my $file = "data/$id.filtered.txt";
  my @genes;
  my %hGenes;
  # read in genes to be filtered out
  if (-e $file) {
    open(my $fh, '<:encoding(UTF-8)', $file)
      or warn "Could not open file '$file' $!";
    chomp(@genes = <$fh>);
    close $fh;
    %hGenes = map { lc $_ => 1 } @genes;
  }
  # generate bed files with those genes removed
  generateFilteredBed($id, \%hGenes);
}

sub generateFilteredBed {
  my $id = $_[0];
  my %filter = %{$_[1]};
  my $type = $_[2];
  my @lines;
  my $bed = "../wgsresults/$id.gencode.bed";
  if (-e $bed) {
    open(my $bedfh, '<:encoding(UTF-8)', $bed)
      or warn "Could not open file '$bed' $!";
    chomp(@lines = <$bedfh>);
    close $bedfh;
    my $filteredBed = "data/$id.filtered.bed";
    open(my $filteredfh, '>:encoding(UTF-8)', $filteredBed)
      or warn "Could not open file '$filteredBed' \n";
    foreach my $line (@lines) {
      my @cols = split(/\s+/, $line);
      my @geneinfo = split(/\_/, $cols[7]);
      my $geneSymbol = $geneinfo[0];
      if (!exists($filter{lc $geneSymbol})) {
        printf $filteredfh "$line\n";
      }
    }
    # print "Removed: ".join(', ', @removed)."\n";
  }
}