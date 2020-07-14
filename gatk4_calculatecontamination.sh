#!/bin/bash

# Run GATK's CalculateContamination using pileups.tables from GetPileupSummaries
# There was a patch released for this tool that resolves error
# "FilterMutectCalls: Log10-probability must be 0 or less" (happens when CalculateContamination
# result is NaN for a tumour-normal pair
# Patch is available in gatk-best-practices resource, kept in References directory

module load gatk/4.1.2.0

set -e

pair=`echo $1 | cut -d ',' -f 1`
nmpileup=`echo $1 | cut -d ',' -f 2`
tmpileup=`echo $1 | cut -d ',' -f 3`
segments=`echo $1 | cut -d ',' -f 4`
out=`echo $1 | cut -d ',' -f 5`
logdir=`echo $1 | cut -d ',' -f 6`

patch=../Reference/gatk-best-practices/somatic-hg38/gatk-builds_contamination-patch-5-27-2019.jar

mkdir -p ${logdir}
rm -rf ${logdir}/${pair}.oe

echo "$(date): Running CalculateContamination for TN pair: ${pair}, Normal pileup: ${nmpileup}, Tumour pileup: ${tmpileup}, Logs: ${logdir}, Out (contamination): ${out}, Out (segments): ${segments}" > ${logdir}/${pair}.oe 2>&1

java -Xmx8g -Xms8g -DGATK_STACKTRACE_ON_USER_EXCEPTION=true -jar ${patch} \
	CalculateContamination \
	-I ${tmpileup} \
	-tumor-segmentation ${segments} \
	-matched ${nmpileup} \
	-O ${out} >> ${logdir}/${pair}.oe 2>&1

echo "$(date): Finished CalculateContamination" >> ${logdir}/${pair}.oe 2>&1
