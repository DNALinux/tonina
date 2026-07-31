---
name: bwa-mem
description: Map Illumina paired-end reads (70-100bp) to reference genomes using BWA-MEM alignment
version: 1.0.0
platforms: [macos, linux]
metadata:
  hermes:
    tags: [bioinformatics, alignment, mapping, bwa, illumina, paired-end]
    category: bioinformatics
    requires_toolsets: [terminal]
---

# BWA-MEM Alignment

BWA-MEM maps short reads against large reference genomes (e.g., human). It performs local/end-to-end alignment, handles paired-end reads, and tolerates chimeric sequences. Suitable for 70bp–few megabase query lengths.

## When to Use

Use BWA-MEM when you have:

**Input requirements:**
- Reference genome (FASTA format)
- Paired-end Illumina reads (cleaned FASTQ)
- Sufficient RAM (~5-6 GB for human genome)

**Appropriate scenarios:**
- Resequencing projects (samples close to reference)
- Variant calling workflows
- ChIP-seq, RNA-seq, ATAC-seq alignment
- Any analysis requiring read-to-genome mapping

**Not suitable for:**
- Samples highly divergent from reference → Use de novo assembly (SPAdes)
- Multiple sequence alignment → Use MUSCLE or Clustal Omega
- No reference available → Use de novo assembly

## Procedure

### 1. Index the reference genome

BWA requires an indexed reference. Skip if `.bwt`, `.sa`, `.pac`, `.ann`, `.amb` files exist alongside your FASTA.

```bash
docker run --rm -v $(pwd):/ftmp -w /ftmp dnalinux/bwa \
  index /ftmp/reference.fasta
```

**Output:** 5 index files (`.bwt`, `.sa`, `.pac`, `.ann`, `.amb`)

**Time:** ~1-2 hours for human genome, ~5 minutes for bacterial genome.

### 2. Align paired-end reads

```bash
docker run --rm -v $(pwd):/ftmp -w /ftmp dnalinux/bwa \
  mem -t $(nproc) reference.fasta reads_R1.fastq.gz reads_R2.fastq.gz > aligned_reads.sam
```

**Flags:**
- `-t $(nproc)` — Use all available CPU cores
- Input: reference FASTA (not the index files explicitly)
- Input: R1 and R2 FASTQ files (can be gzipped)
- Output: SAM file (redirect to file with `>`)

**Time:** ~2-6 hours for 30× human genome, ~10-30 minutes for bacterial genome.

### 3. Convert SAM to BAM (next step)

BWA-MEM outputs SAM format. Use `samtools` to convert, sort, and index:

```bash
docker run --rm -v $(pwd):/ftmp -w /ftmp dnalinux/samtools \
  samtools sort -@ $(nproc) -o aligned_sorted.bam aligned_reads.sam

docker run --rm -v $(pwd):/ftmp -w /ftmp dnalinux/samtools \
  samtools index aligned_sorted.bam
```

**Output:** `aligned_sorted.bam` + `aligned_sorted.bam.bai` (ready for variant calling)

## Pitfalls

**Memory requirements for large genomes:**
Human genome (~3 Gb) needs ~5-6 GB RAM just to hold the BWA index in memory. Ensure your system has enough free RAM before starting. If the process is killed with "Killed" message, you're out of memory.

**Index files must be in same directory as FASTA:**
BWA looks for `.bwt`, `.sa`, `.pac`, `.ann`, `.amb` files with the same basename as the reference FASTA. If they're in a different directory, BWA won't find them and will try to re-index (slow).

```bash
# Correct structure
/data/reference.fasta
/data/reference.fasta.bwt
/data/reference.fasta.sa
...

# Wrong (index files in subdirectory) - BWA won't find them
/data/reference.fasta
/data/indexes/reference.fasta.bwt
```

**Picard compatibility:**
If you're using Picard downstream (MarkDuplicates, etc.), add `-M` flag to mark secondary alignments:

```bash
bwa mem -M -t $(nproc) reference.fasta R1.fastq.gz R2.fastq.gz > aligned.sam
```

## Verification

Successful alignment produces:
- SAM file with alignment records
- Header lines starting with `@`
- Alignment lines with QNAME, FLAG, RNAME, POS, MAPQ, etc.

Quick validation:
```bash
# Count total reads
grep -v "^@" aligned_reads.sam | wc -l

# Count mapped reads (FLAG bit 0x4 unset)
samtools view -F 4 -c aligned_reads.sam

# Mapping rate should be >90% for good samples
```

Check stderr output for BWA stats:
- `[mem_process_seqs] Processed N reads in X seconds`
- If you see warnings about "excessive mismatches," your sample may be divergent from the reference.

## Key Parameters

### Alignment Options
| Flag | Description |
|------|-------------|
| `-t N` | Number of threads (default 1) |
| `-M` | Mark shorter split hits as secondary (Picard compatibility) |
| `-R STR` | Read group header line (e.g., `@RG\tID:sample1\tSM:sample1`) |
| `-T N` | Minimum score to output (default 30) |
| `-U N` | Penalty for unpaired read pair |

### Alignment Scoring
| Flag | Description |
|------|-------------|
| `-A N` | Matching score (default 1) |
| `-B N` | Mismatch penalty (default 4) |
| `-O N,M` | Gap open penalty (default 6,6) |
| `-E N,M` | Gap extension penalty (default 1,1) |

### Insert Size (Paired-End)
| Flag | Description |
|------|-------------|
| `-I FLOAT,FLOAT,INT,INT` | Mean, std dev, max, min insert size |

## Citation

Li H. (2013). Aligning sequence reads, clone sequences and assembly contigs with BWA-MEM. *arXiv preprint* arXiv:1303.3997. doi:10.48550/arXiv.1303.3997
