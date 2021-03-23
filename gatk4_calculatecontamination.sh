#!/bin/bash

#########################################################
#
# Platform: NCI Gadi HPC
# Description: Runs GATK's CalculateContamination using sample_pileups.tables
# from GetPileupSummaries. NOTE that gatk/4.1.2.0 uses a patch that resolves
# this error: "FilterMutectCalls: Log10-probability must be 0 or less"
# This happens when CalculateContamination result is NaN for a tumour-normal pair
# Patch is available in gatk-best-practices resource, kept in References directory
# Runs by gatk4_calculatecontamination_run_parallel.pbs
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

pair=`echo $1 | cut -d ',' -f 1`
nmpileup=`echo $1 | cut -d ',' -f 2`
tmpileup=`echo $1 | cut -d ',' -f 3`
segments=`echo $1 | cut -d ',' -f 4`
out=`echo $1 | cut -d ',' -f 5`
logdir=`echo $1 | cut -d ',' -f 6`

patch=../Reference/gatk-best-practices/somatic-hg38/gatk-builds_contamination-patch-5-27-2019.jar

mkdir -p ${logdir}
rm -rf ${logdir}/${pair}.oe

echo "$(date): Running CalculateContamination for TN pair: ${pair}, Normal pileup: ${nmpileup}, Tumour pileup: ${tmpileup}, Logs: ${logdir}, Out (contamination): ${out}, Out (segments): ${segments}" > ${logdir}/${pair}.oe 2>&1

java -Xmx8g -DGATK_STACKTRACE_ON_USER_EXCEPTION=true -jar ${patch} \
        CalculateContamination \
        -I ${tmpileup} \
        -tumor-segmentation ${segments} \
        -matched ${nmpileup} \
        -O ${out} >> ${logdir}/${pair}.oe 2>&1
