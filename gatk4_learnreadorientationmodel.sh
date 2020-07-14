#!/bin/bash

# Run GATK LearnReadOrientationModel using scatter-gather method

module load gatk/4.1.2.0

pair=`echo $1 | cut -d ',' -f 1`
args=`echo $1 | cut -d ',' -f 2`
logdir=`echo $1 | cut -d ',' -f 3`
out=`echo $1 | cut -d ',' -f 4`

echo "$(date) : Running GATK 4 LearnReadOrientationModel using f1r2 outputs from Mutect2. TN pair: ${pair}, Arguments file: ${args}, Logs: ${logdir}, Out: ${out}" > ${logdir}/${pair}.oe 2>&1

gatk --java-options "-Xmx140g -Xms140g -DGATK_STACKTRACE_ON_USER_EXCEPTION=true" \
	LearnReadOrientationModel \
	--arguments_file ${args} \
	-O ${out} >> ${logdir}/${pair}.oe 2>&1

echo "$(date): Finished running LearnReadOrientationModel for TN pair: ${pair}" >> ${logdir}/${pair}.oe 2>&1 &


