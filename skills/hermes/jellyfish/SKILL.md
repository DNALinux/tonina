---
name: jellyfish
description: Fast, memory-efficient counting of k-mers in DNA sequences
version: 1.0.0
platforms: [macos, linux]
metadata:
  hermes:
    tags: [bioinformatics, k-mer, counting, genomics, sequence-analysis]
    category: bioinformatics
    requires_toolsets: [terminal]
---

# Jellyfish - K-mer Counting

Jellyfish counts k-mers in DNA sequences using memory-efficient hash tables. It's orders of magnitude faster and uses less memory than other k-mer counting tools.

## When to Use

**Appropriate scenarios:**
- Count all k-mers in sequencing reads or genomes
- Identify high-frequency k-mers (genome content)
- K-mer frequency analysis for genome size estimation
- Build k-mer histograms for quality assessment

**Input types:**
- FASTA files (`.fa`, `.fasta`)
- FASTQ files (`.fq`, `.fastq`)
- Compressed files (must pipe through zcat)

## Procedure

### 1. Count all k-mers

Basic k-mer counting with canonical representation:

```bash
docker run --rm -v $(pwd):/ftmp -w /ftmp dnalinux/jellyfish \
  jellyfish count \
  -m 21 \
  -s 100M \
  -t $(nproc) \
  -o mer_counts.jf \
  -C \
  reads.fasta
```

**Flags:**
- `-m` — K-mer length
- `-s` — Hash size (estimate of distinct k-mers)
- `-t` — Number of threads
- `-o` — Output file
- `-C` — Count canonical (both strands)

**Hash size estimation:**
- Single genome: `-s ≈ genome_size × ploidy`
- 30× WGS resequencing: `-s ≈ total_sequenced_bases`
- Human genome: `-s 3G` for high-frequency, `-s 100G` for all k-mers

### 2. Count compressed files

Pipe gzipped files through zcat:

```bash
docker run --rm -v $(pwd):/ftmp -w /ftmp dnalinux/jellyfish \
  bash -c 'zcat reads.fastq.gz | jellyfish count /dev/fd/0 -m 21 -s 100M -o mer_counts.jf'
```

### 3. Count only high-frequency k-mers

Use Bloom filter to reduce memory:

```bash
docker run --rm -v $(pwd):/ftmp -w /ftmp dnalinux/jellyfish \
  jellyfish count \
  -m 25 \
  -s 3G \
  --bf-size 100G \
  -t $(nproc) \
  genome.fa
```

### 4. Generate histogram

Visualize k-mer frequency distribution:

```bash
docker run --rm -v $(pwd):/ftmp -w /ftmp dnalinux/jellyfish \
  jellyfish histo mer_counts.jf
```

### 5. Query specific k-mer

Check count of a specific sequence:

```bash
docker run --rm -v $(pwd):/ftmp -w /ftmp dnalinux/jellyfish \
  jellyfish query mer_counts.jf AACGTTG
```

### 6. Dump all k-mer counts

Export to human-readable FASTA format:

```bash
docker run --rm -v $(pwd):/ftmp -w /ftmp dnalinux/jellyfish \
  jellyfish dump mer_counts.jf > mer_counts_dumps.fa
```

### 7. Count subset of k-mers

Count only k-mers present in a whitelist:

```bash
docker run --rm -v $(pwd):/ftmp -w /ftmp dnalinux/jellyfish \
  jellyfish count \
  -m 20 \
  -s 100M \
  -C \
  -o chr1_shared.jf \
  --if chr20.fa \
  chr1.fa
```

## Pitfalls

**Hash size too small:**
Causes rehashing which slows execution. Increase `-s` if you see "Too many k-mers in hash" error.

**Canonical vs non-canonical:**
Use `-C` for sequencing reads (unknown strand). Omit for finished genomes where strand matters.

**Compressed files need piping:**
Jellyfish doesn't read gzipped files directly. Use `zcat file.gz | jellyfish count /dev/fd/0`.

**K-mer length mismatch with whitelist:**
`--if` file k-mers must match `-m` length exactly.

## Verification

```bash
# Check output was created
ls -lh mer_counts.jf

# View histogram
docker run --rm -v $(pwd):/ftmp dnalinux/jellyfish \
  jellyfish histo mer_counts.jf | head -20

# Count distinct k-mers
docker run --rm -v $(pwd):/ftmp dnalinux/jellyfish \
  jellyfish dump -c mer_counts.jf | wc -l
```

## Key Parameters

### Count
| Flag | Description |
|------|-------------|
| `-m N` | K-mer length |
| `-s SIZE` | Hash size (e.g., 100M, 3G) |
| `-t N` | Number of threads |
| `-o FILE` | Output file |
| `-C` | Canonical (count both strands) |
| `--bf-size SIZE` | Bloom filter size (for high-freq only) |
| `--if FILE` | Whitelist of k-mers to count |

### Analysis
| Command | Description |
|---------|-------------|
| `histo FILE.jf` | Generate frequency histogram |
| `query FILE.jf KMER` | Query specific k-mer count |
| `dump FILE.jf` | Export all k-mer counts |

## Citation

Marcais G and Kingsford C. A fast, lock-free approach for efficient parallel counting of occurrences of k-mers. Bioinformatics (2011) 27(6): 764-770. doi:10.1093/bioinformatics/btr011
