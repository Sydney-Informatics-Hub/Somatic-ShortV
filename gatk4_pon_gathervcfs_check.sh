#! /bin/bash

#########################################################
#
# Platform: NCI Gadi HPC
# Description: Check log and output files from gatk4_pon_gathervcfs_run_parallel.pbs
# Cleans up and removes interval .vcf and .vcf.idx files
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

if [ -z "$1" ]
then
        echo "Please provide the path to your cohort.config file, e.g. sh gatk4_pon_gathervcfs_check.sh ../cohort.config"
        exit
fi

config=$1
cohort=$(basename "$config" | cut -d'.' -f 1)
outdir=./${cohort}_PoN
logs=./Logs/gatk4_pon_gathervcfs
INPUTS=./Inputs
inputfile=${INPUTS}/gatk4_pon_gathervcfs_missing.inputs
out=${logs}/${cohort}_task_duration.txt

rm -rf $out
rm -rf $inputfile

printf "#Sample\tMins\n" > $out


while read -r sampleid labid seq_center library
do
        if [[ ! ${sampleid} =~ ^#.*$ && ${labid} =~ -B.?$ || ${labid} =~ -N.?$ ]]
        then
                samples+=("${labid}")
        fi
done < "${config}"

echo "$(date): Checking VCF and index files for ${#samples[@]} samples"

#For each sample, check logs for duration and VCF dir for gathered GVCF
i=0
for sample in "${samples[@]}"
do
        logfile=${logs}/${sample}.oe
        err=$(grep ERROR $logfile | wc -l)
        if [ $err -gt 0 ]
        then
                echo $sample has $err errors in $logfile
                mins='NA'
        else
                mins=$(grep "GatherVcfs done. Elapsed time" $logfile | rev | cut -d ' ' -f 2 | rev)
        fi
        printf "${sample}\t${mins}\n" >> $out
        vcf=${outdir}/${sample}.pon.vcf.gz
        idx=${outdir}/${sample}.pon.vcf.gz.tbi
        if [[ -s "$vcf" && -s "$idx" ]]
        then
                ((++i))
        else
                echo $sample has missing or empty $vcf or $index file. Writing task to $inputfile
                grep $sample ${INPUTS}/gatk4_pon_gathervcfs.inputs >> $inputfile
        fi
done

echo "$(date): $i samples passed all checks"
if [[ -s "$inputfile" ]]
then
        echo $(date): There are $(wc -l $inputfile) tasks to re-run.
else
        echo $(date): GatherVCFs check complete. There are no tasks to re-run. Cleaning up...
        for sample in "${samples[@]}"
        do
                rm -rf ${outdir}/${sample}
        done
fi
