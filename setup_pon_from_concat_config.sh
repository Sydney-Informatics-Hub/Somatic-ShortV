#! /bin/bash

#########################################################
#
# Platform: NCI Gadi HPC
# Usage:
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
        echo "Please provide the path to your new cohort.config file that was created with concat_configs.sh"
        echo "e.g. sh setup_pon_new_config.sh ../new_cohort.config"
        exit
fi

config=$1
concat_cohort=$(basename $config | cut -d'.' -f 1)

# Create new PoN directory for combined cohort
if [ -d "../${concat_cohort}_PoN" ]; then
        if [ -z "$(ls -A ../${concat_cohort}_PoN)" ]; then
                echo $(date): WARN ../${concat_cohort} exists and is not empty.
        fi
fi

# Collect sample IDs from samples.config
# Only collect IDs from normal samples (labids ending in -B)
while read -r sampleid labid seq_center library; do
        if [[ ! ${sampleid} =~ ^#.*$ && ${labid} =~ -B.?$ || ${labid} =~ -N.?$ ]]; then
                samples+=("${labid}")
        fi
done < "${config}"

echo "$(date): Found ${#samples[@]} normal samples in $config"

mkdir -p ../${concat_cohort}_PoN
cd ../${concat_cohort}_PoN

for nmid in "${samples[@]}"; do
	echo $PWD $nmid
	nmid_vcf=$(find ${PWD}/../*PoN -type f -name "*${nmid}.pon.vcf.gz")
        nmid_tbi=$(find ${PWD}/../*PoN -type f -name "*${nmid}.pon.vcf.gz.tbi")
        if [[ $nmid_vcf && $nmid_tbi ]]; then
                echo Found VCF and index files, creating symbolic links for $nmid_vcf and $nmid_tbi
                cp -rs $nmid_vcf .
                cp -rs $nmid_tbi .
        else
                echo Could not find ${nmid}.pon.vcf.gz or ${nmid}.pon.vcf.gz.tbi
        fi
done
