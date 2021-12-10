#!/bin/bash

#########################################################
#
# Platform: NCI Gadi HPC
# Usage:
# Version: 1.0
#
# For more details see: https://github.com/Sydney-Informatics-Hub/Somatic-ShortV
#
# If you use this script towards a publication, support us by citing:
#
# Suggest citation:
# Sydney Informatics Hub, Core Research Facilities, University of Sydney,
# 2021, The Sydney Informatics Hub Bioinformatics Repository, <date accessed>,
# https://github.com/Sydney-Informatics-Hub/Germline-ShortV
#
# Please acknowledge the Sydney Informatics Hub and the facilities:
#
# Suggested acknowledgement:
# The authors acknowledge the technical assistance provided by the Sydney
# Informatics Hub, a Core Research Facility of the University of Sydney
# and the Australian BioCommons which is enabled by NCRIS via Bioplatforms
# Australia. The authors acknowledge the use of the National Computational
# Infrastructure (NCI) supported by the Australian Government.
#
#########################################################

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

# Run chrM in  mitochondial mode
# PoN not included here
if [[ ${index} =~ chrM ]]
then
        gatk --java-options "-Xmx3g -XX:ParallelGCThreads=$NCPUS -Djava.io.tmpdir=${PBS_JOBFS}" \
                Mutect2 \
                -R ${ref} \
                -L chrM \
                --mitochondria-mode \
                -I ${tmbam} \
                -I ${nmbam} \
                -normal ${nmid} \
		--panel-of-normals ${pon} \
                --native-pair-hmm-threads ${NCPUS} \
                --germline-resource ${gnomad} \
                --f1r2-tar-gz ${f1r2} \
                -O ${gvcf} >>${logdir}/${index}.log 2>&1
else
        gatk --java-options "-Xmx3g -XX:ParallelGCThreads=$NCPUS -Djava.io.tmpdir=${PBS_JOBFS}" \
                Mutect2 \
                -R ${ref} \
                -I ${tmbam} \
                -I ${nmbam} \
                -normal ${nmid} \
                --native-pair-hmm-threads ${NCPUS} \
                --panel-of-normals ${pon} \
                --germline-resource ${gnomad} \
                --f1r2-tar-gz ${f1r2} \
                -XL chrM \
                -L ${interval} \
                -O ${gvcf} >>${logdir}/${index}.log 2>&1
fi
