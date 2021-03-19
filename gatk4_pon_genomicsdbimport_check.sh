#! /bin/bash

#########################################################
#
# Platform: NCI Gadi HPC
# Description: Check gatk4_pon_genomicsdbimport job, write input for failed tasks
# by checking log files for errors. Do clean up if checks are passed.
# Duration and memory per interval is reported.
# Runs gatk4_pon_check_sample.sh for each sample in parallel
# Maximum number of samples processed in parallel is 48
# Usage: nohup sh gatk4_pon_genomicsdbimport_check.sh /path/to/cohort.config 2> /dev/null &
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
        echo "Please provide the path to your cohort.config file, e.g. sh gatk4_pon_genomicsdbimport_check.sh ../cohort.config"
        exit
fi

config=$1
cohort=$(basename "$config" | cut -d'.' -f 1)
INPUTS=./Inputs
inputfile=${INPUTS}/gatk4_pon_genomicsdbimport_missing.inputs
ref=../Reference/hs38DH.fasta
scatterdir=../Reference/ShortV_intervals
scatterlist=${scatterdir}/3200_ordered_exclusions.list
vcfdir=../${cohort}_PoN
sample_map=${INPUTS}/${cohort}.sample_map
outdir=./${cohort}_PoN_GenomicsDBImport
logdir=./Logs/gatk4_pon_genomicsdbimport
PERL_SCRIPT=gatk4_check_logs.pl
perlfile=${logdir}/interval_duration_memory.txt
nt=2 # Increase CPU as necessary

mkdir -p ${INPUTS}
mkdir -p ${logdir}

rm -rf ${inputfile}
rm -rf ${perlfile}

# Run perl script to get duration
echo "$(date): Checking ${logdir} for errors, obtaining duration and memory usage per task..."
perl $PERL_SCRIPT "$logdir"

# Check output file
while read -r interval duration memory; do
        if [[ $duration =~ NA || $memory =~ NA ]]
        then
                redo+=("$interval")
        fi
done < "$perlfile"

if [[ ${#redo[@]}>1 ]]
then
        echo "$(date): There are ${#redo[@]} intervals that need to be re-run."
        echo "$(date): Writing inputs to ${INPUTS}/gatk4_genomicsdbimport_missing.inputs"

        for redo_interval in ${redo[@]};do
                interval="${scatterdir}/${redo_interval}-scattered.interval_list"
                echo "${ref},${cohort},${interval},${sample_map},${outdir},${logdir},${nt}" >> ${inputfile}
        done
else
        echo "$(date): There are no intervals that need to be re-run. Tidying up..."
        cd ${logdir}
        tar --remove-files \
                -kczf genomicsdbimport_logs.tar.gz \
                *.oe
fi
