#! /bin/bash

#########################################################
#
# Platform: NCI Gadi HPC
# Description: Creates input file for gatk4_mutect2_gathervcfs_run_parallel.pbs
# Usage: sh gatk4_mutect2_gathervcfs_make_input.sh /path/to/cohort.config
# Author: Tracy Chew
# tracy.chew@sydney.edu.au
# Date last modified: 23/03/2021
#
# If you use this script towards a publication, please acknowledge the
# Sydney Informatics Hub (or co-authorship, where appropriate).
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
        echo "Please provide the path to your cohort.config file, e.g. sh gatk4_mutect2_gathervcfs_make_input.sh ../cohort.config"
        exit
fi

config=$1
cohort=$(basename "$config" | cut -d'.' -f 1)
vcfdir=./Interval_VCFs
logdir=./Logs/gatk4_mutect2_gathervcfs
scatterdir=../Reference/ShortV_intervals
scatterlist=$scatterdir/3200_ordered_exclusions.list
num_int=`wc -l ${scatterlist} | cut -d' ' -f 1`
INPUTS=./Inputs
inputfile=${INPUTS}/gatk4_mutect2_gathervcfs.inputs

mkdir -p ${logdir}
mkdir -p ${INPUTS}
rm -rf ${inputfile}

# Collect sample IDs from config file
# Only normal ids (labids ending in -B or -N)
pairs_found=0
while read -r sampleid labid seq_center library; do
        if [[ ! ${sampleid} =~ ^#.*$ && ${labid} =~ -B.?$ || ${labid} =~ -N.?$ ]]; then
                #samples+=("${labid}")
                patient=$(echo "${labid}" | perl -pe 's/(-B.?|-N.?)$//g')
                patient_samples=( $(awk -v pattern="${patient}-" '$2 ~ pattern{print $2}' ${config}) )
                if ((${#patient_samples[@]} == 2 )); then
                        pairs_found=$(( ${pairs_found}+1 ))
                        nmid=`printf '%s\n' ${patient_samples[@]} | grep -P 'N.?$|B.?$'`
                        tmid=`printf '%s\n' ${patient_samples[@]} | grep -vP 'N.?$|B.?$'`
                        pair=${tmid}_${nmid}

                        echo "$(date): Writing input files for ${pair}"

                        args=${INPUTS}/gatk4_mutect2_gathervcfs_${pair}\.args
                        partial=${vcfdir}/${pair}/${pair}.unfiltered.no_chrM.vcf.gz
                        chrM=${vcfdir}/${pair}/${pair}.unfiltered.chrM.vcf.gz
                        out=${vcfdir}/${pair}/${pair}.unfiltered.vcf.gz

                        rm -rf ${args}
                        for interval in $(seq -f "%04g" 0 $(($num_int-1)));do
                                echo "--I " ${vcfdir}/${pair}/${pair}.unfiltered.${interval}.vcf.gz >> ${args}
                        done

                        echo "${pair},${args},${logdir},${partial},${chrM},${out}" >> ${inputfile}

                elif (( ${#patient_samples[@]} > 2 )); then
                        nmid=`printf '%s\n' ${patient_samples[@]} | grep -P 'N.?$|B.?$'`
                        for sample in "${patient_samples[@]}"; do
                                if ! [[ ${sample} =~ -N.?$ || ${sample} =~ -B.?$ ]]; then
                                        tmid=${sample}
                                        pair=${tmid}_${nmid}
                                        pairs_found=$(( ${pairs_found}+1 ))

                                        echo "$(date): Writing input files for ${pair}"

                                        args=${INPUTS}/gatk4_mutect2_gathervcfs_${pair}\.args
                                        partial=${vcfdir}/${pair}/${pair}.unfiltered.no_chrM.vcf.gz
                                        chrM=${vcfdir}/${pair}/${pair}.unfiltered.chrM.vcf.gz
                                        out=${vcfdir}/${pair}/${pair}.unfiltered.vcf.gz

                                        rm -rf ${args}
                                        for interval in $(seq -f "%04g" 0 $(($num_int-1)));do
                                                echo "--I " ${vcfdir}/${pair}/${pair}.unfiltered.${interval}.vcf.gz >> ${args}
                                        done

                                        echo "${pair},${args},${logdir},${partial},${chrM},${out}" >> ${inputfile}
                                fi
                        done
                fi
        fi
done < "${config}"

echo "$(date): Wrote input files for ${pairs_found} tumour normal pairs"
