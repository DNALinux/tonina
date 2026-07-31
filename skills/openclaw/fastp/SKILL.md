---
name: fastp
description: Ultrafast all-in-one preprocessing and quality control for Illumina short-read FASTQ data
metadata:
  openclaw:
    emoji: "🧬"
    requires:
      bins: ["docker"]
---

# Fastp Skill

Fastp performs adapter trimming, quality filtering, and QC for Illumina short reads (NovaSeq, MGI).

## When to use it

After FastQC identifies quality issues. Use fastp before downstream analysis (alignment, assembly).

## Usage

**Single-end:**
```bash
podman run --rm --network=none -v $(pwd):/ftmp dnalinux/fastp:latest sh -c \
  "fastp -i /ftmp/input.fastq -o /ftmp/output_cleaned.fastq"
```

**Paired-end:**
```bash
podman run --rm --network=none -v $(pwd):/ftmp dnalinux/fastp:latest sh -c \
  "fastp -i /ftmp/R1.fastq -I /ftmp/R2.fastq -o /ftmp/R1_clean.fastq -O /ftmp/R2_clean.fastq"
```

**With options:**
```bash
fastp -i input.fastq -o output.fastq \
  -q 25 \           # Q25 minimum per base
  -5 -3 \           # Trim both ends
  -m --merged_out merged.fastq  # Merge PE reads
```

## Output

- Cleaned FASTQ file(s)
- `fastp.html` — Quality report with before/after comparison
- `fastp.json` — Machine-readable metrics

## Key Parameters

| Flag | Description |
|------|-------------|
| `-i, --in1` | Read1 input |
| `-I, --in2` | Read2 input (PE) |
| `-o, --out1` | Read1 output |
| `-O, --out2` | Read2 output (PE) |
| `-q N` | Min quality per base (default 15) |
| `-u N` | Max % unqualified bases (default 40) |
| `-l N` | Min length (default 15) |
| `-5, -3, -r` | Sliding window trimming |
| `-W N, -M N` | Window size, min quality (default 4, 20) |
| `-m` | Merge overlapping PE reads |
| `--merged_out` | File for merged reads |
| `-D` | Enable deduplication |
| `-w N` | Threads (default 3) |
| `-A` | Disable adapter trimming |

## Citation

Chen, S. (2025). Fastp 1.0: An ultra‐fast all‐round tool for FASTQ data quality control and preprocessing. *Imeta*, 4(5), e70078.
