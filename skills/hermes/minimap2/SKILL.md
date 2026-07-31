---
name: minimap2
description: Align long/short reads or assemblies to a reference genome using minimap2
version: 1.0.0
platforms: [macos, linux]
metadata:
  hermes:
    tags: [bioinformatics, alignment, mapping, long-reads, nanopore, pacbio, illumina]
    category: bioinformatics
    requires_toolsets: [terminal]
---

# Minimap2 Alignment

Minimap2 is a versatile sequence alignment program that maps DNA or mRNA sequences against a large reference genome or other sequences. It supports long reads (Oxford Nanopore, PacBio), short reads (Illumina), and assembly-to-assembly alignment.

## When to Use

Choose minimap2 based on read length and sequencing technology:

**Long-read platforms (Nanopore, PacBio):**
- Minimap2 is purpose-built for long reads with high error rates
- Handles Oxford Nanopore and PacBio CLR/HiFi data
- Supports splice-aware RNA alignment
- Orders of magnitude faster than short-read tools on long reads

**Short-read Illumina (100-250bp):**
- Use BWA-MEM or BWA-MEM2 for compatibility with established pipelines (GATK best practices)
- Prefer BWA-MEM2 over BWA-MEM (identical output, faster)

**Hybrid multi-platform projects:**
- Minimap2's preset modes (`-x sr`, `-x map-ont`, `-x asm5`) make it versatile for cross-platform work

## Procedure

### 1. Choose the correct preset

Minimap2 uses presets to optimize alignment parameters. Almost every run should pass a preset:

| Preset | Use case |
|--------|----------|
| `-x map-ont` | Oxford Nanopore reads vs reference |
| `-x map-pb` | PacBio CLR reads vs reference |
| `-x map-hifi` | PacBio HiFi / CCS reads vs reference |
| `-x sr` | Short Illumina paired-end reads vs reference |
| `-x asm5` / `-x asm10` / `-x asm20` | Assembly-to-reference at ~5/10/20% divergence |
| `-x splice` / `-x splice:hq` | Spliced alignment (mRNA / IsoSeq) |

### 2. Align reads to reference

The Docker container mounts your current directory to `/ftmp`. All file paths in examples are relative to `/ftmp/`.

Minimap2 transparently reads gzipped FASTA and FASTQ - no need to decompress first.

**PAF output (no base-level alignment):**
```bash
docker run --network=none -v $(pwd):/ftmp dnalinux/minimap2:latest \
  -x map-ont -t 8 /ftmp/reference.fna /ftmp/query.fastq.gz > mapping.paf
```

**PAF with CIGAR:**
```bash
docker run --network=none -v $(pwd):/ftmp dnalinux/minimap2:latest \
  -cx map-ont -t 8 /ftmp/reference.fna /ftmp/query.fastq.gz > align.paf
```

**SAM output:**
```bash
docker run --network=none -v $(pwd):/ftmp dnalinux/minimap2:latest \
  -ax map-ont -t 8 /ftmp/reference.fna /ftmp/query.fastq.gz > alignment.sam
```

**SAM piped to samtools for sorted BAM:**
```bash
docker run --network=none -v $(pwd):/ftmp dnalinux/minimap2:latest \
  -ax map-ont -t 8 /ftmp/reference.fna /ftmp/query.fastq.gz | \
  samtools sort -@ 4 -o alignment.bam -
samtools index alignment.bam
```

**Short-read paired-end Illumina:**
```bash
docker run --network=none -v $(pwd):/ftmp dnalinux/minimap2:latest \
  -ax sr -t 8 /ftmp/reference.fna /ftmp/R1.fastq.gz /ftmp/R2.fastq.gz | \
  samtools sort -@ 4 -o illumina.bam -
```

### 3. Build and reuse index (optional)

For large references, build the index once and reuse it. **Pass the same preset when building the index** since indexing parameters are baked in:

```bash
docker run --network=none -v $(pwd):/ftmp dnalinux/minimap2:latest \
  -x map-ont -d /ftmp/ref-ont.mmi /ftmp/reference.fna
```

Then use the index in place of the FASTA:

```bash
docker run --network=none -v $(pwd):/ftmp dnalinux/minimap2:latest \
  -ax map-ont -t 8 /ftmp/ref-ont.mmi /ftmp/query.fastq.gz > alignment.sam
```

**Note:** Keep separate indexes per preset (e.g., `ref-ont.mmi`, `ref-hifi.mmi`, `ref-sr.mmi`) if running minimap2 for different data types.

## Pitfalls

**Preset must match at index and mapping time:**
Indexing parameters (`-k`, `-w`, `-H`, `-I`) are baked into the `.mmi` file and cannot be changed at mapping time. Always pass the same `-x` preset when building and using an index.

**Default thread count is only 3:**
Minimap2 defaults to 3 threads. On modern hardware, pass `-t $(nproc)` or a specific number. Scales nearly linearly up to ~16 threads.

**PAF vs SAM confusion:**
- Default output is PAF (pairwise mapping format) - no CIGAR, approximate coordinates only
- Use `-c` for PAF with CIGAR
- Use `-a` for SAM output (required for downstream tools expecting BAM)

**Heterozygous sites with haplotype selection:**
Unlike BWA, minimap2 doesn't have a direct equivalent to `-M` for marking secondary alignments for Picard compatibility. Use appropriate downstream filters.

## Verification

Minimap2 writes status, version, and runtime to stderr. Capture with `2> minimap2.log`:

```text
[M::main] Version: 2.30-r1287
[M::main] CMD: minimap2 -ax map-ont /ftmp/ref-ont.mmi /ftmp/query.fastq.gz
[M::main] Real time: 6.536 sec; CPU: 17.485 sec; Peak RSS: 1.225 GB
```

Check the last three lines for version, command, and resource usage.

For SAM output, verify with samtools:
```bash
samtools view -c alignment.bam  # Count total records
samtools flagstat alignment.bam  # Mapping statistics
```

## Key Parameters

### Presets and Output
| Flag | Description |
|------|-------------|
| `-x PRESET` | Preset for data type (map-ont, map-pb, map-hifi, sr, asm5, splice) |
| `-a` | Output SAM format |
| `-c` | Output PAF with CIGAR |
| `-t N` | Number of threads (default 3) |

### Indexing
| Flag | Description |
|------|-------------|
| `-d FILE.mmi` | Build index file |
| `-k N` | K-mer size (preset-dependent, don't change) |
| `-w N` | Minimizer window size (preset-dependent) |

### Input/Output
| Flag | Description |
|------|-------------|
| Input 1 | Reference FASTA or pre-built .mmi index |
| Input 2+ | Query FASTA/FASTQ (one for single-end, two for paired-end with `-x sr`) |
| Output | Redirect to file with `>` |

## Citation

Heng Li, Minimap2: pairwise alignment for nucleotide sequences, Bioinformatics, Volume 34, Issue 18, September 2018, Pages 3094–3100, https://doi.org/10.1093/bioinformatics/bty191
