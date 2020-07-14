#! /bin/bash

# Checks gatk4_pon_run_parallel.pbs
# gatk4_pon_run_parallel.pbs runs Mutect2 in tumour-only mode for each normal sample
# Write inputs for failed tasks/missing interval VCFs per sample
# Run by: nohup sh gatk4_pon_check_sample_parallel.sh samples 2> /dev/null &

module load openmpi/4.0.2

if [ -z "$1" ]
then
	echo "Please run this script with the base name of your config file, e.g. sh gatk4_hc_make_input.sh samples_batch1"
	exit
fi

cohort=$1
config=../$cohort.config
SCRIPT=./gatk4_pon_check_sample.sh
INPUTS=./Inputs
inputfile=${INPUTS}/gatk4_pon_missing.inputs

rm -rf ${inputfile}

# Collect sample IDs from samples.config
# Only collect IDs from normal samples (labids ending in -B)
while read -r sampleid labid seq_center library; do
	if [[ ! ${sampleid} =~ ^#.*$ && ${labid} =~ -B.?$ || ${labid} =~ -N.?$ ]]; then
		samples+=("${cohort},${labid},${inputfile}")
	fi
done < "${config}"

#echo "${samples[@]}"
#echo "${samples[@]}" | xargs --max-args 1 --max-procs 2 ${SCRIPT}
echo "$(date): Checking vcf, vcf.idx and vcf.stats files for ${#samples[@]} samples"
echo "${samples[@]}" | xargs --max-args 1 --max-procs 48 ${SCRIPT}

if [[ -s ${inputfile} ]]; then
	num_inputs=`wc -l ${inputfile}`
	echo "$(date): There are ${num_inputs} tasks to run for gatk4_pon_missing_run_parallel.pbs"
else
	echo "$(date): There are 0 tasks to run for gatk4_pon_missing_run_parallel.pbs"
fi
