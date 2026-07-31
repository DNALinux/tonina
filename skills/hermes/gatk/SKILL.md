---
name: gatk
description: Variant discovery in high-throughput sequencing data - SNP and indel calling for germline and somatic variants
version: 1.0.0
platforms: [macos, linux]
metadata:
  hermes:
    tags: [bioinformatics, variant-calling, genomics, snp, indel, gatk]
    category: bioinformatics
    requires_toolsets: [terminal]
---

# GATK - Genome Analysis Toolkit

GATK is the industry standard for identifying SNPs and indels in germline DNA and RNA-seq data. It also handles somatic short variant calling, copy number (CNV), and structural variation (SV). Includes Picard toolkit utilities.

## When to Use

**Appropriate scenarios:**
- Germline variant calling (SNPs, indels)
- Somatic variant detection
- Base quality score recalibration (BQSR)
- Duplicate marking and BAM processing
- Joint genotyping across samples

**Input requirements:**
- Reference FASTA with index (.fai) and dictionary (.dict)
- Aligned BAM file with index (.bai)
- Known variant sites VCF (optional, for BQSR)

## Procedure

### 1. Create sequence dictionary

GATK requires a SAM-style dictionary for the reference:

```bash
docker run --rm -v $(pwd):/ftmp -w /ftmp dnalinux/gatk \
  gatk CreateSequenceDictionary \
  --REFERENCE reference.fasta \
  --OUTPUT ref.dict
```

### 2. Index VCF files (if using BQSR)

```bash
docker run --rm -v $(pwd):/ftmp -w /ftmp dnalinux/gatk \
  gatk IndexFeatureFile -I known_sites.vcf
```

### 3. Mark duplicates

Mark duplicate reads to avoid PCR artifacts:

```bash
docker run --rm -v $(pwd):/ftmp -w /ftmp dnalinux/gatk \
  gatk MarkDuplicatesSpark \
  --input aligned_reads.bam \
  --output marked_duplicates.bam \
  --metrics-file marked_duplicates_metrics.txt
```

**Note:** Tool is optimized for queryname-grouped alignments. Coordinate-sorted input will be internally re-sorted, making it ~2x slower.

### 4. Base Quality Score Recalibration (BQSR)

Skip if no known variant sites available.

**Step 4a: Generate recalibration table:**
```bash
docker run --rm -v $(pwd):/ftmp -w /ftmp dnalinux/gatk \
  gatk BaseRecalibrator \
  --input marked_duplicates.bam \
  --reference reference.fasta \
  --known-sites known_sites.vcf \
  --output recalibrated.table
```

**Step 4b: Apply recalibration:**
```bash
docker run --rm -v $(pwd):/ftmp -w /ftmp dnalinux/gatk \
  gatk ApplyBQSR \
  --input marked_duplicates.bam \
  --bqsr-recal-file recalibrated.table \
  --output recalibrated.bam
```

### 5. Variant calling with HaplotypeCaller

Call variants per sample:

```bash
docker run --rm -v $(pwd):/ftmp -w /ftmp dnalinux/gatk \
  gatk HaplotypeCaller \
  --reference reference.fasta \
  --input recalibrated.bam \
  --output sample.g.vcf \
  --intervals chr20:10018000-10220000 \
  --emit-ref-confidence GVCF
```

**Flags:**
- `--emit-ref-confidence GVCF` — Output GVCF for efficient joint genotyping
- `--intervals` — Restrict to specific genomic regions

### 6. Combine GVCFs across samples

**Step 6a: Import to GenomicsDB:**
```bash
docker run --rm -v $(pwd):/ftmp -w /ftmp dnalinux/gatk \
  gatk GenomicsDBImport \
  --variant sample1.g.vcf \
  --variant sample2.g.vcf \
  --variant sample3.g.vcf \
  --intervals chr20:10018000-10220000 \
  --genomicsdb-workspace-path genomicsdb
```

**Step 6b: Joint genotyping:**
```bash
docker run --rm -v $(pwd):/ftmp -w /ftmp dnalinux/gatk \
  gatk --java-options "-Xmx4g" \
  GenotypeGVCFs \
  --reference reference.fasta \
  --variant gendb://genomicsdb \
  --intervals chr20:10018000-10220000 \
  --output variants.vcf.gz
```

## Pitfalls

**Sequence dictionary mismatch:**
All input files (FASTA, BAM, VCF) must have identical sequence dictionaries. Contig names and lengths must match exactly.

**Chromosome naming conventions:**
Human genomes may use "chr1" vs "1" format. Ensure all files use the same convention.

**MarkDuplicates slower on coordinate-sorted BAM:**
Queryname-sorted input is faster. Coordinate-sorted input triggers internal re-sorting.

**BQSR requires known sites:**
Without known variant sites VCF, BQSR cannot be performed. Skip to variant calling directly.

## Verification

```bash
# Check dictionary was created
ls -l ref.dict

# Check for duplicate metrics
cat marked_duplicates_metrics.txt

# Count variants
docker run --rm -v $(pwd):/ftmp dnalinux/gatk \
  gatk CountVariants -V variants.vcf.gz

# Validate VCF
docker run --rm -v $(pwd):/ftmp dnalinux/gatk \
  gatk ValidateVariants -V variants.vcf.gz
```

## Key Parameters

### MarkDuplicatesSpark
| Flag | Description |
|------|-------------|
| `--input FILE` | Input BAM |
| `--output FILE` | Output BAM with duplicates marked |
| `--metrics-file FILE` | Duplication metrics |
| `--remove-all-duplicates` | Remove duplicates instead of marking |

### BaseRecalibrator
| Flag | Description |
|------|-------------|
| `--input FILE` | Input BAM |
| `--reference FILE` | Reference FASTA |
| `--known-sites FILE` | Known variant sites VCF (repeatable) |
| `--output FILE` | Recalibration table |

### HaplotypeCaller
| Flag | Description |
|------|-------------|
| `--input FILE` | Input BAM |
| `--reference FILE` | Reference FASTA |
| `--output FILE` | Output VCF/GVCF |
| `--intervals REGION` | Genomic intervals |
| `--emit-ref-confidence MODE` | NONE, BP_RESOLUTION, GVCF |

### GenomicsDBImport
| Flag | Description |
|------|-------------|
| `--variant FILE` | GVCF files (repeatable) |
| `--intervals REGION` | Genomic intervals |
| `--genomicsdb-workspace-path DIR` | Output database path |

## Citation

Van der Auwera GA & O'Connor BD. (2020). Genomics in the Cloud: Using Docker, GATK, and WDL in Terra. O'Reilly Media.

Poplin R, Ruano-Rubio V, DePristo MA, et al. (2017). Scaling accurate genetic variant discovery to tens of thousands of samples. bioRxiv 201178. DOI: 10.1101/201178
