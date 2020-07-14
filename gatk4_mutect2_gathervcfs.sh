#!/bin/bash

# Merge interval level haplotypecaller VCFs per sample
# Final output is gzipped and tabix indexed

module load gatk/4.1.2.0
module load samtools/1.10

set -e

sample=`echo $1 | cut -d ',' -f 1`
args=`echo $1 | cut -d ',' -f 2`
logdir=`echo $1 | cut -d ',' -f 3`
partial=`echo $1 | cut -d ',' -f 4`
chrM=`echo $1 | cut -d ',' -f 5`
out=`echo $1 | cut -d ',' -f 6`

mkdir -p ${logdir}
rm -rf ${logdir}/${sample}.oe

# GatherVcfs requires intervals in order, so add chrM using 
gatk GatherVcfs \
	--arguments_file ${args} \
	--MAX_RECORDS_IN_RAM 100000000 \
	-O ${partial} >> ${logdir}/${sample}.oe 2>&1

# Now gather chrM using MergeVcfs which doesn't require a specific order (but can't take in thousands of intervals like GatherVcfs
# Automatically sorts using VCF headers
gatk MergeVcfs \
	-I ${partial} \
	-I ${chrM} \
	-O ${out} >> ${logdir}/${sample}.oe 2>&1
