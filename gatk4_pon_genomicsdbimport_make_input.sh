#! /bin/bash

#########################################################
#
# Platform: NCI Gadi HPC
# Usage: sh gatk4_pon_genomicsdbimport_make_input.sh /path/to/cohort.config
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
        echo "Please provide the path to your cohort.config file, e.g. sh gatk4_pon_make_input.sh ../cohort.config"
        exit
fi

config=$1
cohort=$(basename "${config}" | cut -d'.' -f 1)
INPUTS=./Inputs
inputfile=${INPUTS}/gatk4_pon_genomicsdbimport.inputs
ref=../Reference/hs38DH.fasta
scatterdir=../Reference/ShortV_intervals
scatterlist=$scatterdir/3200_ordered_exclusions.list
vcfdir=./$cohort\_PoN
sample_map=${INPUTS}/${cohort}.sample_map
outdir=./$cohort\_PoN_GenomicsDBImport
logs=./Logs/gatk4_pon_genomicsdbimport
nt=1

mkdir -p ${INPUTS}
mkdir -p ${logs}

rm -rf ${inputfile}
rm -rf ${sample_map}

# Collect sample IDs from config file
# Only collect IDs for germline variant calling (labids ending in -B or -N)
while read -r sampleid labid seq_center library; do
        if [[ ! ${sampleid} =~ ^#.*$ && ${labid} =~ -B.?$ || ${labid} =~ -N.?$ ]]; then
                samples+=("${labid}")
        fi
done < "${config}"

echo "$(date): Writing sample_map and input file for gatk4_pon_genomicsdbimport_run_parallel.pbs for ${#samples[@]} samples"

for sample in "${samples[@]}"; do
        echo "$(date): Found ${sample}"
        echo -e "${sample}      ${vcfdir}/${sample}.pon.vcf.gz" >> ${sample_map}
done

# Loop through intervals in scatterlist file
# Print to ${INPUTS}
while IFS= read -r intfile; do
        interval="${scatterdir}/${intfile}"
        echo "${ref},${cohort},${interval},${sample_map},${outdir},${logs},${nt}" >> ${inputfile}
done < "${scatterlist}"

num_tasks=`wc -l ${inputfile}`

echo "$(date): Number of tasks to run are ${num_tasks}"
