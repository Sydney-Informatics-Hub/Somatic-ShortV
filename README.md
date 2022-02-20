# Somatic-ShortV

The scripts in this repository call somatic short variants (SNPs and indels) from tumour and matched normal BAM files following [GATK's Best Practices Workflow](https://gatk.broadinstitute.org/hc/en-us/articles/360035894731-Somatic-short-variant-discovery-SNVs-Indels-). The workflow and scripts have been specifically optimised to run efficiently and at scale on the __National Compute Infrastructure, Gadi.__

<img src="https://user-images.githubusercontent.com/49257820/94503907-ebb0cc80-024a-11eb-800c-41854b1f041c.png" width="110%" height="110%">

### Features of this pipeline

* High compute efficiency
* Scalable through scatter-gather parallelism with `openmpi` and `nci.parallel`
* Checker scripts (no KSU cost)
* Checkpointing and resumption of only failed tasks if required
* Support: this repository is actively monitored

### Reference genome: GRCh38/hg38 + ALT contigs

By default, this pipeline is compatible with BAMs aligned to the __GRCh38/hg38 + ALT contigs reference__ genome. Scatter-gather parallelism has been designed to operate over 3,200 evenly sized genomic intervals (~1Mb in size) across your sample cohort. Some [genomic intervals are excluded](#excluded-sites) - these typically include repetitive regions which can significantly impede on compute performance. 

#### Excluded sites

Excluded sites are listed in the Delly group's [sv_repeat_telomere_centromere.bed](https://gist.github.com/chapmanb/4c40f961b3ac0a4a22fd) file. This is included in the `Reference` dataset. The BED file contains:

* telemeres
* centromeres
* chrUn (unplaced)
* chrUn_XXXXX_decoy (decoy)
* chrN_XXXXX_random (unlocalized)
* chrEBV

# Set up

This pipeline can be implemented after running the [Fastq-to-BAM](https://github.com/Sydney-Informatics-Hub/Fastq-to-BAM) pipeline. The scripts use relative paths, so correct set-up is important. 

The minimum requirements and high level directory structure resemble the following:

```bash
├── Final_bams
├── <cohort>.config
├── Reference
└── Somatic-ShortV 
```

__Output will be created at this directory level. Submit jobs within the `Somatic-ShortV` directory__

#### 1. Clone this respository 

In your high level directory `git clone https://github.com/Sydney-Informatics-Hub/Somatic-ShortV.git`. `Somatic-ShortV` contains the scripts of the workflow. Submit all jobs within `Somatic-ShortV`.

#### 2. Tool dependances

The tools required to run this pipeline include:

* `openmpi/4.1.0`
* `nci-parallel/1.0.0a`
* GATK4. The pipeline is compatible with versions: `gatk/4.1.2.0`,`gatk/4.1.8.1`. It has not been tested with other versions of GATK4. 

Use `module avail` to check if they are currently globally installed.

If you have used [Fastq-to-BAM](https://github.com/Sydney-Informatics-Hub/Fastq-to-BAM) pipeline, you can skip the remaining set up steps.

#### 3. Prepare your `<cohort>.config` file

The steps in this pipeline operate on samples present in your `<cohort>.config` file.

* [See here](https://github.com/Sydney-Informatics-Hub/Fastq-to-BAM/blob/fastq-to-bam-v2/README.md#1-prepare-your-cohortconfig-file) for a full description
* `<cohort>.config` is a TSV file with one row per unique sample, matching the format in the example below. Start header lines with `#`
* LabSampleID's are your in-house sample IDs. Input and output files are named with this ID.
  * Normal samples should be named `<patientID>-N<normalID>`
  * Matched tumour samples should be named `<patientID>-T<tumourID>`. Multiple tumour samples are OK. Only `<patientID>-T<tumourID>`, `<patientID>-M<tumourID>`, `<patientID>-P<tumourID>` extensions are recognised.
  * `<patientID>` is used to find normal and tumour samples belonging to a single patient

The below is an example `<cohort>.config` with two patient samples. Patient 1 has 2 matched tumour samples.

|#SampleID|LabSampleID|Seq_centre|Library(default=1)|
|---------|-----------|----------|------------------|
|SAMPLE1  |PATIENT1-N    |AGRF      |                  |
|SAMPLE2  |PATIENT1-T1    |AGRF      |                  |
|SAMPLE3  |PATIENT1-T2    |AGRF      |                  |
|SAMPLE4  |PATIENT2-N    |AGRF      |                  |
|SAMPLE5  |PATIENT2-T    |AGRF      |                  |

#### 4. Prepare your BAM files

* BAM files should be at the sample level
* BAM and BAI (index) filenames should follow:
  * `<patientID>-N<ID>.final.bam` for normal samples
  * `<patientID>-T<tumourID>.final.bam` for tumour samples

#### 5. Download the `Reference` directory

Ensure you have `Reference` directory from [Fastq-to-BAM](https://github.com/Sydney-Informatics-Hub/Fastq-to-BAM/blob/fastq-to-bam-v2/README.md#3-prepare-the-reference-genome). This contains input data required for Somatic-ShortV. 

The reference used includes __Human genome: hg38 + alternate contigs__ and a list of __scatter interval files__ for scatter-gather parallelism. 

# User guide

This pipeline will perform [GATK4's Somatic Short Variant Discovery](https://gatk.broadinstitute.org/hc/en-us/articles/360035894731-Somatic-short-variant-discovery-SNVs-Indels-) (SNVs and Indels) best practices workflows for all samples present in `<cohort>.config`. 

__Adding new samples to a cohort for PoN__: If you have sequenced new samples belonging to a cohort that was previously sequenced and wish to re-create PoN with all samples, you can skip some of the processing steps for the previously sequenced samples. If you would like to do this:

  * Please create a config file containing the new samples only and process these from step 1. 
  * Follow optional steps from step 5 onwards if you would like to consolidate the new samples with previously processed samples.

## General structure

Each step in the pipeline generally includes:

* A script to create an input file, where 1 line of input = 1 scatter task
* A "run_parallel.pbs" script, the job you submit to run "task.sh" for each input created
* A checker script and if required, an additional script to re-submit failed jobs
* The checker scripts tar archive log files if checks have passed 
* Job logs written to `./Logs` and task logs written to `./Logs/<jobname>`

By default, compute resources are optimal for processing 40 normal (35X) and 40 matched tumour (70X) samples. See [benchmarking metrics](#-Benchmarking-metrics) for additional guidance with compute resource requests.

## Create the Panel of Normals

__! Submit all jobs from the `Somatic-ShortV` directory__

### 1. Scatter and create PoN across genomic intervals

The scripts below run Mutect2 in tumour only mode for the normal samples to create `sample.pon.index.vcf`, `sample.pon.index.vcf.idx` and `sample.pon.index.vcf.stats`. By default, this job scatters the task into 3,200 genomic intervals per sample (index is a number given to a unique interval). Normal samples are ideally samples sequenced on the same platform and chemistry (library kit) as tumour samples. These are used to filter sequencing artefacts (polymerase slippage occurs pretty much at the same genomic loci for short read sequencing technologies) as well as germline variants. Read more about [PoN on GATK's website](https://gatk.broadinstitute.org/hc/en-us/articles/360035890631-Panel-of-Normals-PON-)

Create task inputs: 

```
sh gatk4_pon_make_input.sh /path/to/cohort.config
```

Edit and run the script below to scatter task inputs for parallel processing. Adjust <project> and compute resource requests to suit your cohort, then:

```
qsub gatk4_pon_run_parallel.pbs
```
#### Perform checks 

The next script checks that tasks for the previous job have completed successfully. Inputs for failed tasks are written to `gatk_pon_missing.inputs` for re-submission. Checks include: `sample.pon.index.vcf`, `sample.pon.index.vcf.idx` and `sample.pon.index.vcf.stats` files exist and are non-empty; GATK logs are checked for "SUCCESS" or "error" messages.

The checker script can be run on the login node. I advise using the `nohup` command to run this script so that the script runs without being killed. 
 
Replace  `/path/to/cohort.config` with your `cohort.config` file and run:
 
```
nohup sh gatk4_pon_check_sample_parallel.sh /path/to/cohort.config 2> /dev/null 1> ./Logs/gatk4_pon_check.log &
```
 
Check the output by `cat ./Logs/gatk_pon_check.log` to see if the job was successful. If there are no failed tasks, move to [2. Gather interval VCFs into sample level VCFs](#2-gather-interval-vcfs-into-sample-level-vcfs)
 
#### Re-running failed gatk4_pon.sh tasks
 
If there are tasks to re-run from step 1 (check number of tasks to re-run using `wc -l Inputs/gatk4_pon_missing.inputs`), re-run the failed tasks. After adjusting <project> and compute resource requests (usually one node normal node is sufficient for ~3200 tasks) in `gatk4_pon_missing_run_parallel.pbs`, submit the job by:
 
```
qsub gatk4_pon_missing_run_parallel.pbs
```

The steps under "Perform checks" above can be repeated until all tasks pass checks.
 
#### gatk4_pon passes checks
 
If all checks pass, the checker script prints task duration and memory per task (genomic interval) to `./Logs/gatk4_pon/sample`. Each sample log directory is archived into `.Logs/gatk4_pon/sample_logs.tar.gz`. Tar archives reduce iNode quota.

### 2. Gather interval VCFs into sample level VCFs
 
Gather interval `sample.pon.index.vcf`, `sample.pon.index.vcf.idx` into single sample, gzipped VCFs. `sample.pon.vcf.gz` and `sample.pon.vcf.gz.tbi` are wrtten to `../cohort_PoN`

Create inputs (1 sample per task, an arguments file is created per sample). This can actually take a while and I recommend using nohup if you have > 200 samples.
 
```
sh gatk4_pon_gathervcfs_make_input.sh /path/to/cohort.config
```         

Or with nohup (output is written to `nohup.out`):

```
nohup gatk4_pon_gathervcfs_make_input.sh /path/to/cohort.config 2>&1 &
``` 

Edit and run the script below to scatter task inputs for parallel processing. Adjust <project> and compute resource requests to suit your cohort, then:

```
qsub gatk4_pon_gathervcfs_run_parallel.pbs
```

#### Perform checks
 
The next script checks that tasks for the previous job have completed successfully. Inputs for failed tasks are written to `./Inputs/gatk_pon_gathervcfs_missing.inputs` for re-submission. The script checks `sample.pon.vcf.gz` and `sample.pon.vcf.gz.tbi` files are present and not empty in `./cohort_PoN`. Log files are checked for errors.

Run this script on the login node (quick):
 
```
sh gatk4_pon_gathervcfs_check.sh /path/to/cohort.config
```         

If all tasks are successful, we recommend backing up `sample.pon.vcf.gz` and `sample.pon.vcf.gz.tbi` to long term storage and continuing to [3. Consolidate samples with GenomicsDBImport](#3-consolidate-samples-with-genomicsdbimport).
 
#### Re-running failed gatk4_pon_gathervcfs.sh tasks
 
Check the number of tasks to re-run using `wc -l ./Inputs/gatk4_pon_gathervcfs_missing.inputs`. Adjust <project> and compute resource requests in `gatk4_pon_gathervcfs_missing_run_parallel.pbs` then run it:

```   
qsub gatk4_pon_gathervcfs_missing_run_parallel.pbs
```

Perform checks and re-run failed tasks until all tasks have completed successfully. 
 
### 3. Consolidate samples with GenomicsDBImport
 
The downstream analysis are performed across multiple samples and sample data is first consolidated with GenomicsDBImport. By default, this occurs at 3,200 genomic intervals. If you are processing a new cohort, start at [Consolidate PoN](#consolidate-pon).

#### Including previously analysed samples

To create a new PoN to include previously processed sample data (e.g. when you want to combine previously processed samples with newly sequenced samples), perform the additional steps in below, __otherwise skip this step__. 
 
Downstream steps require:
 
* A `cohort.config` file
* The directory `../cohort_PoN` containing `sample.pon.vcf.gz`, `sample.pon.vcf.gz.tbi` for each sample in `cohort.config`
 
These can be created with some simple commands, copying data or using symbolic links. The example below shows how this can be done if you used this pipeline to analyse a separate cohort:
 
```bash
├── Final_bams
├── samplesSet1.config # Previously analysed cohort
├── samplesSet2.config # Currently analysed cohort
├── samplesSet1andSet2.config # Joined cohort - this needs to be created
├── samplesSet1_PoN # Previously analysed cohort
├── samplesSet2_PoN # Currently analysed cohort
├── samplesSet1andSet2_PoN # Joined cohort - this needs to be created
├── Reference
└── Somatic-ShortV
```
         
Concatenate the config files of the previously sequenced samples (e.g. in `samplesSet1.config`) and newly sequenced samples (e.g. in `samplesSet2.config`) into a new config file (e.g. in `samplesSet1andSet2.config`) by:
 
```
sh concat_configs.sh samplesSet1andSet2.config samplesSet1.config samplesSet2.config
```                      
Create symbolic links for `sample.pon.vcf.gz`, `sample.pon.vcf.gz.tbi` into `../samplesSet1andSet2_PoN` using this script:

```
sh setup_pon_from_concat_config.sh samplesSet1andSet2.config
```
 
#### Consolidate PoN
 
Create inputs:
 
```
sh gatk4_pon_genomicsdbimport_make_input.sh /path/to/cohort.config
```
 
Edit and run the script below to scatter task inputs for parallel processing. Adjust <project> and compute resource requests to suit your cohort (this job scales to cohort size with memory), then:
 
```   
qsub gatk4_pon_genomicsdbimport_run_parallel.pbs
```

#### Perform checks
         
Check the job when it's complete by: 
      
```
nohup sh gatk4_pon_genomicsdbimport_check.sh /path/to/cohort.config 2> /dev/null 1> ./Logs/gatk4_pon_genomicsdbimport.log &
```
 
This takes a couple of minutes. Check the `./Logs/gatk4_pon_genomicsdbimport.log` file. If all tasks were successful, continue to [4. Create PoN per genomic interval](#4-create-pon-per-genomic-interval).
 
#### Re-run failed tasks

Check the number of tasks to re-run using `wc -l ./Inputs/gatk4_pon_genomicsdbimport_missing.inputs`. Adjust <project> and compute resource requests in `gatk4_pon_genomicsdbimport_missing_run_parallel.pbs` then run it:

```
qsub gatk4_pon_genomicsdbimport_missing_run_parallel.pbs
```
Perform check and re-run failed tasks until all tasks have completed successfully. 
 
### 4. Create PoN per genomic interval

Here, hg38 gnomAD are used as a germline resource by default (`af-only-gnomad.hg38.vcf.gz` obtained from [GATK's Google Cloud Resource Bucket](https://console.cloud.google.com/storage/browser/gatk-best-practices/somatic-hg38;tab=objects?pli=1&prefix=&forceOnObjectsSortingFiltering=false). You may wish to change this by specifying the resource you wish to use in the `gatk4_cohort_pon_make_input.sh` file at `germline=`

Create inputs: 

```
sh gatk4_cohort_pon_make_input.sh /path/to/cohort.config
```

Edit and run the script below to scatter task inputs for parallel processing. Adjust <project> and compute resource requests to suit your cohort, then:

```
qsub gatk4_cohort_pon_run_parallel.pbs
```
       
#### Perform checks

Check that each task for `gatk4_cohort_pon_run_parallel.pbs` ran successfully. This script checks that there is a non-empty VCF and TBI file for all genomic intervals that the job operated on and that there were no error messages in the log files. The script runs collects duration and memory used per task or genomic interval and then cleans up by gzip tar archiving log files. Run:

```
sh gatk4_cohort_pon_check.sh /path/to/cohort.config
```
 
If there are no failed tasks, move on to [5. Gather intervals and sort into a single, multisample PoN](#5-gather-intervals-and-sort-into-a-single-multisample-pon).
 
#### Re-run failed tasks

Check the number of tasks to re-run using `wc -l ./Inputs/gatk4_cohort_pon_missing.inputs`. Adjust <project> and compute resource requests in the script below, then submit the job:
 
```
qsub gatk4_cohort_pon_missing_run_parallel.pbs
```

### 5. Gather intervals and sort into a single, multisample PoN
 
Gather and sort interval cohort PoN to a single VCFs into a single, multisample sorted and indexed PoN VCF. This job performs these commands as a single task.
 
Set the config variable and submit the job:

```
qsub gatk4_cohort_pon_gather_sort.pbs
```
 
#### Perform checks

```
sh gatk4_cohort_pon_gather_sort_check.sh
```
 
Errors should be investigated before re-running `gatk4_cohort_pon_gather_sort.pbs`.
 
This is the last step for a creating a panel of normals and you should now have the following outputs for your `<cohort>.config` file:

* `../<cohort>_cohort_PoN/<cohort>.sorted.pon.vcf.gz`
* `../<cohort>_cohort_PoN/<cohort>.sorted.pon.vcf.gz.tbi`
       
## Variant calling with Mutect2

Once you have completed creating your panel of normals, you may begin calling somatic variants with Mutect2 in tumour-matched normal mode. Variants are filtered downstream. Variants will be called for each unique tumour-normal pair (i.e. if you have 3 tumour samples matching 1 normal sample, 3 VCF files for each pair will be produced if LabSampleID's follow Set up guide)

### 1. Scatter Mutect2 tasks

For each unique tumour-normal pair in `<cohort>.config`, write inputs for scattering Mutect2 over 3,201 for genomic intervals. One tasks processes the mitochondial chromosome, for those who wish to perform mitochondial analysis.

```
sh gatk4_mutect2_make_input.sh /path/to/cohort.config
```
 
Edit and run the script below to scatter task inputs for parallel processing. Adjust <project> and compute resource requests to suit your cohort. 
 
 __Note__: We recommend setting the walltime limit low (scale compute to 2 - 4 normal nodes per pair, leaving walltime=02:00:00). Whilst we've implemented strategies to avoid tasks this situation, occassionally a spurious sample pair can have a task that "hangs" (happens about ~1 task/50 pairs). This causes idle CPUs at the tail end of the job. These spurious tasks can be found and re-run when checks are performed in a separate job. 

``` 
qsub gatk4_mutect2_run_parallel.pbs
```

Outputs for each unique tumour normal pair (index is the interval id or chrM):
 
* `<patient>-T<ID>_<patient>-N<ID>.unfiltered.<index>.vcf.gz`
* `<patient>-T<ID>_<patient>-N<ID>.unfiltered.<index>.vcf.gz.tbi`
* `<patient>-T<ID>_<patient>-N<ID>.unfiltered.<index>.vcf.gz.stats`
* `<patient>-T<ID>_<patient>-N<ID>.f1r2.<index>.tar.gz`
  
#### Perform checks

The script below checks that the expected output files are preset. Log files are checked for "SUCCESS" or error messages. The script takes ~30 seconds/40 tumour-normal pairs. We recommend using `nohup` if you have a large number of pairs.  

```
sh gatk4_mutect2_check_pair_parallel.sh /path/to/cohort.config
````
Check output or `Inputs/gatk4_mutect2_missing.inputs` for failed tasks. 

#### Re-run failed tasks

If there are tasks to re-run, adjust <project> and compute resource requests in `gatk4_mutect2_missing_run_parallel.pbs`, then submit your job by:

``` 
qsub gatk4_mutect2_missing_run_parallel.pbs
```

### 2. Gather Mutect2 VCFs

Gather the unfiltered Mutect2 interval outputs for each tumour normal pair. Create inputs by:

```
sh gatk4_mutect2_gathervcfs_make_input.sh /path/to/cohort.config
```

Adjust <project> and compute resource requests in `gatk4_mutect2_gathervcfs_run_parallel.pbs`, then submit your job by:

```
qsub gatk4_mutect2_gathervcfs_run_parallel.pbs
```

For each tumour normal pair in your `cohort.config` file, you will now have:

* `../Mutect2/<patient>-T<ID>_<patient>-N<ID>/<patient>-T<ID>_<patient>-N<ID>.unfiltered.vcf.gz`
* `../Mutect2/<patient>-T<ID>_<patient>-N<ID>/<patient>-T<ID>_<patient>-N<ID>.unfiltered.vcf.gz.tbi`

You will also have input files for the filtering steps, including:

* Per interval `.stats` files for `MergeMutectStats`
* Per interval `f1r2` files for `LearnReadOrientationModel`

## Prepare for filtering 

The following jobs prepare input files for the last part of the Somatic-ShortV pipeline, `FilterMutectCalls`. There are three parts and each of these can be run concurrently:

* `MergeMutectStats`
* `LearnReadOrientationModel`
* `GetPileupSummaries` and `CalculaterContamination`

### 1. MergeMutectStats

After variant calling with Mutect2, `stats` files are created for each interval. Gather these into tumour-normal pair `stats` file. Stats files contain the number of callable sites, (by default the callable depth is 10). 

Create inputs by:

```
sh gatk4_mergemutectstats_make_input.sh /path/to/cohort.config
```
Adjust <project> and compute resource requests in `gatk4_mergemutectstats_run_parallel.pbs`, then submit your job by:

```
qsub gatk4_mergemutectstats_run_parallel.pbs
```    

For each tumour-normal pair in your `cohort.config` file, you will now have: 

* `../Mutect2/<patient>-T<ID>_<patient>-N<ID>/<patient>-T<ID>_<patient>-N<ID>.unfiltered.vcf.gz.stats`

### 2. LearnReadOrientationModel

This step aims to remove substitution error bias on a single strand. This applies to FFPE tumour samples and samples sequenced on Illumina Novaseq machines. It is recommended to run this, even if your samples/sequencing machines are not prone to orientation bias. 

Create a job input file and arguments file for each tumour normal pair (containining f1r2 genomic interval files for the pair created from Mutect2) by:

```
sh gatk4_learnreadorientationmodel_make_input.sh /path/to/cohort.config
```

Adjust <project> and compute resource requests in `gatk4_learnreadorientationmodel_run_parallel.pbs`, then submit your job by:

```  
qsub gatk4_learnreadorientationmodel_run_parallel.pbs
```
----------
 
#### Perform checks

Check that LearnReadOrientationModel ran successfully for each tumour-normal pair. The log files are checked for `SUCCESS` and `error` messages and that the expected output file  `../Mutect2/TumourID_NormalID/TumourID_NormalID_read-orientation-model.tar.gz` exists and is not empty. Create inputs by:

```
sh gatk4_learnreadorientationmodel_check.sh /path/to/cohort.config
```        
For each tumour-normal pair in your `cohort.config` file, you will now have:

* `../Mutect2/<patient>-T<ID>_<patient>-N<ID>/<patient>-T<ID>_<patient>-N<ID>_read-orientation-model.tar.gz`

### GetPileupSummaries & CalculateContamination

With the assumption that known germline variant sites are biallelic, any site that presents multiple variant alleles suggests possible sample contamination.

`GetPileupSummaries` uses a sample BAM file and a __germline resource containing common biallelic variants__. This tabulates pileup metrics for `CalculateContamination`, summarizing the counts of reads that support the reference, alternate and other alleles. 

__Germline resources__

The `../Reference` directory downloadable and described in [Fastq-to-BAM](https://github.com/Sydney-Informatics-Hub/Fastq-to-BAM) contains two germline resources that can be used for `GetPileupSummaries`:

* Common biallelic variants from the ExAC dataset (containing 60,706 exomes), lifted to the hg38 reference genome in `../Reference/gatk-best-practices/somatic-hg38/small_exac_common_3.hg38.vcf.gz`
* Common biallelic variants from gnomAD (76,156 whole genomes) mapped to hg38 in `../Reference/gatk-best-practices/somatic-hg38/af-only-gnomad.common_biallelic.hg38.vcf.gz`. This was created using the optional `SelectVariants` tool in the `gatk4_selectvariants.pbs` script. 

Optionally, you can generate your own common biallelic variant resource.
 
### 0. Optional: Create common biallelic variant resources
 
`gatk4_selectvariants.pbs` takes your public resource VCF, and selects common biallelic SNP variants (by default, those with an allele frequency of > 0.05).
  
In the `gatk4_selectvariants.pbs` script, replace `<>` with your resource for `resource=<path/to/public_dataset.vcf.gz>` and output file `resource_common=</path/to/output_public_dataset_common_biallelic.vcf.gz>`. Adjust your <project> and compute resources, then submit your job by:

```
qsub gatk4_selectvariants.pbs
```

### 1. GetPileupSummaries
 
With your common biallelic germline resource, run `GetPileupSummaries` for all samples in your `cohort.config` file. 

The default germline resource used is `af-only-gnomad.common_biallelic.hg38.vcf.gz`. If you would like to change this resource, set `common_biallelic` variable to the path to your chosen resource.
 
Then create inputs by:
        
```
sh gatk4_getpileupsummaries_make_input.sh /path/to/cohort.config
```
   
Adjust <project> and compute resource requests in `gatk4_getpileupsummaries_run_parallel.pbs`, then submit your job by:

```
qsub gatk4_getpileupsummaries_run_parallel.pbs     
```
#### Perform checks 
 
`GetPileupSummaries` task log files are checked for `SUCCESS` and `error` messages. The script also checks that the expected output `<cohort>_GetPileupSummaries/samples_pileups.table` exists and it not empty. 

First, edit the common_biallelic variable in gatk4_getpileupsummaries_check.sh so that it is consistent with what you used in step 15. Then:

```
sh gatk4_getpileupsummaries_check.sh /path/to/cohort.config
```         

The script will print the number of successful and unsuccessful tasks to the terminal. Failed tasks will be written to `Inputs/gatk4_getpileupsummaries_missing.inputs`. If there are failed tasks to re-run, adjust <project> and compute resource requests in `gatk4_getpileupsummaries_missing_run_parallel.pbs`, then submit your job by:

```
qsub gatk4_getpileupsummaries_missing_run_parallel.pbs
```

### 2. Calculate contamination
 
Calculate the fraction of reads coming from cross sample contamination using `CalculateContamination` using pileups tables from `GetPileupSummaries` as inputs. The resulting contamination table is used in `FilterMutectCalls`. Create inputs by:

```
sh gatk4_calculatecontamination_make_input.sh /path/to/cohort.config
```

## FilterMutectCalls   

You are finally ready to obtain a filtered set of somatic variants using `FilterMutectCalls`. You will need the inputs from the previous steps, including:

* `<patient>-T<ID>_<patient>-N<ID>.unfiltered.vcf.gz` (from Mutect2, using PoN)
* `<patient>-T<ID>_<patient>-N<ID>.unfiltered.vcf.gz.stats` (from Mutect2, genomic intervals gathered into a single stats file with `MergeMutectStats`)
* `tumor_segments.table` (from GetPileupSummaries & CalculateContamination)
* `<patient>-T<ID>_<patient>-N<ID>_contamination.table` (from GetPileupSummaries & CalculateContamination)
* `<patient>-T<ID>_<patient>-N<ID>_read-orientation-model.tar.gz` (from Mutect2 & LearnReadOrientationModel)

1. Create input files for each task (`FilterMutectCalls` for a single tumour normal pair) by:

```
sh gatk4_filtermutectcalls_make_input.sh /path/to/cohort.config
```

Adjust <project> and compute resource requests in `gatk4_filtermutectcalls_run_parallel.pbs`, then submit your job by:

```
qsub gatk4_filtermutectcalls_run_parallel.pbs             
```
 
# Benchmarking metrics
 
 The following benchmarks were obtained from processing 20 tumour-normal pairs (34X and 70X, human samples).  My apologies that the steps are not in order, I will amend this soon!
 
 | #JobName                        | CPUs_requested | CPUs_used | Mem_requested | Mem_used | CPUtime    | CPUtime_mins | Walltime_req | Walltime_used | Walltime_mins | JobFS_req | JobFS_used | Efficiency | Service_units(CPU_hours) |
|---------------------------------|----------------|-----------|---------------|----------|------------|--------------|--------------|---------------|---------------|-----------|------------|------------|--------------------------|
| gatk4_cohort_pon_144            | 144            | 144       | 4.39TB        | 110.13GB | 16:39:15   | 999.25       | 5:00:00      | 0:24:51       | 24.85         | 1.46GB    | 9.08MB     | 0.28       | 178.92                   |
| gatk4_cohort_pon_48             | 48             | 48        | 1.46TB        | 102.54GB | 17:26:26   | 1046.43      | 10:00:00     | 0:26:04       | 26.07         | 500.0MB   | 9.08MB     | 0.84       | 62.56                    |
| gatk4_cohort_pon_96             | 96             | 96        | 2.93TB        | 110.97GB | 17:07:23   | 1027.38      | 10:00:00     | 0:26:07       | 26.12         | 1000.0MB  | 9.07MB     | 0.41       | 125.36                   |
| gatk4_cohort_pon_gather_sort    | 1              | 1         | 18.0GB        | 4.28GB   | 0:02:18    | 2.3          | 1:00:00      | 0:03:15       | 3.25          | 100.0MB   | 0B         | 0.71       | 0.49                     |
| gatk4_getpileupsummaries_exac*   | 48             | 48        | 190GB        | 145.94GB   | 10:42:43     | 642.72         | 15:00:00     | 01:03:58       | 63.97         | 100.0MB   | 40.09MB     | 0.21       | 102.35                     |
| gatk4_mutect2_1920              | 1920           | 1920      | 7.5TB         | 6.61TB   | 1890:56:30 | 113456.5     | 4:00:00      | 1:07:04       | 67.07         | 3.91GB    | 32.77MB    | 0.88       | 4292.27                  |
| gatk4_mutect2_2880              | 2880           | 2880      | 11.25TB       | 9.81TB   | 1963:57:43 | 117837.72    | 2:00:00      | 0:48:33       | 48.55         | 5.86GB    | 33.38MB    | 0.84       | 4660.8                   |
| gatk4_mutect2_3840              | 3840           | 3840      | 15.0TB        | 13.07TB  | 2033:47:24 | 122027.4     | 2:00:00      | 0:39:04       | 39.07         | 7.81GB    | 32.77MB    | 0.81       | 5000.53                  |
| gatk4_mutect2_960               | 960            | 960       | 3.75TB        | 3.3TB    | 1865:51:58 | 111951.97    | 4:00:00      | 2:05:44       | 125.73        | 1.95GB    | 32.77MB    | 0.93       | 4023.47                  |
| gatk4_pon_1920                  | 1920           | 1920      | 7.5TB         | 6.39TB   | 1546:53:50 | 92813.83     | 2:00:00      | 0:50:06       | 50.1          | 3.91GB    | 21.23MB    | 0.96       | 3206.4                   |
| gatk4_pon_2880                  | 2880           | 2880      | 11.25TB       | 8.62TB   | 1601:44:32 | 96104.53     | 2:00:00      | 0:35:13       | 35.22         | 5.86GB    | 21.23MB    | 0.95       | 3380.8                   |
| gatk4_pon_3840                  | 3840           | 3840      | 15.0TB        | 11.36TB  | 1859:29:08 | 111569.13    | 2:00:00      | 0:31:43       | 31.72         | 7.81GB    | 21.23MB    | 0.92       | 4059.73                  |
| gatk4_pon_960                   | 960            | 960       | 3.75TB        | 3.27TB   | 1537:26:16 | 92246.27     | 2:00:00      | 1:38:03       | 98.05         | 1.95GB    | 21.1MB     | 0.98       | 3137.6                   |
| gatk4_pon_gathervcfs_20         | 20             | 20        | 640.0GB       | 42.43GB  | 1:04:42    | 64.7         | 2:00:00      | 1:44:51       | 104.85        | 500.0MB   | 8.09MB     | 0.03       | 104.85                   |
| gatk4_pon_genomicsdbimport_144  | 144            | 144       | 4.39TB        | 698.85GB | 22:28:42   | 1348.7       | 5:00:00      | 0:14:20       | 14.33         | 1.46GB    | 8.96MB     | 0.65       | 103.2                    |
| gatk4_pon_genomicsdbimport_48   | 48             | 48        | 1.46TB        | 314.08GB | 21:27:48   | 1287.8       | 10:00:00     | 0:30:33       | 30.55         | 500.0MB   | 8.95MB     | 0.88       | 73.32                    |
| gatk4_pon_genomicsdbimport_96   | 96             | 96        | 2.93TB        | 602.88GB | 21:48:05   | 1308.08      | 10:00:00     | 0:18:14       | 18.23         | 1000.0MB  | 8.95MB     | 0.75       | 87.52                    |

* gatk4_getpileupsummaries_exac was benchmarked with 80 tumour (~70X) and normal (~35X) paired samples, using `common_biallelic=../Reference/gatk-best-practices/somatic-hg38/small_exac_common_3.hg38.vcf.gz`. I recommend NOT using gnoMAD variants as a common biallelic resource as it requires extensive benchmarking to overcome Java "OutOfMemory" errors, specific to your sample and sample coverage. 
 
# Cite us to support us!
 
 Chew, T., Willet, C., Samaha, G., Menadue, B. J., Downton, M., Sun, Y., Kobayashi, R., & Sadsad, R. (2021). Somatic-ShortV (Version 1.0) [Computer software]. https://doi.org/10.48546/workflowhub.workflow.148.1
 
# Acknowledgements

Acknowledgements (and co-authorship, where appropriate) are an important way for us to demonstrate the value we bring to your research. Your research outcomes are vital for ongoing funding of the Sydney Informatics Hub and national compute facilities.

Suggested acknowledgements:

__NCI Gadi__

The authors acknowledge the technical assistance provided by the Sydney Informatics Hub, a Core Research Facility of the University of Sydney. This research/project was undertaken with the assistance of resources and services from the National Computational Infrastructure (NCI), which is supported by the Australian Government.

# References

GATK 4: Van der Auwera et al. 2013 https://currentprotocols.onlinelibrary.wiley.com/doi/abs/10.1002/0471250953.bi1110s43

OpenMPI: Graham et al. 2015 https://dl.acm.org/doi/10.1007/11752578_29
