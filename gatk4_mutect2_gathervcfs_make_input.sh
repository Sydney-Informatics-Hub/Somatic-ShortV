#! /bin/bash
# Create input for: gatk4_mutect2_gathervcfs_run_parallel.pbs

set -e

if [ -z "$1" ]
then
	echo "Please run this script with the base name of your config file, e.g. sh gatk4_hc_make_input.sh samples_batch1"
	exit
fi

cohort=$1
config=../$cohort.config
vcfdir=./Interval_VCFs
logdir=./Logs/gatk4_mutect2_gathervcfs
bamdir=../Final_bams
INPUTS=./Inputs
inputfile=${INPUTS}/gatk4_mutect2_gathervcfs.inputs

mkdir -p ${logdir}
mkdir -p ${INPUTS}
rm -rf ${inputfile}

# Collect sample IDs from config file
# Only normal ids (labids ending in -B or -N)
pairs_found=0
while read -r sampleid labid seq_center library; do
	if [[ ! ${sampleid} =~ ^#.*$ && ${labid} =~ -B.?$ || ${labid} =~ -N.?$ ]]; then
		#samples+=("${labid}")
		patient=$(echo "${labid}" | perl -pe 's/(-B.?|-N.?)$//g')
		patient_samples=( $(awk -v pattern="${patient}-" '$2 ~ pattern{print $2}' ${config}) )
		if ((${#patient_samples[@]} == 2 )); then
			pairs_found=$(( ${pairs_found}+1 ))
			nmid=`printf '%s\n' ${patient_samples[@]} | grep -P 'N.?$|B.?$'`
			tmid=`printf '%s\n' ${patient_samples[@]} | grep -vP 'N.?$|B.?$'`
			pair=${tmid}_${nmid}
			
			echo "$(date): Writing input files for ${pair}"

			args=${INPUTS}/gatk4_mutect2_gathervcfs_${pair}\.args
			partial=${vcfdir}/${pair}/${pair}.unfiltered.no_chrM.vcf.gz
			chrM=${vcfdir}/${pair}/${pair}.unfiltered.chrM.vcf.gz
			out=${vcfdir}/${pair}/${pair}.unfiltered.vcf.gz

			rm -rf ${args}
			for interval in $(seq -f "%04g" 0 3199);do
				echo "--I " ${vcfdir}/${pair}/${pair}.unfiltered.${interval}.vcf.gz >> ${args}
			done
			
		       	echo "${pair},${args},${logdir},${partial},${chrM},${out}" >> ${inputfile}

		elif (( ${#patient_samples[@]} > 2 )); then
			nmid=`printf '%s\n' ${patient_samples[@]} | grep -P 'N.?$|B.?$'`
			for sample in "${patient_samples[@]}"; do
				if ! [[ ${sample} =~ -N.?$ || ${sample} =~ -B.?$ ]]; then
					tmid=${sample}
					pair=${tmid}_${nmid}
					pairs_found=$(( ${pairs_found}+1 ))

					echo "$(date): Writing input files for ${pair}"

					args=${INPUTS}/gatk4_mutect2_gathervcfs_${pair}\.args
					partial=${vcfdir}/${pair}/${pair}.unfiltered.no_chrM.vcf.gz
		                        chrM=${vcfdir}/${pair}/${pair}.unfiltered.chrM.vcf.gz
                		        out=${vcfdir}/${pair}/${pair}.unfiltered.vcf.gz					
					
					rm -rf ${args}
					for interval in $(seq -f "%04g" 0 3199);do
						echo "--I " ${vcfdir}/${pair}/${pair}.unfiltered.${interval}.vcf.gz >> ${args}
					done
					
					echo "${pair},${args},${logdir},${partial},${chrM},${out}" >> ${inputfile}
				fi
			done
		fi
	fi
done < "${config}"

echo "$(date): Wrote input files for ${pairs_found} tumour normal pairs"
