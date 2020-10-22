#! /bin/bash

# Create input file to check log files in parallel
# For each sample, record minutes taken per interval
# Flag any intervals with error messages
# If there are no error messages, archive log files in a per sample tarball

if [ -z "$1" ]
then
	echo "Please run this script with the base name of your config file, e.g. sh gatk4_hc_checklogs_make_input.sh samples_batch1"
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
nt=1

rm -rf ${inputfile}

# Collect sample IDs from samples.config
# Only collect IDs for germline variant calling (labids ending in -B)
while read -r sampleid labid seq_center library; do
	if [[ ! ${sampleid} =~ ^#.*$ && ${labid} =~ -B$ || ${labid} =~ -N$ ]]; then
		samples+=("${labid}")
	fi
done < "${config}"


# For each sample, check which tasks have failed

for sample in "${samples[@]}"; do
	rm -rf ${INPUTS}/gatk4_pon_checklogs_${sample}.inputs
	for interval in $(seq -f "%04g" 0 3199); do
		logfile=${logs}/${sample}/${interval}.oe
		echo "${sample},${interval},${logfile},${logs}" >> ${INPUTS}/gatk4_pon_checklogs_${sample}.inputs
	done
done
