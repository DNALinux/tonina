---
name: spades
description: De novo genome assembly from short and long reads for bacteria, small eukaryotes, and metagenomes
version: 1.0.0
platforms: [macos, linux]
metadata:
  hermes:
    tags: [bioinformatics, assembly, genomics, de-novo, bacteria, metagenomics]
    category: bioinformatics
    requires_toolsets: [terminal]
---

# SPAdes Genome Assembly

SPAdes is a de novo genome assembler designed for bacterial and small eukaryotic genomes. It handles Illumina short reads, PacBio/Nanopore long reads, and supports specialized modes for single-cell, metagenomic, plasmid, and transcriptome assembly.

## When to Use

**Primary use cases:**
- Bacterial and archaeal genome assembly (primary use case)
- Small eukaryotic genomes (fungi, protists) — not suitable for large genomes (human, plant)
- Single-cell genomics (SC-SPAdes mode for MDA-amplified DNA)
- Metagenomics (metaSPAdes with `--meta`)
- Plasmid assembly (plasmidSPAdes with `--plasmid`)
- RNA-Seq transcriptome assembly (rnaSPAdes with `rnaspades.py`)

**Input types:**
- Illumina paired-end reads (most common)
- Illumina mate-pair reads (for larger insert sizes)
- Single-end reads
- PacBio/Oxford Nanopore reads (hybrid assembly with Illumina)

**Not suitable for:**
- Large eukaryotic genomes (human, plant) — memory and time prohibitive
- Resequencing projects — use BWA-MEM alignment instead

## Procedure

### 1. Basic paired-end assembly

Most common use case with standard Illumina paired-end reads:

```bash
docker run --network=none -v $(pwd):/ftmp dnalinux/spades spades.py \
  -1 /ftmp/reads_R1.fastq.gz \
  -2 /ftmp/reads_R2.fastq.gz \
  -o /ftmp/output_directory
```

**Flags:**
- `-1` — Forward reads
- `-2` — Reverse reads
- `-o` — Output directory (required)

### 2. Multiple libraries with different insert sizes

Use both paired-end and mate-pair libraries for better scaffolding:

```bash
docker run --network=none -v $(pwd):/ftmp dnalinux/spades spades.py \
  --pe1-1 /ftmp/pe_reads_R1.fastq.gz --pe1-2 /ftmp/pe_reads_R2.fastq.gz \
  --mp1-1 /ftmp/mp_reads_R1.fastq.gz --mp1-2 /ftmp/mp_reads_R2.fastq.gz \
  -o /ftmp/output_directory
```

**Flags:**
- `--pe1-1/--pe1-2` — Paired-end library
- `--mp1-1/--mp1-2` — Mate-pair library (larger insert size)
- Add more libraries with `pe2`, `mp2`, etc.

### 3. Single-cell genome assembly

For single-cell sequencing data with MDA bias correction:

```bash
docker run --network=none -v $(pwd):/ftmp dnalinux/spades spades.py \
  --sc \
  -1 /ftmp/sc_reads_R1.fastq.gz \
  -2 /ftmp/sc_reads_R2.fastq.gz \
  -o /ftmp/sc_output
```

**Flag:** `--sc` activates single-cell mode with special error correction for MDA amplification artifacts.

### 4. Hybrid assembly with long reads

Combining Illumina short reads with PacBio or Nanopore long reads:

**PacBio:**
```bash
docker run --network=none -v $(pwd):/ftmp dnalinux/spades spades.py \
  -1 /ftmp/illumina_R1.fastq.gz -2 /ftmp/illumina_R2.fastq.gz \
  --pacbio /ftmp/pacbio_reads.fastq.gz \
  -o /ftmp/hybrid_output
```

**Nanopore:**
```bash
docker run --network=none -v $(pwd):/ftmp dnalinux/spades spades.py \
  -1 /ftmp/illumina_R1.fastq.gz -2 /ftmp/illumina_R2.fastq.gz \
  --nanopore /ftmp/nanopore_reads.fastq.gz \
  -o /ftmp/hybrid_output
```

**Note:** For PacBio HiFi/CCS reads, also pass `--only-assembler`.

### 5. Bacterial isolate assembly (recommended)

For high-coverage bacterial isolates, use `--isolate` mode:

```bash
docker run --network=none -v $(pwd):/ftmp dnalinux/spades spades.py \
  -1 /ftmp/reads_R1.fastq.gz -2 /ftmp/reads_R2.fastq.gz \
  -o /ftmp/output_directory \
  -t 16 \
  -m 64 \
  --isolate
```

**Flags:**
- `-t 16` — Use 16 threads (SPAdes defaults to 16 if available)
- `-m 64` — Peak memory budget in GB (SPAdes aborts if it estimates needing more)
- `--isolate` — Recommended for high-coverage bacterial isolates (replaces `--careful` in SPAdes >= 3.14)

## Pitfalls

**SPAdes 4.x ignores --careful:**
In SPAdes 4.x, `--careful` is ignored and prints a warning. Use `--isolate` instead for bacterial isolates.

**Memory estimation is strict:**
`-m` is not an OS-level cap — SPAdes will abort if it estimates it needs more memory than specified. Set conservatively for large datasets.

**Output directory must not exist:**
SPAdes will fail if the output directory already exists. Delete or rename before re-running.

**Large genomes are impractical:**
SPAdes is not designed for large eukaryotic genomes. Attempting human or plant genome assembly will consume excessive memory and time.

## Verification

All results are written to the directory passed to `-o`:

**Key output files:**
- `contigs.fasta` — Assembled contigs
- `scaffolds.fasta` — Scaffolds built from contigs (usually the main result)
- `assembly_graph.fastg` / `assembly_graph_with_scaffolds.gfa` — Assembly graph for visualization (e.g., Bandage)
- `spades.log` — Full run log with version and runtime

Quick validation:
```bash
# Count contigs/scaffolds
grep -c "^>" output_directory/scaffolds.fasta

# Get assembly statistics (if quast is available)
quast.py output_directory/scaffolds.fasta -o quast_report

# Check log for completion
tail -20 output_directory/spades.log
```

## Key Parameters

### Input
| Flag | Description |
|------|-------------|
| `-1 FILE` | Forward reads (R1) |
| `-2 FILE` | Reverse reads (R2) |
| `--pacbio FILE` | PacBio CLR reads |
| `--nanopore FILE` | Oxford Nanopore reads |
| `--pe1-1/--pe1-2` | Paired-end library 1 |
| `--mp1-1/--mp1-2` | Mate-pair library 1 |

### Mode Selection
| Flag | Description |
|------|-------------|
| `--isolate` | High-coverage bacterial isolates (recommended) |
| `--sc` | Single-cell MDA-amplified DNA |
| `--meta` | Metagenomic assembly |
| `--plasmid` | Plasmid assembly |
| `--rna` | Transcriptome assembly (use `rnaspades.py`) |

### Resource Control
| Flag | Description |
|------|-------------|
| `-t N` | Number of threads (default 16) |
| `-m N` | Memory limit in GB |
| `-k LIST` | K-mer sizes (default auto) |

### Assembly Options
| Flag | Description |
|------|-------------|
| `--cov-cutoff auto` | Automatic coverage cutoff for filtering contaminants |
| `--only-assembler` | Skip read error correction (for HiFi reads) |

## Citation

Prjibelski, A., Antipov, D., Meleshko, D., Lapidus, A. and Korobeynikov, A., 2020. Using SPAdes de novo assembler. Current protocols in bioinformatics, 70(1), p.e102. doi.org/10.1002/cpbi.102
