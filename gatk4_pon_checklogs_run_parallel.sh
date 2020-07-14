#!/bin/bash

# Update these variables
if [ -z "$1" ]
then
	echo "Please run this script with the base name of your config file, e.g. sh gatk4_hc_checklogs_run_parallel.sh samples_batch1"
	exit
fi

cohort=$1
config=../$cohort.config
INPUTS=./Inputs
SCRIPT=./gatk4_pon_checklogs.sh
PERL_SCRIPT=./get_interval_times_gatklog.pl
logs=./Logs/gatk4_pon

while read -r sampleid labid seq_center library; do
	if [[ ! ${sampleid} =~ ^#.*$ && ${labid} =~ -B$ || ${labid} =~ -N$ ]]; then
		samples+=("${labid}")
	fi
done < "${config}"

num_samples="${#samples[@]}"

echo "$(date): There are $num_samples of normal samples in $cohort. Running $num_samples jobs to check errors. Tarring log directories once complete"

for sample in "${samples[@]}"; do
	qsub \
	-v sample="${sample}",logs="${logs}",input="${INPUTS}/gatk4_pon_checklogs_${sample}.inputs",perl="${PERL_SCRIPT}" \
	-N ${sample}_checklogs \
	-P oj47 \
	-l wd,ncpus=48,mem=192GB,walltime=00:10:00 \
	-W umask=022 \
	-l storage=scratch/hm82 \
	-q normal \
	-e ${logs}/${sample}_checklogs.e \
	-o ${logs}/${sample}_checklogs.o \
	${SCRIPT}
done
