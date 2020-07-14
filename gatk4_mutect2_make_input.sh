#! /bin/bash

# Create input file for gatk4_mutect2_run_parallel.pbs
# One input line will be created per interval, there are 3,201 intervals for this sample
# Extra 1 is for chrM which is run in mitochondiral mode

set -e

if [ -z "$1" ]
then
	echo "Please run this script with the base name of your config file, e.g. sh gatk4_hc_make_input.sh samples_batch1"
	exit
fi

# INPUTS
cohort=$1
config=../$cohort.config
outdir=./Interval_VCFs
logdir=./Logs/gatk4_mutect2
bamdir=../Final_bams
INPUTS=./Inputs
inputfile=${INPUTS}/gatk4_mutect2.inputs
SCRIPT=./gatk4_mutect2_pair_make_input.sh

mkdir -p ${logdir}
mkdir -p ${outdir}
mkdir -p ${INPUTS}

rm -rf ${inputfile}

echo "$(date): Writing inputs for gatk4_mutect2_run_parallel.pbs"

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
	all_bams=(`find ${bamdir} -name ${patient}-*.final.bam -execdir echo {} ';' | sed 's|^./||'`)
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
# Not all normals have a matching tumour sample - skip these samplesi
# Each line of input is for one sample and 3,201 intervals. One of the intervals=chrM. 
for nmid in "${samples[@]}"; do
	# Find any matching tumour bams using normal id without -N or -B
	patient=$(echo "${nmid}" | perl -pe 's/(-B.?|-N.?)$//g')
	patient_samples=( $(awk -v pattern="${patient}-" '$2 ~ pattern{print $2}' ${config}) )
	if (( ${#patient_samples[@]} == 2 )); then
		nmid=`printf '%s\n' ${patient_samples[@]} | grep -P 'N.?$|B.?$'`
		tmid=`printf '%s\n' ${patient_samples[@]} | grep -vP 'N.?$|B.?$'`
		tmp+=("${INPUTS}/gatk4_mutect2_${tmid}_${nmid}.inputs")
		inputs+=("${cohort},${tmid},${nmid}")
	elif (( ${#patient_samples[@]} > 2 )); then
		nmid=`printf '%s\n' ${patient_samples[@]} | grep -P 'N.?$|B.?$'`
		for sample in "${patient_samples[@]}"; do
			if ! [[ ${sample} =~ -N.?$ || ${sample} =~ -B.?$ ]]; then
				tmid=${sample}
				inputs+=("${cohort},${tmid},${nmid}")
				tmp+=("${INPUTS}/gatk4_mutect2_${tmid}_${nmid}.inputs")
			fi
		done	
	fi
done

echo "${inputs[@]}" | xargs --max-args 1 --max-procs 20 ${SCRIPT}

echo "$(date): Wrote inputs for ${#inputs[@]} tumour-normal pairs. Interleaving input files to retain interval order"

paste -d'\n' "${tmp[@]}" > ${inputfile}

echo "$(date): Removing temporary files"

for tmp in "${tmp[@]}"; do
	rm -rf ${tmp}
done

echo "$(date): Done!"
