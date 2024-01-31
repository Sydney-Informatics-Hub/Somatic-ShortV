#!/bin/bash

#########################################################
#
# Platform: NCI Gadi HPC
# Usage: bash gatk4_getpileupsummaries_splitIntervals.sh
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

module load gatk/4.2.1.0

int=24 # selected based on considering the largest chr size and the number of CPU on Gadi hugemem nodes 
dict=../Reference/hs38DH.dict
ref=../Reference/hs38DH.fasta
common_biallelic=../Reference/gatk-best-practices/somatic-hg38/af-only-gnomad.hg38.vcf.gz

outdir=../Reference/GetPileupSummaries_intervals

printf "\n########################\n"
if [ -d $outdir ]
then
	printf "WARNING: Directory '${outdir}' already exists.\nDeleting its contents and updating with new intervals from $common_biallelic\n########################\n\n"
	rm -rf $outdir
else
	printf "Writing $int intervals from $common_biallelic to $outdir\n########################\n\n"
	mkdir ${outdir}
fi

gatk SplitIntervals \
	-R ${ref} \
	-scatter-count $int  \
	--subdivision-mode BALANCING_WITHOUT_INTERVAL_SUBDIVISION  \
	-O ${outdir}
	
printf "\n################\nIntervals directory: ${outdir}\nIntervals requested: ${int}\nIntervals created: `ls -1 ${outdir} | wc -l`\n"
