
#! /bin/bash

#########################################################
#
# Platform: NCI Gadi HPC
# Description: Check gatk4_pon job, write input for failed tasks
# Runs gatk4_pon_check_sample.sh for each sample in parallel
# Maximum number of samples processed in parallel is 48
# Usage: nohup sh gatk4_pon_check_sample_parallel.sh /path/to/cohort.config 2> /dev/null &
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

module load openmpi/4.0.2

if [ -z "$1" ]
then
        echo "Please provide the path to your cohort.config file, e.g nohup sh gatk4_pon_check_sample_parallel.sh /path/to/cohort.config 2> /dev/null &"
        exit
fi

config=$1
SCRIPT=./gatk4_pon_check_sample.sh
INPUTS=./Inputs
inputfile=${INPUTS}/gatk4_pon_missing.inputs

rm -rf ${inputfile}

# Collect sample IDs from samples.config
# Only collect IDs from normal samples (labids ending in -B)
while read -r sampleid labid seq_center library; do
        if [[ ! ${sampleid} =~ ^#.*$ && ${labid} =~ -B.?$ || ${labid} =~ -N.?$ ]]; then
                samples+=("${cohort},${labid},${inputfile}")
        fi
done < "${config}"

echo "$(date): Checking vcf, vcf.idx and vcf.stats files for ${#samples[@]} samples"
echo "${samples[@]}" | xargs --max-args 1 --max-procs 48 ${SCRIPT}

if [[ -s ${inputfile} ]]; then
        num_inputs=`wc -l ${inputfile}`
        echo "$(date): There are ${num_inputs} tasks to run for gatk4_pon_missing_run_parallel.pbs"
else
        echo "$(date): There are 0 tasks to run for gatk4_pon_missing_run_parallel.pbs"
fi
