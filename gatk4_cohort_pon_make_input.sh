#! /bin/bash

#########################################################
#
# Platform: NCI Gadi HPC
# Description: Create input file to run gatk4_cohort_pon_run_parallel.pbs
# This operates on per interval GenomicsDBImport database files
# Usage: sh gatk4_cohort_pon_make_input.sh /path/to/cohort.config
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

if [ -z "$1" ]
then
        echo "Please provide the path to your cohort.config file, e.g. sh gatk4_cohort_pon_make_input.sh ../cohort.config"
        exit
fi

config=$1
cohort=$(basename $config | cut -d'.' -f 1)
INPUTS=./Inputs
inputfile=${INPUTS}/gatk4_cohort_pon.inputs
ref=../Reference/hs38DH.fasta
gnomad=../Reference/broad-references/ftp/Mutect2/af-only-gnomad.hg38.vcf.gz
scatterdir=../Reference/ShortV_intervals
scatterlist=$scatterdir/3200_ordered_exclusions.list
gendbdir=./$cohort\_PoN_GenomicsDBImport
outdir=./$cohort\_cohort_PoN
logdir=./Logs/gatk4_cohort_pon

rm -rf ${inputfile}
mkdir -p ${logdir}

# Collect normal sample IDs from cohort.config
while read -r sampleid labid seq_center library; do
        if [[ ! ${sampleid} =~ ^#.*$ && ${labid} =~ -B.?$ || ${labid} =~ -N.?$ ]]; then
                samples+=("${labid}")
        fi
done < "${config}"

echo "$(date): Writing input file for gatk4_cohort_pon_run_parallel.pbs for ${#samples[@]} samples"

# Write gatk4_cohort_pon.inputs file
while IFS= read -r intfile; do
        interval="${scatterdir}/${intfile}"
        echo "${ref},${cohort},${gnomad},${gendbdir},${interval},${outdir},${logdir}" >> ${inputfile}
done < "${scatterlist}"

num_tasks=`wc -l ${inputfile}`
echo "$(date): Number of tasks are ${num_tasks}"

