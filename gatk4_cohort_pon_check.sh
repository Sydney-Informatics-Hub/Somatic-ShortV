#! /bin/bash

#########################################################
#
# Platform: NCI Gadi HPC
# Description: Check gatk4_cohort_pon job, write input for failed tasks
# Usage: nohup sh gatk4_cohort_pon_check.sh /path/to/cohort.config 2> /dev/null &
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
        echo "Please provide the path to your cohort.config file, e.g nohup sh gatk4_cohort_pon_check.sh /path/to/cohort.config 2> /dev/null &"
        exit
fi

config=$1
cohort=$(basename $config | cut -d'.' -f 1)
INPUTS=./Inputs
inputfile=${INPUTS}/gatk4_cohort_pon_missing.inputs
ref=../Reference/hs38DH.fasta
gnomad=../Reference/broad-references/ftp/Mutect2/af-only-gnomad.hg38.vcf.gz
scatterdir=../Reference/ShortV_intervals
scatterlist=$scatterdir/3200_ordered_exclusions.list
gendbdir=./$cohort\_PoN_GenomicsDBImport
outdir=./$cohort\_cohort_PoN
logdir=./Logs/gatk4_cohort_pon
PERL_SCRIPT=./gatk4_check_logs.pl
perlfile=${logdir}/interval_duration_memory.txt
num_int=`wc -l ${scatterlist} | cut -d' ' -f 1`

# Increase CPU as necessary

mkdir -p ${INPUTS}
mkdir -p ${logdir}

rm -rf ${inputfile}
rm -rf ${perlfile}

# Check each interval vcf and tbi file exists and is not empty
for index in $(seq -f "%04g" 0 $((${num_int}-1))); do
        vcf=${outdir}/${cohort}.${index}.pon.vcf.gz
        tbi=${outdir}/${cohort}.${index}.pon.vcf.gz.tbi
        if ! [[ -s "${vcf}" && -s "${tbi}" ]]
        then
                redo+=("$index")
        fi
done
echo $(date): "${#redo[@]}" tasks had missing or empty VCF or TBI files, wrote to $inputfile.

# Check log files. Run perl script to get duration
echo "$(date): Checking log files for errors, obtaining duration and memory usage per task..."
perl $PERL_SCRIPT "$logdir"

# Check output file
while read -r interval duration memory; do
        if [[ $duration =~ NA || $memory =~ NA ]]
        then
                if [[ ! "${redo[@]}" =~ "${interval}" ]]
                then
                        redo+=("$interval")
                fi
        fi
done < "$perlfile"

if [[ ${#redo[@]}>1 ]]
then

        echo "$(date): There are ${#redo[@]} intervals that need to be re-run."
        echo "$(date): Writing inputs to ${inputfile}"

        for redo_interval in ${redo[@]}; do
                interval="${scatterdir}/${redo_interval}-scattered.interval_list"
                echo "${ref},${cohort},${gnomad},${gendbdir},${interval},${outdir},${logdir}" >> ${inputfile}
        done
else
        echo "$(date): There are no intervals that need to be re-run. Tidying up..."
        cd ${logdir}
        tar --remove-files \
        -kczf cohort_pon_logs.tar.gz \
        *.oe
fi
