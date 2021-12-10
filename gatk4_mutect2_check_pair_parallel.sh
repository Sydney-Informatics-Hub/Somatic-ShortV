#! /bin/bash

#########################################################
#
# Platform: NCI Gadi HPC
# Usage: nohup sh gatk4_mutect2_check_pair_parallel.sh /path/to/cohort.config 2> /dev/null &
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
        echo "Please provide the path to your cohort.config file, e.g. sh gatk4_mutect2_check_pair.sh ../cohort.config"
        exit
fi

# INPUTS
config=$1
cohort=$(basename $config | cut -d'.' -f 1)
mt2dir=../Mutect2
ref=../Reference/hs38DH.fasta
scatterdir=../Reference/ShortV_intervals
scatterlist=$(ls $scatterdir/*.list)
if [[ ${#scatterlist[@]} > 1 ]]; then
        echo "$(date): ERROR - more than one scatter list file found: ${scatterlist[@]}"
        exit
fi
pon=../$cohort\_cohort_PoN/$cohort.sorted.pon.vcf.gz
germline=../Reference/broad-references/ftp/Mutect2/af-only-gnomad.hg38.vcf.gz
logdir=./Logs/gatk4_mutect2
INPUTS=./Inputs
bamdir=../Final_bams
inputfile=${INPUTS}/gatk4_mutect2_missing.inputs
SCRIPT=./gatk4_mutect2_check_pair.sh
num_intervals=$(wc -l $scatterlist | cut -d' ' -f 1)

rm -rf ${inputfile}

# Collect sample IDs from samples.config
# Only collect IDs from normal samples (labids ending in -B)
while read -r sampleid labid seq_center library; do
        if [[ ! ${sampleid} =~ ^#.*$ && ${labid} =~ -B.?$ || ${labid} =~ -N.?$ ]]; then
                samples+=("${labid}")
        fi
done < "${config}"

# Collect all tumour IDs for each normal sample
for nmid in "${samples[@]}"; do
        # Find any matching tumour bams using normal id without -N or -B
        patient=$(echo "${nmid}" | perl -pe 's/(-B.?|-N.?)$//g')
	patient_samples=(`find ${bamdir} -name "${patient}-[B|N|T|M|P]*.final.bam" -execdir echo {} ';' | sed 's|^./||' | sed 's|.final.bam||g'`)
        if (( ${#patient_samples[@]} == 2 )); then
                nmid=`printf '%s\n' ${patient_samples[@]} | grep -P 'N.?$|B.?$'`
                tmid=`printf '%s\n' ${patient_samples[@]} | grep -vP 'N.?$|B.?$'`
                tmpfile=${INPUTS}/gatk4_mutect2_${tmid}_${nmid}.inputs.tmp
                rm -rf $tmpfile
		tmp+=("$tmpfile")
                outdir=${mt2dir}/${tmid}_${nmid}
                inputs+=("${cohort},${tmid},${nmid},${ref},${pon},${germline},${outdir},${tmpfile},${scatterlist},${bamdir},${scatterdir},${logdir}")
        elif (( ${#patient_samples[@]} > 2 )); then
                nmid=`printf '%s\n' ${patient_samples[@]} | grep -P 'N.?$|B.?$'`
                for sample in "${patient_samples[@]}"; do
                        if ! [[ ${sample} =~ -N.?$ || ${sample} =~ -B.?$ ]]; then
                                tmid=${sample}
                                tmpfile=${INPUTS}/gatk4_mutect2_${tmid}_${nmid}.inputs.tmp
                                rm -rf $tmpfile
				tmp+=("$tmpfile")
                                outdir=${mt2dir}/${tmid}_${nmid}
                                inputs+=("${cohort},${tmid},${nmid},${ref},${pon},${germline},${outdir},${tmpfile},${scatterlist},${bamdir},${scatterdir},${logdir}")
                        fi
                done
        fi
done

echo "$(date): Checking .vcf.gz, .vcf.gz.tbi, .vcf.gz.stats, f1r2 files for ${#inputs[@]} tumour normal pairs"

echo "${inputs[@]}" | xargs --max-args 1 --max-procs 48 ${SCRIPT}

for tmp in "${tmp[@]}"; do
        if [[ -s $tmp ]]; then
		cat $tmp >> $inputfile
	fi
	rm -rf ${tmp}
done

if [[ -s ${inputfile} ]]; then
        num_inputs=`wc -l ${inputfile}`
        echo "$(date): There are ${num_inputs} tasks to run for gatk4_mutect2_missing_run_parallel.pbs"
else
        echo "$(date): There are 0 tasks to run for gatk4_mutect2_missing_run_parallel.pbs"
fi
