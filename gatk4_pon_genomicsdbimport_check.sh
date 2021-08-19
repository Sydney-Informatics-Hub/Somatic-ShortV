#! /bin/bash

#########################################################
#
# Platform: NCI Gadi HPC
# Usage: nohup sh gatk4_pon_genomicsdbimport_check.sh /path/to/cohort.config 2> /dev/null &
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
