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

ref=`echo $1 | cut -d ',' -f 1`
sample=`echo $1 | cut -d ',' -f 2`
bam=`echo $1 | cut -d ',' -f 3`
interval=`echo $1 | cut -d ',' -f 4`
outdir=`echo $1 | cut -d ',' -f 5`
logdir=`echo $1 | cut -d ',' -f 6`

mkdir -p ${outdir} ${logdir}

filename=${interval##*/}
index=${filename%-scattered.interval_list}

vcf=${outdir}/${sample}.pon.${index}.vcf

gatk --java-options "-Xmx8g -XX:ParallelGCThreads=$NCPUS -Djava.io.tmpdir=${PBS_JOBFS}" \
	Mutect2 \
	-R ${ref} \
	-I ${bam} \
	-L ${interval} \
	--max-mnp-distance 0 \
	-O ${vcf} \
	--native-pair-hmm-threads $NCPUS >>${logdir}/${index}.log 2>&1 

