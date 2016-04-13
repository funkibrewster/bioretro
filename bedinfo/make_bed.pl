#!/usr/bin/perl

@lines = <>;
chomp @lines;

foreach $line (@lines){

	($chr,$pos,$reads) = split(/\t/,$line);
	
	printf "%s\t%d\t%d\t%d\n", $chr, $pos-1,$pos,$reads;
	
	

}
