#! /bin/bash

# Check the first step is to run Mutect2 in tumour-only mode for each normal sample
# Write inputs for failed tasks/missing interval VCFs per sample

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
inputfile=${INPUTS}/gatk4_pon_missing.inputs
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

# For each sample, check intervals with no .vcf, .vcf.idx and .vcf.stats files
# Check interval.oe files have SUCCESS and no errors

echo "$(date): Checking vcf, vcf.idx and vcf.stats files for ${#samples[@]} samples"

rm -rf ${inputfile}

for sample in "${samples[@]}"; do
	i=0
	logdir=${logs}/${sample}
	echo "$(date): Checking ${sample}..."
	for interval in $(seq -f "%04g" 0 3199); do
		vcf=${outdir}/${sample}/${sample}.pon.${interval}.vcf
		idx=${outdir}/${sample}/${sample}.pon.${interval}.vcf.idx
		stats=${outdir}/${sample}/${sample}.pon.${interval}.vcf.stats
		if ! [[ -s "${vcf}" &&  -s "${idx}" && -s "${stats}" ]]
		then
			((++i))
			echo "$(date): Grepping interval"
			intfile=$(fgrep ${interval} ${scatterlist})
			echo "${ref},${sample},${bam},${intfile},${out},${nt},${logdir}" >> ${inputfile}
		fi
	done
	
	echo "$(date): Grepping logs"
	success=$(fgrep SUCCESS ${logdir}/*oe)
	#error=$(grep -il error ${logdir}/*oe)
	if [[ ! ${success} && ${error} ]]; then
		((++i))
		echo "$(date): Problem found with ${sample} log files. Please investigate"
	fi
done

num_inputs=`wc -l ${inputfile}`

echo "$(date): There are ${num_inputs} tasks to run for gatk4_pon_run_parallel.pbs"
