#! /bin/bash

#########################################################
#
# Platform: NCI Gadi HPC
# Description: Check gatk4_pon job, write input for failed tasks
# Runs gatk4_pon_check_sample.sh for each sample in parallel
# Maximum number of samples processed in parallel is 48
# Usage: nohup sh gatk4_pon_check_sample_parallel.sh /path/to/cohort.config 2> /dev/null &
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

config=`echo $1 | cut -d ',' -f 1`
sample=`echo $1 | cut -d ',' -f 2`
inputfile=`echo $1 | cut -d ',' -f 3`
ref=`echo $1 | cut -d ',' -f 4`
scatterdir=`echo $1 | cut -d ',' -f 5`
scatterlist=`echo $1 | cut -d ',' -f 6`
bamdir=`echo $1 | cut -d ',' -f 7`
logdir=`echo $1 | cut -d ',' -f 8`
cohort=$(basename "$config" | cut -d. -f 1)
outdir=./$cohort\_PoN
PERL_SCRIPT=get_interval_times_gatklog.pl
num_int=`wc -l ${scatterlist} | cut -d' ' -f 1`

i=0
echo "$(date): Checking ${sample}..."
for interval in $(seq -f "%04g" 0 $((${num_int}-1))); do
        logfile=${logdir}/${sample}/${interval}.oe
        vcf=${outdir}/${sample}/${sample}.pon.${interval}.vcf
        idx=${outdir}/${sample}/${sample}.pon.${interval}.vcf.idx
        stats=${outdir}/${sample}/${sample}.pon.${interval}.vcf.stats
        if ! [[ -s "${vcf}" &&  -s "${idx}" && -s "${stats}" ]]
        then
                ((++i))
                intfile=$(grep ${interval} ${scatterlist})
                echo "${ref},${sample},${bam},${intfile},${out},${nt},${logdir}" >> ${inputfile}
        elif [[ -s "${logfile}" ]]
        then
                success=$(grep -i success ${logfile})
                error=$(grep -i error ${logfile})
                if [[ ! ${success} && -z ${error} ]]; then
                        ((++i))
                        intfile=$(grep ${interval} ${scatterlist})
                        echo "${ref},${sample},${bam},${intfile},${out},${nt},${logdir}" >> ${inputfile}
                fi
        else
                "$(date): ${sample} has all output files but no log file for ${interval}"
        fi
done

if [[ ${i}>0 ]]; then
        echo "$(date): ${sample} has $i failed tasks. Wrote $i tasks to ${inputfile}"
else
        echo "$(date): ${sample} has $i failed tasks. Printing task duration and memory usage..."
        perl ${PERL_SCRIPT} ${logdir}/${sample} > ${logdir}/${sample}/${sample}_task_duration_mem.txt
        echo "$(date): Tarring ${sample} logs..."
        cd ${logdir}
        tar -czf ${sample}_logs.tar.gz ${sample}
        rm -rf ${logdir}/${sample}
fi
