---
name: fastp
description: Ultrafast all-in-one preprocessing and quality control for Illumina short-read FASTQ data
version: 1.0.0
platforms: [macos, linux]
metadata:
  hermes:
    tags: [bioinformatics, qc, preprocessing, adapter-trimming, quality-filtering, illumina]
    category: bioinformatics
    requires_toolsets: [terminal]
---

# Fastp Preprocessing

Fastp performs adapter trimming, quality filtering, and quality control in a single pass. Designed for Illumina short reads (NovaSeq, MGI). For long reads (Nanopore, PacBio), use fastplong instead.

## When to Use

Use fastp after FastQC identifies issues in raw sequencing data:

**Typical workflow position:**
1. FastQC (diagnose)
2. **Fastp (clean)** ← You are here
3. FastQC again (verify)
4. Downstream analysis (alignment, assembly, etc.)

**Use when:**
- FastQC shows adapter contamination
- Quality scores are low
- Reads contain polyG/polyX tails (NextSeq/NovaSeq artifacts)
- Paired-end reads need merging
- Deduplication is required

## Procedure

### 1. Single-end reads

```bash
podman run --rm --network=none -v $(pwd):/ftmp dnalinux/fastp:latest sh -c \
  "fastp -i /ftmp/input.fastq -o /ftmp/output_cleaned.fastq"
```

### 2. Paired-end reads

```bash
podman run --rm --network=none -v $(pwd):/ftmp dnalinux/fastp:latest sh -c \
  "fastp -i /ftmp/R1.fastq -I /ftmp/R2.fastq -o /ftmp/R1_cleaned.fastq -O /ftmp/R2_cleaned.fastq"
```

### 3. Review the HTML report

Fastp automatically generates `fastp.html` and `fastp.json` in the working directory. Open the HTML report to see:
- Before/after quality comparison
- Adapter content removed
- Read length distribution
- Filtering statistics

### 4. Common cleaning scenarios

**Aggressive quality trimming:**
```bash
fastp -i input.fastq -o output.fastq \
  -q 25 \           # Q25 minimum quality per base
  -u 20 \           # Max 20% unqualified bases
  -5 -3 \           # Trim both ends
  -W 4 -M 25        # Sliding window Q25
```

**Merge overlapping PE reads:**
```bash
fastp -i R1.fastq -I R2.fastq -o R1_clean.fastq -O R2_clean.fastq \
  -m --merged_out merged.fastq
```

**Deduplicate:**
```bash
fastp -i input.fastq -o output.fastq -D
```

## Pitfalls

**File extension doesn't matter:**
The original skill shows `.fastqc` extensions in examples, but these are typos. Fastp works with `.fastq`, `.fq`, `.fastq.gz`, `.fq.gz` — any valid FASTQ format. The extension doesn't change behavior.

**Default settings are usually good:**
Fastp auto-detects adapters and applies reasonable defaults. Don't over-tune unless FastQC shows specific issues remain.

**PolyG trimming on NextSeq/NovaSeq:**
Fastp auto-enables polyG trimming for two-color chemistry platforms (NextSeq, NovaSeq). If you see long G-tails in FastQC after cleaning, ensure `-g` is set or not disabled with `-G`.

**Deduplication memory:**
`-D` enables deduplication with default accuracy level 3. Higher accuracy (`--dup_calc_accuracy 6`) uses more memory. Increase only if default misses duplicates.

## Verification

Successful run produces:
- Cleaned FASTQ file(s)
- `fastp.html` — Quality report
- `fastp.json` — Machine-readable metrics

Check file sizes and read counts:
```bash
# Before
wc -l input.fastq

# After
wc -l output_cleaned.fastq

# Expect ~10-30% read loss depending on quality
```

Run FastQC on cleaned data to verify:
```bash
fastqc output_cleaned.fastq
```

## Key Parameters

### Input/Output
| Flag | Description |
|------|-------------|
| `-i, --in1` | Read1 input file |
| `-I, --in2` | Read2 input (paired-end) |
| `-o, --out1` | Read1 output file |
| `-O, --out2` | Read2 output (paired-end) |
| `--failed_out` | File for reads that failed filters |

### Quality Filtering
| Flag | Description |
|------|-------------|
| `-q N` | Min quality score per base (default 15) |
| `-u N` | Max % unqualified bases allowed (default 40) |
| `-e N` | Min average quality (default 0=off) |
| `-n N` | Max N bases allowed (default 5) |
| `-Q` | Disable quality filtering |

### Adapter Trimming
| Flag | Description |
|------|-------------|
| `-A` | Disable adapter trimming |
| `-a SEQ` | Adapter for read1 (auto-detected if omitted) |
| `--adapter_sequence_r2 SEQ` | Adapter for read2 |
| `--adapter_fasta FILE` | FASTA file with adapters |

### Length Filtering
| Flag | Description |
|------|-------------|
| `-l N` | Min length required (default 15) |
| `--length_limit N` | Max length (default 0=off) |

### Sliding Window Trimming
| Flag | Description |
|------|-------------|
| `-5` | Trim low-quality from 5' end |
| `-3` | Trim low-quality from 3' end |
| `-r` | Drop everything after first low-quality window |
| `-W N` | Window size (default 4) |
| `-M N` | Min mean quality in window (default 20) |

### Paired-End Options
| Flag | Description |
|------|-------------|
| `-m` | Merge overlapping PE reads |
| `--merged_out FILE` | Output file for merged reads |
| `-c` | Base correction in overlapping regions |

### Performance
| Flag | Description |
|------|-------------|
| `-w N` | Worker threads (default 3) |
| `-z N` | Gzip compression level 1-9 (default 4) |

## Citation

Chen, S. (2025). Fastp 1.0: An ultra‐fast all‐round tool for FASTQ data quality control and preprocessing. *Imeta*, 4(5), e70078.
