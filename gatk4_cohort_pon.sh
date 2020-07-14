#!/bin/bash

# Create cohort somatic PoN per interval
# No option to set numnber of threads

module load gatk/4.1.2.0

ref=`echo $1 | cut -d ',' -f 1`
cohort=`echo $1 | cut -d ',' -f 2`
gnomad=`echo $1 | cut -d ',' -f 3`
gendbdir=`echo $1 | cut -d ',' -f 4`
interval=`echo $1 | cut -d ',' -f 5`
outdir=`echo $1 | cut -d ',' -f 6`
logdir=`echo $1 | cut -d ',' -f 7`

mkdir -p ${outdir}
mkdir -p ${logdir}

filename=${interval##*/}
index=${filename%-scattered.interval_list}

out=${outdir}/${cohort}.${index}.pon.vcf.gz
tmp=${outdir}/tmp/${index}

mkdir -p ${outdir}
mkdir -p ${tmp}

echo "$(date): Running CreateSomaticPanelOfNormals with gatk4. Reference: ${ref}; Resource: ${gnomad}; Interval: ${filename}; Out: ${out};  Logs: ${logdir}" > ${logdir}/${index}.oe 2>&1

gatk --java-options "-Xmx28g -Xms28g" \
	CreateSomaticPanelOfNormals \
	-R ${ref} \
	--germline-resource ${gnomad} \
	-V gendb://${gendbdir}/${index} \
	--tmp-dir ${tmp} \
	-O ${out} >>${logdir}/${index}.oe 2>&1

echo "$(date): Finished CreateSomaticPanelOfNormals, saving output to: ${out}" >> ${logdir}/${index}.oe 2>&1 
