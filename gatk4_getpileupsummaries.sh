#!/bin/bash

# Run GATK's GetPileupSummaries for a bam file

module load gatk/4.1.2.0

set -e

sample=`echo $1 | cut -d ',' -f 1`
bam=`echo $1 | cut -d ',' -f 2`
common_biallelic=`echo $1 | cut -d ',' -f 3`
out=`echo $1 | cut -d ',' -f 4`
logdir=`echo $1 | cut -d ',' -f 5`

mkdir -p ${logdir}
rm -rf ${logdir}/${sample}.oe

echo "$(date): Running GetPileupSummaries for: Sample: ${sample}, BAM: ${bam}, Logs: ${logdir}, Out: ${out}" > ${logdir}/${sample}.oe 2>&1

gatk --java-options "-Xmx54g -Xms54g -DGATK_STACKTRACE_ON_USER_EXCEPTION=true" \
	GetPileupSummaries \
	-I ${bam} \
	-V ${common_biallelic} \
	-L ${common_biallelic} \
	-O ${out} >> ${logdir}/${sample}.oe 2>&1

echo "$(date): Finished GetPileupSummaries" >> ${logdir}/${sample}.oe 2>&1
