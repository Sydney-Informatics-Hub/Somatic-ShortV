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

# User guide

The following will perform somatic short variant calling for all samples present in `/path/to/<cohort>.config`. Once you're set up (see the guide above), change into the `Somatic-ShortV` directory after cloning this repository. The scripts use relative paths and the `Somatic-ShortV` is your working directory. Adjust compute resources requested in the `.pbs` files using the guide provided in each of the parallel scripts. This will often be according to the number of samples in `/path/to/<cohort>.config`.

__Adding new samples to a cohort for PoN__: If you have sequenced new samples belonging to a cohort that was previously sequenced and wish to re-create PoN with all samples, you can skip some of the processing steps for the previously sequenced samples. If you would like to do this:

  * Please create a config file containing the new samples only and process these from step 1. 
  * Follow optional steps from step 5 onwards if you would like to consolidate the new samples with previously processed samples.

__18/03/21__ Please check Log directory paths in PBS scripts

## Create Panel of Normals

1. Start panel of normals (PoN) creation by running Mutect2 on each normal sample to create `sample.pon.vcf.gz` and `sample.pon.vcf.gz.tbi`. The scripts below run Mutect2 in tumour only mode for the normal samples. Normal samples are ideally samples sequenced on the same platform and chemistry (library kit) as tumour samples. These are used to filter sequencing artefacts (polymerase slippage occurs pretty much at the same genomic loci for short read sequencing technologies) as well as germline variants. Read more about [PoN on GATK's website](https://gatk.broadinstitute.org/hc/en-us/articles/360035890631-Panel-of-Normals-PON-)

         sh gatk4_pon_make_input.sh /path/to/cohort.config

   Adjust <project> and compute resource requests to suit your cohort, then:

         qsub gatk4_pon_run_parallel.pbs
  
2. Check all .vcf, .vcf.idx and .vcf.stats files exist and are non-empty for step 1. Checks each log file for "SUCCESS" or "error" messages printed by GATK. If there are any missing output files or log files contain "error" or no "SUCCESS" message, the script writes inputs to re-run to an input file (`gatk_pon_missing.inputs`). If all checks pass, the script prints task duration and memory per interval, then archives log files. If you are not using the Reference available on the [Fastq-to-BAM](https://github.com/Sydney-Informatics-Hub/Fastq-to-BAM), adjust inputs in `gatk4_pon_check_sample_run_parallel.sh`.
 
         nohup sh gatk4_pon_check_sample_parallel.sh /path/to/cohort.config 2> /dev/null &
         
    The checker script can be run on the login node and is quick. I advise using the `nohup` command to run this script so that the script runs without being killed. Things can get messy otherwise (especially if the script stops mid tar archiving)! Check `nohup.out` (appends stdout of nohup to file) to see if your job ran successfully:

        cat nohup.out
        
    If there are tasks to re-run from step 1 (check number of tasks to re-run using `wc -l Inputs/gatk4_pon_missing.inputs`), re-run the failed tasks. After adjusting <project> and compute resource requests (usually one node normal node is sufficient) in `gatk4_pon_missing_run_parallel.pbs`, submit the job by:
 
        qsub gatk4_pon_missing_run_parallel.pbs

3. Gather step 1 per interval PoN VCFs into a single zipped GVCFs per sample. `sample.pon.vcf.gz` and `sample.pon.vcf.gz.tbi` are wrtten to `./cohort_PoN`

         sh gatk4_pon_gathervcfs_make_input.sh /path/to/config
         
   Adjust <project> and compute resource requests to suit your cohort. 

         qsub gatk4_pon_gathervcfs_run_parallel.pbs
         
   __Recommended step__: Back up `sample.pon.g.vcf.gz` and `sample.pon.g.vcf.gz.tbi` to long term storage

4. Check pon gathervcfs from step 3. Checks `sample.pon.vcf.gz` and `sample.pon.vcf.gz.tbi` are present and not empty in `./cohort_PoN`. Checks for ERROR messages in log files. Cleans up by removing interval `pon.vcf` and `pon.vcf.tbi` files if all checks have passed. 

         sh gatk4_pon_gathervcfs_check.sh /path/to/cohort.config
         
    If there are failed samples, a missing input file will be written and you will need to follow the next step. Adjust <project> and compute resource requests in `gatk4_pon_gathervcfs_missing_run_parallel.pbs` then run it:
   
         qsub gatk4_pon_gathervcfs_missing_run_parallel.pbs

5. Consolidate PoN across genomic intervals with multiple samples using GenomicsDBImport. To create a new PoN with previously processed sample data (e.g. when you want to combine previously processed samples with newly sequenced samples), follow steps 5a and 5b. Otherwise, just follow 5b. 

      5a. Perform steps 1 - 4 for each cohort. If you have already processed data, you will only need to do this for the newly sequenced and aligned samples.
         
      Concatenate the config files of the previously sequenced samples (e.g. in `samplesSet1.config`) and newly sequenced samples (e.g. in `samplesSet2.config`) into a new config file (e.g. in `samplesSet1andSet2.config`) by:
         
         sh concat_configs.sh samplesSet1andSet2.config samplesSet1.config samplesSet2.config
                      
      Create a new PoN directory for `samplesSet1andSet2.config` by:

         sh setup_pon_from_concat_config.sh samplesSet1andSet2.config
            
      5b. Consolidate PoN into interval databases across multiple samples by:
      
      Adjusting <project> and compute resource requests in `gatk4_pon_genomicsdbimport_run_parallel.pbs`, then submit your job by:
   
         qsub gatk4_pon_genomicsdbimport_run_parallel.pbs
         
      Check the job when it's complete by: 
      
         nohup sh gatk4_pon_genomicsdbimport_check.sh /path/to/cohort.config 2> /dev/null &
         cat nohup.out

6. Create PoN per genomic interval. Here, hg38 gnomAD are used as a germline resource by default (`af-only-gnomad.hg38.vcf.gz` obtained from [GATK's Google Cloud Resource Bucket](https://console.cloud.google.com/storage/browser/gatk-best-practices/somatic-hg38;tab=objects?pli=1&prefix=&forceOnObjectsSortingFiltering=false). You may wish to change this by specifying the resource you wish to use in the `gatk4_cohort_pon_make_input.sh` file at `germline=`

       sh gatk4_cohort_pon_make_input.sh /path/to/cohort.config
       
    Adjust <project> and compute resource requests in `gatk4_cohort_pon_run_parallel.pbs`, then submit your job by:
 
       qsub gatk4_cohort_pon_run_parallel.pbs
       
7. Check that each task for `gatk4_cohort_pont_run_parallel.pbs` ran successfully. This script checks that there is a non-empty VCF and TBI file for all genomic intervals that the job operated on and that there were no error messages in the log files. The script runs collects duration and memory used per task or genomic interval and then cleans up by gzip tar archiving log files. Run:

       nohup sh gatk4_cohort_pon_check.sh ../samplesSet1andSet2.config 2> /dev/null &
       cat nohup.out     

8. Gather and sort interval cohort PoN to a single VCFs into a single, multisample sorted and indexed PoN VCF. First __edit the cohort=__ variable in the script, save, then submit your job:

       qsub gatk4_cohort_pon_gather_sort.pbs
       
This is the last step for creating a panel of normals and you should now have the following outputs for your `samples.config` file:

* `./samples_cohort_PoN/samplesSet1andSet2.sorted.pon.vcf.gz`
* `./samples_cohort_PoN/samplesSet1andSet2.sorted.pon.vcf.gz.tbi`
       
## Variant calling with Mutect2

Once you have completed creating your panel of normals, you may begin calling somatic variants with Mutect2 in tumour-matched normal mode. Mutect2 outputs f1r2 files used in `ReadOrientationArtefactsWorkflow` and stats files for `MergeMutectStats`, both outputs are later used in `FilterMutectCalls`. A few things to note:

* Variants will be called for each unique tumour-normal pair (i.e. if you have 3 normal samples matching 1 tumour sample. 3 VCF files for each pair will be produced)

9. Create inputs to run Mutect2 for tumour-normal pairs for genomic intervals in parallel by:

       sh gatk4_mutect2_make_input.sh /path/to/cohort.config
       
   Adjust <project> and compute resource requests in `gatk4_mutect2_run_parallel.pbs`, then submit your job by:
 
       qsub gatk4_mutect2_run_parallel.pbs

10. Check that Mutect2 ran successfully in the previous step. This checks that the expected output files are preset (`.vcf.gz`, `.vcf.gz.tbi`, `.vcf.gz.stats`,`f1f2.interval.tar.gz` for each tumour normal pair). This also checks for the presence of SUCCESS and error messages in the log files. 
   
        nohup sh gatk4_mutect2_check_pair_parallel.sh /path/to/cohort.config 2> /dev/null &
        cat nohup.out

   If there are tasks to re-run (check number of tasks to re-run using `wc -l Inputs/gatk4_mutect2_missing.inputs` or `cat nohup.out`), re-run the failed tasks. 
   
   Adjust <project> and compute resource requests in `gatk4_mutect2_missing_run_parallel.pbs`, then submit your job by:
 
      qsub gatk4_mutect2_missing_run_parallel.pbs
   


More to come...

# References

GATK 4: Van der Auwera et al. 2013 https://currentprotocols.onlinelibrary.wiley.com/doi/abs/10.1002/0471250953.bi1110s43

OpenMPI: Graham et al. 2015 https://dl.acm.org/doi/10.1007/11752578_29
