#!/bin/bash

# Merge interval stats files from Mutect2

module load gatk/4.1.2.0
module load samtools/1.10

set -e

pair=`echo $1 | cut -d ',' -f 1`
args=`echo $1 | cut -d ',' -f 2`
logdir=`echo $1 | cut -d ',' -f 3`
out=`echo $1 | cut -d ',' -f 4`

mkdir -p ${logdir}
rm -rf ${logdir}/${pair}.oe

echo "$(date): Merging interval stats files from Mutect2. TN pair: ${pair}, Arguments file: ${args}, Logs: ${logdir}, Out: ${out}" > ${logdir}/${pair}.oe 2>&1

gatk MergeMutectStats \
	--arguments_file ${args} \
	-O ${out} >> ${logdir}/${pair}.oe 2>&1
