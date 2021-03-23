#!/bin/bash

#########################################################
#
# Platform: NCI Gadi HPC
# Description: GetPileUpSummaries for a BAM file at
# loci contained in common biallelic variant resource
# Pileups are used in CalculateContamination
# Runs by gatk4_getpileupsummaries_run_parallel.pbs
# Author: Tracy Chew
# tracy.chew@sydney.edu.au
# Date last modified: 23/03/2021
#
# If you use this script towards a publication, please acknowledge the
# Sydney Informatics Hub (or co-authorship, where appropriate).
#
# Suggested citation:
# Sydney Informatics Hub, Core Research Facilities, University of Sydney,
# 2021, The Sydney Informatics Hub Bioinformatics Repository, <date accessed>,
# https://github.com/Sydney-Informatics-Hub/Bioinformatics
#
# Suggested acknowledgement:
# The authors acknowledge the scientific and technical assistance
# <or e.g. bioinformatics assistance of <PERSON>> of Sydney Informatics
# Hub and resources and services from the National Computational
# Infrastructure (NCI), which is supported by the Australian Government
# with access facilitated by the University of Sydney.
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
