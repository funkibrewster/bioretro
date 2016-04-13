#!/bin/bash
FILE=$1
i=1
START=2
END=100
LIMIT=100
outputdir="wgsresults/"
while read line; do
	if [ $i -ge $START -a $i -le $END ]
	then 
		filename=$(basename "$line")
		fname="${filename%.*}"
		outputfile=$outputdir$fname".txt"
		qsub -o queue.log -j y -q long -cwd -V -b y -N BamInfo perl queue.pl $line $outputfile
	fi
	if [ $i -eq $LIMIT ]
	then
		break
	fi
	let i=i+1
done < $FILE
