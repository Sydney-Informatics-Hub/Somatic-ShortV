#!/bin/bash

#########################################################
#
# Platform: NCI Gadi HPC
# Usage: bash gatk4_getpileupsummaries_split_common_vcf_run.sh
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

# Update VCF filepath depending on your chosen resource: 
common_biallelic=../Reference/gatk-best-practices/somatic-hg38/af-only-gnomad.hg38.vcf.gz

script=gatk4_getpileupsummaries_split_common_vcf.pbs
scatterdir=../Reference/GetPileupSummaries_intervals
ref=../Reference/hs38DH.fasta
outdir=$(dirname $common_biallelic)
prefix=$(basename $common_biallelic | sed 's/\.vcf.*//')
mkdir -p ${outdir}/${prefix} # assumes Reference directory is writable by user
logdir=Logs/split_common_biallelic
mkdir -p $logdir

printf "Extracting intervals from ${common_biallelic}\n"

for interval in ${scatterdir}/*interval_list
do 
	#../Reference/GetPileupSummaries_intervals/0017-scattered.interval_list
	
	int=$(basename ${interval} | cut -d '-' -f 1) # assumes GATK newer versions maintain the same
	# SplitIntervals output format eg NNNN-scattered.interval.list
	
	out=${outdir}/${prefix}/${prefix}.${int}.vcf.gz
	log=${logdir}/${prefix}_${int}.log
	printf "\nOutput VCF: ${out}\nPBS job ID:"
	 
	o_log=./Logs/gatk4_split_common_biallelic_${int}.o
	e_log=./Logs/gatk4_split_common_biallelic_${int}.e
	
	qsub -o $o_log -e $e_log -v ref="${ref}",common_biallelic="${common_biallelic}",interval="${interval}",out="${out}",log="${log}" $script 
	sleep 1		
done
