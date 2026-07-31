---
name: pear
description: Merge overlapping paired-end Illumina reads into single assembled sequences
version: 1.0.0
platforms: [macos, linux]
metadata:
  hermes:
    tags: [bioinformatics, paired-end, read-merging, illumina, fastq]
    category: bioinformatics
    requires_toolsets: [terminal]
---

# PEAR - Paired-End reAd mergeR

PEAR merges overlapping paired-end FASTQ reads (Illumina-style forward/reverse pairs) into single assembled sequences. It evaluates all possible overlaps without requiring the target fragment size as input and implements a statistical test to minimize false-positive results.

## When to Use

**Appropriate scenarios:**
- Two paired-end read files (forward R1 and reverse R2)
- Need to merge millions of paired-end reads quickly
- Illumina-style overlapping read pairs

**Input requirements:**
- Forward reads file (R1)
- Reverse reads file (R2)
- Both can be gzipped (.fastq.gz)

**Not suitable for:**
- Single-end reads
- Non-overlapping paired-end reads (fragment larger than read length × 2)
- Alignment to a reference genome

## Procedure

### 1. Merge paired-end reads

```bash
docker run --rm -v $(pwd):/ftmp -w /ftmp dnalinux/pear \
  pear \
  -f forward_reads.fq.gz \
  -r reverse_reads.fq.gz \
  -o merged_reads \
  -j $(nproc)
```

**Flags:**
- `-f` — Forward reads file (R1)
- `-r` — Reverse reads file (R2)
- `-o` — Output base name (files will be named with this prefix)
- `-j` — Number of threads

### 2. Review output files

PEAR produces four files:

```text
merged_reads.assembled.fastq        # Successfully merged reads
merged_reads.discarded.fastq        # Reads discarded due to low quality
merged_reads.unassembled.forward.fastq  # Unmerged forward reads
merged_reads.unassembled.reverse.fastq  # Unmerged reverse reads
```

### 3. Adjust parameters (optional)

For stricter merging with quality filtering:

```bash
docker run --rm -v $(pwd):/ftmp -w /ftmp dnalinux/pear \
  pear \
  -f forward_reads.fq.gz \
  -r reverse_reads.fq.gz \
  -o merged_reads \
  -j $(nproc) \
  -v 20 \
  -q 15 \
  -b 64
```

**Additional flags:**
- `-v 20` — Minimum overlap size (default 10)
- `-q 15` — Quality score threshold for trimming (default 0)
- `-b 64` — Base PHRED quality score (default 33)

## Pitfalls

**Non-overlapping reads:**
If the fragment size is larger than twice the read length, reads won't overlap and PEAR cannot merge them. Check `unassembled` files for high unmerged rates.

**Wrong quality encoding:**
Illumina 1.8+ uses Phred 33. Older data may use Phred 64. Use `-b 64` if you see quality scores in unusual ranges.

**Minimum overlap too strict:**
Default `-v 10` works for most datasets. Increasing it may reduce false positives but also reduce merge rate.

## Verification

Successful run produces all four output files with reasonable sizes:

```bash
# Check file sizes
ls -lh merged_reads.*

# Count merged vs unassembled
echo "Assembled: $(wc -l < merged_reads.assembled.fastq)"
echo "Unassembled F: $(wc -l < merged_reads.unassembled.forward.fastq)"
echo "Unassembled R: $(wc -l < merged_reads.unassembled.reverse.fastq)"

# Check assembly stats in PEAR output (printed to stderr during run)
```

## Key Parameters

### Input/Output
| Flag | Description |
|------|-------------|
| `-f FILE` | Forward reads (R1) |
| `-r FILE` | Reverse reads (R2) |
| `-o NAME` | Output base name |
| `-j N` | Number of threads |

### Overlap and Quality
| Flag | Description |
|------|-------------|
| `-v N` | Minimum overlap size (default 10) |
| `-m N` | Maximum assembled length (default 0 = unlimited) |
| `-n N` | Minimum assembled length (default 50) |
| `-q N` | Quality threshold for trimming (default 0) |
| `-b N` | Base PHRED quality (default 33) |

## Citation

Zhang et al (2014) PEAR: a fast and accurate Illumina Paired-End reAd mergeR. Bioinformatics 30(5): 614-620. doi:10.1093/bioinformatics/btt593
