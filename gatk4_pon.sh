#!/bin/bash

#########################################################
#
# Platform: NCI Gadi HPC
# Description: Runs GATK4 Mutect2 on normal samples for
# creating a panel of normal (PoN)
# Author: Tracy Chew
# tracy.chew@sydney.edu.au
# Date last modified: 18/03/2021
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

ref=`echo $1 | cut -d ',' -f 1`
sample=`echo $1 | cut -d ',' -f 2`
bam=`echo $1 | cut -d ',' -f 3`
interval=`echo $1 | cut -d ',' -f 4`
out=`echo $1 | cut -d ',' -f 5`
nt=`echo $1 | cut -d ',' -f 6`
logdir=`echo $1 | cut -d ',' -f 7`

mkdir -p ${out}
mkdir -p ${logdir}

filename=${interval##*/}
index=${filename%-scattered.interval_list}

vcf=${out}/${sample}.pon.${index}.vcf

echo "$(date): Creating panel of normals using GATK4 Mutect2. Reference: ${ref}; Sample: ${sample}; Bam: ${bam}; Interval: ${filename}; VCF: ${vcf}; Threads: ${nt}; Logs: ${logdir}" > ${logdir}/${index}.oe 2>&1 

gatk --java-options "-Xmx8g -Xms8g" \
	Mutect2 \
	-R ${ref} \
	-I ${bam} \
	-L ${interval} \
	--max-mnp-distance 0 \
	-O ${vcf} \
	--native-pair-hmm-threads ${nt} >>${logdir}/${index}.oe 2>&1 

echo "$(date): Finished creating panel of normals, saving output to: ${vcf}" >> ${logdir}/${index}.oe 2>&1 
