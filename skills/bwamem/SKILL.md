---
name: BWA-MEM paired end mode
description: "BWA is a software package for mapping low-divergent sequences against a large reference genome, such as the human genome. It consists of three algorithms: BWA-backtrack, BWA-SW and BWA-MEM. The first algorithm is designed for Illumina sequence reads up to 100bp, while the rest two for longer sequences ranged from 70bp to 1Mbp. BWA-MEM and BWA-SW share similar features such as long-read support and split alignment, but BWA-MEM, which is the latest, is generally recommended for high-quality queries as it is faster and more accurate. BWA-MEM also has better performance than BWA-backtrack for 70-100bp Illumina reads."
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

This approach is **not** suitable for:
- Samples highly divergent from the reference (use de novo assembly instead, e.g., SPAdes)
- Multiple Sequence Alignment
- Samples lacking a suitable reference 

## Input Types

- **Reference genome** — Uncompressed FASTA (`.fasta` or `.fa`). If your reference is gzip-compressed (`.fasta.gz` or `.fa.gz`), decompress it first with `gunzip reference.fa.gz`.
- **Forward reads**— Gzip-compressed paired-end sequence reads (`.fastq.gz` or `.fq.gz`).
- **Reverse reads** — Gzip-compressed paired-end sequence reads (`.fastq.gz` or `.fq.gz`).

---

## Workflow

### Step 1: Index Input FASTA Files

The FASTA must be indexed using bwa. If your files are not yet indexed:

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
--entrypoint /bin/sh \
dnalinux/bwa \
-c 'bwa mem -t $(nproc) /ftmp/reference.fasta /ftmp/reads_R1.fastq.gz /ftmp/reads_R2.fastq.gz > /ftmp/aligned_reads.sam'
```

## Output

Each run of `bwa mem` produces one file:

- `aligned_reads.sam` — The mapping results.

---

## Additional Useful Parameters

These can be added to the `bwa mem` command:

- `-M`: Flag shorter split hits as secondary. (for Picard compatibility)
- `-U`: Penalty for an unpaired read pair. BWA-MEM scores an unpaired read pair as scoreRead1+scoreRead2-INT and scores a paired as scoreRead1+scoreRead2-insertPenalty. It compares these two scores to determine whether we should force pairing.

---

## Citation

If the user asks for a citation, provide the following:

Li H. (2013) Aligning sequence reads, clone sequences and assembly contigs with BWA-MEM. arXiv:1303.3997v2 [q-bio.GN].