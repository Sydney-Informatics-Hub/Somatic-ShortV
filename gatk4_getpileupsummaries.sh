#!/bin/bash

#########################################################
#
# Platform: NCI Gadi HPC
# Usage: gatk4_getpileupsummaries_run_parallel.pbs
# Version: 1.0
#
# For more details see: https://github.com/Sydney-Informatics-Hub/Somatic-ShortV
#
# If you use this script towards a publication, support us by citing:
#
# Suggest citation:
# Sydney Informatics Hub, Core Research Facilities, University of Sydney,
# 2021, The Sydney Informatics Hub Bioinformatics Repository, <date accessed>,
# https://github.com/Sydney-Informatics-Hub/Germline-ShortV
#
# Please acknowledge the Sydney Informatics Hub and the facilities:
#
# Suggested acknowledgement:
# The authors acknowledge the technical assistance provided by the Sydney
# Informatics Hub, a Core Research Facility of the University of Sydney
# and the Australian BioCommons which is enabled by NCRIS via Bioplatforms
# Australia. The authors acknowledge the use of the National Computational
# Infrastructure (NCI) supported by the Australian Government.
#
#########################################################

set -e

sample=`echo $1 | cut -d ',' -f 1`
bam=`echo $1 | cut -d ',' -f 2`
common_biallelic=`echo $1 | cut -d ',' -f 3`
out=`echo $1 | cut -d ',' -f 4`
logdir=`echo $1 | cut -d ',' -f 5`

mkdir -p ${logdir}
rm -rf ${logdir}/${sample}.oe

echo "$(date): Running GetPileupSummaries for: Sample: ${sample}, BAM: ${bam}, Logs: ${logdir}, Out: ${out}" > ${logdir}/${sample}.oe 2>&1

gatk --java-options "-Xmx54g -DGATK_STACKTRACE_ON_USER_EXCEPTION=true" \
        GetPileupSummaries \
        -I ${bam} \
        -V ${common_biallelic} \
        -L ${common_biallelic} \
        -O ${out} >> ${logdir}/${sample}.oe 2>&1
