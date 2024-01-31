#!/bin/bash

#########################################################
#
# Platform: NCI Gadi HPC
# Usage: bash gatk4_getpileupsummaries_byInterval_check.sh /path/to/cohort.config
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


#----------------------------

#----------------------------
# I/O

# Sample config file:
if [ -z "$1" ]
then
        printf "Please provide the path to your cohort.config file, e.g. sh gatk4_getpileupsummaries_scattered_make_input.sh ../cohort.config\n"
        exit
fi
config=$1
cohort=$(basename "$config" | cut -d'.' -f 1)

#----------------------------

#----------------------------

inputs=Inputs/gatk4_getpileupsummaries.inputs
failed=Inputs/gatk4_getpileupsummaries.inputs-failed
pbs_logdir=Logs/getpileupsummaries_PBS
gatk_logdir=Logs/gatk4_getpileupsummaries
gatk_outdir=../${cohort}_GetPileupSummaries/scatter

rm -f $failed

#----------------------------

#----------------------------
# Check the inputs file is not empty

if ! [[ -s $inputs ]]
then 
	printf "ERROR: ${inputs} is missing or empty\n"
	printf "This likely means the whole job failed. Please investigate and re-submit the job.\n"
	exit
fi

#----------------------------

#---------------------------- 
# Check all expected outputs and successful logs
f=0
while read LINE
do
	sample=`echo $LINE | cut -d ',' -f 1`
	bam=`echo $LINE | cut -d ',' -f 2`
	vcfdir=`echo $LINE | cut -d ',' -f 3`
	vcfprefix=`echo $LINE | cut -d ',' -f 4`
	outdir=`echo $LINE | cut -d ',' -f 5`
	logdir=`echo $LINE | cut -d ',' -f 6`
	intervals=`echo $LINE | cut -d ',' -f 7`
	
	e_log=${pbs_logdir}/${sample}_${intervals}.e
	o_log=${pbs_logdir}/${sample}_${intervals}.o
	
	e_log=$(echo $e_log | sed 's/;/-/g')
	o_log=$(echo $o_log | sed 's/;/-/g')
	
	#---------------------------- 
	# e should be empty
	if [ ! -e $e_log ] || [ -s $e_log ]
	then     
		printf "ERROR: $e_log does not exist or is not empty\n"
		echo $LINE >> $failed
		((f++))
	fi

	#---------------------------- 
	# o should have an exit status of 0:
	exit=$(grep "Exit" ${o_log} | awk '{print $3}')
	if [[ $exit -ne 0 ]]
	then
		printf "ERROR: non-zero exit status of $exit for $o_log\n"
		echo $LINE >> $failed
		((f++))
	fi
	
	#----------------------------
	# Check outputs for each interval:
	ints=($(echo "$intervals" | tr ';' '\n'))
	for int in ${ints[@]}
	do

		out=${gatk_outdir}/${sample}_pileups.${int}.table
		log=${gatk_logdir}/${sample}.${int}.log
		
		#----------------------------
		# out should exist and be non-zero bytes
		if ! [[ -s $out ]]
		then 
			printf "ERROR: ${out} is missing or zero bytes\n"
			((f++))
			echo $LINE >> $failed
		fi
				
		#----------------------------
		# log should have SUCCESS return
		return=$(grep -A 1 "Tool returned:" $log | tail -1)
		if [ "$return" != "SUCCESS" ]
		then 
			printf "ERROR: ${log} has unsuccessful return of \"$return\"\n"	
			((f++))
			echo $LINE >> $failed			
		fi
	done
done < $inputs

#----------------------------

#----------------------------
# Remove duplicate entries from failed list and report:

if [ $f -gt 0 ]
then 
	sort $failed | uniq > ${failed}-uniq
	mv ${failed}-uniq $failed
	printf "\n#----------------------------\nErrors detected: `wc -l < ${failed}`\nPlease investigate error source then re-submit with $failed inputs\n#----------------------------\n"
else 
	printf "#----------------------------\nNo issues detected. Please continue with gatk4_getpileupsummaries_byInterval_concat.sh\n#----------------------------\n"
fi

#----------------------------

#----------------------------
