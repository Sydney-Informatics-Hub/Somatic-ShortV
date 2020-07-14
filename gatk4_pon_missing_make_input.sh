#! /bin/bash

# Create input for first step in creating a panel of normals
# First step is to run Mutect2 in tumour-only mode for each normal sample
# Check .vcf, .vcf.idx and vcf.stats files for each sample

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
	if [[ ! ${sampleid} =~ ^#.*$ && ${labid} =~ -B$ || ${labid} =~ -N$ ]]; then
		samples+=("${labid}")
	fi
done < "${config}"

rm -rf ${inputfile}

# For each sample, check intervals with no .vcf, .vcf.idx and .vcf.stats files
for sample in "${samples[@]}"; do
	# Check if .vcf .vcf.idx, .vcf.stats files exist and are not empty
	i=0
	for interval in $(seq -f "%04g" 0 3199); do
		logfile=${logs}/${sample}/${interval}.oe
		vcf=${outdir}/${sample}/${sample}.pon.${interval}.vcf
		idx=${outdir}/${sample}/${sample}.pon.${interval}.vcf.idx
		stats=${outdir}/${sample}/${sample}.pon.${interval}.vcf.stats
		bam=${bamdir}/${sample}.final.bam
		out=${outdir}/${sample}
		logdir=${logs}/${sample}
		if ! [[ -s "${vcf}" &&  -s "${idx}" && -s "${stats}" ]]
		then
			intfile=$(grep ${interval} ${scatterlist})
	                interval="${scatterdir}/${intfile}"
        	        echo "${ref},${sample},${bam},${interval},${out},${nt},${logdir}" >> ${inputfile}
		else
			((++i))
		fi
	done

	if [[ $i == 3200 ]]
	then
		echo "$(date): ${sample} has all .vcf, vcf.idx and .vcf.stats files present. Ready for merging into GVCF."
	else
		num_missing=$((3200 - $i))
		echo "$(date): ${sample} has ${num_missing} missing .vcf, vcf.idx, .vcf.stats files."
		total_missing=$(($total_missing+$num_missing))
	fi
	# Write a list of existing log files to later check for errors in parallel
	# find ${logs}/${sample} -name *.oe -type f >> ${inputlogs}
done

