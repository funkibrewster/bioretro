#!/usr/bin/perl -w
use strict;

my $numArgs = $#ARGV + 1;
if ($numArgs != 2) {
	print "\nUsage: queue.pl [inputfile] [outputfile]\n";
	exit;
}

my $inputfile = $ARGV[0];
my $outputfile = $ARGV[1];

if (-e $inputfile) {
	my $output = `./baminfo/bam_md $inputfile`;
	unless(open OUTPUT, '>'.$outputfile) {
		die "\nUnable to create '$outputfile'\n";
	}
	print OUTPUT $output;
	close OUTPUT;
}
