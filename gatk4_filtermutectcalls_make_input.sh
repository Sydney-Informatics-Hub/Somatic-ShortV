#! /bin/bash

#########################################################
#
# Platform: NCI Gadi HPC
# Description: Creates input file for gatk4_filtermutectcalls_run_parallel.pbs
# This filters VCFs for each tumour-normal pair using
#       pair.unfiltered.vcf.gz (from Mutect2)
#       pair.unfiltered.vcf.gz.stats (from Mutect2)
#       tumor_segments.table (from GetPileupSummaries & CalculateContamination)
#       tumor_normal_contamination.table (from GetPileupSummaries & CalculateContamination)
#       tumour_normal_read-orientation-model.tar.gz (from Mutect2 & LearnReadOrientationModel)
# Usage: sh gatk4_filtermutectcalls_make_input.sh /path/to/cohort.config
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
        echo "Please provide the path to your cohort.config file, e.g. sh gatk4_filtermutectcalls_make_input.sh ../cohort.config"
        exit
fi

config=$1
cohort=$(basename "$config" | cut -d'.' -f 1)
ref=../Reference/hs38DH.fasta
vcfdir=./Interval_VCFs
logdir=./Logs/gatk4_filtermutectcalls
outdir=../Final_Somatic-ShortV_VCFs
INPUTS=./Inputs
inputfile=${INPUTS}/gatk4_filtermutectcalls.inputs

mkdir -p ${outdir}
mkdir -p ${logdir}
mkdir -p ${INPUTS}
rm -rf ${inputfile}

# Collect sample IDs from config file
# Only normal ids (labids ending in -B or -N)
pairs_found=0
patients=0
while read -r sampleid labid seq_center library; do
        if [[ ! ${sampleid} =~ ^#.*$ && ${labid} =~ -B.?$ || ${labid} =~ -N.?$ ]]; then
                #samples+=("${labid}")
                patient=$(echo "${labid}" | perl -pe 's/(-B.?|-N.?)$//g')
                patient_samples=( $(awk -v pattern="${patient}-" '$2 ~ pattern{print $2}' ${config}) )
                #echo ${patient_sampples[@]}
                if ((${#patient_samples[@]} == 2 )); then
                        pairs_found=$(( ${pairs_found}+1 ))
                        patients=$(( ${patients}+1 ))
                        nmid=`printf '%s\n' ${patient_samples[@]} | grep -P 'N.?$|B.?$'`
                        tmid=`printf '%s\n' ${patient_samples[@]} | grep -vP 'N.?$|B.?$'`
                        pair=${tmid}_${nmid}

                        echo "$(date): Writing input files for ${pair}"

                        unfiltered=${vcfdir}/${pair}/${pair}.unfiltered.vcf.gz
                        stats=${vcfdir}/${pair}/${pair}.unfiltered.vcf.gz.stats
                        segments=./${cohort}_GetPileupSummaries/${tmid}_segments.table
                        contamination=./${cohort}_GetPileupSummaries/${pair}_contamination.table
                        ob_priors=${vcfdir}/${pair}/${pair}_read-orientation-model.tar.gz
                        filtered=${outdir}/${pair}.filtered.vcf.gz

                        echo "${pair},${unfiltered},${ref},${stats},${segments},${contamination},${ob_priors},${filtered},${logdir}" >> ${inputfile}

                elif (( ${#patient_samples[@]} > 2 )); then
                        nmid=`printf '%s\n' ${patient_samples[@]} | grep -P 'N.?$|B.?$'`
                        patients=$(( ${patients}+1 ))
                        for sample in "${patient_samples[@]}"; do
                                if ! [[ ${sample} =~ -N.?$ || ${sample} =~ -B.?$ ]]; then
                                        tmid=${sample}
                                        pair=${tmid}_${nmid}
                                        pairs_found=$(( ${pairs_found}+1 ))

                                        echo "$(date): Writing input files for ${pair}"
                                        unfiltered=${vcfdir}/${pair}/${pair}.unfiltered.vcf.gz
                                        stats=${vcfdir}/${pair}/${pair}.unfiltered.vcf.gz.stats
                                        segments=./${cohort}_GetPileupSummaries/${tmid}_segments.table
                                        contamination=./${cohort}_GetPileupSummaries/${pair}_contamination.table
                                        ob_priors=${vcfdir}/${pair}/${pair}_read-orientation-model.tar.gz
                                        filtered=${outdir}/${pair}.filtered.vcf.gz

                                        echo "${pair},${unfiltered},${ref},${stats},${segments},${contamination},${ob_priors},${filtered},${logdir}" >> ${inputfile}
                                fi
                        done
                fi
        fi
done < "${config}"

echo "$(date): Wrote input files for ${pairs_found} tumour normal pairs (patient samples = ${patients}) for gatk4_filtermutectcalls_run_parallel.pbs"
