#!/bin/bash

#########################################################
#
# Platform: NCI Gadi HPC
# Description: Gather interval Mutect2 VCFs into per sample,
# gzipped VCFs that are tabix indexed
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
