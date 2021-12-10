#! /bin/bash

#########################################################
#
# Platform: NCI Gadi HPC
# Usage: sh gatk4_mutect2_make_input.sh
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
        echo "Please provide the path to your cohort.config file, e.g. sh gatk4_mutect2_make_input.sh ../cohort.config"
        exit
fi

# INPUTS
config=$1
cohort=$(basename $config | cut -d'.' -f 1)
outdir=../Mutect2
logdir=./Logs/gatk4_mutect2
bamdir=../Final_bams
ref=../Reference/hs38DH.fasta
scatterdir=../Reference/ShortV_intervals
scatterlist=$(ls $scatterdir/*.list)
if [[ ${#scatterlist[@]} > 1 ]]; then
        echo "$(date): ERROR - more than one scatter list file found: ${scatterlist[@]}"
        exit
fi
pon=../$cohort\_cohort_PoN/$cohort.sorted.pon.vcf.gz
germline=../Reference/broad-references/ftp/Mutect2/af-only-gnomad.hg38.vcf.gz
INPUTS=./Inputs
inputfile=${INPUTS}/gatk4_mutect2.inputs
SCRIPT=./gatk4_mutect2_pair.sh

mkdir -p ${logdir} ${outdir} ${INPUTS}
rm -rf ${inputfile}

# Collect normal sample IDs from cohort.config
while read -r sampleid labid seq_center library; do
        if [[ ! ${sampleid} =~ ^#.*$ && ${labid} =~ -B.?$ || ${labid} =~ -N.?$ ]]; then
                samples+=("${labid}")
        fi
done < "${config}"

# Perform a count so we know how many tasks to expect
tasks=0
for nmid in "${samples[@]}"; do
        patient=$(echo "${nmid}" | perl -pe 's/(-B.?|-N.?)$//g')
        all_bams=(`find ${bamdir} -name "${patient}-[B|N|T|M|P]*.final.bam" -execdir echo {} ';' | sed 's|^./||'`)
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
echo "$(date): There are $tasks tumour normal pairs. Writing 3,201 input lines to $inputfile"

# Write gatk4_mutect2.inputs file for each tumour matching the normal sample
# This will find bams matching the normal id with anything other than -B or -N appended to the name
# Not all normals have a matching tumour sample - skip these samples
# Each line of input is for one sample and 3,201 intervals. One of the intervals=chrM.
for nmid in "${samples[@]}"; do
        # Find any matching tumour bams using normal id without -N or -B
        patient=$(echo "${nmid}" | perl -pe 's/(-B.?|-N.?)$//g')
        patient_samples=(`find ${bamdir} -name "${patient}-[B|N|T|M|P]*.final.bam" -execdir echo {} ';' | sed 's|^./||' | sed 's|.final.bam||g'`)
	if (( ${#patient_samples[@]} == 2 )); then
                nmid=`printf '%s\n' ${patient_samples[@]} | grep -P 'N.?$|B.?$'`
                tmid=`printf '%s\n' ${patient_samples[@]} | grep -vP 'N.?$|B.?$'`
		tmpfile=${INPUTS}/gatk4_mutect2_${tmid}_${nmid}.inputs
                tmp+=("${tmpfile}")
                inputs+=("${cohort},${tmid},${nmid},${ref},${pon},${germline},${outdir},${tmpfile},${scatterlist},${bamdir},${scatterdir}")
        elif (( ${#patient_samples[@]} > 2 )); then
                nmid=`printf '%s\n' ${patient_samples[@]} | grep -P 'N.?$|B.?$'`
                for sample in "${patient_samples[@]}"; do
                        if ! [[ ${sample} =~ -N.?$ || ${sample} =~ -B.?$ ]]; then
                                tmid=${sample}
		                tmpfile=${INPUTS}/gatk4_mutect2_${tmid}_${nmid}.inputs
		                tmp+=("${tmpfile}")
                                inputs+=("${cohort},${tmid},${nmid},${ref},${pon},${germline},${outdir},${tmpfile},${scatterlist},${bamdir},${scatterdir}")
                        fi
                done
        fi
done

echo "${inputs[@]}" | xargs --max-args 1 --max-procs 40 ${SCRIPT}

echo "$(date): Wrote inputs for ${#inputs[@]} tumour-normal pairs. Interleaving input files to retain interval order"

paste -d'\n' "${tmp[@]}" > ${inputfile}

echo "$(date): Removing temporary files"

for tmp in "${tmp[@]}"; do
        rm -rf ${tmp}
done

num_inputs=`wc -l ${inputfile}`
ncpus=$(( ${#samples[@]}*48*4 ))
mem=$(( ${#samples[@]}*192*4 ))
num_tasks=`wc -l $inputfile | cut -d' ' -f 1`
echo "$(date): Number of tasks in $inputfile: $num_tasks"
echo "$(date): Suggested compute to request in gatk4_mutect2_run_parallel.pbs: walltime=02:00:00,ncpus=${ncpus},mem=${mem}GB,wd"

