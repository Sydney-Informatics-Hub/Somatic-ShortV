#! /bin/bash

# Create input file run gatk4 GenomicsDBImport in parallel
# Consolidates VCFs across multiple samples for each interval
# Run after mergining interval VCFs into GVCF per sample (operates on GVCFs)

if [ -z "$1" ]
then
	echo "Please run this script with the base name of your config file, e.g. sh gatk4_hc_make_input.sh samples_batch1"
	exit
fi

cohort=$1
config=../$cohort.config
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
	echo -e "${sample}	${vcfdir}/${sample}.pon.g.vcf.gz" >> ${sample_map}
done

# Loop through intervals in scatterlist file
# Print to ${INPUTS}
while IFS= read -r intfile; do
	interval="${scatterdir}/${intfile}"
	echo "${ref},${cohort},${interval},${sample_map},${outdir},${logs},${nt}" >> ${inputfile}
done < "${scatterlist}"

num_tasks=`wc -l ${inputfile}`

echo "$(date): Number of tasks to run are ${num_tasks}"


