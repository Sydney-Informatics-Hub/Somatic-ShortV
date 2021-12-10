#! /bin/bash

#########################################################
#
# Platform: NCI Gadi HPC
# Usage: nohup sh gatk4_pon_check_sample_parallel.sh /path/to/cohort.config 2> /dev/null &
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
        echo "Please provide the path to your cohort.config file, e.g nohup sh gatk4_pon_check_sample_parallel.sh /path/to/cohort.config 2> /dev/null &"
        exit
fi

config=$1
if [ ! -f $config ]; then
	echo "$config does not exist."
fi
ref=../Reference/hs38DH.fasta
scatterdir=../Reference/ShortV_intervals
scatterlist=$(ls $scatterdir/*.list)
if [[ ${#scatterlist[@]} > 1 ]]; then
        echo "$(date): ERROR - more than one scatter list file found: ${scatterlist[@]}"
        exit
fi
bamdir=../Final_bams
logdir=./Logs/gatk4_pon
SCRIPT=./gatk4_pon_check_sample.sh
INPUTS=./Inputs
inputfile=${INPUTS}/gatk4_pon_missing.inputs

rm -rf ${inputfile}

# Collect sample IDs from samples.config
# Only collect IDs from normal samples (labids ending in -B)
while read -r sampleid labid seq_center library; do
        if [[ ! ${sampleid} =~ ^#.*$ && ${labid} =~ -B.?$ || ${labid} =~ -N.?$ ]]; then
		samples+=("${config},${labid},${inputfile},${ref},${scatterdir},${scatterlist},${bamdir},${logdir}")
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
