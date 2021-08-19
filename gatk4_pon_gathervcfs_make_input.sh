#! /bin/bash

#########################################################
#
# Platform: NCI Gadi HPC
# Usage: sh gatk4_pon_gathervcfs_make_input.sh /path/to/cohort.config
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
