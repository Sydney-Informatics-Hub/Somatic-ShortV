#! /bin/bash

#########################################################
#
# Platform: NCI Gadi HPC
# Description: Simple concatenation of config files into a new config file
# Usage: sh concat_configs.sh <new_config.config> <cohort1.config> <cohort2.config>
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
cat=$(cat "${@:2}")

if [ -f $output ]; then
        echo $(date): The $output file exists, please choose another filename to output the new config file to.
        exit
fi

echo $(date) Concatenting "${configs[@]}", assuming LabSampleIDs are unique. Writing to $output

# Simple concatenate configs, contains all headers if present
echo "$cat" > $output

header=$(grep -m 1 "^#" $output)
config_noheader=$(grep -v "^#" $output)

# Keep only first header, two steps for newline after header
echo $(date): Writing new config to $output, including samples in "${configs[@]}"

echo "$header" > $output
echo "$config_noheader" >> $output
sed -i '/^$/d' $output
