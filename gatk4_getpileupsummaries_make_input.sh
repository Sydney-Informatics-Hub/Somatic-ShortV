#! /bin/bash
# Create input for: gatk4_getpileupsummaries_run_parallel.pbs
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
inputfile=${INPUTS}/gatk4_getpileupsummaries.inputs

mkdir -p ${outdir}
mkdir -p ${logdir}
mkdir -p ${INPUTS}
rm -rf ${inputfile}

# Collect all sample IDs from config file
samples=0
while read -r sampleid labid seq_center library; do
	if [[ ! ${sampleid} =~ ^#.*$ ]]; then
		samples=$(( ${samples}+1 ))
		bam=${bamdir}/${labid}.final.bam
		out=${outdir}/${labid}_pileups.table
		echo "${labid},${bam},${common_biallelic},${out},${logdir}" >> ${inputfile}
	fi
done < "${config}"

echo "$(date): Wrote input files for ${samples} bams for gatk4_getpileupsummaries_run_parallel.pbs"
