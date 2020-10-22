#! /bin/bash
# Create input for: gatk4_pon_gathervcfs_run_parallel.pbs

set -e

if [ -z "$1" ]
then
	echo "Please run this script with the base name of your config file, e.g. sh gatk4_hc_make_input.sh samples_batch1"
	exit
fi

cohort=$1
config=../$cohort.config
vcfdir=./$cohort\_PoN
logdir=./Logs/gatk4_pon_gathervcfs
INPUTS=./Inputs
inputfile=${INPUTS}/gatk4_pon_gathervcfs.inputs

# Collect sample IDs from config file
# Only normal sample IDs are collected (labids ending in -B or -N)
while read -r sampleid labid seq_center library; do
	if [[ ! ${sampleid} =~ ^#.*$ && ${labid} =~ -B.?$ || ${labid} =~ -N.?$ ]]; then
		samples+=("${labid}")
	fi
done < "${config}"

mkdir -p ${logdir}
mkdir -p ${INPUTS}
rm -rf ${inputfile}

echo "$(date): Writing arguments and input file for ${#samples[@]} samples for gatk4_pon_gathervcfs_run_parallel.pbs"

# Make arguments file for each sample, then add to inputs file
for sample in "${samples[@]}"; do
	echo "$(date): Writing arguments for ${sample}..."
	args=${INPUTS}/gatk4_pon_gathervcfs_${sample}\.args
	out=${vcfdir}/${sample}/${sample}.pon.g.vcf.gz

	rm -rf ${args}

	for interval in $(seq -f "%04g" 0 3199);do
		echo "--I " ${vcfdir}/${sample}/${sample}.pon.${interval}.vcf >> ${args}
	done
	echo "${sample},${args},${logdir},${out}" >> ${inputfile}
done

num_tasks=`wc -l ${inputfile}`

echo "$(date): Wrote ${num_tasks} tasks in ${inputfile}"

