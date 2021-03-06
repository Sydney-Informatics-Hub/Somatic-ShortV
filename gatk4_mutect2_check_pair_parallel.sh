#! /bin/bash

#########################################################
#
# Platform: NCI Gadi HPC
# Description: Check gatk4_mutect2 job, writes inputs for failed tasks
# Runs gatk4_mutect2_check_pair.sh for each tumour-normal pair in parallel
# Maximum number of samples processed in parallel is 48
# Usage: nohup sh gatk4_mutect2_check_pair_parallel.sh /path/to/cohort.config 2> /dev/null &
# Check nohup.out file. Failed tasks will be written to ./Inputs/gatk4_mutect2_missing.inputs 
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
        echo "Please provide the path to your cohort.config file, e.g. sh gatk4_mutect2_make_input.sh ../cohort.config"
        exit
fi

# INPUTS
config=$1
cohort=$(basename $config | cut -d'.' -f 1)
ref=../Reference/hs38DH.fasta
scatterdir=../Reference/ShortV_intervals
scatterlist=$scatterdir/3200_ordered_exclusions.list
pon=./$cohort\_cohort_PoN/$cohort.sorted.pon.vcf.gz
germline=../Reference/broad-references/ftp/Mutect2/af-only-gnomad.hg38.vcf.gz
logdir=./Logs/gatk4_mutect2
INPUTS=./Inputs
bamdir=../Final_bams
inputfile=${INPUTS}/gatk4_mutect2_missing.inputs
SCRIPT=./gatk4_mutect2_check_pair.sh
num_intervals=$(wc -l $scatterlist | cut -d' ' -f 1)

rm -rf ${inputfile}

# Collect sample IDs from samples.config
# Only collect IDs from normal samples (labids ending in -B)
while read -r sampleid labid seq_center library; do
        if [[ ! ${sampleid} =~ ^#.*$ && ${labid} =~ -B.?$ || ${labid} =~ -N.?$ ]]; then
                samples+=("${labid}")
        fi
done < "${config}"

# Collect all tumour IDs for each normal sample
for nmid in "${samples[@]}"; do
        # Find any matching tumour bams using normal id without -N or -B
        patient=$(echo "${nmid}" | perl -pe 's/(-B.?|-N.?)$//g')
        patient_samples=( $(awk -v pattern="${patient}-" '$2 ~ pattern{print $2}' ${config}) )
        if (( ${#patient_samples[@]} == 2 )); then
                nmid=`printf '%s\n' ${patient_samples[@]} | grep -P 'N.?$|B.?$'`
                tmid=`printf '%s\n' ${patient_samples[@]} | grep -vP 'N.?$|B.?$'`
                tmpfile=${INPUTS}/gatk4_mutect2_${tmid}_${nmid}.inputs
                tmp+=("$tmpfile")
                outdir=./Interval_VCFs/${tmid}_${nmid}
                inputs+=("${cohort},${tmid},${nmid},${ref},${pon},${germline},${outdir},${tmpfile},${scatterlist},${bamdir},${scatterdir},${logdir}")
        elif (( ${#patient_samples[@]} > 2 )); then
                nmid=`printf '%s\n' ${patient_samples[@]} | grep -P 'N.?$|B.?$'`
                for sample in "${patient_samples[@]}"; do
                        if ! [[ ${sample} =~ -N.?$ || ${sample} =~ -B.?$ ]]; then
                                tmid=${sample}
                                tmpfile=${INPUTS}/gatk4_mutect2_${tmid}_${nmid}.inputs
                                tmp+=("$tmpfile")
                                outdir=./Interval_VCFs/${tmid}_${nmid}
                                inputs+=("${cohort},${tmid},${nmid},${ref},${pon},${germline},${outdir},${tmpfile},${scatterlist},${bamdir},${scatterdir},${logdir}")
                        fi
                done
        fi
done

echo "$(date): Checking .vcf.gz, .vcf.gz.tbi, .vcf.gz.stats, f1r2 files for ${#inputs[@]} tumour normal pairs"

echo "${inputs[@]}" | xargs --max-args 1 --max-procs 48 ${SCRIPT}

if [[ -s ${inputfile} ]]; then
        paste -d'\n' "${tmp[@]}" > ${inputfile}
        echo "$(date): Removing temporary files..."
        for tmp in "${tmp[@]}"; do
                rm -rf ${tmp}
        done
        num_inputs=`wc -l ${inputfile}`
        echo "$(date): There are ${num_inputs} tasks to run for gatk4_mutect2_missing_run_parallel.pbs"
else
        echo "$(date): There are 0 tasks to run for gatk4_mutect2_missing_run_parallel.pbs"
fi
