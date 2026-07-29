---
name: GATK
description: "Variant Discovery in High-Throughput Sequencing Data"
metadata:
  openclaw:
    emoji: "🧬"
    requires:
      bins: ["docker"]
    install:
      - id: apt
        kind: apt
        package: podman-docker
        bins: ["podman", "docker"]
        label: "Install Docker"
---

# GATK - Genome Analysis Toolkit Skill 

This skill is a genomic analysis toolkit focused on variant discovery. It is the industry standard for identifying SNPs and indels in germline DNA and RNAseq data. Its scope is now expanding to include somatic short variant calling, and to tackle copy number (CNV) and structural variation (SV). In addition to the variant callers themselves, the GATK also includes many utilities to perform related tasks such as processing and quality control of high-throughput sequencing data, and bundles the popular Picard toolkit.

These tools were primarily designed to process exomes and whole genomes generated with Illumina sequencing technology, but they can be adapted to handle a variety of other technologies and experimental designs. And although it was originally developed for human genetics, the GATK has since evolved to handle genome data from any organism, with any level of ploidy.

## When This Skill Is Used

Use this workflow when you have:
- 4 files: one FASTA file, its corresponding FASTA index file,  one mapped BAM files, and its corresponding index file
- Optional files: VCF's- reference annotation databases and gold-standard training sets
This approach is **not** suitable for:
- Pairwise assignment tasks

## Input Types

- **Reference FASTA** — reference FASTA file (`.fasta` or `.fa`).
- **Reference FASTA index** — reference FASTA file index (`.fai`).
- **Mapped BAM** — reference FASTA file (`.bam`).
- **Mapped BAM index** — reference FASTA file index (`.bai`).
- **Optional VCFs**- Optional VCF's for reference (`.vcf`)
## Universal Input Validation Steps

- Before running any workflow, perform the following general steps:

a. **Extract variables from the user prompt:**
  - `<REFERENCE_VCFS>`: The input filenames provided by the user, e.g. variants/1000g_gold_standard.indels.filtered.vcf variants/GCF.38.filtered.renamed.vcf.
  - `<INTERVALS>`: The intervals provided by the user, e.g. chr20:10018000-10220000

b. **Validate arguments and fill missing inputs:**
  - If any required file parameters are missing from the user request, prompt the user for them before executing the command.

c. **Determine optional flags based on user request:**
   - Append any requested optional parameters from **Additional Useful Parameters**.
---

## Workflow

### Step 1: Generate necessary files

**Warning: GATK requires all input files and indexes to share identical sequence dictionaries. The FASTA reference, BAM, and VCF files must have matching contig names (@sq SN:) and lengths (LN:). If contig lengths differ, tools like BaseRecalibrator and HaplotypeCaller will fail with "incompatible contigs" errors. In general, for the human genome there are three types of chromosome names**

#### Step 1a: Generate FASTA sequence dictionary file
```bash
docker run --rm -v $(pwd):/ftmp -w /ftmp dnalinux/gatk \
  gatk \
  CreateSequenceDictionary \
  --REFERENCE reference.fasta \
  --OUTPUT ref.dict
```

- `--REFERENCE`: Specify the name of reference fasta or fasta.gz file
- `--OUTPUT`: Output SAM file containing only the sequence dictionary. By default it will use the base name of the input reference with the .dict extension

#### Step 1b: Generate indices for VCF's. 

- Skip this step if no <REFERENCE_VCFS> were provided
- Do it separately for each respective VCF.

```bash
docker run --rm -v $(pwd):/ftmp -w /ftmp dnalinux/gatk \
  gatk \
  IndexFeatureFile \
  -I <REFERENCE_VCFS>
``` 

- `-I`: Feature file (eg., VCF or BED file) to index. Must be in a tribble-supported formats


**Example: With 2 VCF's in <REFERENCE_VCFS>**
- Do not run, example only

```bash
docker run --rm -v $(pwd):/ftmp -w /ftmp dnalinux/gatk \
  gatk \
  IndexFeatureFile \
  -I variants/1000g_gold_standard.indels.filtered.vcf
```
```bash
docker run --rm -v $(pwd):/ftmp -w /ftmp dnalinux/gatk \
  gatk \
  IndexFeatureFile \
  -I variants/GCF.38.filtered.renamed.vcf
```

### Step 2: Mark Duplicates and Sort

**Warning:The tool is optimized to run on queryname-grouped alignments (that is, all reads with the same queryname are together in the input file). If provided coordinate-sorted alignments, the tool will spend additional time first queryname sorting the reads internally. This can result in the tool being up to 2x slower processing under some circumstances.**

```bash
docker run --rm -v $(pwd):/ftmp -w /ftmp dnalinux/gatk \
  gatk \
  MarkDuplicatesSpark \
  --input Sample1.aligned_reads.bam \
  --output Sample1.marked_duplicates.bam \
  --metrics-file Sample1.marked_duplicates_metrics.txt
```

- `--input`: Specify the name of input BAM/SAM/CRAM file containing reads
- `--output`: Specify the name of output BAM file
- `--metrics-file`: Specify the path to write duplication metrics to.

**Example: Multiple samples (loop)**
- Do not run, example only

```bash
for SAMPLE in Sample1 Sample2 Sample3 Sample4; do
  docker run --rm -v $(pwd):/ftmp -w /ftmp dnalinux/gatk \
  gatk \
  MarkDuplicatesSpark \
  --input "${SAMPLE}".aligned_reads.bam \
  --output "${SAMPLE}".marked_duplicates.bam \
  --metrics-file "${SAMPLE}".marked_duplicates_metrics.txt
done
```

### Step 3: Base Quality Recalibration
- Skip this step if no <REFERENCE_VCFS> were provided

#### Step 3a: Set up bqsr directory 

```bash
mkdir bqsr
```

#### Step 3b: Run GATK Base Recalibrator 

```bash
docker run --rm -v $(pwd):/ftmp -w /ftmp dnalinux/gatk \
  gatk \
  BaseRecalibrator \
  --input Sample1.marked_duplicates.bam \
  --reference reference.fasta \
  --known-sites <REFERENCE_VCF_1> \
  --known-sites <REFERENCE_VCF_2> \
  --output bqsr/Sample1.recalibrated.table
```
- `--known-sites`: One or more databases of known polymorphic sites used to exclude regions around known polymorphisms from analysis. This algorithm treats every reference mismatch as an indication of error. However, real genetic variation is expected to mismatch the reference, so it is critical that a database of known polymorphic sites is given to the tool in order to skip over those sites. This tool accepts any number of Feature-containing files (VCF, BCF, BED, etc.) for use as this database.

**Example: Multiple samples (loop) with 2 VCF's in <REFERENCE_VCFS>**

```bash
for SAMPLE in Sample1 Sample2 Sample3; 
do
  docker run --rm -v $(pwd):/ftmp -w /ftmp dnalinux/gatk \
  gatk \
  BaseRecalibrator \
  --reference reference.fasta \
  --input "${SAMPLE}".marked_duplicates.bam \
  --known-sites data/variants/GCF.38.filtered.renamed.vcf \
  --known-sites data/variants/1000g_gold_standard.indels.filtered.vcf \
  --output bqsr/"${SAMPLE}".recalibrated.table
done
```

#### Step 3c: Run GATK Apply BQSR

```bash
docker run --rm -v $(pwd):/ftmp -w /ftmp dnalinux/gatk \
  gatk \
  ApplyBQSR \
  --input Sample1.marked_duplicates.bam \
  --bqsr-recal-file Sample1.recalibrated.table \
  --output bqsr/Sample1.recalibrated.bam
```

- `bqsr-recal-file`: Input recalibration table for BQSR

**Example: Multiple samples (loop) with 2 VCF's in <REFERENCE_VCFS>**

```bash
for SAMPLE in Sample1 Sample2 Sample3; 
do
  docker run --rm -v $(pwd):/ftmp -w /ftmp dnalinux/gatk \
  gatk \
  ApplyBQSR \
  --input "${SAMPLE}".marked_duplicates.bam \
  --bqsr-recal-file bqsr/"${SAMPLE}".recalibrated.table \
  --output bqsr/"${SAMPLE}".recalibrated.bam
done
```

### Step 4: Variant Calling- Run GATK HaploTypeCaller

#### Step 4a:
```bash
mkdir variants
```
#### Step 4b:
```bash
  docker run --rm -v $(pwd):/ftmp -w /ftmp dnalinux/gatk \
  gatk \
  HaplotypeCaller \
  --reference reference.fasta \
  --input bqsr/Sample1.recalibrated.bam \
  --output variants/Sample1.HC.g.vcf \
  --intervals <INTERVALS> \
  --emit-ref-confidence GVCF
```

- `--intervals`: One or more genomic intervals over which to operate
- `--emit-ref-confidence`: Mode for emitting reference confidence scores (For Mutect2, this is a BETA feature)

**Example: Multiple samples (loop)**
- Note: For efficient merging of vcfs, we will need to output the variants as a GVCF. To do that, we will use the option --emit-ref-confidence GVCF.

```bash
for SAMPLE in Sample1 Sample2 Sample3; 
do
  docker run --rm -v $(pwd):/ftmp -w /ftmp dnalinux/gatk \
  gatk \
  HaplotypeCaller \
  --input bqsr/"${SAMPLE}".recalibrated.bam \
  --output variants/"${SAMPLE}".HC.g.vcf \
  --intervals <INTERVALS> \
  --emit-ref-confidence GVCF
done
```

### Step 5: Combining GVCFs

#### Step 5a: Generate a database, specifically GenomicsDB 
```bash
docker run --rm -v $(pwd):/ftmp -w /ftmp dnalinux/gatk \
  gatk \
  GenomicsDBImport \
  --variant variants/Sample1.HC.g.vcf \
  --variant variants/Sample2.HC.g.vcf \
  --variant variants/Sample3.HC.g.vcf \
  --intervals chr20:10018000-10220000 \
  --genomicsdb-workspace-path genomicsdb
```
- `--variant`: GVCF files to be imported to GenomicsDB. Each file must containdata for only a single sample. Either this or sample-name-map must be specified.
- `--genomicsdb-workspace-path`:  Workspace for GenomicsDB. Must be a POSIX file system path, but can be a relative path. Must be an empty or non-existent directory.

#### Step 5b: Perform joint genotyping on GenomicsDB workspace created with GenomicsDBImport/Retrieve the combined VCF from the database 

```bash
docker run --rm -v $(pwd):/ftmp -w /ftmp dnalinux/gatk \
  gatk \
  --java-options "-Xmx4g" \
  GenotypeGVCFs \
  --reference reference.fasta \
  --variant gendb://genomicsdb  \
  --intervals <INTERVALS> \
  --output variants.vcf.gz
```

- `--java-options`: Any java-specific arguments (such as -Xmx to specify memory allocation). This can be added to any gatk command.

## Output

Each run of `gatk` produces at least five files:

- `ref.dict` — SAM-style header file describing the contents of the FASTA file.
- `marked_duplicates_metrics.txt` — One metrics text file for the marked duplicates for each sample
- `marked_duplicates.bam` — Marked duplicates BAM file for each sample
- `HC.vcf` — One VCF file filled with genomic variants found using GATK's HaplotypeCaller for each sample
- A genomicsdb database will be produced
- `.vcf.gz` — One gunzipped VCF file filled with combined VCF's filled with genomic variants found using GATK's HaplotypeCaller
- if given <REFERENCE_VCFS>:
  - `.tbi` or `.idx` — One corresponding index file for each reference VCF
  - `recalibrated.table` — One recalibration table for BQSR for each sample
  - `recalibrated.bam` — One analysis-ready BAM for each sample

---

## Additional Useful Parameters

These can be added to the `gatk HaplotypeCaller` command:

- `--bam-output`: File to which assembled haplotypes should be written
The assembled haplotypes and locally realigned reads will be written as BAM to this file if requested. Really for debugging purposes only. Note that the output here does not include uninformative reads so that not every input read is emitted to the bam. Turning on this mode may result in serious performance cost for the caller. It's really only appropriate to use in specific areas where you want to better understand why the caller is making specific calls.


**Example: Multiple samples (loop)**
- Do not run, example only
- Note: To visualise the haplotype phasing with IGV, a phased bam is necessary


```bash
for SAMPLE in Sample1 Sample2 Sample3 Sample4; 
do
  docker run --rm -v $(pwd):/ftmp -w /ftmp dnalinux/gatk \
  gatk \
  HaplotypeCaller \
  --input bqsr/"${SAMPLE}".recalibrated.bam \
  --output variants/"${SAMPLE}".HC.g.vcf \
  --bam-output variants/"${SAMPLE}".phased.bam \
  --intervals <INTERVALS> \
  --emit-ref-confidence GVCF
done
```

## Citation

If the user asks for a citation for GATK, provide the following:

Van der Auwera GA & O'Connor BD. (2020). Genomics in the Cloud: Using Docker, GATK, and WDL in Terra (1st Edition). O'Reilly Media.

Poplin R, Ruano-Rubio V, DePristo MA, Fennell TJ, Carneiro MO, Van der Auwera GA, Kling DE, Gauthier LD, Levy-Moonshine A, Roazen D, Shakir K, Thibault J, Chandran S, Whelan C, Lek M, Gabriel S, Daly MJ, Neale B, MacArthur DG, Banks E. (2017). Scaling accurate genetic variant discovery to tens of thousands of samples bioRxiv, 201178. DOI: 10.1101/201178
