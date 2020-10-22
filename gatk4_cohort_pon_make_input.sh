#! /bin/bash

# Create input file to run gatk4_cohort_pon_run_parallel.pbs
# Operates on per interval GenomicsDBImport database files

if [ -z "$1" ]
then
	echo "Please run this script with the base name of your config file, e.g. sh gatk4_hc_make_input.sh samples_batch1"
	exit
fi

cohort=$1
config=../$cohort.config
INPUTS=./Inputs
inputfile=${INPUTS}/gatk4_cohort_pon.inputs
ref=../Reference/hs38DH.fasta
gnomad=../Reference/broad-references/ftp/Mutect2/af-only-gnomad.hg38.vcf.gz
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
	echo "${ref},${cohort},${gnomad},${gendbdir},${interval},${outdir},${logdir}" >> ${inputfile}
done < "${scatterlist}"

num_tasks=`wc -l ${inputfile}`
echo "$(date): Number of tasks are ${num_tasks}"



