#!/bin/bash

# Run GATK Mutect2 using scatter-gather method

module load gatk/4.1.2.0

ref=`echo $1 | cut -d ',' -f 1`
tmid=`echo $1 | cut -d ',' -f 2`
tmbam=`echo $1 | cut -d ',' -f 3`
nmid=`echo $1 | cut -d ',' -f 4`
nmbam=`echo $1 | cut -d ',' -f 5`
interval=`echo $1 | cut -d ',' -f 6`
pon=`echo $1 | cut -d ',' -f 7`
gnomad=`echo $1 | cut -d ',' -f 8`
out=`echo $1 | cut -d ',' -f 9`
logdir=`echo $1 | cut -d ',' -f 10`
nt=`echo $1 | cut -d ',' -f 11`

mkdir -p ${logdir}
mkdir -p ${out}

if [[ ${interval} =~ chrM ]]
then
	index=chrM
else
	filename=${interval##*/}
	index=${filename%-scattered.interval_list}
fi

gvcf=${out}/${tmid}_${nmid}.unfiltered.${index}.vcf.gz
f1r2=${out}/${tmid}_${nmid}.f1r2.${index}.tar.gz

echo "$(date) : Running GATK 4 Mutect2. Reference: ${ref}, Tumour: ${tmid}, Normal: ${nmid}, PoN: ${pon}, Interval: ${interval}, Output: ${gvcf}, Threads: ${nt}, Logs: ${logdir}, Germline resource: ${gnomad}" >> ${logdir}/${index}.oe 2>&1

# Run chrM in  mitochondial modei
# PoN not included here
if [[ ${index} =~ chrM ]]
then
	gatk --java-options "-Xmx8g -Xms8g" \
		Mutect2 \
		-R ${ref} \
		-L chrM \
		--mitochondria-mode \
		-I ${tmbam} \
		-I ${nmbam} \
		-normal ${nmid} \
		--native-pair-hmm-threads ${nt} \
		--germline-resource ${gnomad} \
		--f1r2-tar-gz ${f1r2} \
		-O ${gvcf} >>${logdir}/${index}.oe 2>&1
	echo "$(date) : Finished GATK 4 Mutect2 in mitochondrial mode for: ${gvcf}" >> ${logdir}/${index}.oe 2>&1
else
	gatk --java-options "-Xmx8g -Xms8g" \
		Mutect2 \
		-R ${ref} \
		-I ${tmbam} \
		-I ${nmbam} \
		-normal ${nmid} \
		--native-pair-hmm-threads ${nt} \
		--panel-of-normals ${pon} \
		--germline-resource ${gnomad} \
		--f1r2-tar-gz ${f1r2} \
		-XL chrM \
		-L ${interval} \
		-O ${gvcf} >>${logdir}/${index}.oe 2>&1
	echo "$(date) : Finished GATK 4 Mutect2 for: ${gvcf}" >> ${logdir}/${index}.oe 2>&1
fi
