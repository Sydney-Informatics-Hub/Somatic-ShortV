#!/bin/bash

#########################################################
#
# Platform: NCI Gadi HPC
# Usage: gatk4_learnreadorientationmodel_run_parallel.pbs
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


pair=`echo $1 | cut -d ',' -f 1`
args=`echo $1 | cut -d ',' -f 2`
logdir=`echo $1 | cut -d ',' -f 3`
out=`echo $1 | cut -d ',' -f 4`

echo "$(date) : Running GATK 4 LearnReadOrientationModel using f1r2 outputs from Mutect2. TN pair: ${pair}, Arguments file: ${args}, Logs: ${logdir}, Out: ${out}" > ${logdir}/${pair}.oe 2>&1

gatk --java-options "-Xmx140g -DGATK_STACKTRACE_ON_USER_EXCEPTION=true" \
        LearnReadOrientationModel \
        --arguments_file ${args} \
        -O ${out} >> ${logdir}/${pair}.oe 2>&1

echo "$(date): Finished running LearnReadOrientationModel for TN pair: ${pair}" >> ${logdir}/${pair}.oe 2>&1 &

