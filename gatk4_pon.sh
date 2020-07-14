#!/bin/bash

# Run GATK Mutect2 (create PON) using scatter-gather method
# Runs Mutect2 in tumour only mode on normal samples

module load gatk/4.1.2.0

ref=`echo $1 | cut -d ',' -f 1`
sample=`echo $1 | cut -d ',' -f 2`
bam=`echo $1 | cut -d ',' -f 3`
interval=`echo $1 | cut -d ',' -f 4`
out=`echo $1 | cut -d ',' -f 5`
nt=`echo $1 | cut -d ',' -f 6`
logdir=`echo $1 | cut -d ',' -f 7`

mkdir -p ${out}
mkdir -p ${logdir}

filename=${interval##*/}
index=${filename%-scattered.interval_list}

vcf=${out}/${sample}.pon.${index}.vcf

echo "$(date): Creating panel of normals using GATK4 Mutect2. Reference: ${ref}; Sample: ${sample}; Bam: ${bam}; Interval: ${filename}; VCF: ${vcf}; Threads: ${nt}; Logs: ${logdir}" > ${logdir}/${index}.oe 2>&1 

gatk --java-options "-Xmx8g -Xms8g" \
	Mutect2 \
	-R ${ref} \
	-I ${bam} \
	-L ${interval} \
	--max-mnp-distance 0 \
	-O ${vcf} \
	--native-pair-hmm-threads ${nt} >>${logdir}/${index}.oe 2>&1 

echo "$(date): Finished creating panel of normals, saving output to: ${vcf}" >> ${logdir}/${index}.oe 2>&1 
