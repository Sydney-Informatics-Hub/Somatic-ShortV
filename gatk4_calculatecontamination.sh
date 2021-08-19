#!/bin/bash

#########################################################
#
# Platform: NCI Gadi HPC
# Usage:
# Version: 2.0
#
# For more details see: https://github.com/Sydney-Informatics-Hub/Germline-ShortV
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
