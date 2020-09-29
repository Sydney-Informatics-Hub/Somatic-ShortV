# Somatic-ShortV

The scripts in this repository call somatic short variants (SNPs and indels) from BAM files following [GATK's Best Practices Workflow](https://gatk.broadinstitute.org/hc/en-us/articles/360035894731-Somatic-short-variant-discovery-SNVs-Indels-). The workflow and scripts have been specifically optimised to run efficiently and at scale on the __National Compute Infrastructure, Gadi.__

<img src="https://user-images.githubusercontent.com/49257820/94503907-ebb0cc80-024a-11eb-800c-41854b1f041c.png" width="110%" height="110%">

# Set up

## GRCh38/hg38 + ALT contigs

The Somatic-ShortV pipeline works seamlessly with the [Fastq-to-BAM](https://github.com/Sydney-Informatics-Hub/Fastq-to-BAM) pipeline. The scripts use relative paths, so correct set-up is important. 

Upon completion of [Fastq-to-BAM](https://github.com/Sydney-Informatics-Hub/Fastq-to-BAM):

1. Change to the working directory where your final bams were created.
* ensure you have a `<cohort>.config` file, that is a tab-delimited file including `#SampleID	LabSampleID	SeqCentre	Library(default=1)` (the same config or a subset of samples from the config used in [Fastq-to-BAM](https://github.com/Sydney-Informatics-Hub/Fastq-to-BAM) is perfect). Sample GVCFs and multi-sample VCFs will be created for samples included in <cohort>.config. Sample ID's must end in -B or -N (this is to denote that they are normal, not tumour samples). 
* ensure you have a `Final_bams` directory, containing `<labsampleid>.final.bam` and `<labsampleid>.final.bai` files. <labsampleid> should match LabSampleID column in your `<cohort>.config` file.
 * ensure you have `References` directory from [Fastq-to-BAM](https://github.com/Sydney-Informatics-Hub/Fastq-to-BAM). This contains input data required for Germline-ShortV (ordered and pre-definted intervals, known variants for variant quality score recalibration).
2. Clone this respository by `git clone https://github.com/Sydney-Informatics-Hub/Germline-ShortV.git`

Your high level directory structure should resemble the following:

```bash
├── Fastq
├── Fastq_to_BAM_job_logs
├── Fastq_to_BAM_program_logs
├── Fastq_to_BAM_scripts_and_inputs
├── Final_bams
├── samples.config
├── Reference
└── Somatic-ShortV
```

`Somatic-ShortV` will be your working directory.

# Running the pipeline

The following will perform somatic short variant calling for all samples present in `../<cohort>.config`. Once you're set up (see the guide above), change into the `Somatic-ShortV` directory after cloning this repository. The scripts use relative paths and the `Somatic-ShortV` is your working directory. Adjust compute resources requested in the `.pbs` files using the guide provided in each of the parallel scripts. This will often be according to the number of samples in `../<cohort>.config`.

1. Start panel of normals (PoN) creation by running Mutect2 on normal samples. The scripts below run Mutect2 in tumour only mode for the normal samples. Normal samples are ideally samples sequenced on the same platform and chemistry (library kit) as tumour samples. These are used to filter sequencing artefacts (polymerase slippage occurs pretty much at the same genomic loci for short read sequencing technologies) as well as germline variants. Read more about [PoN on GATK's website](https://gatk.broadinstitute.org/hc/en-us/articles/360035890631-Panel-of-Normals-PON-)

* `sh gatk4_pon_make_input.sh <cohort>`
* `qsub gatk4_pon_run_parallel.pbs` after adjusting <project> and compute resource requests to suit your cohort. 
  
2. Check log files in step 1 for errors, collect duration per task and archive log files if the job was successful:

* `nohup sh gatk4_pon_check_sample_parallel.sh samples 2> /dev/null &`

# References

GATK 4: Van der Auwera et al. 2013 https://currentprotocols.onlinelibrary.wiley.com/doi/abs/10.1002/0471250953.bi1110s43

OpenMPI: Graham et al. 2015 https://dl.acm.org/doi/10.1007/11752578_29
