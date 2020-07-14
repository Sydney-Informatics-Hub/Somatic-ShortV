#! /bin/bash

# Check the first step is to run Mutect2 in tumour-only mode for each normal sample
# Write inputs for failed tasks/missing interval VCFs per sample

cohort=`echo $1 | cut -d ',' -f 1`
sample=`echo $1 | cut -d ',' -f 2`
inputfile=`echo $1 | cut -d ',' -f 3`
ref=../Reference/hs38DH.fasta
scatterdir=../Reference/ShortV_intervals
scatterlist=$scatterdir/3200_ordered_exclusions.list
bamdir=../Final_bams
outdir=./$cohort\_PoN
logs=./Logs/gatk4_pon
PERL_SCRIPT=get_interval_times_gatklog.pl

i=0
echo "$(date): Checking ${sample}..."
for interval in $(seq -f "%04g" 0 3199); do
	logfile=${logs}/${sample}/${interval}.oe
	vcf=${outdir}/${sample}/${sample}.pon.${interval}.vcf
	idx=${outdir}/${sample}/${sample}.pon.${interval}.vcf.idx
	stats=${outdir}/${sample}/${sample}.pon.${interval}.vcf.stats
	if ! [[ -s "${vcf}" &&  -s "${idx}" && -s "${stats}" ]]
	then
		((++i))
		intfile=$(grep ${interval} ${scatterlist})
		echo "${ref},${sample},${bam},${intfile},${out},${nt},${logdir}" >> ${inputfile}
	elif [[ -s "${logfile}" ]]
	then
		success=$(grep -i success ${logfile})
		error=$(grep -i error ${logfile})
		if [[ ! ${success} && -z ${error} ]]; then
			((++i))
			intfile=$(grep ${interval} ${scatterlist})
			echo "${ref},${sample},${bam},${intfile},${out},${nt},${logdir}" >> ${inputfile}
		fi
	else
		"$(date): ${sample} has all output files but no log file for ${interval}"
	fi
done

if [[ ${i}>0 ]]; then
	echo "$(date): ${sample} has $i failed tasks. Wrote $i tasks to ${inputfile}"
else
	echo "$(date): ${sample} has $i failed tasks. Printing task duration and memory usage..."
	perl ${PERL_SCRIPT} ${logs}/${sample} > ${logs}/${sample}/${sample}_task_duration_mem.txt
	echo "$(date): Tarring ${sample} logs..."
	cd ${logs}
	tar -czf ${sample}_logs.tar.gz ${sample}
fi

