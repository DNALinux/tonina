---
name: tabix
description: Index and query TAB-delimited genome position files for fast region retrieval
version: 1.0.0
platforms: [macos, linux]
metadata:
  hermes:
    tags: [bioinformatics, indexing, genomics, vcf, bed, gff]
    category: bioinformatics
    requires_toolsets: [terminal]
---

# Tabix - Genome Position File Indexer

Tabix indexes bgzipped TAB-delimited genome position files (BED, GFF, VCF, SAM) and enables fast retrieval of data lines overlapping specified genomic regions.

## When to Use

**Appropriate scenarios:**
- Need fast region-based queries on large genomic files
- Preparing VCF/BED/GFF files for visualization tools (IGV, UCSC Browser)
- Creating indexes for downstream tools that require them

**Input requirements:**
- File must be **position sorted**
- File must be **compressed with bgzip** (not gzip)
- Standard formats (VCF, BED, GFF, SAM) are auto-detected

**Not suitable for:**
- Unsorted files → Sort first
- Standard gzip-compressed files → Use bgzip instead

## Procedure

### 1. Index a file

Create an index file for fast region retrieval:

```bash
docker run --rm -v $(pwd):/ftmp -w /ftmp dnalinux/tabix \
  tabix \
  --force \
  --threads $(nproc) \
  file.vcf.gz
```

**Output:** `file.vcf.gz.tbi` (or `.csi` if using `--csi`)

**Flags:**
- `--force` — Overwrite existing index
- `--threads` — Number of threads (default 0)

### 2. Query by region

Retrieve data lines overlapping a genomic region:

```bash
docker run --rm -v $(pwd):/ftmp -w /ftmp dnalinux/tabix \
  tabix \
  file.vcf.gz \
  chr1:1000000-2000000
```

**Region format:** `chr:begin-end` (1-based, inclusive)

Multiple regions:
```bash
docker run --rm -v $(pwd):/ftmp -w /ftmp dnalinux/tabix \
  tabix \
  file.vcf.gz \
  chr1 chr2:500-1500 chr3
```

### 3. List chromosomes

Show available sequences in the index:

```bash
docker run --rm -v $(pwd):/ftmp -w /ftmp dnalinux/tabix \
  tabix \
  --list-chroms \
  file.vcf.gz
```

### 4. Query with header

Include header lines in output:

```bash
docker run --rm -v $(pwd):/ftmp -w /ftmp dnalinux/tabix \
  tabix \
  --print-header \
  file.vcf.gz \
  chr1:1000000-2000000
```

## Pitfalls

**File must be bgzipped:**
Standard gzip produces files tabix cannot read. Use `bgzip` from samtools/htslib:
```bash
bgzip file.bed
```

**File must be sorted:**
Tabix requires position-sorted files. Sort before bgzipping:
```bash
sort -k1,1 -k2,2n file.bed | bgzip > file.bed.gz
```

**Non-standard formats need explicit -p:**
For files that aren't standard VCF/BED/GFF/SAM, specify format:
```bash
tabix -p bed custom_file.gz
```

**Positions exceeding 512 Mbp:**
Use `--csi` index instead of default TBI for genomes with very long chromosomes:
```bash
tabix --csi file.vcf.gz
```

## Verification

Successful indexing produces:
- `.tbi` or `.csi` index file alongside the data file

Quick validation:
```bash
# Check index exists
ls -l file.vcf.gz.tbi

# List chromosomes
tabix --list-chroms file.vcf.gz

# Query a known region
tabix file.vcf.gz chr1:1-1000 | head -5
```

## Key Parameters

### Indexing
| Flag | Description |
|------|-------------|
| `--force` | Overwrite existing index |
| `--threads N` | Number of threads |
| `--preset FORMAT` | Input format: vcf, bed, gff, sam |
| `--csi` | Use CSI index (for large positions) |
| `-p FORMAT` | Same as --preset |

### Querying
| Flag | Description |
|------|-------------|
| `--list-chroms` | List sequence names |
| `--print-header` | Include header in output |
| Region format | `chr:begin-end` (1-based, inclusive) |

## Citation

Li, Heng (2011). Tabix: fast retrieval of sequence features from generic TAB-delimited files. Bioinformatics 27(5): 718–719. doi:10.1093/bioinformatics/btq671
