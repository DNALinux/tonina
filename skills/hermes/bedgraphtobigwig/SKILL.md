---
name: bedgraphtobigwig
description: Convert bedGraph coverage files to binary bigWig format for efficient visualization
version: 1.0.0
platforms: [macos, linux]
metadata:
  hermes:
    tags: [bioinformatics, genomics, visualization, coverage, genome-browser]
    category: bioinformatics
    requires_toolsets: [terminal]
---

# bedGraph to bigWig Conversion

Converts text-based bedGraph files into binary bigWig (.bw) files using the UCSC bedGraphToBigWig utility. This dramatically reduces file size and enables rapid visualization in genome browsers (UCSC, IGV, JBrowse).

## When to Use

**Appropriate scenarios:**
- Continuous genomic data (RNA-seq coverage, ChIP-seq signal, methylation levels)
- Uploading tracks to web-based genome browsers
- Large files causing performance issues in local visualization tools
- Sharing coverage data with collaborators

**Input requirements:**
- bedGraph file (4-column: chrom, start, end, value)
- Must be sorted by chromosome, then start position
- Chromosome sizes file (chrom, length)

**Not suitable for:**
- Discrete features (genes, exons, binding sites) → Use bedToBigBed instead
- Unsorted bedGraph files → Sort first

## Procedure

### 1. Sort the bedGraph file (if needed)

```bash
docker run --rm -v $(pwd):/data -w /data dnalinux/bedGraphToBigWig:2.10 sh -c \
  "LC_COLLATE=C sort -k1,1 -k2,2n input.bedGraph > sorted.bedGraph"
```

Skip if already sorted.

### 2. Prepare chromosome sizes file

**Option A: From reference FASTA index:**
```bash
docker run --rm -v $(pwd):/data -w /data dnalinux/bedGraphToBigWig:2.10 sh -c \
  "cut -f1,2 reference.fa.fai > chrom.sizes"
```

**Option B: Download from UCSC (e.g., hg38):**
```bash
docker run --rm -v $(pwd):/data -w /data dnalinux/bedGraphToBigWig:2.10 sh -c \
  "wget -qO- http://hgdownload.cse.ucsc.edu/goldenpath/hg38/bigZips/hg38.chrom.sizes > chrom.sizes"
```

### 3. Convert to bigWig

```bash
docker run --rm -v $(pwd):/data -w /data dnalinux/bedGraphToBigWig:2.10 \
  bedGraphToBigWig \
  /data/sorted.bedGraph \
  /data/chrom.sizes \
  /data/output.bw
```

**Output:** Binary bigWig file ready for genome browser upload

## Pitfalls

**Input must be sorted:**
bedGraphToBigWig fails on unsorted input. Always verify sort order or sort as Step 1.

**Chromosome names must match:**
Chromosome names in bedGraph must match those in chrom.sizes exactly (e.g., "chr1" vs "1" mismatch will fail).

**Binary vs text gzip:**
bedGraph files should not be gzipped before conversion. If compressed, decompress first.

**Large files need more memory:**
Very large bedGraph files (>1GB uncompressed) may require significant memory during conversion.

## Verification

Successful conversion produces:
- `.bw` file significantly smaller than original bedGraph

Quick validation:
```bash
# Check file was created
ls -lh output.bw

# Verify it's a valid bigWig (file command)
file output.bw

# Load in IGV or upload to UCSC Genome Browser
```

## Key Parameters

| Flag | Description |
|------|-------------|
| `-blockSize=N` | Parameter block size (default 256) |
| `-itemsPerSlot=N` | Data points per group (default 1024) |
| `-unc` | Disable compression (debugging only) |

**Example with custom parameters:**
```bash
bedGraphToBigWig -blockSize=512 sorted.bedGraph chrom.sizes output.bw
```

## Output Format

The bigWig file contains:
- Compressed binary signal data
- Built-in index for fast random access
- Suitable for HTTP/FTP serving to genome browsers

## Citation

Kent, W. J., Zweig, A. S., Barber, G., Hinrichs, A. S., & Karolchik, D. (2010). BigWig and BigBed: enabling browsing of large distributed datasets. Bioinformatics, 26(17), 2204–2207. https://doi.org/10.1093/bioinformatics/btq351
