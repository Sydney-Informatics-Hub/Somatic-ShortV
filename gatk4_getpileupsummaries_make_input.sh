#! /bin/bash

#########################################################
#
# Platform: NCI Gadi HPC
# Usage: sh gatk4_getpileupsummaries_make_input.sh /path/to/cohort.config
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

set -e

if [ -z "$1" ]
then
        echo "Please provide the path to your cohort.config file, e.g. sh gatk4_getpileupsummaries_make_input.sh ../cohort.config"
        exit
fi

# Select your common biallelic resource, or input your own resource:
#common_biallelic=../Reference/gatk-best-practices/somatic-hg38/small_exac_common_3.hg38.vcf.gz
common_biallelic=../Reference/gatk-best-practices/somatic-hg38/af-only-gnomad.common_biallelic.hg38.vcf.gz

config=$1
cohort=$(basename "$config" | cut -d'.' -f 1)
bamdir=../Final_bams
outdir=./${cohort}_GetPileupSummaries
logdir=./Logs/gatk4_getpileupsummaries
INPUTS=./Inputs
inputfile=${INPUTS}/gatk4_getpileupsummaries.inputs

mkdir -p ${outdir}
mkdir -p ${logdir}
mkdir -p ${INPUTS}
rm -rf ${inputfile}

# Collect all sample IDs from config file
samples=0
while read -r sampleid labid seq_center library; do
        if [[ ! ${sampleid} =~ ^#.*$ ]]; then
                samples=$(( ${samples}+1 ))
                bam=${bamdir}/${labid}.final.bam
                out=${outdir}/${labid}_pileups.table
                echo "${labid},${bam},${common_biallelic},${out},${logdir}" >> ${inputfile}
        fi
done < "${config}"

echo "$(date): Wrote input files for ${samples} bams for gatk4_getpileupsummaries_run_parallel.pbs"
