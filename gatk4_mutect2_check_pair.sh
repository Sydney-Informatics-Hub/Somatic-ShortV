#! /bin/bash

# Check the first step is to run Mutect2 in tumour-only mode for each normal sample
# Write inputs for failed tasks/missing interval VCFs per sample

cohort=`echo $1 | cut -d ',' -f 1`
tmid=`echo $1 | cut -d ',' -f 2`
nmid=`echo $1 | cut -d ',' -f 3`

ref=../Reference/hs38DH.fasta
scatterdir=../Reference/ShortV_intervals
scatterlist=$scatterdir/3200_ordered_exclusions.list
bamdir=../Final_bams
pon=./$cohort\_cohort_PoN/$cohort.sorted.pon.g.vcf.gz
gnomad=../Reference/broad-references/ftp/Mutect2/af-only-gnomad.hg38.vcf.gz
nt=1
INPUTS=./Inputs
inputfile=${INPUTS}/gatk4_mutect2_missing.inputs
nmbam=${bamdir}/${nmid}.final.bam
tmbam=${bamdir}/${tmid}.final.bam
out=./Interval_VCFs/${tmid}_${nmid}
logs=./Logs/gatk4_mutect2/${tmid}_${nmid}

i=0
echo "$(date): Checking tumour ${tmid} normal ${nmid} pair..."
for interval in $(seq -f "%04g" 0 3199); do
	logfile=${logs}/${interval}.oe
	vcf=${out}/${tmid}_${nmid}.unfiltered.${interval}.vcf.gz
	tbi=${out}/${tmid}_${nmid}.unfiltered.${interval}.vcf.gz.tbi
	stats=${out}/${tmid}_${nmid}.unfiltered.${interval}.vcf.gz.stats
	f1r2=${out}/${tmid}_${nmid}.f1r2.${interval}.tar.gz
	if ! [[ -s "${vcf}" &&  -s "${tbi}" && -s "${stats}" && -s "${f1r2}" && -s "${logfile}" ]]
	then
		((++i))
		intfile=$(grep ${interval} ${scatterlist})
		echo "${ref},${tmid},${tmbam},${nmid},${nmbam},${interval},${pon},${gnomad},${out},${logs},${nt}" >> ${inputfile}
	else
		success=$(grep -i success ${logfile})
		error=$(grep -i error ${logfile})
		if [[ ! ${success} && -z ${error} ]]; then
			((++i))
			intfile=$(grep ${interval} ${scatterlist})
			echo "${ref},${tmid},${tmbam},${nmid},${nmbam},${interval},${pon},${gnomad},${out},${logs},${nt}" >> ${inputfile}
		fi
	fi
done

# Check chrM 
chrM_logfile=${logs}/chrM.oe
chrM_vcf=${out}/${tmid}_${nmid}.unfiltered.chrM.vcf.gz
chrM_tbi=${out}/${tmid}_${nmid}.unfiltered.chrM.vcf.gz.tbi
chrM_stats=${out}/${tmid}_${nmid}.unfiltered.chrM.vcf.gz.stats
chrM_f1r2=${out}/${tmid}_${nmid}.f1r2.chrM.tar.gz

if ! [[ -s "${chrM_vcf}" &&  -s "${chrM_tbi}" && -s "${chrM_stats}" && -s "${chrM_f1r2}" && -s "${chrM_logfile}" ]]
then
	((++i))
	echo "${ref},${tmid},${tmbam},${nmid},${nmbam},chrM,${pon},${gnomad},${out},${logs},${nt}" >> ${inputfile}
else
	success=$(grep -i success ${chrM_logfile})
	error=$(grep -i error ${chrM_logfile})
	if [[ ! ${success} && -z ${error} ]]; then
		((++i))
		echo "${ref},${tmid},${tmbam},${nmid},${nmbam},chrM,${pon},${gnomad},${out},${logs},${nt}" >> ${inputfile}
	fi
fi

echo "$(date): Tumour ${tmid} normal ${nmid} pair has $i failed tasks. Wrote $i tasks to ${inputfile}"

