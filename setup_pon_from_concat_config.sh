#! /bin/bash

#########################################################
#
# Platform: NCI Gadi HPC
# Description: Creates a single new_cohort_PoN directory after joining
# data from multiple cohorts using concat_configs.sh.
# Required for downstream processing in Somatic-ShortV pipeline.
# Creates a single new_cohort_PoN directory with
# sample.pon.vcf.gz and sample.pon.vcf.gz.tbi
# files symbollically linked from their original cohort1_PoN, cohort2_PoN,
# etc directories
# Usage:
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

if [ -z "$1" ]
then
        echo "Please provide the path to your new cohort.config file that was created with concat_cohorts_one_config.sh"
        echo "e.g. sh setup_pon_new_config.sh ../new_cohort.config"
        exit
fi

config=$1
concat_cohort=$(basename $config | cut -d'.' -f 1)

if [ -d "./${concat_cohort}_PoN" ]; then
        if [ -z "$(ls -A ./${concat_cohort}_PoN)" ]; then
                echo $(date): WARN ./${concat_cohort} exists and is not empty.
        fi
fi

# Collect sample IDs from samples.config
# Only collect IDs from normal samples (labids ending in -B)
while read -r sampleid labid seq_center library; do
        if [[ ! ${sampleid} =~ ^#.*$ && ${labid} =~ -B.?$ || ${labid} =~ -N.?$ ]]; then
                samples+=("${labid}")
        fi
done < "${config}"

echo "$(date): Found ${#samples[@]} samples normal samples in $config"

mkdir -p ./${concat_cohort}_PoN
cd ./${concat_cohort}_PoN

for nmid in "${samples[@]}"; do
        nmid_vcf=$(find ${PWD}/.. -type f -name ${nmid}.pon.vcf.gz -print -quit)
        nmid_tbi=$(find ${PWD}/.. -type f -name ${nmid}.pon.vcf.gz.tbi -print -quit)
        if [[ $nmid_vcf && $nmid_tbi ]]; then
                echo Found VCF and index files, creating symbolic links for $nmid_vcf and $nmid_tbi
                ln -s $nmid_vcf .
                ln -s $nmid_tbi .
        else
                echo Could not find $nmid_vcf or $nmid_tbi
        fi
done
