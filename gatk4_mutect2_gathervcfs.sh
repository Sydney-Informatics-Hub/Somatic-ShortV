#!/bin/bash

#########################################################
#
# Platform: NCI Gadi HPC
# Usage:
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
