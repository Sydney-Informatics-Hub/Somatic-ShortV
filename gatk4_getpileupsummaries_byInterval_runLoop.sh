#!/bin/bash

#########################################################
#
# Platform: NCI Gadi HPC
# Usage: bash gatk4_getpileupsummaries_byInterval_runLoop.sh
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

inputs=Inputs/gatk4_getpileupsummaries.inputs
script=gatk4_getpileupsummaries_byInterval.pbs

mkdir -p Logs/getpileupsummaries_PBS

c=0

while read LINE
do
	((c++))
	sample=`echo $LINE | cut -d ',' -f 1`
	bam=`echo $LINE | cut -d ',' -f 2`
	vcfdir=`echo $LINE | cut -d ',' -f 3`
	vcfprefix=`echo $LINE | cut -d ',' -f 4`
	outdir=`echo $LINE | cut -d ',' -f 5`
	logdir=`echo $LINE | cut -d ',' -f 6`
	intervals=`echo $LINE | cut -d ',' -f 7`
	
	e_log=Logs/getpileupsummaries_PBS/${sample}_${intervals}.e
	o_log=Logs/getpileupsummaries_PBS/${sample}_${intervals}.o
	
	e_log=$(echo $e_log | sed 's/;/-/g')
	o_log=$(echo $o_log | sed 's/;/-/g')
	
	jobname=GPS-${c}
	
	echo Submitting $LINE
	qsub \
		-N ${jobname} \
		-e $e_log \
		-o $o_log \
		-v  sample="${sample}",bam="${bam}",vcfdir="${vcfdir}",vcfprefix="${vcfprefix}",outdir="${outdir}",logdir="${logdir}",intervals="${intervals}" \
		$script 
	
	echo	
	sleep 1

	
done < $inputs
	
