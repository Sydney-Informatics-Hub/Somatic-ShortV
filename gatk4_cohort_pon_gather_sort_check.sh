#!/bin/bash

#########################################################
#
# Platform: NCI Gadi HPC
# Usage: sh gatk4_cohort_pon_gather_sort_check.sh
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
        echo "Please provide the path to your cohort.config file, e.g. sh gatk4_cohort_pon_gather_sort_check.sh ../cohort.config"
        exit
fi

config=$1
cohort=$(basename "$config" | cut -d. -f 1)
vcfdir=../$cohort\_cohort_PoN
logdir=./Logs/gatk4_cohort_pon_gather_sort
sorted=${vcfdir}/${cohort}.sorted.pon.vcf.gz

# Check expected output files exist
if ! [[ -s "${sorted}" &&  -s "${sorted}.tbi" ]]; then
	echo "$(date): Missing output files. Please investigate"
fi

gather_err=$(grep -i ERROR ${logdir}/${cohort}_gathervcfs.log)
sort_err=$(grep -i ERROR ${logdir}/${cohort}_sortvcf.log)

if ! [ -z "${gather_err}" ]; then
	echo "$(date): Error in ${logdir}/${cohort}_gathervcfs.log"
elif ! [ -z "${sort_err}" ]; then
	echo "$(date): Error in ${logdir}/${cohort}_sortvcf.log"
else
	echo "$(date): Checks passed"
fi
