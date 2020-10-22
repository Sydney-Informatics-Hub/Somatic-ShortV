#! /bin/bash
# Create input for: gatk4_filtermutectcalls_run_parallel.pbs
# One task (one line of input) is one TN pair

set -e

if [ -z "$1" ]
then
	echo "Please run this script with the base name of your config file, e.g. sh gatk4_hc_make_input.sh samples_batch1"
	exit
fi

cohort=$1
config=../$cohort.config
ref=../Reference/hs38DH.fasta
vcfdir=./Interval_VCFs
logdir=./Logs/gatk4_filtermutectcalls
outdir=../Final_Somatic-ShortV_VCFs
INPUTS=./Inputs
inputfile=${INPUTS}/gatk4_filtermutectcalls.inputs

mkdir -p ${outdir}
mkdir -p ${logdir}
mkdir -p ${INPUTS}
rm -rf ${inputfile}

# Collect sample IDs from config file
# Only normal ids (labids ending in -B or -N)
pairs_found=0
patients=0
while read -r sampleid labid seq_center library; do
	if [[ ! ${sampleid} =~ ^#.*$ && ${labid} =~ -B.?$ || ${labid} =~ -N.?$ ]]; then
		#samples+=("${labid}")
		patient=$(echo "${labid}" | perl -pe 's/(-B.?|-N.?)$//g')
		patient_samples=( $(awk -v pattern="${patient}-" '$2 ~ pattern{print $2}' ${config}) )
		#echo ${patient_sampples[@]}
		if ((${#patient_samples[@]} == 2 )); then
			pairs_found=$(( ${pairs_found}+1 ))
			patients=$(( ${patients}+1 ))
			nmid=`printf '%s\n' ${patient_samples[@]} | grep -P 'N.?$|B.?$'`
			tmid=`printf '%s\n' ${patient_samples[@]} | grep -vP 'N.?$|B.?$'`
			pair=${tmid}_${nmid}
			
			echo "$(date): Writing input files for ${pair}"
			
			unfiltered=${vcfdir}/${pair}/${pair}.unfiltered.vcf.gz
			stats=${vcfdir}/${pair}/${pair}.unfiltered.vcf.gz.stats
			segments=./${cohort}_GetPileupSummaries/${tmid}_segments.table
			contamination=./${cohort}_GetPileupSummaries/${pair}_contamination.table
			ob_priors=${vcfdir}/${pair}/${pair}_read-orientation-model.tar.gz
			filtered=${outdir}/${pair}.filtered.vcf.gz

			echo "${pair},${unfiltered},${ref},${stats},${segments},${contamination},${ob_priors},${filtered},${logdir}" >> ${inputfile}

		elif (( ${#patient_samples[@]} > 2 )); then
			nmid=`printf '%s\n' ${patient_samples[@]} | grep -P 'N.?$|B.?$'`
			patients=$(( ${patients}+1 ))
			for sample in "${patient_samples[@]}"; do
				if ! [[ ${sample} =~ -N.?$ || ${sample} =~ -B.?$ ]]; then
					tmid=${sample}
					pair=${tmid}_${nmid}
					pairs_found=$(( ${pairs_found}+1 ))

					echo "$(date): Writing input files for ${pair}"
		                        unfiltered=${vcfdir}/${pair}/${pair}.unfiltered.vcf.gz
                		        stats=${vcfdir}/${pair}/${pair}.unfiltered.vcf.gz.stats
		                        segments=./${cohort}_GetPileupSummaries/${tmid}_segments.table
                		        contamination=./${cohort}_GetPileupSummaries/${pair}_contamination.table
		                        ob_priors=${vcfdir}/${pair}/${pair}_read-orientation-model.tar.gz
                		        filtered=${outdir}/${pair}.filtered.vcf.gz

		                        echo "${pair},${unfiltered},${ref},${stats},${segments},${contamination},${ob_priors},${filtered},${logdir}" >> ${inputfile}
				fi
			done
		fi
	fi
done < "${config}"

echo "$(date): Wrote input files for ${pairs_found} tumour normal pairs (patient samples = ${patients}) for gatk4_filtermutectcalls_run_parallel.pbs"
