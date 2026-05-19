---
name: Spades
description: "Assemble genomes from short and long reads with SPAdes."
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

# SPAdes Skill

SPAdes is a genome assembly software used in bioinformatics.

## When SPAdes is Used

SPAdes is used for de novo genome assembly, particularly in these scenarios:

- Bacterial and archaeal genome assembly - This is its primary use case
- Small eukaryotic genomes - Such as fungi and some protists (not suitable for large eukaryotic genomes such as human or plant)
- Single-cell genomics - SPAdes has a specific mode (SC-SPAdes) designed for single-cell sequencing data
- Metagenomics - metaSPAdes variant (`--meta`) for assembling metagenomic datasets
- Plasmid assembly - plasmidSPAdes (`--plasmid`) for assembling plasmid sequences
- RNA-Seq assembly - rnaSPAdes (`rnaspades.py`) for transcriptome assembly

## SPAdes Usage

### Input Types

- Illumina paired-end reads - The most common input
- Illumina mate-pair reads - For larger insert sizes
- Single-end reads - Though less common
- PacBio/Oxford Nanopore reads - Can be used in hybrid assembly mode combined with Illumina reads

### 1. Basic Paired-End Assembly

This is the most common use case with standard Illumina paired-end reads:


```bash
docker run --network=none -v $(pwd):/ftmp dnalinux/spades spades.py -1 /ftmp/reads_R1.fastq.gz -2 /ftmp/reads_R2.fastq.gz -o /ftmp/output_directory
```

- `-1`: Forward reads
- `-2`: Reverse reads
- `-o`: Output directory

### 2. Multiple Libraries with Different Insert Sizes
Using both paired-end and mate-pair libraries for better scaffolding:

```bash
docker run --network=none -v $(pwd):/ftmp dnalinux/spades spades.py \
  --pe1-1 /ftmp/pe_reads_R1.fastq.gz --pe1-2 /ftmp/pe_reads_R2.fastq.gz \
  --mp1-1 /ftmp/mp_reads_R1.fastq.gz --mp1-2 /ftmp/mp_reads_R2.fastq.gz \
  -o /ftmp/output_directory
```

- `--pe1-1/--pe1-2`: Paired-end library
- `--mp1-1/--mp1-2`: Mate-pair library (larger insert size)
- You can add more libraries (pe2, mp2, etc.)

### 3. Single-Cell Genome Assembly
For single-cell sequencing data with MDA bias correction:

```bash
docker run --network=none -v $(pwd):/ftmp dnalinux/spades spades.py --sc -1 /ftmp/sc_reads_R1.fastq.gz -2 /ftmp/sc_reads_R2.fastq.gz -o /ftmp/sc_output
```

- `--sc`: Activates single-cell mode (SC-SPAdes)
- Applies special error correction for MDA amplification artifacts

### 4. Hybrid Assembly with Long Reads
Combining Illumina short reads with PacBio or Nanopore long reads:

```bash
docker run --network=none -v $(pwd):/ftmp dnalinux/spades spades.py \
  -1 /ftmp/illumina_R1.fastq.gz -2 /ftmp/illumina_R2.fastq.gz \
  --pacbio /ftmp/pacbio_reads.fastq.gz \
  -o /ftmp/hybrid_output
```

Or with Nanopore:

```bash
docker run --network=none -v $(pwd):/ftmp dnalinux/spades spades.py \
  -1 /ftmp/illumina_R1.fastq.gz -2 /ftmp/illumina_R2.fastq.gz \
  --nanopore /ftmp/nanopore_reads.fastq.gz \
  -o /ftmp/hybrid_output
```

- `--pacbio`: PacBio CLR reads (for HiFi/CCS reads, also pass `--only-assembler`)
- `--nanopore`: Oxford Nanopore reads
- Long reads help resolve repeats and improve assembly contiguity

## Output

All results are written to the directory passed to `-o`. The most relevant files are:

- `contigs.fasta` - Assembled contigs.
- `scaffolds.fasta` - Scaffolds built from the contigs (usually the main result).
- `assembly_graph.fastg` / `assembly_graph_with_scaffolds.gfa` - Assembly graph for visualization (e.g. in Bandage).
- `spades.log` - Full run log; useful for debugging and to report the version/runtime.

## Additional Useful Parameters

You can add these to any command:

- `-t 16`: Use 16 threads (SPAdes already defaults to 16 if available, so this is only needed to reduce or pin the count).
- `-m 64`: Peak memory budget in GB. Not an OS-level cap; SPAdes will abort if it estimates it needs more.
- `-k 21,33,55,77`: Specify custom k-mer sizes.
- `--isolate`: Recommended mode for high-coverage bacterial isolates (replaces `--careful` in SPAdes >= 3.14).
- `--careful`: Older flag that reduces mismatches and indels. Note: SPAdes 4.x ignores this flag and prints a warning - use `--isolate` instead.
- `--cov-cutoff auto`: Automatic coverage cutoff for filtering contaminants.

**Example with common parameters (bacterial isolate):**

```bash
docker run --network=none -v $(pwd):/ftmp dnalinux/spades spades.py \
  -1 /ftmp/reads_R1.fastq.gz -2 /ftmp/reads_R2.fastq.gz \
  -o /ftmp/output_directory \
  -t 16 \
  -m 64 \
  --isolate
```

## Citation

If the user asks for a citation, provide the following:

Prjibelski, A., Antipov, D., Meleshko, D., Lapidus, A. and Korobeynikov, A., 2020. Using SPAdes de novo assembler. Current protocols in bioinformatics, 70(1), p.e102.
doi.org/10.1002/cpbi.102