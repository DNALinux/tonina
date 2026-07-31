---
name: sra-toolkit
description: Download and convert NCBI SRA accessions to FASTQ/FASTA format
version: 1.0.0
platforms: [macos, linux]
metadata:
  hermes:
    tags: [bioinformatics, sra, ncbi, download, fastq, sequencing]
    category: bioinformatics
    requires_toolsets: [terminal]
---

# SRA Toolkit - Sequence Read Archive Downloader

The SRA Toolkit downloads and converts data from NCBI's Sequence Read Archive. This skill uses `fasterq-dump` to convert SRA accessions (SRR, ERR, DRR) to FASTQ format.

## When to Use

**Appropriate scenarios:**
- Download sequencing data from NCBI SRA
- Convert local .sra files to FASTQ/FASTA
- Inspect and validate SRA archives

**Input types:**
- SRA accession (SRR..., ERR..., DRR...)
- Local .sra file path

**Note:** This container requires network access. Do NOT use `--network=none`.

## Procedure

### 1. Initial configuration (one-time)

Initialize default config to avoid interactive prompts:

```bash
docker run --rm -v $(pwd):/ftmp dnalinux/sra-toolkit:latest vdb-config --restore-defaults
```

### 2. Download with prefetch (recommended for large accessions)

For large accessions or unreliable networks:

```bash
# Download .sra archive
docker run --rm -v $(pwd):/ftmp dnalinux/sra-toolkit:latest \
  prefetch SRR15536067 -O /ftmp

# Convert to FASTQ
docker run --rm -v $(pwd):/ftmp dnalinux/sra-toolkit:latest \
  fasterq-dump /ftmp/SRR15536067 --outdir /ftmp
```

### 3. One-shot download

For small/fast accessions:

```bash
docker run --rm -v $(pwd):/ftmp dnalinux/sra-toolkit:latest \
  fasterq-dump SRR15536067 --outdir /ftmp
```

### 4. Output file structure

Default mode (`--split-3`) produces:

**Paired-end:**
- `<acc>_1.fastq` — Forward reads
- `<acc>_2.fastq` — Reverse reads
- `<acc>.fastq` — Orphan/unpaired reads (if any)

**Single-end:**
- `<acc>.fastq` — All reads

### 5. Use custom temp directory

For large files, point temp to fast storage:

```bash
docker run --rm -v $(pwd):/ftmp dnalinux/sra-toolkit:latest \
  fasterq-dump SRR15536067 --outdir /ftmp -t /ftmp/scratch
```

### 6. Compress output

`fasterq-dump` outputs uncompressed FASTQ. Compress afterward:

```bash
gzip -f SRR15536067_1.fastq SRR15536067_2.fastq
```

### 7. Stream to stdout

Pipe directly to another tool:

```bash
docker run --rm -v $(pwd):/ftmp dnalinux/sra-toolkit:latest \
  fasterq-dump -Z SRR15536067 | head
```

## Pitfalls

**First run prompts for cloud usage:**
Initialize config with `vdb-config --restore-defaults` before first use in scripts.

**Large files need scratch space:**
`fasterq-dump` needs ~10x the final FASTQ size in temp space. Point `-t` to a fast, large disk.

**Output is uncompressed:**
Always gzip the output files to save space.

**Network required:**
Do not use `--network=none`. The container needs to contact NCBI, AWS, and GCP.

## Verification

```bash
# Check files were created
ls -lh SRR*.fastq

# Count reads
wc -l SRR15536067_1.fastq

# Validate archive (if downloaded with prefetch)
docker run --rm -v $(pwd):/ftmp dnalinux/sra-toolkit:latest \
  vdb-validate /ftmp/SRR15536067
```

## Key Parameters

### fasterq-dump
| Flag | Description |
|------|-------------|
| `-O, --outdir DIR` | Output directory |
| `-t, --temp DIR` | Temp directory (default: current) |
| `-e, --threads N` | Number of threads (default 6) |
| `-p, --progress` | Show progress |
| `-f, --force` | Overwrite existing files |
| `-Z, --stdout` | Stream to stdout |
| `--split-3` | Split paired-end (default) |
| `--split-files` | Write reads to separate files |
| `--split-spot` | Split spots into reads |
| `--concatenate-reads` | Write all to one file |
| `--skip-technical` | Skip technical reads |
| `--include-technical` | Include technical reads |
| `--fasta` | Output FASTA format |

### prefetch
| Flag | Description |
|------|-------------|
| `-O DIR` | Output directory |
| `--progress` | Show progress |

### Companion Tools
| Tool | Purpose |
|------|---------|
| `prefetch` | Download .sra archive |
| `fasterq-dump` | Convert to FASTQ/FASTA |
| `fastq-dump` | Older converter (supports --gzip) |
| `vdb-validate` | Check archive integrity |
| `sra-stat` | Print statistics |

## Citation

Leinonen R, Sugawara H, Shumway M; International Nucleotide Sequence Database Collaboration. The Sequence Read Archive. Nucleic Acids Research. 2011 Jan;39(Database issue):D19-D21. doi:10.1093/nar/gkq1019.

SRA Toolkit: https://github.com/ncbi/sra-tools
