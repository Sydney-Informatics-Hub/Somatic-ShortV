#! /bin/bash

# Check gatk4_mutect2 tumour-normal pair calling
# Write inputs for failed tasks/missing interval VCFs per sample

if [ -z "$1" ]
then
	echo "Please run this script with the base name of your config file, e.g. sh gatk4_hc_make_input.sh samples_batch1"
	exit
fi

cohort=$1
config=../$cohort.config
SCRIPT=./gatk4_mutect2_check_pair.sh
INPUTS=./Inputs
inputfile=${INPUTS}/gatk4_mutect2_missing.inputs

rm -rf ${inputfile}

# Collect sample IDs from samples.config
# Only collect IDs from normal samples (labids ending in -B)
while read -r sampleid labid seq_center library; do
	if [[ ! ${sampleid} =~ ^#.*$ && ${labid} =~ -B.?$ || ${labid} =~ -N.?$ ]]; then
		samples+=("${labid}")
	fi
done < "${config}"

# Collect all tumour IDs for each normal sample
for nmid in "${samples[@]}"; do
	# Find any matching tumour bams using normal id without -N or -B
	patient=$(echo "${nmid}" | perl -pe 's/(-B.?|-N.?)$//g')
	patient_samples=( $(awk -v pattern="${patient}-" '$2 ~ pattern{print $2}' ${config}) )
	if (( ${#patient_samples[@]} == 2 )); then
		nmid=`printf '%s\n' ${patient_samples[@]} | grep -P 'N.?$|B.?$'`
		tmid=`printf '%s\n' ${patient_samples[@]} | grep -vP 'N.?$|B.?$'`
		inputs+=("${cohort},${tmid},${nmid}")
	elif (( ${#patient_samples[@]} > 2 )); then
		nmid=`printf '%s\n' ${patient_samples[@]} | grep -P 'N.?$|B.?$'`
		for sample in "${patient_samples[@]}"; do
			if ! [[ ${sample} =~ -N.?$ || ${sample} =~ -B.?$ ]]; then
				tmid=${sample}
				inputs+=("${cohort},${tmid},${nmid}")
			fi
		done
	fi
done

#echo "${samples[@]}"
#echo "${samples[@]}" | xargs --max-args 1 --max-procs 2 ${SCRIPT}
echo "$(date): Checking .vcf.gz, .vcf.gz.tbi, vcf.gz.stats, f1r2 files for ${#inputs[@]} tumour normal pairs"

echo "${inputs[@]}" | xargs --max-args 1 --max-procs 20 ${SCRIPT}

if [[ -s ${inputfile} ]]; then
	num_inputs=`wc -l ${inputfile}`
	echo "$(date): There are ${num_inputs} tasks to run for gatk4_mutect2_missing_run_parallel.pbs"
else
	echo "$(date): There are 0 tasks to run for gatk4_mutect2_missing_run_parallel.pbs"
fi
