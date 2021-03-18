#! /bin/bash

#########################################################
#
# Platform: NCI Gadi HPC
# Description: Creates a single new_cohort.config file from multiple
# config files for downstream processing in Somatic-ShortV pipeline.
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

# There should be at least 3 args
if [ -z "$3" ]
then
        echo "Please provide the name of the output config file followed by the config files you wish to join"
        echo "e.g. sh concat_configs.sh ../combinedSampleCohort.config ../oldSamples.config ../newSamples.config"
        echo "sh concat_configs.sh ../combinedSampleCohort.config ../*config also works"
        exit
fi

output=$1
configs=("${@:2}")
cat=$(cat ${configs[@]})

# Simple concatenate configs, contains all headers if present
echo "$cat" > $output

header=$(grep -m 1 "^#" $output)
config_noheader=$(grep -v "^#" $output)

# Keep only first header, two steps for newline after header
echo $(date): Writing new config to $output, including samples in "${configs[@]}"

echo "$header" > $output
echo "$config_noheader" >> $output

# Create a single directory containing PoN sample VCFs
concat_cohort=$(basename $output | cut -d'.' -f 1)
mkdir -p ./${concat_cohort}_PoN

for config in "${configs[@]}"; do
        cohort=$(basename ${config} | cut -d'.' -f 1)
        if [ -d "./${cohort}_PoN" ]; then
                if [ -z "$(ls -A ./${cohort}_PoN)" ]; then
                        echo $(date): ./${cohort}_PoN is empty and will be excluded in ./${concat_cohort}_PoN
                        echo $(date): If you are running gatk4_pon_genomicsdbimport step please make sure you run upsteam steps for ./${cohort}_PoN
                else
                        echo $(date): Creating symbolic links for files in ./${cohort}_PoN to ./${concat_cohort}_PoN
                        `ln -s ./${cohort}_PoN/* ./${concat_cohort}_PoN/.`

                fi
        else
                echo $(date): ./${cohort}_PoN does not exist and will be excluded in ./${concat_cohort}_PoN
        fi
done
