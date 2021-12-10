#! /bin/bash

#########################################################
#
# Platform: NCI Gadi HPC
# Usage: nohup sh gatk4_cohort_pon_check.sh /path/to/cohort.config 2> /dev/null &
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

if [ -z "$1" ]
then
        echo "Please provide the path to your cohort.config file, e.g nohup sh gatk4_cohort_pon_check.sh /path/to/cohort.config 2> /dev/null &"
        exit
fi

config=$1
cohort=$(basename $config | cut -d'.' -f 1)
INPUTS=./Inputs
inputfile=${INPUTS}/gatk4_cohort_pon_missing.inputs
ref=../Reference/hs38DH.fasta
gnomad=../Reference/broad-references/ftp/Mutect2/af-only-gnomad.hg38.vcf.gz
scatterdir=../Reference/ShortV_intervals
scatterlist=$(ls $scatterdir/*.list)
if [[ ${#scatterlist[@]} > 1 ]]; then
        echo "$(date): ERROR - more than one scatter list file found: ${scatterlist[@]}"
        exit
fi
gendbdir=../$cohort\_PoN_GenomicsDBImport
outdir=../$cohort\_cohort_PoN
logdir=./Logs/gatk4_cohort_pon
PERL_SCRIPT=./gatk4_check_logs.pl
perlfile=${logdir}/interval_duration_memory.txt
num_int=`wc -l ${scatterlist} | cut -d' ' -f 1`

mkdir -p ${INPUTS} ${logdir}
rm -rf ${inputfile} ${perlfile}

# Check each interval vcf and tbi file exists and is not empty
for index in $(seq -f "%04g" 0 $((${num_int}-1))); do
        vcf=${outdir}/${cohort}.${index}.pon.vcf.gz
        tbi=${outdir}/${cohort}.${index}.pon.vcf.gz.tbi
        if ! [[ -s "${vcf}" && -s "${tbi}" ]]
        then
                redo+=("$index")
        fi
done
echo $(date): "${#redo[@]}" tasks had missing or empty cohort.interval.pon.vcf.gz or cohort.interval.pon.vcf.gz.tbi files. Checking log files...

# Check log files. Run perl script to get duration
echo "$(date): Checking log files for errors, obtaining duration and memory usage per task..."
perl $PERL_SCRIPT "$logdir"

# Check output file
while read -r interval duration memory; do
        if [[ $duration =~ NA || $memory =~ NA ]]
        then
                if [[ ! "${redo[@]}" =~ "${interval}" ]]
                then
                        redo+=("$interval")
                fi
        fi
done < "$perlfile"

if [[ ${#redo[@]}>0 ]]
then

        echo "$(date): There are ${#redo[@]} intervals that need to be re-run."
        echo "$(date): Writing inputs to ${inputfile}"

        for redo_interval in ${redo[@]}; do
                interval="${scatterdir}/${redo_interval}-scattered.interval_list"
                echo "${ref},${cohort},${gnomad},${gendbdir},${interval},${outdir},${logdir}" >> ${inputfile}
        done
else
        echo "$(date): There are no intervals that need to be re-run. Tidying up..."
        cd ${logdir}
        tar -kczf cohort_pon_logs.tar.gz \
	        *.log
	retVal=$?
        if [ $retVal -eq 0 ]; then
                echo "$(date): Tar successful. Cleaning up..."
                rm -rf *log
	fi
fi
