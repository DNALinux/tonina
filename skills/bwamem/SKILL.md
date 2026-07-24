---
name: BWA-MEM paired end mode
description: "BWA is a software package for mapping low-divergent sequences against a large reference genome, such as the human genome. BWA-MEM has long-read support and split alignment, and is generally recommended for high-quality queries and 70-100bp Illumina reads."
metadata:
  openclaw:
    emoji: "🧬"
    requires:
      bins: ["docker"]
    install:
      - id: apt
        kind: apt
        package: podman-docker
        bins: ["podman", "docker"]
        label: "Install Docker"
---

# BWA Indexing and BWA Mem (Local/end-to-end, Paired-end, Pairwise Mapping by Alignment Skill)

This skill aligns sequence reads or long query sequences against a large reference genome such as human. It automatically chooses between local and end-to-end alignments, does paired-end reads and performs chimeric alignment. The algorithm is robust to sequencing errors and applicable to a wide range of sequence lengths from 70bp to a few megabases.

## When This Skill Is Used

Use this workflow when you have:

- A reference genome (FASTA) and raw or trimmed paired-end sequencing reads (FASTQ)
- A need to map individual sequence reads to a reference backbone without performing de novo assembly
- For a human-sized reference genome (~3 Gb), BWA-MEM requires ~5–6 GB of RAM to hold the index. Ensure your machine has sufficient free memory before running.

This approach is **not** suitable for:
- Samples highly divergent from the reference (use de novo assembly instead, e.g., SPAdes)
- Multiple Sequence Alignment
- Samples lacking a suitable reference 

## Input Types

- **Reference genome** — Uncompressed or compressed FASTA (`.fasta` or `.fa`). 
- **Forward reads**— Gzip-compressed paired-end sequence reads (`.fastq.gz` or `.fq.gz`).
- **Reverse reads** — Gzip-compressed paired-end sequence reads (`.fastq.gz` or `.fq.gz`).

---

## Workflow

### Step 1: Index Input FASTA Files

- The FASTA must be indexed using bwa before it can be used. Skip this step if the five index files already exist alongside the reference.

```bash
docker run --rm -v $(pwd):/ftmp \
-w /ftmp \
dnalinux/bwa index /ftmp/reference.fasta
```

- Produces 5 files in these formats: `.bwt`, `.sa`,  `.pac`,  `.ann`,  `.amb` 
- Skip this step if these index files already exist.

### Step 2: Mapping by Alignment

The main function bwa mem to map by alignment is now run.

```bash
docker run --rm -v $(pwd):/ftmp \
-w /ftmp \
dnalinux/bwa \
mem -t $(nproc) reference.fasta reads_R1.fastq.gz reads_R2.fastq.gz > aligned_reads.sam
```

## Output

Each run of `bwa mem` produces one file:

- `aligned_reads.sam` — The mapping results.

## Note

Next step: aligned_reads.sam is typically converted to a sorted, compressed BAM file using samtools for downstream analysis.

---

## Additional Useful Parameters

These can be added to the `bwa mem` command:

- `-M`: Flag shorter split hits as secondary. (for Picard compatibility)
- `-U`: Penalty for an unpaired read pair. BWA-MEM scores an unpaired read pair as scoreRead1+scoreRead2-INT and scores a paired as scoreRead1+scoreRead2-insertPenalty. It compares these two scores to determine whether we should force pairing.

---

## Citation

If the user asks for a citation, provide the following:

Li H. Aligning sequence reads, clone sequences and assembly contigs with BWA-MEM. arXiv preprint arXiv:1303.3997. 2013. doi:10.48550/arXiv.1303.3997
