#! /bin/bash

#########################################################
#
# Platform: NCI Gadi HPC
# Description: Creates input file for gatk4_pon_genomicsdbimport_run_parallel.pbs
# Usage: sh gatk4_pon_genomicsdbimport_make_input.sh /path/to/cohort.config
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
cohort=$(basename "${config}" | cut -d'.' -f 1)
INPUTS=./Inputs
inputfile=${INPUTS}/gatk4_pon_genomicsdbimport.inputs
ref=../Reference/hs38DH.fasta
scatterdir=../Reference/ShortV_intervals
scatterlist=$scatterdir/3200_ordered_exclusions.list
vcfdir=./$cohort\_PoN
sample_map=${INPUTS}/${cohort}.sample_map
outdir=./$cohort\_PoN_GenomicsDBImport
logs=./Logs/gatk4_pon_genomicsdbimport
nt=1

mkdir -p ${INPUTS}
mkdir -p ${logs}

rm -rf ${inputfile}
rm -rf ${sample_map}

# Collect sample IDs from config file
# Only collect IDs for germline variant calling (labids ending in -B or -N)
while read -r sampleid labid seq_center library; do
        if [[ ! ${sampleid} =~ ^#.*$ && ${labid} =~ -B.?$ || ${labid} =~ -N.?$ ]]; then
                samples+=("${labid}")
        fi
done < "${config}"

echo "$(date): Writing sample_map and input file for gatk4_pon_genomicsdbimport_run_parallel.pbs for ${#samples[@]} samples"

for sample in "${samples[@]}"; do
        echo "$(date): Found ${sample}"
        echo -e "${sample}      ${vcfdir}/${sample}.pon.vcf.gz" >> ${sample_map}
done

# Loop through intervals in scatterlist file
# Print to ${INPUTS}
while IFS= read -r intfile; do
        interval="${scatterdir}/${intfile}"
        echo "${ref},${cohort},${interval},${sample_map},${outdir},${logs},${nt}" >> ${inputfile}
done < "${scatterlist}"

num_tasks=`wc -l ${inputfile}`

echo "$(date): Number of tasks to run are ${num_tasks}"
