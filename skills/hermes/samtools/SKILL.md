---
name: samtools
description: Manipulate, convert, sort, index, and query SAM, BAM, and CRAM alignment files
version: 1.0.0
platforms: [macos, linux]
metadata:
  hermes:
    tags: [bioinformatics, alignment, bam, sam, cram, sequencing]
    category: bioinformatics
    requires_toolsets: [terminal]
---

# Samtools - SAM/BAM/CRAM Utilities

Samtools is a suite of utilities for manipulating alignments in SAM, BAM, and CRAM formats. It converts between formats, sorts, merges, indexes, and retrieves reads in any region swiftly.

## When to Use

**Appropriate scenarios:**
- Converting SAM to BAM or CRAM formats
- Sorting and indexing alignment files
- Extracting alignment statistics
- Querying reads by region
- Merging multiple alignment files

**Input types:**
- SAM files (raw text alignment)
- BAM files (binary compressed alignment)
- CRAM files (reference-based compression)
- FASTA reference (required for CRAM)

## Procedure

### 1. Convert SAM to BAM

First check if @SQ lines are present in the header:

```bash
docker run --rm -v "$(pwd)":/ftmp -w /ftmp dnalinux/samtools \
  samtools view -H input.sam | grep -i '^@SQ'
```

**If @SQ lines present:**
```bash
docker run --rm -v "$(pwd)":/ftmp -w /ftmp dnalinux/samtools:1.24-src \
  view -b -o output.bam input.sam
```

**If @SQ lines absent, use reference:**
```bash
# Index reference first
docker run --rm -v "$(pwd)":/ftmp -w /ftmp dnalinux/samtools:1.24-src \
  faidx reference.fasta

# Convert with reference
docker run --rm -v "$(pwd)":/ftmp -w /ftmp dnalinux/samtools:1.24-src \
  view -b -t reference.fasta.fai -o output.bam --threads $(nproc) input.sam
```

### 2. Sort and index BAM

BAM files must be sorted before indexing:

```bash
# Sort
docker run --rm -v "$(pwd)":/ftmp -w /ftmp dnalinux/samtools:1.24-src \
  sort -m 768M -o output.sorted.bam --threads $(nproc) input.bam

# Index
docker run --rm -v "$(pwd)":/ftmp -w /ftmp dnalinux/samtools:1.24-src \
  index --threads $(nproc) output.sorted.bam
```

**Output:** `output.sorted.bam.bai` (or `.csi` if using `--csi`)

### 3. Convert BAM to CRAM

CRAM requires a reference FASTA:

```bash
docker run --rm -v "$(pwd)":/ftmp -w /ftmp dnalinux/samtools:1.24-src \
  view -C -T reference.fasta -o output.cram input.bam --threads $(nproc)
```

### 4. Generate alignment statistics

**Flagstat (simple stats):**
```bash
docker run --rm -v "$(pwd)":/ftmp -w /ftmp dnalinux/samtools:1.24-src \
  flagstat input.bam -O default -@ $(nproc)
```

**Idxstats (per-reference stats):**
```bash
docker run --rm -v "$(pwd)":/ftmp -w /ftmp dnalinux/samtools:1.24-src \
  idxstats input.bam
```

**Depth (coverage):**
```bash
docker run --rm -v "$(pwd)":/ftmp -w /ftmp dnalinux/samtools:1.24-src \
  depth input.bam
```

### 5. Merge BAM files

```bash
docker run --rm -v "$(pwd)":/ftmp -w /ftmp dnalinux/samtools:1.24-src \
  merge --threads $(nproc) output.bam input1.bam input2.bam input3.bam
```

**Note:** All input BAMs must be sorted the same way.

### 6. Pileup generation

```bash
docker run --rm -v "$(pwd)":/ftmp -w /ftmp dnalinux/samtools:1.24-src \
  mpileup --count-orphans --no-BAQ --max-depth 0 \
  --fasta-ref reference.fasta --min-BQ 0 \
  --excl-flags 0 --disable-overlap-removal input.bam
```

## Pitfalls

**BAM must be sorted before indexing:**
Indexing fails on unsorted BAM. Always sort first.

**Coordinate sort required for indexing:**
The default coordinate sort is required. `-n`, `-N`, `-t` options are incompatible with `samtools index`.

**Large chromosomes need CSI index:**
BAI index fails for chromosomes >512 Mbp. Use `--csi` for large genomes.

**CRAM requires reference:**
Converting to/from CRAM always requires the reference FASTA via `-T`.

## Verification

Quick validation:
```bash
# Check BAM is valid
docker run --rm -v $(pwd):/ftmp dnalinux/samtools \
  samtools quickcheck -v output.bam

# View header
docker run --rm -v $(pwd):/ftmp dnalinux/samtools \
  samtools view -H output.bam

# Count reads
docker run --rm -v $(pwd):/ftmp dnalinux/samtools \
  samtools view -c output.bam
```

## Key Parameters

### View (conversion)
| Flag | Description |
|------|-------------|
| `-b` | Output BAM format |
| `-C` | Output CRAM format |
| `-T FILE` | Reference FASTA (required for CRAM) |
| `-t FILE` | Reference index (.fai) |
| `-o FILE` | Output file |
| `--threads N` | Compression threads |

### Sort
| Flag | Description |
|------|-------------|
| `-m SIZE` | Memory per thread (default 768M) |
| `-o FILE` | Output file |
| `--threads N` | Number of threads |

### Index
| Flag | Description |
|------|-------------|
| `--csi` | Create CSI index (for large chromosomes) |
| `--threads N` | Number of threads |

### Statistics
| Flag | Description |
|------|-------------|
| `flagstat` | Simple alignment statistics |
| `idxstats` | Per-reference read counts |
| `depth` | Coverage depth |
| `-O FORMAT` | Output format: default, json, tsv |

## Citation

Danecek P, Bonfield JK, Liddle J, Marshall J, Ohan V, Pollard MO, Whitwham A, Keane T, McCarthy SA, Davies RM, Li H. Twelve years of SAMtools and BCFtools. GigaScience, Volume 10, Issue 2, February 2021, giab008. https://doi.org/10.1093/gigascience/giab008
