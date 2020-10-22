#! /bin/bash
# Create input for: gatk4_calculatecontomination_run_parallel.pbs
# One task (one line of input) gets pileup for one tumour bam

set -e

if [ -z "$1" ]
then
	echo "Please run this script with the base name of your config file, e.g. sh gatk4_hc_make_input.sh samples_batch1"
	exit
fi

cohort=$1
config=../$cohort.config
outdir=./${cohort}_GetPileupSummaries
logdir=./Logs/gatk4_calculatecontamination
INPUTS=./Inputs
inputfile=${INPUTS}/gatk4_calculatecontamination.inputs

mkdir -p ${outdir}
mkdir -p ${logdir}
mkdir -p ${INPUTS}
rm -rf ${inputfile}

# Collect sample IDs from config file
# Only tumour ids (labids NOT ending in -B or -N)
samples=0
pairs_found=0
while read -r sampleid labid seq_center library; do
	if [[ ! ${sampleid} =~ ^#.*$ && ${labid} =~ -B.?$ || ${labid} =~ -N.?$ ]]; then
		samples=$(( ${samples}+1 ))
		patient=$(echo "${labid}" | perl -pe 's/(-B.?|-N.?)$//g')
		patient_samples=( $(awk -v pattern="${patient}-" '$2 ~ pattern{print $2}' ${config}) )
		if ((${#patient_samples[@]} == 2 )); then
			pairs_found=$(( ${pairs_found}+1 ))
			nmid=`printf '%s\n' ${patient_samples[@]} | grep -P 'N.?$|B.?$'`
			tmid=`printf '%s\n' ${patient_samples[@]} | grep -vP 'N.?$|B.?$'`
			pair=${tmid}_${nmid}

			echo "$(date): Writing input files for ${pair}"

			nmpileup=${outdir}/${nmid}_pileups.table
			tmpileup=${outdir}/${tmid}_pileups.table
			segments=${outdir}/${tmid}_segments.table
			out=${outdir}/${pair}_contamination.table
			echo "${pair},${nmpileup},${tmpileup},${segments},${out},${logdir}" >> ${inputfile}
		elif (( ${#patient_samples[@]} > 2 )); then
			nmid=`printf '%s\n' ${patient_samples[@]} | grep -P 'N.?$|B.?$'`
			for sample in "${patient_samples[@]}"; do
				if ! [[ ${sample} =~ -N.?$ || ${sample} =~ -B.?$ ]]; then
					tmid=${sample}
					pair=${tmid}_${nmid}
					pairs_found=$(( ${pairs_found}+1 ))

					echo "$(date): Writing input files for ${pair}"

					nmpileup=${outdir}/${nmid}_pileups.table
					tmpileup=${outdir}/${tmid}_pileups.table
					segments=${outdir}/${tmid}_segments.table
					out=${outdir}/${pair}_contamination.table

					echo "${pair},${nmpileup},${tmpileup},${segments},${out},${logdir}" >> ${inputfile}
				fi
			done
		fi
	fi
done < "${config}"

echo "$(date): Wrote input files for ${pairs_found} TN pairs from ${cohort}.config (normal samples = ${samples})  for gatk4_calculatecontamination_run_parallel.pbs"
