#!/bin/bash

#########################################################
#
# Platform: NCI Gadi HPC
# Usage: bash gatk4_getpileupsummaries_byInterval_concat.sh /path/to/cohort.config
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

# Sample config file:
if [ -z "$1" ]
then
        printf "Please provide the path to your cohort.config file, e.g. sh gatk4_getpileupsummaries_scattered_make_input.sh ../cohort.config\n"
        exit
fi
config=$1

#####################

cohort=$(basename "$config" | cut -d'.' -f 1)

outdir=../${cohort}_GetPileupSummaries
indir=${outdir}/scatter

#####################

awk 'NR>1' ${config} | while read LINE
do
	sample=`echo $LINE | cut -d ' ' -f 2`
	files=($(ls ${indir}/${sample}*table))
	out=${outdir}/${sample}_pileups.table
	# Take headers from first (they are all indentical)
	head -n 2 ${files[0]} > ${out}
	
	echo Combining pileup tables for $sample into $out
	# Concatenate the contents of all files, skip first two header lines
	for file in ${files[@]}
	do
    		awk 'NR > 2 {print}' $file >> $out
	done
done
