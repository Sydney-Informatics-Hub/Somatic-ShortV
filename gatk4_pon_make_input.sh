#! /bin/bash

#########################################################
#
# Platform: NCI Gadi HPC
# Description: Creates input file for gatk4_pon_run_parallel.pbs
# Usage: sh gatk4_hc_make_input.sh /path/to/cohort.config
# Author: Tracy Chew
# tracy.chew@sydney.edu.au
# Date last modified: 18/03/2021
#
# If you use this script towards a publication, please acknowledge the
# Sydney Informatics Hub (or co-authorship, where appropriate).
#
# Suggested acknowledgement:
# The authors acknowledge the scientific and technical assistance
# <or e.g. bioinformatics assistance of <PERSON>> of Sydney Informatics
# Hub and resources and services from the National Computational
# Infrastructure (NCI), which is supported by the Australian Government
# with access facilitated by the University of Sydney.
#
#########################################################

if [ -z "$1" ]
then
	echo "Please provide the path to your cohort.config file, e.g. sh gatk4_pon_make_input.sh ../cohort.config"
	exit
fi

config=$1
ref=../Reference/hs38DH.fasta
scatterdir=../Reference/ShortV_intervals
scatterlist=$scatterdir/3200_ordered_exclusions.list
bamdir=../Final_bams
outdir=./$cohort\_PoN
logs=./Logs/gatk4_pon
INPUTS=./Inputs
inputfile=${INPUTS}/gatk4_pon.inputs
nt=1

mkdir -p ${INPUTS}
mkdir -p ${logs}

# Collect sample IDs from samples.config
# Only collect IDs from normal samples (labids ending in -B)
while read -r sampleid labid seq_center library; do
	if [[ ! ${sampleid} =~ ^#.*$ && ${labid} =~ -B.?$ || ${labid} =~ -N.?$ ]]; then
		samples+=("${labid}")
	fi
done < "${config}"

echo "$(date): Writing inputs for gatk4_pon_run_parallel.pbs for ${#samples[@]} samples and 3200 tasks per sample to ${inputfile}"
# Resource requirements:
echo "$(date): Normal samples found include ${samples[@]}"

rm -rf ${inputfile}

# Write gatk4_pon_mutect2.inputs file, using nt=1
while IFS= read -r intfile; do
	for sample in "${samples[@]}"; do
		out=${outdir}/${sample}
		bam=${bamdir}/${sample}.final.bam
		logdir=${logs}/${sample}
		interval="${scatterdir}/${intfile}"
		echo "${ref},${sample},${bam},${interval},${out},${nt},${logdir}" >> ${inputfile}
	done
done < "${scatterlist}"

num_inputs=`wc -l ${inputfile}`
ncpus=$(( ${#samples[@]}*48*2 ))
mem=$(( ${#samples[@]}*192*2 ))
echo "$(date): Recommended compute to request in gatk4_pon_run_parallel.pbs: walltime=02:00:00,ncpus=${ncpus},mem=${mem}GB,wd"
