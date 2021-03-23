#!/bin/bash

#########################################################
#
# Platform: NCI Gadi HPC
# Description: Run LearnReadOrientationModel. Used by
# gatk4_learnreadorientationmodel_run_parallel.pbs
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

