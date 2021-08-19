#! /bin/bash

#########################################################
#
# Platform: NCI Gadi HPC
# Usage:
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
