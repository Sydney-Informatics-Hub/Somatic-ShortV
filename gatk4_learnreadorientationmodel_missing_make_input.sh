#! /bin/bash
# Create input for: gatk4_learnreadorientationmodel_run_parallel.pbs
# Create arg file per TN pair 
# One task (one line of input) is one TN pair

set -e

if [ -z "$1" ]
then
	echo "Please run this script with the base name of your config file, e.g. sh gatk4_hc_make_input.sh samples_batch1"
	exit
fi

cohort=$1
config=../$cohort.config
vcfdir=./Interval_VCFs
logdir=./Logs/gatk4_learnreadorientationmodel
INPUTS=./Inputs
inputfile=${INPUTS}/gatk4_learnreadorientationmodel_missing.inputs

mkdir -p ${logdir}
mkdir -p ${INPUTS}
rm -rf ${inputfile}

# Get pairs that ran successfully
# have SUCCESS in log file and no errors
# Have expected output file: TN_NM_read-orientation-model.tar.gz
success=(`grep SUCCESS ${logdir}/*oe | awk -F/ '{print $NF}' | cut -d '.' -f 1`)
error=(`grep -i error ${logdir}/*oe | awk -F/ '{print $NF}' | cut -d '.' -f 1`)
#echo ${success[@]}

# Collect sample IDs from config file
# Only normal ids (labids ending in -B or -N)
pairs_found=0
missing_pairs=0
successful_pairs=0
while read -r sampleid labid seq_center library; do
	if [[ ! ${sampleid} =~ ^#.*$ && ${labid} =~ -B.?$ || ${labid} =~ -N.?$ ]]; then
		patient=$(echo "${labid}" | perl -pe 's/(-B.?|-N.?)$//g')
		patient_samples=( $(awk -v pattern="${patient}-" '$2 ~ pattern{print $2}' ${config}) )

		if ((${#patient_samples[@]} == 2 )); then
			pairs_found=$(( ${pairs_found}+1 ))
			nmid=`printf '%s\n' ${patient_samples[@]} | grep -P 'N.?$|B.?$'`
			tmid=`printf '%s\n' ${patient_samples[@]} | grep -vP 'N.?$|B.?$'`
			pair=${tmid}_${nmid}
			args=${INPUTS}/gatk4_readorientation_${pair}\.args
			out=${vcfdir}/${pair}/${pair}_read-orientation-model.tar.gz

			# Don't continue if pair matches any in ${success[@]}
			if [[ " ${success[@]} " =~ " ${pair} " && -s ${out} ]]; then
				echo "$(date): SUCCESS in ${pair}.oe and ${out} non-empty"
				successful_pairs=$(( ${successful_pairs}+1 ))
			else
				if [[ " ${error[@]} " =~ " ${pair} " ]]; then 
					echo "$(date): ERROR in ${pair}.oe, you might want to investigate"
				fi
				echo "$(date): Writing input files for ${pair}"
				rm -rf ${args}
				missing_pairs=$(( ${missing_pairs}+1 ))
				for interval in $(seq -f "%04g" 0 3199);do
					echo "--I " ${vcfdir}/${pair}/${pair}.f1r2.${interval}.tar.gz >> ${args}
				done
				echo "--I " ${vcfdir}/${pair}/${pair}.f1r2.chrM.tar.gz >> ${args}
			
			       	echo "${pair},${args},${logdir},${out}" >> ${inputfile}
			fi
			
		elif (( ${#patient_samples[@]} > 2 )); then
			nmid=`printf '%s\n' ${patient_samples[@]} | grep -P 'N.?$|B.?$'`
			for sample in "${patient_samples[@]}"; do
				if ! [[ ${sample} =~ -N.?$ || ${sample} =~ -B.?$ ]]; then
					tmid=${sample}
					pair=${tmid}_${nmid}
					pairs_found=$(( ${pairs_found}+1 ))
					args=${INPUTS}/gatk4_readorientation_${pair}\.args
					out=${vcfdir}/${pair}/${pair}_read-orientation-model.tar.gz
					
					if [[ " ${success[@]} " =~ " ${pair} " && -s ${out} ]]; then
						echo "$(date): SUCCESS in ${pair}.oe and ${out} non-empty"
						successful_pairs=$(( ${successful_pairs}+1 ))
					else
						if [[ " ${error[@]} " =~ " ${pair} " ]]; then
							echo "$(date): ERROR in ${pair}.oe, you might want to investigate"
						fi
						
						echo "$(date): Writing input files for ${pair}"
						missing_pairs=$(( ${missing_pairs}+1 ))
						rm -rf ${args}
						for interval in $(seq -f "%04g" 0 3199);do
							echo "--I " ${vcfdir}/${pair}/${pair}.f1r2.${interval}.tar.gz >> ${args}
						done
						echo "--I " ${vcfdir}/${pair}/${pair}.f1r2.chrM.tar.gz >> ${args}
						echo "${pair},${args},${logdir},${out}" >> ${inputfile}
					fi
				fi
			done
		fi
	fi
done < "${config}"

echo "$(date): LearnReadOrientationModel. ${config} has ${pairs_found} tumour normal pairs. Successful tasks: ${successful_pairs}. Wrote ${missing_pairs} tasks for gatk4_learnreadorientationmodel_missing_run_parallel.pbs"
