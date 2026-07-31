---
name: bwa-mem
description: Map Illumina paired-end reads (70-100bp) to reference genomes using BWA-MEM alignment
metadata:
  openclaw:
    emoji: "🧬"
    requires:
      bins: ["docker"]
---

# BWA-MEM Alignment Skill

Maps Illumina paired-end reads to large reference genomes. Handles local/end-to-end alignment, paired-end reads, chimeric sequences.

## When to use it

- Resequencing projects (variant calling)
- Samples close to reference genome
- ChIP-seq, RNA-seq, ATAC-seq alignment

**Not for:** Highly divergent samples (use SPAdes de novo assembly)

## Workflow

### Step 1: Index reference

Skip if `.bwt`, `.sa`, `.pac`, `.ann`, `.amb` files exist.

```bash
docker run --rm -v $(pwd):/ftmp -w /ftmp dnalinux/bwa \
  index /ftmp/reference.fasta
```

**Memory:** ~5-6 GB for human genome.

### Step 2: Align reads

```bash
docker run --rm -v $(pwd):/ftmp -w /ftmp dnalinux/bwa \
  mem -t $(nproc) reference.fasta reads_R1.fastq.gz reads_R2.fastq.gz > aligned_reads.sam
```

## Output

- `aligned_reads.sam` — Alignment results

**Next step:** Convert to sorted BAM with samtools:
```bash
samtools sort -@ $(nproc) -o aligned_sorted.bam aligned_reads.sam
samtools index aligned_sorted.bam
```

## Key Parameters

| Flag | Description |
|------|-------------|
| `-t N` | Threads (default 1) |
| `-M` | Mark secondary alignments (Picard compatibility) |
| `-R STR` | Read group header (`@RG\tID:sample\tSM:sample`) |
| `-T N` | Min score to output (default 30) |

## Citation

Li H. (2013). Aligning sequence reads, clone sequences and assembly contigs with BWA-MEM. *arXiv preprint* arXiv:1303.3997. doi:10.48550/arXiv.1303.3997
