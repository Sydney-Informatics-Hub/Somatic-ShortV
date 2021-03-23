#! /bin/bash

#########################################################
#
# Platform: NCI Gadi HPC
# Description: Creates inputs for gatk4_mutect2_run_parallel.pbs
# This runs Mutect2 for tumour-normal pairs for N genomic intervals
# Author: Tracy Chew
# tracy.chew@sydney.edu.au
# Date last modified: 24/02/2021
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

set -e

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
outdir=./Interval_VCFs
logdir=./Logs/gatk4_mutect2
INPUTS=./Inputs
bamdir=../Final_bams
inputfile=${INPUTS}/gatk4_mutect2.inputs
SCRIPT=./gatk4_mutect2_pair_make_input.sh
num_intervals=$(wc -l $scatterlist | cut -d' ' -f 1)

mkdir -p ${logdir}
mkdir -p ${outdir}
mkdir -p ${INPUTS}

rm -rf ${inputfile}

echo "$(date): Writing inputs for gatk4_mutect2_run_parallel.pbs"

# Collect normal sample IDs from cohort.config
while read -r sampleid labid seq_center library; do
        if [[ ! ${sampleid} =~ ^#.*$ && ${labid} =~ -B.?$ || ${labid} =~ -N.?$ ]]; then
                samples+=("${labid}")
        fi
done < "${config}"

echo "$(date) Found "${#samples[@]}" normal samples in $config"

# Perform a count so we know how many tasks to expect
tasks=0
for nmid in "${samples[@]}"; do
        patient=$(echo "${nmid}" | perl -pe 's/(-B.?|-N.?)$//g')
        all_bams=(`find ${bamdir} -name ${patient}-*.final.bam -execdir echo {} ';' | sed 's|^./||'`)
        #echo $patient has ${#all_bams[@]} bams: "${all_bams[@]}"
        if (( ${#all_bams[@]} == 1 )); then
                echo ${patient} has 1 bam: "${all_bams[@]}". Mutect2 for tumour-normal mode will not be performed.
        elif (( ${#all_bams[@]} == 2 )); then
                echo "${patient} has ${#all_bams[@]} bams: ${all_bams[@]}"
                pairs=$(( ${#all_bams[@]}-1 ))
                tasks=$(( ${tasks}+${pairs} ))
        elif  (( ${#all_bams[@]} > 2 )); then
                echo ${patient} has ${#all_bams[@]} bams: "${all_bams[@]}"
                pairs=$(( ${#all_bams[@]}-1 ))
                tasks=$(( ${tasks}+${pairs} ))
        fi
done
echo "$(date): There are $tasks unique tumour normal pairs. Writing $((${num_intervals}+1)) input lines for each unique tumour normal pair to $inputfile"

# Write gatk4_mutect2.inputs file for each tumour matching the normal sample
# This will find bams matching the normal id with anything other than -B or -N appended to the name
# Not all normals have a matching tumour sample - skip these samples
# Each line of input is for one sample and 3,201 intervals. One of the intervals=chrM.
for nmid in "${samples[@]}"; do
        # Find any matching tumour bams using normal id without -N or -B
        patient=$(echo "${nmid}" | perl -pe 's/(-B.?|-N.?)$//g')
        patient_samples=( $(awk -v pattern="${patient}-" '$2 ~ pattern{print $2}' ${config}) )
        if (( ${#patient_samples[@]} == 2 )); then
                nmid=`printf '%s\n' ${patient_samples[@]} | grep -P 'N.?$|B.?$'`
                tmid=`printf '%s\n' ${patient_samples[@]} | grep -vP 'N.?$|B.?$'`
                tmpfile=${INPUTS}/gatk4_mutect2_${tmid}_${nmid}.inputs
                tmp+=("$tmpfile")
                inputs+=("${cohort},${tmid},${nmid},${ref},${pon},${germline},${outdir},${tmpfile},${scatterlist},${bamdir},${scatterdir}")
        elif (( ${#patient_samples[@]} > 2 )); then
                nmid=`printf '%s\n' ${patient_samples[@]} | grep -P 'N.?$|B.?$'`
                for sample in "${patient_samples[@]}"; do
                        if ! [[ ${sample} =~ -N.?$ || ${sample} =~ -B.?$ ]]; then
                                tmid=${sample}
                                tmpfile=${INPUTS}/gatk4_mutect2_${tmid}_${nmid}.inputs
                                inputs+=("${cohort},${tmid},${nmid},${ref},${pon},${germline},${outdir},${tmpfile},${scatterlist},${bamdir},${scatterdir}")
                                tmp+=("$tmpfile")
                        fi
                done
        else
                echo $(date): $patient has no matching tumour sample
        fi
done

echo "${inputs[@]}" | xargs --max-args 1 --max-procs 20 ${SCRIPT}

echo "$(date): Wrote inputs for ${#inputs[@]} tumour-normal pairs. Interleaving input files to retain interval order"

paste -d'\n' "${tmp[@]}" > ${inputfile}

echo "$(date): Removing temporary files"

for tmp in "${tmp[@]}"; do
        rm -rf ${tmp}
done

echo "$(date): Done!"
