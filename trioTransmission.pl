#!/usr/bin/perl
use strict;
use warnings FATAL => 'all';

use PatientData;

use List::MoreUtils qw(uniq);

sub generateBedFiles;
sub generateGeneFiles;

my %patients = PatientData::GetPatientData();

my @allchildren = PatientData::GetAllChildren();
my @diseasedchildren = PatientData::GetDiseasedChildren();

#printf "All children with parents: ".join(', ', @allchildren)."\n";
#printf "Diseased children with parents: ".join(', ', @diseasedchildren)."\n";


# generate bed files and gene files
foreach my $childId (@diseasedchildren) {
  my %patient = %{$patients{$childId}};
  my $paternalId = $patient{paternalId};
  my $maternalId = $patient{maternalId};
  my $childFile = "../wgsresults/$childId.gencode.bed";
  my $paternalFile = "../wgsresults/$paternalId.gencode.bed";
  my $maternalFile = "../wgsresults/$maternalId.gencode.bed";
  if (-e $childFile && -e $paternalFile && -e $maternalFile) {
    generateBedFiles($childId, $childFile, $paternalFile, $maternalFile);
    generateGeneFiles($childId);
  } else {
    warn "Trio files not complete\n";
  }
}

# cleanup unused files
my $output = `rm -rf data/*.parents.bed`;

sub generateBedFiles($$$) {
  my ($childId, $childFile, $paternalFile, $maternalFile) = ($_[0], $_[1], $_[2], $_[3]);
  # de-novo
  my $output = `bedtools intersect -a $childFile -b $paternalFile $maternalFile -v`;
  my $denovofile = "data/$childId.denovo.bed";
  unless(open OUTPUT, '>'.$denovofile) {
    die "\nUnable to create '$denovofile'\n";
  }
  print OUTPUT $output;
  close OUTPUT;
  # homozygous / heterozygous
  $output = `bedtools intersect -a $childFile -b $paternalFile $maternalFile -u > data/$childId.parents.bed`;
  $output = `bedtools intersect -a $paternalFile -b $maternalFile -u > data/$childId.intersect.parents.bed`;
  $output = `bedtools subtract -a data/$childId.parents.bed -b data/$childId.intersect.parents.bed > data/$childId.heterozygous.bed`;
  $output = `bedtools intersect -a $childFile -b data/$childId.intersect.parents.bed > data/$childId.homozygous.bed`;
}

sub generateGeneFiles($) {
  my $childId = $_[0];
  my $output = `cut -f8 data/$childId.denovo.bed | cut -f1 -d'_' | sort | uniq -c | sort -nr > data/$childId.denovo.genes.txt`;
  $output = `cut -f8 data/$childId.homozygous.bed | cut -f1 -d'_' | sort | uniq -c | sort -nr > data/$childId.homozygous.genes.txt`;
  $output = `cut -f8 data/$childId.heterozygous.bed | cut -f1 -d'_' | sort | uniq -c | sort -nr > data/$childId.heterozygous.genes.txt`;
}
