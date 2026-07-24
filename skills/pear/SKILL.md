---
name:  PEAR
description: "Merges overlapping paired-end FASTQ/FASTQ.GZ reads (Illumina-style forward/reverse read pairs) into single assembled sequences. Use this whenever the user has forward and reverse read files and wants to merge, assemble, or join paired-end reads, even if they just say 'merge my reads' or mention R1/R2 FASTQ files. Not for single-file reads, alignment to a reference, or structural variant calling"
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

# PEAR- Paired-End reAd mergeR Skill 

This skill evaluates all possible paired-end read overlaps and without requiring the target fragment size as input. In addition, it implements a statistical test for minimizing false-positive results. Together with a highly optimized implementation, it can merge millions of paired end reads within a couple of minutes on a standard desktop computer.

## When This Skill Is Used

Use this workflow when you have:
- Two files: one file that contains the forward paired-end reads and one file that contains the reverse paired-end reads.
- A need to merge millions of paired end reads within a couple of minutes on a standard desktop computer.

This approach is **not** suitable for:
- Only one file of paired-end reads
- Pairwise assignment tasks
- Aligning genomic structural variants, whole chromosomes, or sequencing reads against a reference genome

## Input Types

- **Forward reads**— Gzip-compressed paired-end sequence reads (`.fastq.gz` or `.fq.gz`).
- **Reverse reads** — Gzip-compressed paired-end sequence reads (`.fastq.gz` or `.fq.gz`).

---

## Workflow

### Step 1: Merge

```bash
docker run --rm -v $(pwd):/ftmp -w /ftmp dnalinux/pear \
pear \
-f forward_reads.fq.gz \
-r reverse_reads.fq.gz \
-o merged_reads \
-j $(nproc) 
```

- `-f`: Specify the name of file that contains the forward paired-end reads.
- `-r`: Specify the name of file that contains the reverse paired-end reads.
- `-o`: Specify the name to be used as base for the output files.
- `-j`: Number of threads to use.

## Output

Each run of `pear` produces four files:

- `assembled.fastq` — A file containing the assembled reads
- `unassembled.forward.fastq`, resp.`unassembled.reverse.fastq` — two files containing the forward, resp. reverse, unassembled reads
- `discarded.fastq` — a file containing the discarded reads

- Ex.
  - if "merged_reads" is the output name, you should get:
    - Assembled reads file...............: merged_reads.assembled.fastq
    - Discarded reads file...............: merged_reads.discarded.fastq
    - Unassembled forward reads file.....: merged_reads.unassembled.forward.fastq
    - Unassembled reverse reads file.....: merged_reads.unassembled.reverse.fastq

---

## Additional Useful Parameters

These can be added to the `pear` command:

- `-v`: Specify the minimum overlap size. The minimum overlap may be set to 1 when the statistical test is used. However, further restricting the minimum overlap size to a proper value may reduce false-positive assemblies. (default: 10)
- `-m`: Specify the maximum possible length of the assembled sequences. Setting this value to 0 disables the restriction and assembled sequences may be arbitrary long. (default: 0)
- `-n`: Specify the minimum possible length of the assembled sequences. Setting this value to 0 disables the restriction and assembled sequences may be arbitrary short. (default: 50)
- `-q`: Specify the quality score threshold for trimming the low quality part of a read. If the quality scores of two consecutive bases are strictly less than the specified threshold, the rest of the read will be trimmed. (default: 0)
- `-b`: Base PHRED quality score. (default: 33)


**Example with (`-v`), (`-q`), (`-b`):**

- If your dataset uses **Phred 64** quality scoring instead of the standard Phred 33, and you want to enforce a stricter **minimum overlap of 20 base pairs** while trimming low-quality ends (score below 15), run:

```bash
docker run --rm -v $(pwd):/ftmp -w /ftmp dnalinux/pear \
pear \
-f forward_reads.fq.gz \
-r reverse_reads.fq.gz \
-o merged_reads \
-j $(nproc) \
-b 64 \
-v 20 \
-q 15
```


## Citation

If the user asks for a citation for pear, provide the following:

PEAR: a fast and accurate Illumina Paired-End reAd mergeR 
Zhang et al (2014) Bioinformatics 30(5): 614-620 | doi:10.1093/bioinformatics/btt593