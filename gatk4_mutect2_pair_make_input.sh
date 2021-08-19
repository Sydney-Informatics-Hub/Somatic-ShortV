#! /bin/bash

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
