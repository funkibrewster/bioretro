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
		bedfile=${outputdir}${fname}".gencode.bed"
    outputfile=${outputdir}${fname}".genes.txt"
    # uniquefile=${outputdir}${fname}".unique.genes.txt"
    echo "Processing "${fname}" ...";
		cut -f8 ${bedfile} | cut -f1 -d'_' | sort | uniq -c | sort -nr > ${outputfile}
		# perl remove_knowngenes.pl ${outputfile} > ${uniquefile}
	fi
	if [ ${i} -eq ${LIMIT} ]
	then
		break
	fi
	let i=i+1
done < $FILE
