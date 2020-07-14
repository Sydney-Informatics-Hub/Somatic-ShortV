#! /bin/bash

# Checks gatk4_pon_gathervcfs_run_parallel.pbs
# Create input file to check log files and output files
# For each sample, record minutes taken per interval
# Flag any intervals with error messages or missing/empty files

if [ -z "$1" ]
then
	echo "Please run this script with the base name of your config file, e.g. sh gatk4_hc_checklogs_make_input.sh samples_batch1"
	exit
fi

cohort=$1
config=../$cohort.config
outdir=./${cohort}_PoN
logs=./Logs/gatk4_pon_gathervcfs
INPUTS=./Inputs
inputfile=${INPUTS}/gatk4_pon_gathervcfs_missing.inputs
out=${logs}/${cohort}_task_duration.txt

rm -rf $out
rm -rf $inputfile

printf "#Sample\tMins\n" > $out


while read -r sampleid labid seq_center library
do
	if [[ ! ${sampleid} =~ ^#.*$ && ${labid} =~ -B.?$ || ${labid} =~ -N.?$ ]]
	then
		samples+=("${labid}")
	fi
done < "${config}"

echo "$(date): Checking VCF and index files for ${#samples[@]} samples"

#For each sample, check logs for duration and VCF dir for gathered GVCF
i=0
for sample in "${samples[@]}"
do
	logfile=${logs}/${sample}.oe
	err=$(grep ERROR $logfile | wc -l)
	if [ $err -gt 0 ]
	then
		echo $sample has $err errors in $logfile
		mins='NA'
	else	
		mins=$(grep "GatherVcfs done. Elapsed time" $logfile | rev | cut -d ' ' -f 2 | rev)
	fi
	printf "${sample}\t${mins}\n" >> $out	
	vcf=${outdir}/${sample}/${sample}.pon.g.vcf.gz
	idx=${outdir}/${sample}/${sample}.pon.g.vcf.gz.tbi
	if ! [[ -s $vcf && -s $idx ]]
	then
		echo $sample has missing or empty VCF or index file. Writing to task to $inputfile
		grep $sample ${INPUTS}/gatk4_pon_gathervcfs.inputs >> $inputfile
	else
		((++i))
		echo $sample has non-empty VCF and index files
	fi
done

echo "$(date): $i samples had non-empty VCF and index files"

