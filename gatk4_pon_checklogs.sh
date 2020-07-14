#!/bin/bash

module load parallel/20191022

echo "Checking sample: ${sample}, input: ${input}. Writing to ${logs}"

rm -rf ${logs}/${sample}_errors.txt
rm -rf ${logs}/${sample}_task_duration.txt

# Check for errors in parallel
parallel -j ${NCPUS} --col-sep ',' "grep -i '"error"' {3}" :::: ${input} >> ${logs}/${sample}_errors.txt

# Get elapsed time
perl ${perl} ${logs}/${sample} >> ${logs}/${sample}_task_duration.txt
#parallel -j 1 grep -oP '"Elapsed time: [0-9]+\.[0-9]+"' :::: ${logs}
#parallel -j ${NCPUS}  --colsep ',' "printf "{1}," && printf "{2}," && grep -oP '"Elapsed time: [0-9]+\.[0-9]+"' {3}" :::: ${input} >> ${logs}/${sample}_task_duration.txt

# Tar log directory if no errors were found
if ! [[ -s "${logs}/${sample}_errors.txt" ]]
then
	cd ${logs}
	#mv ${sample}_errors.txt ${sample}
	tar --remove-files -czvf ${sample}_logs.tar.gz ${sample}
fi
