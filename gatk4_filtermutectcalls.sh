#!/bin/bash

# Run GATK's FilterMutectCalls using:
# -V pair.unfiltered.vcf.gz (from Mutect2)
# -stats pair.unfiltered.vcf.gz.stats (from Mutect2)
# --tumor-segmentation tumor_segments.table (from GetPileupSummaries & CalculateContamination)
# --contamination-table tumor_normal_contamination.table (from GetPileupSummaries & CalculateContamination)
# --ob-priors tumour_normal_read-orientation-model.tar.gz (from Mutect2 & LearnReadOrientationModel)


module load gatk/4.1.2.0

set -e

pair=`echo $1 | cut -d ',' -f 1`
unfiltered=`echo $1 | cut -d ',' -f 2`
ref=`echo $1 | cut -d ',' -f 3`
stats=`echo $1 | cut -d ',' -f 4`
segments=`echo $1 | cut -d ',' -f 5`
contamination=`echo $1 | cut -d ',' -f 6`
ob_priors=`echo $1 | cut -d ',' -f 7`
filtered=`echo $1 | cut -d ',' -f 8`
logdir=`echo $1 | cut -d ',' -f 9`

mkdir -p ${logdir}
rm -rf ${logdir}/${pair}.oe

echo "$(date): Running FilterMutectCalls for TN pair: ${pair}, Reference: ${ref}, Unfiltered VCF: ${unfiltered}, Stats: ${stats}, Segments: ${segments}, Contamination: ${contamination}, OB priors: ${ob_priors}, Out: ${filtered}, Logs: ${logdir}" > ${logdir}/${pair}.oe 2>&1

gatk --java-options "-Xmx8g -Xms8g -DGATK_STACKTRACE_ON_USER_EXCEPTION=true" \
	FilterMutectCalls \
	--reference ${ref} \
	-V ${unfiltered} \
	--stats ${stats} \
	--tumor-segmentation ${segments} \
	--contamination-table ${contamination} \
	--ob-priors ${ob_priors} \
	-O ${filtered} >> ${logdir}/${pair}.oe 2>&1

echo "$(date): Finished FilterMutectCalls" >> ${logdir}/${pair}.oe 2>&1
