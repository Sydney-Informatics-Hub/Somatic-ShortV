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
cohort=`echo $1 | cut -d ',' -f 2`
interval=`echo $1 | cut -d ',' -f 3`
sample_map=`echo $1 | cut -d ',' -f 4`
outdir=`echo $1 | cut -d ',' -f 5`
logdir=`echo $1 | cut -d ',' -f 6`
nt=`echo $1 | cut -d ',' -f 7`

filename=${interval##*/}
index=${filename%-scattered.interval_list}

# out must be an empty of non-existant directory
# --overwrite-existing-genomicsdb-workspace doesn't work so has to be done this way
out=${outdir}/${index}
tmp=${outdir}/tmp/${index}

rm -rf ${out}
rm -rf ${tmp}

mkdir -p ${outdir}
mkdir -p ${tmp}
mkdir -p ${logdir}

echo "$(date) : Start GATK 4 GenomicsDBImport. Reference: ${ref}; Cohort: ${cohort}; Interval: ${interval}; Sample map: ${sample_map}; Out: ${out}; Logs: ${logdir}; Threads: ${nt}" >${logdir}/${index}.oe 2>&1

gatk --java-options "-Xmx64g" \
        GenomicsDBImport \
        --sample-name-map ${sample_map} \
        --overwrite-existing-genomicsdb-workspace \
        --genomicsdb-workspace-path ${out} \
        --tmp-dir ${tmp} \
        --reader-threads ${nt} \
        --intervals ${interval} >>${logdir}/${index}.oe 2>&1

echo "$(date): Finished GATK 4 consolidate VCFs with GenomicsDBImport for: ${out}" >>${logdir}/${index}.oe 2>&1
