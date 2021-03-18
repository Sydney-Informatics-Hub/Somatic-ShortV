#! /bin/bash

#########################################################
#
# Platform: NCI Gadi HPC
# Description: Creates input file for gatk4_pon_gathervcfs_run_parallel.pbs
# Usage: sh gatk4_pon_gathervcfs_make_input.sh /path/to/cohort.config
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
        echo "Please provide the path to your cohort.config file, e.g. sh gatk4_pon_gathervcfs_make_input.sh ../cohort.config"
        exit
fi

config=$1
cohort=$(basename "$config" | cut -d'.' -f 1)
vcfdir=./$cohort\_PoN
logdir=./Logs/gatk4_pon_gathervcfs
scatterdir=../Reference/ShortV_intervals
scatterlist=$scatterdir/3200_ordered_exclusions.list
num_int=`wc -l ${scatterlist} | cut -d' ' -f 1`

INPUTS=./Inputs
inputfile=${INPUTS}/gatk4_pon_gathervcfs.inputs

# Collect sample IDs from config file
# Only normal sample IDs are collected (labids ending in -B or -N)
while read -r sampleid labid seq_center library; do
        if [[ ! ${sampleid} =~ ^#.*$ && ${labid} =~ -B.?$ || ${labid} =~ -N.?$ ]]; then
                samples+=("${labid}")
        fi
done < "${config}"

mkdir -p ${logdir}
mkdir -p ${INPUTS}
rm -rf ${inputfile}

echo "$(date): Writing arguments and input file for ${#samples[@]} samples for gatk4_pon_gathervcfs_run_parallel.pbs"

# Make arguments file for each sample, then add to inputs file
for sample in "${samples[@]}"; do
        echo "$(date): Writing arguments for ${sample}..."
        args=${INPUTS}/gatk4_pon_gathervcfs_${sample}\.args
        out=${vcfdir}/${sample}.pon.vcf.gz

        rm -rf ${args}

        for interval in $(seq -f "%04g" 0 $(($num_int-1)));do
                echo "--I " ${vcfdir}/${sample}/${sample}.pon.${interval}.vcf >> ${args}
        done
        echo "${sample},${args},${logdir},${out}" >> ${inputfile}
done

num_tasks=$(wc -l ${inputfile} | cut -d' ' -f1)

echo "$(date): Wrote ${num_tasks} tasks in ${inputfile}"
