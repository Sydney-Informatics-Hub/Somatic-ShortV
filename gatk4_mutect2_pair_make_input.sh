#! /bin/bash

#########################################################
#
# Platform: NCI Gadi HPC
# Description: Creates inputs for gatk4_mutect2_run_parallel.pbs
# This runs Mutect2 for tumour-normal pairs for N genomic intervals
# Author: Tracy Chew
# tracy.chew@sydney.edu.au
# Date last modified: 24/02/2021
#
# If you use this script towards a publication, please acknowledge the
# Sydney Informatics Hub (or co-authorship, where appropriate).
#
# Suggested citation:
# Sydney Informatics Hub, Core Research Facilities, University of Sydney,
# 2021, The Sydney Informatics Hub Bioinformatics Repository, <date accessed>,
# https://github.com/Sydney-Informatics-Hub/Bioinformatics
#
# Suggested acknowledgement:
# The authors acknowledge the scientific and technical assistance
# <or e.g. bioinformatics assistance of <PERSON>> of Sydney Informatics
# Hub and resources and services from the National Computational
# Infrastructure (NCI), which is supported by the Australian Government
# with access facilitated by the University of Sydney.
#
#########################################################

set -e

cohort=`echo $1 | cut -d ',' -f 1`
tmid=`echo $1 | cut -d ',' -f 2`
nmid=`echo $1 | cut -d ',' -f 3`
ref=`echo $1 | cut -d ',' -f 4`
pon=`echo $1 | cut -d ',' -f 5`
germline=`echo $1 | cut -d ',' -f 6`
outdir=`echo $1 | cut -d ',' -f 7`
tmpfile=`echo $1 | cut -d ',' -f 8`
scatterlist=`echo $1 | cut -d ',' -f 9`
bamdir=`echo $1 | cut -d ',' -f 10`
scatterdir=`echo $1 | cut -d ',' -f 11`
nmbam=$bamdir/${nmid}.final.bam
tmbam=${bamdir}/${tmid}.final.bam
outdir=./Interval_VCFs/${tmid}_${nmid}
logs=./Logs/gatk4_mutect2/${tmid}_${nmid}
nt=1

mkdir -p ${outdir}
mkdir -p ${logs}
rm -rf ${tmpfile}

while IFS= read -r intfile; do
        interval="${scatterdir}/${intfile}"
        echo "${ref},${tmid},${tmbam},${nmid},${nmbam},${interval},${pon},${germline},${outdir},${logs},${nt}" >> ${tmpfile}
done < "${scatterlist}"

echo "${ref},${tmid},${tmbam},${nmid},${nmbam},chrM,${pon},${germline},${outdir},${logs},${nt}" >> ${tmpfile}
