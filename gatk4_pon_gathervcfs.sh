#!/bin/bash

# Merge interval level Mutect2 (PoN) VCFs per sample
# Final output is gzipped and tabix indexed

module load gatk/4.1.2.0
module load samtools/1.10

set -e

sample=`echo $1 | cut -d ',' -f 1`
args=`echo $1 | cut -d ',' -f 2`
logdir=`echo $1 | cut -d ',' -f 3`
out=`echo $1 | cut -d ',' -f 4`

mkdir -p ${logdir}
rm -rf ${logdir}/${sample}.oe

gatk GatherVcfs \
	--arguments_file ${args} \
	--MAX_RECORDS_IN_RAM 1000000 \
	-O ${out} >> ${logdir}/${sample}.oe 2>&1

