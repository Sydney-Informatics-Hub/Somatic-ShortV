#! /bin/bash

#########################################################
#
# Platform: NCI Gadi HPC
# Usage: sh gatk4_getpileupsummaries_scattered_make_input.sh /path/to/cohort.config
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

# Sample config file:
if [ -z "$1" ]
then
        echo "Please provide the path to your cohort.config file, e.g. sh gatk4_getpileupsummaries_scattered_make_input.sh ../cohort.config"
        exit
fi
config=$1

#####################

# Select your common biallelic resource. This must be the same as used in the previous steps of
# gatk4_getpileupsummaries_splitIntervals.sh and gatk4_getpileupsummaries_split_common_vcf_run.sh 
# (both need only be run once per vcf resource)  
common_biallelic=../Reference/gatk-best-practices/somatic-hg38/af-only-gnomad.hg38.vcf.gz

#####################

# Location of VCF interval files for the above VCF resource is assumed as per below
# If not, please nanually over-ride with your split VCF dirpath and prefix
vcfdir=$(dirname $common_biallelic)
vcfprefix=$(basename $common_biallelic | sed 's/\.vcf.*//')


#####################

# Other IO:

cohort=$(basename "$config" | cut -d'.' -f 1)
dict=../Reference/hs38DH.dict
bamdir=../Final_bams
outdir=../${cohort}_GetPileupSummaries
logdir=./Logs/gatk4_getpileupsummaries
INPUTS=./Inputs
inputfile=${INPUTS}/gatk4_getpileupsummaries.inputs

mkdir -p ${outdir} ${outdir}/scatter ${logdir} ${INPUTS}
rm -rf ${inputfile}

#####################

# Testing has found this job not performing well as typical nci-parallel scatter
# Split the intervals to 3 jobs per sample based on approximately equal walltimes, this is 
# based on testing one 81 GB sample 
# Define the intervals: 

# Tested different int chunks to try and get the most equitable split:
#int_chunks=("0000;0001;0002;0003;0004;0005" "0006;0007;0008;0009;0010;0011" "0012;0013;0014;0015;0016;0017")
#int_chunks=("0000;0001;0002;0003;0004" "0005;0006;0007;0008;0009;0010" "0011;0012;0013;0014;0015;0016;0017") 
int_chunks=("0000;0001;0002;0003" "0004;0005;0006;0007;0008;0009" "0010;0011;0012;0013;0014;0015;0016;0017")




# Write inputs per interval-group per sample - each sample will have 
# 3 lines in the inputs file, covering all 18 VCF interval chunks
# There is no need to sort the inputs file, as each line will be 
# sent to a separate PBS job 
while read -r sampleid labid seq_centre lib
do
        if [[ ! ${sampleid} =~ ^#.*$ ]]
	then
                bam=${bamdir}/${labid}.final.bam
		
		for intervals in ${int_chunks[@]}
		do
		
                	printf "${labid},${bam},${vcfdir},${vcfprefix},${outdir}/scatter,${logdir},${intervals}\n" >> ${inputfile}
		done
        fi
done < ${config}


#####################

echo Inputs for GetPileupSummaries written to ${inputfile}
printf "Number of jobs to be run: `wc -l < ${inputfile}`\n"
printf "\n###############\nPlease next run gatk4_getpileupsummaries_byInterval_runLoop.sh \
which will submit 3 jobs per sample. The job is defined in the script \
gatk4_getpileupsummaries_byInterval.pbs. You may wish to adjust walltime \
in this script, for example 1 hour for 30X, 2 hours for 60X, 3 hours for 90X.\n###############\n"

#####################
