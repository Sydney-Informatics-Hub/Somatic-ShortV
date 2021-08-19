#! /bin/bash

#########################################################
#
# Platform: NCI Gadi HPC
# Usage: Run by gatk4_mutect2_check_pair_parallel.sh
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
logdir=`echo $1 | cut -d ',' -f 12`
pair=${tmid}_${nmid}
nmbam=${bamdir}/${nmid}.final.bam
tmbam=${bamdir}/${tmid}.final.bam
nt=1
num_intervals=$(wc -l $scatterlist | cut -d' ' -f 1)
PERL_SCRIPT=get_interval_times_gatklog.pl

i=0
echo "$(date): Checking tumour ${tmid} normal ${nmid} pair..."
for interval in $(seq -f "%04g" 0 $((${num_intervals}-1))); do
        logfile=${logdir}/${pair}/${interval}.oe
        vcf=${outdir}/${pair}.unfiltered.${interval}.vcf.gz
        tbi=${outdir}/${pair}.unfiltered.${interval}.vcf.gz.tbi
        stats=${outdir}/${pair}.unfiltered.${interval}.vcf.gz.stats
        f1r2=${outdir}/${pair}.f1r2.${interval}.tar.gz
        if ! [[ -s "${vcf}" &&  -s "${tbi}" && -s "${stats}" && -s "${f1r2}" && -s "${logfile}" ]]
        then
                ((++i))
                intfile=$(grep ${interval} ${scatterlist})
                echo "${ref},${tmid},${tmbam},${nmid},${nmbam},${scatterdir}/${intfile},${pon},${germline},${outdir},${logdir}/${pair},${nt}" >> ${tmpfile}
        else
                success=$(grep -i success ${logfile})
                error=$(grep -i error ${logfile})
                if [[ ! ${success} && -z ${error} ]]; then
                        ((++i))
                        intfile=$(grep ${interval} ${scatterlist})
                        echo "${ref},${tmid},${tmbam},${nmid},${nmbam},${scatterdir}/${intfile},${pon},${germline},${outdir},${logdir}/${pair},${nt}" >> ${tmpfile}
                fi
        fi
done

# Check chrM
chrM_logfile=${logdir}/${pair}/chrM.oe
chrM_vcf=${outdir}/${pair}.unfiltered.chrM.vcf.gz
chrM_tbi=${outdir}/${pair}.unfiltered.chrM.vcf.gz.tbi
chrM_stats=${outdir}/${pair}.unfiltered.chrM.vcf.gz.stats
chrM_f1r2=${outdir}/${pair}.f1r2.chrM.tar.gz

if ! [[ -s "${chrM_vcf}" &&  -s "${chrM_tbi}" && -s "${chrM_stats}" && -s "${chrM_f1r2}" && -s "${chrM_logfile}" ]]
then
        ((++i))
        echo "${ref},${tmid},${tmbam},${nmid},${nmbam},chrM,${pon},${germline},${outdir},${logdir}/${pair},${nt}" >> ${tmpfile}
else
        success=$(grep -i success ${chrM_logfile})
        error=$(grep -i error ${chrM_logfile})
        if [[ ! ${success} && -z ${error} ]]; then
                ((++i))
                echo "${ref},${tmid},${tmbam},${nmid},${nmbam},chrM,${pon},${germline},${outdir},${logdir}/${pair},${nt}" >> ${tmpfile}
        fi
fi

if [[ ${i}>0 ]]; then
        echo "$(date): ${pair} has $i failed tasks."
else
        echo "$(date): ${pair} has $i failed tasks. Printing task duration and memory usage..."
        perl ${PERL_SCRIPT} ${logdir}/${pair} > ${logdir}/${pair}/${pair}_task_duration_mem.txt
        echo "$(date): Tarring ${pair} logs..."
        cd ${logdir}
        tar -czf ${pair}_mutect2_logs.tar.gz ${pair}
        rm -rf ${logdir}
fi
