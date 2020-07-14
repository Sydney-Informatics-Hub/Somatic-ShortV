#!/bin/bash

# Run GATK Mutect2 using scatter-gather method

module load gatk/4.1.2.0

ref=`echo $1 | cut -d ',' -f 1`
tmid=`echo $1 | cut -d ',' -f 2`
tmbam=`echo $1 | cut -d ',' -f 3`
nmid=`echo $1 | cut -d ',' -f 4`
nmbam=`echo $1 | cut -d ',' -f 5`
out=`echo $1 | cut -d ',' -f 6`
nt=`echo $1 | cut -d ',' -f 7`
logdir=`echo $1 | cut -d ',' -f 8`
gnomad=`echo $1 | cut -d ',' -f 9`

mkdir -p ${logdir}
mkdir -p ${out}

gvcf=${out}/${tmid}_${nmid}.unfiltered.chrM.vcf.gz
f1r2=${out}/${tmid}_${nmid}.f1r2.chrM.tar.gz

echo "$(date) : Running GATK 4 Mutect2 in mitochondrial mode. Reference: ${ref}, Tumour: ${tmid}, Normal: ${nmid}, Interval: chrM, Output: ${gvcf}, Threads: ${nt}, Logs: ${logdir}, Germline resource: ${gnomad}" >> ${logdir}/${index}.oe 2>&1

# Exclude mitochondial calling
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
	-XL chrM \
	-L ${interval} \
	-O ${gvcf} >>${logdir}/${index}.oe 2>&1

echo "$(date) : Finished GATK 4 Mutect2 for: ${gvcf}" >> ${logdir}/${index}.oe 2>&1
