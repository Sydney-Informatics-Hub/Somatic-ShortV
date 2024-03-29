#! /bin/bash

#########################################################
#
# Platform: NCI Gadi HPC
# Usage:
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

set -e

if [ -z "$1" ]
then
        echo "Please provide the path to your cohort.config file, e.g. sh gatk4_getpileupsummaries_make_input.sh ../cohort.config"
        exit
fi

config=$1
cohort=$(basename "$config" | cut -d'.' -f 1)
pileups=./${cohort}_GetPileupSummaries
logdir=./Logs/gatk4_calculatecontamination
INPUTS=./Inputs
inputfile=${INPUTS}/gatk4_calculatecontamination.inputs

mkdir -p ${logdir}
mkdir -p ${INPUTS}
rm -rf ${inputfile}

# Collect sample IDs from config file
# Only tumour ids (labids NOT ending in -B or -N)
samples=0
pairs_found=0
while read -r sampleid labid seq_center library; do
        if [[ ! ${sampleid} =~ ^#.*$ && ${labid} =~ -B.?$ || ${labid} =~ -N.?$ ]]; then
                samples=$(( ${samples}+1 ))
                patient=$(echo "${labid}" | perl -pe 's/(-B.?|-N.?)$//g')
                patient_samples=(`find ${bamdir} -name "${patient}-[B|N|T|M|P]*.final.bam" -execdir echo {} ';' | sed 's|^./||' | sed 's|.final.bam||g'`)
                if ((${#patient_samples[@]} == 2 )); then
                        pairs_found=$(( ${pairs_found}+1 ))
                        nmid=`printf '%s\n' ${patient_samples[@]} | grep -P 'N.?$|B.?$'`
                        tmid=`printf '%s\n' ${patient_samples[@]} | grep -vP 'N.?$|B.?$'`
                        pair=${tmid}_${nmid}

                        echo "$(date): Writing input files for ${pair}"

                        nmpileup=${pileups}/${nmid}_pileups.table
                        tmpileup=${pileups}/${tmid}_pileups.table
                        segments=${pileups}/${tmid}_segments.table
                        out=${pileups}/${pair}_contamination.table
                        echo "${pair},${nmpileup},${tmpileup},${segments},${out},${logdir}" >> ${inputfile}
                elif (( ${#patient_samples[@]} > 2 )); then
                        nmid=`printf '%s\n' ${patient_samples[@]} | grep -P 'N.?$|B.?$'`
                        for sample in "${patient_samples[@]}"; do
                                if ! [[ ${sample} =~ -N.?$ || ${sample} =~ -B.?$ ]]; then
                                        tmid=${sample}
                                        pair=${tmid}_${nmid}
                                        pairs_found=$(( ${pairs_found}+1 ))

                                        echo "$(date): Writing input files for ${pair}"

                                        nmpileup=${pileups}/${nmid}_pileups.table
                                        tmpileup=${pileups}/${tmid}_pileups.table
                                        segments=${pileups}/${tmid}_segments.table
                                        out=${pileups}/${pair}_contamination.table

                                        echo "${pair},${nmpileup},${tmpileup},${segments},${out},${logdir}" >> ${inputfile}
                                fi
                        done
                fi
        fi
done < "${config}"

echo "$(date): Wrote input files for ${pairs_found} TN pairs from ${cohort}.config (normal samples = ${samples})  for gatk4_calculatecontamination_run_parallel.pbs"
