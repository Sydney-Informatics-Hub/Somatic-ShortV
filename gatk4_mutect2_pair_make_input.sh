#! /bin/bash

# Write inputs for Mutect2 per pair
# gatk4_mutect2_make_input.sh runs this script in parallel 

cohort=`echo $1 | cut -d ',' -f 1`
tmid=`echo $1 | cut -d ',' -f 2`
nmid=`echo $1 | cut -d ',' -f 3`

ref=../Reference/hs38DH.fasta
scatterdir=../Reference/ShortV_intervals
scatterlist=$scatterdir/3200_ordered_exclusions.list
bamdir=../Final_bams
pon=./$cohort\_cohort_PoN/$cohort.sorted.pon.g.vcf.gz
gnomad=../Reference/broad-references/ftp/Mutect2/af-only-gnomad.hg38.vcf.gz
nt=1
INPUTS=./Inputs
inputfile=${INPUTS}/gatk4_mutect2_${tmid}_${nmid}.inputs
nmbam=${bamdir}/${nmid}.final.bam
tmbam=${bamdir}/${tmid}.final.bam
out=./Interval_VCFs/${tmid}_${nmid}
logs=./Logs/gatk4_mutect2/${tmid}_${nmid}

mkdir -p ${out}
mkdir -p ${logs}
rm -rf ${inputfile}

while IFS= read -r intfile; do
	interval="${scatterdir}/${intfile}"
	echo "${ref},${tmid},${tmbam},${nmid},${nmbam},${interval},${pon},${gnomad},${out},${logs},${nt}" >> ${inputfile}
done < "${scatterlist}"

echo "${ref},${tmid},${tmbam},${nmid},${nmbam},chrM,${pon},${gnomad},${out},${logs},${nt}" >> ${inputfile}
