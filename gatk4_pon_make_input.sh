#! /bin/bash

# Create input for first step in creating a panel of normals
# First step is to run Mutect2 in tumour-only mode for each normal sample

if [ -z "$1" ]
then
	echo "Please run this script with the base name of your config file, e.g. sh gatk4_hc_make_input.sh samples_batch1"
	exit
fi

cohort=$1
config=../$cohort.config
ref=../Reference/hs38DH.fasta
scatterdir=../Reference/ShortV_intervals
scatterlist=$scatterdir/3200_ordered_exclusions.list
bamdir=../Final_bams
outdir=./$cohort\_PoN
logs=./Logs/gatk4_pon
INPUTS=./Inputs
inputfile=${INPUTS}/gatk4_pon.inputs
nt=1

mkdir -p ${INPUTS}
mkdir -p ${logs}

# Collect sample IDs from samples.config
# Only collect IDs from normal samples (labids ending in -B)
while read -r sampleid labid seq_center library; do
	if [[ ! ${sampleid} =~ ^#.*$ && ${labid} =~ -B.?$ || ${labid} =~ -N.?$ ]]; then
		samples+=("${labid}")
	fi
done < "${config}"

echo "$(date): Writing inputs for gatk4_pon_run_parallel.pbs for ${#samples[@]} samples and 3200 tasks to ${inputfile}"
echo "$(date): Normal samples found include ${samples[@]}"

rm -rf ${inputfile}

# Write gatk4_pon_mutect2.inputs file, using nt=1 
while IFS= read -r intfile; do
	for sample in "${samples[@]}"; do
		out=${outdir}/${sample}
		bam=${bamdir}/${sample}.final.bam
		logdir=${logs}/${sample}
		interval="${scatterdir}/${intfile}"
		echo "${ref},${sample},${bam},${interval},${out},${nt},${logdir}" >> ${inputfile}
	done
done < "${scatterlist}"

num_inputs=`wc -l ${inputfile}`

echo "$(date): There are ${num_inputs} tasks to run for gatk4_pon_run_parallel.pbs"
