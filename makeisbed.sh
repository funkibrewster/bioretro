#!/bin/bash
FILE=$1
i=1
START=1
END=300
LIMIT=5
outputdir="wgsresults/"
gencodemerge="bedinfo/gencode_v18_merged.bed"
while read line; do
	if [ $i -ge $START -a $i -le $END ]
	then 
		filename=$(basename "$line")
		fname="${filename%.*}"
		bedfile=$outputdir$fname".bed"
		gencodefile=$outputdir$fname".gencode.bed"
		echo "Running bedtools intersect on "$bedfile
		bedtools intersect -a $bedfile -b $gencodemerge -wa -wb > $gencodefile
	fi
	if [ $i -eq $LIMIT ]
	then
		break
	fi
	let i=i+1
done < $FILE
