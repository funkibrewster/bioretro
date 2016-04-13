#!/bin/bash
FILE=$1
i=1
START=1
END=300
LIMIT=-1
outputdir="wgsresults/"
while read line; do
	if [ $i -ge $START -a $i -le $END ]
	then 
		filename=$(basename "$line")
		fname="${filename%.*}"
		inputfile=$outputdir$fname".txt"
		bedfile=$outputdir$fname".bed"
		perl bedinfo/make_bed.pl $inputfile > $bedfile
	fi
	if [ $i -eq $LIMIT ]
	then
		break
	fi
	let i=i+1
done < $FILE
