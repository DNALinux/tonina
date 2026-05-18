---
name: Spades
description: "Uses spades docker to assemble genomes."
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

# Spades Skill

SPAdes is a genome assembly software used in bioinformatics.

## When SPAdes is Used

SPAdes is used for de novo genome assembly, particularly in these scenarios:

* Bacterial and archaeal genome assembly - This is its primary use case
* Small eukaryotic genomes - Such as fungi and some protists
* Single-cell genomics - SPAdes has a specific mode (SC-SPAdes) designed for single-cell sequencing data
* Metagenomics - metaSPAdes variant for assembling metagenomic datasets
* Plasmid assembly - plasmidSPAdes for assembling plasmid sequences
* RNA-Seq assembly - rnaSPAdes for transcriptome assembly

## Spades Usage


### Input Types

* Illumina paired-end reads - The most common input
* Illumina mate-pair reads - For larger insert sizes
* Single-end reads - Though less common
* PacBio/Oxford Nanopore reads - Can be used in hybrid assembly mode combined with Illumina reads


## 1. Basic Paired-End Assembly

This is the most common use case with standard Illumina paired-end reads:


```bash
docker run --network=none -v $(pwd):/ftmp dnalinux/spades spades.py -1 reads_R1.fastq.gz -2 reads_R2.fastq.gz -o output_directory
```

- `-1`: Forward reads
- `-2`: Reverse reads
- `-o`: Output directory

## 2. Multiple Libraries with Different Insert Sizes
Using both paired-end and mate-pair libraries for better scaffolding:

```bash
docker run --network=none -v $(pwd):/ftmp dnalinux/spades spades.py \
  --pe1-1 pe_reads_R1.fastq.gz --pe1-2 pe_reads_R2.fastq.gz \
  --mp1-1 mp_reads_R1.fastq.gz --mp1-2 mp_reads_R2.fastq.gz \
  -o output_directory
```

- `--pe1-1/--pe1-2`: Paired-end library
- `--mp1-1/--mp1-2`: Mate-pair library (larger insert size)
- You can add more libraries (pe2, mp2, etc.)

## 3. Single-Cell Genome Assembly
For single-cell sequencing data with MDA bias correction:

```bash
docker run --network=none -v $(pwd):/ftmp dnalinux/spades spades.py --sc -1 sc_reads_R1.fastq.gz -2 sc_reads_R2.fastq.gz -o sc_output
```

- `--sc`: Activates single-cell mode (SC-SPAdes)
- Applies special error correction for MDA amplification artifacts

## 4. Hybrid Assembly with Long Reads
Combining Illumina short reads with PacBio or Nanopore long reads:

```bash
docker run --network=none -v $(pwd):/ftmp dnalinux/spades spades.py \
  -1 illumina_R1.fastq.gz -2 illumina_R2.fastq.gz \
  --pacbio pacbio_reads.fastq.gz \
  -o hybrid_output
```

Or with Nanopore:

```bash
docker run --network=none -v $(pwd):/ftmp dnalinux/spades spades.py \
  -1 illumina_R1.fastq.gz -2 illumina_R2.fastq.gz \
  --nanopore nanopore_reads.fastq.gz \
  -o hybrid_output
```

- `--pacbio`: PacBio CLR reads
- `--nanopore`: Oxford Nanopore reads
- Long reads help resolve repeats and improve assembly contiguity

## Additional Useful Parameters

You can add these to any command:

- `-t 16`: Use 16 threads
- `-m 64`: Limit memory to 64 GB
- `-k 21,33,55,77`: Specify custom k-mer sizes
- `--careful`: Reduces mismatches and indels (recommended for bacterial genomes)
- `--cov-cutoff auto`: Automatic coverage cutoff for filtering contaminants

**Example with common parameters:**

```bash
docker run --network=none -v $(pwd):/ftmp dnalinux/spades spades.py \
  -1 reads_R1.fastq.gz -2 reads_R2.fastq.gz \
  -o output_directory \
  -t 16 \
  -m 64 \
  --careful
```


# To cite

If the user asks for a citation, provide the following:

Prjibelski, A., Antipov, D., Meleshko, D., Lapidus, A. and Korobeynikov, A., 2020. Using SPAdes de novo assembler. Current protocols in bioinformatics, 70(1), p.e102.
doi.org/10.1002/cpbi.102