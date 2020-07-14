#! /bin/bash

# For each sample, remove interval .vcf and .vcf.idx pon files once GenomicsDBImport and gatk4_cohort_pon
# have run successfully
# .stats files are kept for now (shouldn't need them but just in case...)

if [ -z "$1" ]
then
	echo "Please run this script with the base name of your config file, e.g. sh gatk4_hc_checklogs_make_input.sh samples_batch1"
	exit
fi

cohort=$1
config=../$cohort.config
outdir=./$cohort\_PoN

# Collect sample IDs from samples.config
# Only collect IDs for germline variant calling (labids ending in -B)
while read -r sampleid labid seq_center library; do
	if [[ ! ${sampleid} =~ ^#.*$ && ${labid} =~ -B.?$ || ${labid} =~ -N.?$ ]]; then
		samples+=("${labid}")
	fi
done < "${config}"

echo "$(date): Cleaning up $outdir for ${#samples[@]} samples"

# Remove interval .vcf, .vcf.idx and .stats files
for sample in "${samples[@]}"; do
	num_vcf=`ls ${outdir}/${sample}/${sample}.pon.*.vcf | wc -l`
	num_idx=`ls ${outdir}/${sample}/${sample}.pon.*.vcf.idx | wc -l`
	
	echo "$(date): ${sample} has ${num_vcf} and ${num_idx}"
	
	if [[ ${num_vcf} == 3200 && ${num_idx} == 3200 ]]; then
		
		echo "Cleaning up $outdir: removing interval .vcf, .vcf.idx and .stats files for ${sample}"
		
		cp ${outdir}/${sample}/${sample}.pon.g.vcf.gz ${outdir}/.
		cp ${outdir}/${sample}/${sample}.pon.g.vcf.gz.tbi ${outdir}/.
		
		rm -rf ${outdir}/${sample}
	else
		echo WARNING ${sample} did not have 3200 vcf and 3200 idx files
	fi
done

