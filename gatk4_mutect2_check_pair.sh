#! /bin/bash

#########################################################
#
# Platform: NCI Gadi HPC
# Description: Check gatk4_mutect2 job
# Run by gatk4_mutect2_check_pair_parallel.sh
# Author: Tracy Chew
# tracy.chew@sydney.edu.au
# Date last modified: 18/03/2021
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
nmbam=${bamdir}/${nmid}.final.bam
tmbam=${bamdir}/${tmid}.final.bam
logs=./Logs/gatk4_mutect2/${tmid}_${nmid}
nt=1
num_intervals=$(wc -l $scatterlist | cut -d' ' -f 1)

i=0
echo "$(date): Checking tumour ${tmid} normal ${nmid} pair..."
for interval in $(seq -f "%04g" 0 $((${num_intervals}-1))); do
        logfile=${logs}/${interval}.oe
        vcf=${outdir}/${tmid}_${nmid}.unfiltered.${interval}.vcf.gz
        tbi=${outdir}/${tmid}_${nmid}.unfiltered.${interval}.vcf.gz.tbi
        stats=${outdir}/${tmid}_${nmid}.unfiltered.${interval}.vcf.gz.stats
        f1r2=${outdir}/${tmid}_${nmid}.f1r2.${interval}.tar.gz
        if ! [[ -s "${vcf}" &&  -s "${tbi}" && -s "${stats}" && -s "${f1r2}" && -s "${logfile}" ]]
        then
                ((++i))
                intfile=$(grep ${interval} ${scatterlist})
                echo "${ref},${tmid},${tmbam},${nmid},${nmbam},${scatterdir}/${intfile},${pon},${germline},${outdir},${logs},${nt}" >> ${tmpfile}
        else
                success=$(grep -i success ${logfile})
                error=$(grep -i error ${logfile})
                if [[ ! ${success} && -z ${error} ]]; then
                        ((++i))
                        intfile=$(grep ${interval} ${scatterlist})
                        echo "${ref},${tmid},${tmbam},${nmid},${nmbam},${scatterdir}/${intfile},${pon},${germline},${outdir},${logs},${nt}" >> ${tmpfile}
                fi
        fi
done

# Check chrM
chrM_logfile=${logs}/chrM.oe
chrM_vcf=${outdir}/${tmid}_${nmid}.unfiltered.chrM.vcf.gz
chrM_tbi=${outdir}/${tmid}_${nmid}.unfiltered.chrM.vcf.gz.tbi
chrM_stats=${outdir}/${tmid}_${nmid}.unfiltered.chrM.vcf.gz.stats
chrM_f1r2=${outdir}/${tmid}_${nmid}.f1r2.chrM.tar.gz

if ! [[ -s "${chrM_vcf}" &&  -s "${chrM_tbi}" && -s "${chrM_stats}" && -s "${chrM_f1r2}" && -s "${chrM_logfile}" ]]
then
        ((++i))
        echo "${ref},${tmid},${tmbam},${nmid},${nmbam},chrM,${pon},${germline},${outdir},${logs},${nt}" >> ${tmpfile}
else
        success=$(grep -i success ${chrM_logfile})
        error=$(grep -i error ${chrM_logfile})
        if [[ ! ${success} && -z ${error} ]]; then
                ((++i))
                echo "${ref},${tmid},${tmbam},${nmid},${nmbam},chrM,${pon},${germline},${outdir},${logs},${nt}" >> ${tmpfile}
        fi
fi

echo "$(date): Tumour ${tmid} normal ${nmid} pair has $i failed tasks."

