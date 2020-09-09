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
		nonuniq_samples+=("${labid}")
		samples=($(printf "%s\n" "${nonuniq_samples[@]}" | sort -u | tr '\n' ' '))
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
		nmid=`printf -- '%s\n' "${all_bams[@]}" | sed 's|.final.bam||g' | grep -P 'N.?$|B.?$'`
		tmid=`printf -- '%s\n' "${all_bams[@]}" | sed 's|.final.bam||g' | grep -vP 'N.?$|B.?$'`
		#echo $nmid $tmid
		inputs+=("${cohort},${tmid},${nmid}")
		tmp+=("${INPUTS}/gatk4_mutect2_${tmid}_${nmid}.inputs")
	elif  (( ${#all_bams[@]} > 2 )); then
		echo ${patient} has ${#all_bams[@]} bams: "${all_bams[@]}"
		pairs=$(( ${#all_bams[@]}-1 ))
		tasks=$(( ${tasks}+${pairs} ))
		nmid=`printf -- '%s\n' "${all_bams[@]}" | sed 's|.final.bam||g' | grep -P 'N.?$|B.?$'`
		for bam in "${all_bams[@]}"; do
			if ! [[ ${bam} =~ -N.?.final.bam$ || ${sample} =~ -B.?.final.bam$ ]]; then
				tmid=`printf -- '%s\n' ${bam} | sed 's|.final.bam||g'`
				#echo $nmid $tmid
				inputs+=("${cohort},${tmid},${nmid}")
				tmp+=("${INPUTS}/gatk4_mutect2_${tmid}_${nmid}.inputs")
			fi
		done

	fi
done
echo "$(date): There are $tasks tumour normal pairs. Writing 3,201 input lines to $inputfile"

echo "${inputs[@]}" | xargs --max-args 1 --max-procs 20 ${SCRIPT}

echo "$(date): Wrote inputs for ${#inputs[@]} tumour-normal pairs. Interleaving input files to retain interval order"

paste -d'\n' "${tmp[@]}" > ${inputfile}

echo "$(date): Removing temporary files"

for tmp in "${tmp[@]}"; do
	rm -rf ${tmp}
done

echo "$(date): Done!"
