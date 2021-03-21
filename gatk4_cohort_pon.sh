#!/bin/bash

#########################################################
#
# Platform: NCI Gadi HPC
# Description: Creates a panel of normal for multiple samples per genomic interval
# Author: Tracy Chew
# tracy.chew@sydney.edu.au
# Date last modified: 19/03/2021
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

# No option to set numnber of threads

ref=`echo $1 | cut -d ',' -f 1`
cohort=`echo $1 | cut -d ',' -f 2`
gnomad=`echo $1 | cut -d ',' -f 3`
gendbdir=`echo $1 | cut -d ',' -f 4`
interval=`echo $1 | cut -d ',' -f 5`
outdir=`echo $1 | cut -d ',' -f 6`
logdir=`echo $1 | cut -d ',' -f 7`

mkdir -p ${outdir}
mkdir -p ${logdir}

filename=${interval##*/}
index=${filename%-scattered.interval_list}

out=${outdir}/${cohort}.${index}.pon.vcf.gz
tmp=${outdir}/tmp/${index}

mkdir -p ${outdir}
mkdir -p ${tmp}

echo "$(date): Running CreateSomaticPanelOfNormals with gatk4. Reference: ${ref}; Resource: ${gnomad}; Interval: ${filename}; Out: ${out};  Logs: ${logdir}" > ${logdir}/${index}.oe 2>&1

gatk --java-options "-Xmx8g" \
        CreateSomaticPanelOfNormals \
        -R ${ref} \
        --germline-resource ${gnomad} \
        -V gendb://${gendbdir}/${index} \
        --tmp-dir ${tmp} \
        -O ${out} >>${logdir}/${index}.oe 2>&1

echo "$(date): Finished CreateSomaticPanelOfNormals, saving output to: ${out}" >> ${logdir}/${index}.oe 2>&1
