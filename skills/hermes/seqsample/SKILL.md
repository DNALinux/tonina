---
name: seqsample
description: Sample or generate random sequences from FASTA or FASTQ files
version: 1.0.0
platforms: [macos, linux]
metadata:
  hermes:
    tags: [bioinformatics, sampling, sequences, fasta, fastq, random]
    category: bioinformatics
    requires_toolsets: [terminal]
---

# SeqSample - Sequence Sampling and Generation

SeqSample extracts subsets of sequences from FASTA/FASTQ files or generates synthetic random sequences. It streams one record at a time and never loads the entire file into memory.

## When to Use

**Appropriate scenarios:**
- Extract a random subset for testing or development
- Take first N or last N records from a large file
- Generate synthetic FASTA/FASTQ for pipeline testing
- Create smaller datasets from large files

**Input types:**
- FASTA files (plain or gzipped)
- FASTQ files (plain or gzipped)
- Format auto-detected from content, not extension

## Procedure

### 1. Random sample by percentage

Extract ~10% of records:

```bash
python3 main.py -i input.fastq -p 10 > sample.fastq
```

### 2. Exact count sampling

Extract exactly 100 random records:

```bash
python3 main.py -i reads.fa.gz -u 100 -s 42 -o sample.fa
```

**Flags:**
- `-u` — Exact number of records to keep
- `-s` — Random seed for reproducibility

### 3. Head or tail sampling

**First 50 records:**
```bash
python3 main.py -i input.fastq -u 50 --order head > head.fastq
```

**Last 5% of records:**
```bash
python3 main.py -i input.fastq -p 5 --order tail > tail.fastq
```

### 4. Generate synthetic sequences

Generate 20 random FASTA records of length 150:

```bash
python3 main.py -u 20 -t fasta -l 150 -s 1 -o synthetic.fa
```

Generate 50 random FASTQ records:

```bash
python3 main.py -u 50 -t fastq -l 100 | head -8
```

## Pitfalls

**Percentage vs unit:**
`-p` (percentage) and `-u` (unit count) are mutually exclusive. Use only one.

**Unit count exceeds file:**
If `-u N` is larger than the file, all records are returned.

**Output is always uncompressed:**
Pipe to `gzip` if you need compressed output:
```bash
python3 main.py -i input.fastq -p 10 | gzip > sample.fastq.gz
```

## Verification

```bash
# Count input records
grep -c "^>" input.fasta

# Count output records
grep -c "^>" sample.fa

# Verify count matches expectation
```

## Key Parameters

### Sampling Options
| Flag | Description |
|------|-------------|
| `-i PATH` | Input file (FASTA/FASTQ, plain or gzipped) |
| `-p N` | Keep N% of records |
| `-u N` | Keep exactly N records |
| `--order MODE` | Selection: random, head, tail (default: random) |
| `-s N` | Random seed for reproducibility |
| `-o PATH` | Output file (default: stdout) |

### Generation Options
| Flag | Description |
|------|-------------|
| `-u N` | Generate N records (no `-i` required) |
| `-t FORMAT` | Output format: fasta or fastq |
| `-l N` | Sequence length (default: 100) |
| `-s N` | Random seed |

## Usage Examples

```bash
# 10% random sample
python3 main.py -i input.fastq -p 10 > sample.fastq

# Exactly 100 random records, reproducible
python3 main.py -i reads.fa.gz -u 100 -s 42 -o sample.fa

# First 50 records
python3 main.py -i input.fastq -u 50 --order head > head.fastq

# Last 5%
python3 main.py -i input.fastq -p 5 --order tail > tail.fastq

# Generate synthetic data
python3 main.py -u 20 -t fasta -l 150 -s 1 -o synthetic.fa
```
