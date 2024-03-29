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

# No option to set threads

ref=`echo $1 | cut -d ',' -f 1`
cohort=`echo $1 | cut -d ',' -f 2`
gnomad=`echo $1 | cut -d ',' -f 3`
gendbdir=`echo $1 | cut -d ',' -f 4`
interval=`echo $1 | cut -d ',' -f 5`
outdir=`echo $1 | cut -d ',' -f 6`
logdir=`echo $1 | cut -d ',' -f 7`

filename=${interval##*/}
index=${filename%-scattered.interval_list}
out=${outdir}/${cohort}.${index}.pon.vcf.gz
tmp=${outdir}/tmp/${index}

rm -rf ${out} ${tmp}
mkdir -p ${outdir} ${logdir} ${tmp}

gatk --java-options "-Xmx8g -XX:ParallelGCThreads=$NCPUS -Djava.io.tmpdir=${PBS_JOBFS}" \
        CreateSomaticPanelOfNormals \
        -R ${ref} \
        --germline-resource ${gnomad} \
        -V gendb://${gendbdir}/${index} \
        --tmp-dir ${tmp} \
        -O ${out} >${logdir}/${index}.log 2>&1
