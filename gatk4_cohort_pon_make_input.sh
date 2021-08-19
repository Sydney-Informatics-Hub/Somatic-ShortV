#! /bin/bash

#########################################################
#
# Platform: NCI Gadi HPC
# Usage: sh gatk4_cohort_pon_make_input.sh /path/to/cohort.config
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
        echo "Please provide the path to your cohort.config file, e.g. sh gatk4_cohort_pon_make_input.sh ../cohort.config"
        exit
fi

config=$1
cohort=$(basename $config | cut -d'.' -f 1)
INPUTS=./Inputs
inputfile=${INPUTS}/gatk4_cohort_pon.inputs
ref=../Reference/hs38DH.fasta
germline=../Reference/broad-references/ftp/Mutect2/af-only-gnomad.hg38.vcf.gz
scatterdir=../Reference/ShortV_intervals
scatterlist=$scatterdir/3200_ordered_exclusions.list
gendbdir=./$cohort\_PoN_GenomicsDBImport
outdir=./$cohort\_cohort_PoN
logdir=./Logs/gatk4_cohort_pon

rm -rf ${inputfile}
mkdir -p ${logdir}

# Collect normal sample IDs from cohort.config
while read -r sampleid labid seq_center library; do
        if [[ ! ${sampleid} =~ ^#.*$ && ${labid} =~ -B.?$ || ${labid} =~ -N.?$ ]]; then
                samples+=("${labid}")
        fi
done < "${config}"

echo "$(date): Writing input file for gatk4_cohort_pon_run_parallel.pbs for ${#samples[@]} samples"

# Write gatk4_cohort_pon.inputs file
while IFS= read -r intfile; do
        interval="${scatterdir}/${intfile}"
        echo "${ref},${cohort},${germline},${gendbdir},${interval},${outdir},${logdir}" >> ${inputfile}
done < "${scatterlist}"

num_tasks=`wc -l ${inputfile}`
echo "$(date): Number of tasks are ${num_tasks}"

