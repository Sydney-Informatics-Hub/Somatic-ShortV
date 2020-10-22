#! /bin/bash
# Create input for: gatk4_getpileupsummaries_missing_run_parallel.pbs
# One task (one line of input) gets pileup for one sample

set -e

if [ -z "$1" ]
then
	echo "Please run this script with the base name of your config file, e.g. sh gatk4_hc_make_input.sh samples_batch1"
	exit
fi

cohort=$1
config=../$cohort.config
bamdir=../Final_bams
#common_biallelic=../Reference/gatk-best-practices/somatic-hg38/small_exac_common_3.hg38.vcf.gz
common_biallelic=../Reference/gatk-best-practices/somatic-hg38/af-only-gnomad.common_biallelic.hg38.vcf.gz
outdir=./${cohort}_GetPileupSummaries
logdir=./Logs/gatk4_getpileupsummaries
INPUTS=./Inputs
inputfile=${INPUTS}/gatk4_getpileupsummaries_missing.inputs

mkdir -p ${outdir}
mkdir -p ${logdir}
mkdir -p ${INPUTS}
rm -rf ${inputfile}

# Find samples that run successfully/with errors
success=(`grep SUCCESS ${logdir}/*oe | awk -F/ '{print $NF}' | cut -d '.' -f 1`)
error=(`grep -i error ${logdir}/*oe | awk -F/ '{print $NF}' | cut -d '.' -f 1`)

#echo "${success[@]}"
#echo "${error[@]}"

# Collect all sample IDs from config file
samples=0
missing=0
successful=0
while read -r sampleid labid seq_center library; do
	if [[ ! ${sampleid} =~ ^#.*$ ]]; then
		samples=$(( ${samples}+1 ))
		bam=${bamdir}/${labid}.final.bam
		out=${outdir}/${labid}_pileups.table
		
		if [[ " ${success[@]} " =~ " ${labid} " && -s ${out} ]]; then
			echo "$(date): SUCCESS in ${labid}.oe and ${out} is non-empty"
			successful=$(( ${successful}+1 ))
		else
			if [[ " ${error[@]} " =~ " ${labid} " ]]; then
				echo "$(date): ERROR in ${labid}.oe, you might want to investigate"
			fi
			missing=$(( ${missing}+1 ))
			echo "Writing input files for ${labid}"
			echo "${labid},${bam},${common_biallelic},${out},${logdir}" >> ${inputfile}
	
		fi
	fi
done < "${config}"

echo "$(date): GetPileupSummaries. ${config} has ${samples} samples. Successful samples: ${successful}. Wrote ${missing} tasks for gatk4_getpileupsummaries_missing_run_parallel.pbs"
