#! /bin/bash

#########################################################
#
# Platform: NCI Gadi HPC
# Usage: sh gatk4_pon_gathervcfs_make_input.sh /path/to/cohort.config
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
        echo "Please provide the path to your cohort.config file, e.g. sh gatk4_mergemutectstats_make_input.sh ../cohort.config"
        exit
fi

config=$1
cohort=$(basename "$config" | cut -d'.' -f 1)
vcfdir=../Mutect2
bamdir=../Final_bams
logdir=./Logs/gatk4_mergemutectstats
scatterdir=../Reference/ShortV_intervals
scatterlist=$(ls $scatterdir/*.list)
if [[ ${#scatterlist[@]} > 1 ]]; then
        echo "$(date): ERROR - more than one scatter list file found: ${scatterlist[@]}"
        exit
fi
num_int=`wc -l ${scatterlist} | cut -d' ' -f 1`
INPUTS=./Inputs
inputfile=${INPUTS}/gatk4_mergemutectstats.inputs

mkdir -p ${logdir} ${INPUTS}
rm -rf ${inputfile}

# Collect sample IDs from config file
# Only normal ids (labids ending in -B or -N)
pairs_found=0
patients=0
while read -r sampleid labid seq_center library; do
        if [[ ! ${sampleid} =~ ^#.*$ && ${labid} =~ -B.?$ || ${labid} =~ -N.?$ ]]; then
                #samples+=("${labid}")
                patient=$(echo "${labid}" | perl -pe 's/(-B.?|-N.?)$//g')
                patient_samples=(`find ${bamdir} -name "${patient}-[B|N|T|M|P]*.final.bam" -execdir echo {} ';' | sed 's|^./||' | sed 's|.final.bam||g'`)
		if ((${#patient_samples[@]} == 2 )); then
                        pairs_found=$(( ${pairs_found}+1 ))
                        patients=$(( ${patients}+1 ))
                        nmid=`printf '%s\n' ${patient_samples[@]} | grep -P 'N.?$|B.?$'`
                        tmid=`printf '%s\n' ${patient_samples[@]} | grep -vP 'N.?$|B.?$'`
                        pair=${tmid}_${nmid}

                        echo "$(date): Writing input files for ${pair}"

                        args=${INPUTS}/gatk4_mergemutectstats_${pair}\.args
                        out=${vcfdir}/${pair}/${pair}.unfiltered.vcf.gz.stats

                        rm -rf ${args}
                        for interval in $(seq -f "%04g" 0 $((${num_int}-1)));do
                                echo "--stats " ${vcfdir}/${pair}/${pair}.unfiltered.${interval}.vcf.gz.stats >> ${args}
                        done
                        echo "--stats " ${vcfdir}/${pair}/${pair}.unfiltered.chrM.vcf.gz.stats >> ${args}

                        echo "${pair},${args},${logdir},${out}" >> ${inputfile}

                elif (( ${#patient_samples[@]} > 2 )); then
                        nmid=`printf '%s\n' ${patient_samples[@]} | grep -P 'N.?$|B.?$'`
                        patients=$(( ${patients}+1 ))
                        for sample in "${patient_samples[@]}"; do
                                if ! [[ ${sample} =~ -N.?$ || ${sample} =~ -B.?$ ]]; then
                                        tmid=${sample}
                                        pair=${tmid}_${nmid}
                                        pairs_found=$(( ${pairs_found}+1 ))

                                        echo "$(date): Writing input files for ${pair}"

                                        args=${INPUTS}/gatk4_mergemutectstats_${pair}\.args
                                        out=${vcfdir}/${pair}/${pair}.unfiltered.vcf.gz.stats

                                        rm -rf ${args}
                                        for interval in $(seq -f "%04g" 0 $((${num_int}-1)));do
                                                echo "--stats " ${vcfdir}/${pair}/${pair}.unfiltered.${interval}.vcf.gz.stats >> ${args}
                                        done
                                        echo "--stats " ${vcfdir}/${pair}/${pair}.unfiltered.chrM.vcf.gz.stats >> ${args}

                                        echo "${pair},${args},${logdir},${out}" >> ${inputfile}
                                fi
                        done
                fi
        fi
done < "${config}"

echo "$(date): Wrote input files for ${pairs_found} tumour normal pairs (patient samples = ${patients}) for gatk4_mergemutectstats_run_parallel.pbs"
