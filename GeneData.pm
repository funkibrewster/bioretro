package GeneData;
use strict;
use warnings FATAL => 'all';

sub GetKnownRetrogenes;
sub IsKnownRetrogene;
sub GetGeneNames;
sub GetGeneName;
sub GetGeneExons;

# read in known genes
my $known = 'known.retrogenes.csv';
open(my $fh, '<:encoding(UTF-8)', $known)
  or die "Could not open file '$known' $!";

chomp(my @genes = <$fh>);
close $fh;
my %retroGenes = map { lc $_ => 1 } @genes;

sub GetKnownRetrogenes() {
  return %retroGenes;
}

sub IsKnownRetrogene($) {
  my $geneSymbol = $_[0];
  return exists($retroGenes{(lc $geneSymbol)});
}

# read in gene names
my $names = 'genenames.txt';
open(my $fhn, '<:encoding(UTF-8)', $names)
  or die "Could not open file '$names' $!";
chomp(my @genenames = <$fhn>);
close $fh;

my %hGeneNames;
foreach my $geneNameLine (@genenames) {
  my ($geneSymbol, $geneName) = split(/\t/, $geneNameLine);
  $hGeneNames{lc $geneSymbol} = $geneName;
}

sub GetGeneNames() {
  return %hGeneNames;
}

sub GetGeneName($) {
  my $geneSymbol = $_[0];
  if (!exists($hGeneNames{lc $geneSymbol})) {
    return $geneSymbol;
  }
  return $hGeneNames{lc $geneSymbol};
}

# count number of exons for each gene: gencode.genes.txt
# cut -f4 bedinfo/gencode_v18_merged.bed | cut -f1 -d'_' | sort | uniq -c > gencode.genes.txt
# read in gencode gene exon counts, load into hash %genes
my $gencodegenes = 'gencode.genes.txt';
open(my $gfh, '<:encoding(UTF-8)', $gencodegenes)
  or die "Could not open file '$gencodegenes' $!";
chomp(my @genelines = <$gfh>);
my %genes;
foreach my $geneline (@genelines) {
  $geneline =~ s/^\s+//;
  my ($freq, $gene) = split(/ /, $geneline);
  $genes{lc $gene} = $freq;
}

sub GetGeneExons($) {
  my $geneSymbol = $_[0];
  if (!exists($genes{lc $geneSymbol})) {
    return $geneSymbol;
  }
  return $genes{lc $geneSymbol};
}

1;