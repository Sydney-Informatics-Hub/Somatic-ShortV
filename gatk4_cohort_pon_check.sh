#! /bin/bash

# Create input file to check log files in parallel
# For each sample, record minutes taken per interval
# Flag any intervals with error messages
# If there are no error messages, archive log files in a per sample tarball

if [ -z "$1" ]
then
	echo "Please run this script with the base name of your config file, e.g. sh gatk4_genomicsdbimport_missing_make_input.sh samples_batch1"
	exit
fi

cohort=$1
config=../$cohort.config
INPUTS=./Inputs
inputfile=${INPUTS}/gatk4_cohort_pon_missing.inputs
ref=../Reference/hs38DH.fasta
gnomad=../Reference/broad-references/ftp/Mutect2/af-only-gnomad.hg38.vcf.gz
scatterdir=../Reference/ShortV_intervals
scatterlist=$scatterdir/3200_ordered_exclusions.list
gendbdir=./$cohort\_PoN_GenomicsDBImport
outdir=./$cohort\_cohort_PoN
logdir=./Logs/gatk4_cohort_pon
perlfile=${logdir}/interval_duration_memory.txt

# Increase CPU as necessary

mkdir -p ${INPUTS}
mkdir -p ${logdir}

rm -rf ${inputfile}
rm -rf ${perlfile}

# Run perl script to get duration
echo "$(date): Checking log files for errors, obtaining duration and memory usage per task..."
perl gatk4_check_logs.pl "$logdir"

# Check output file 
while read -r interval duration memory; do
	if [[ $duration =~ NA || $memory =~ NA ]]
	then
		redo+=("$interval")
	fi
done < "$perlfile"

if [[ ${#redo[@]}>1 ]]
then
	echo "$(date): There are ${#redo[@]} intervals that need to be re-run."
	echo "$(date): Writing inputs to ${inputfile}"

	for redo_interval in ${redo[@]}; do
        	interval="${scatterdir}/${redo_interval}-scattered.interval_list"
		echo "${ref},${cohort},${gnomad},${gendbdir},${interval},${outdir},${logdir}" >> ${inputfile}
	done
else
	echo "$(date): There are no intervals that need to be re-run. Tidying up..."
	cd ${logdir}
	tar --remove-files \
		-kczf cohort_pon_logs.tar.gz \
		*.oe
fi
