---
name: minimap2
description: "Uses minimap2 docker to align sequences."
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

# Minimap2 Skill


Minimap2 is a versatile sequence alignment program that aligns DNA sequences against a reference genome or other sequences.

## When to use it

The decision between BWA, BWA=MEM2 and minimap2 is primarily driven by read length, sequencing technology, and computational priorities. If your data comes from long-read platforms — Oxford Nanopore or PacBio — minimap2 is the unambiguous choice: it was purpose-built for this data type, handles high error rates gracefully, supports splice-aware RNA alignment, and is orders of magnitude faster than adapting short-read tools to the task. If your data is short-read Illumina (typically 100–250bp) and you are working in a context where result reproducibility and compatibility with established pipelines (such as GATK best practices for germline or somatic variant calling) is critical, BWA or BWA-MEM2 are appropriate. Between those two, BWA-MEM2 is the straightforward upgrade: it produces identical alignments to BWA-MEM but is meaningfully faster, making it the better default for any new pipeline setup or for centers processing large volumes of samples where compute time is a cost. The only reason to prefer the original BWA over BWA-MEM2 would be legacy system constraints, strict software certification requirements in clinical settings that have already validated BWA, or memory-limited environments where BWA-MEM2's larger index footprint (requiring roughly 28× the reference genome size in RAM) is prohibitive. For projects that span both short and long reads — such as hybrid assembly or multi-platform comparative studies — minimap2's versatility with preset modes (-x sr, -x map-ont, -x asm5, etc.) makes it the most flexible single tool to standardize on.

## Minimap2 Usage

Note that there is a docker (dnalinux/minimap2) that has *minimap2* as entry point, so you don't need to specify the command.

To get a Pairwise Alignment Format (PAF) of a reference genome and a query sequence file (like SSR3p.fastq), without base-level alignment (i.e. coordinates are only approximate and no CIGAR in output):

```bash
docker run --network=none -v $(pwd):/ftmp dnalinux/minimap2 /ftmp/.openclaw/workspace/ncbi_dataset/data/GCA_000005845.2/GCA_000005845.2_ASM584v2_genomic.fna /ftmp/SSR3p.fastq > mapping.paf
```

To output a cigar file:

```bash
docker run --network=none -v $(pwd):/ftmp dnalinux/minimap2 -c /ftmp/.openclaw/workspace/ncbi_dataset/data/GCA_000005845.2/GCA_000005845.2_ASM584v2_genomic.fna /ftmp/SSR3p.fastq > align.paf
```

To output a SAM file:

```bash
docker run --network=none -v $(pwd):/ftmp dnalinux/minimap2 -a /ftmp/.openclaw/workspace/ncbi_dataset/data/GCA_000005845.2/GCA_000005845.2_ASM584v2_genomic.fna /ftmp/SSR3p.fastq > alignment.sam
```

Minimap2 seamlessly works with gzip'd FASTA and FASTQ formats as input. You don't need to convert between FASTA and FASTQ or decompress gzip'd files first.

For the human reference genome, minimap2 takes a few minutes to generate a minimizer index for the reference before mapping. To reduce indexing time, you can optionally save the index with option -d and replace the reference sequence file with the index file on the minimap2 command line. Generate an index:

```bash
docker run --network=none -v $(pwd):/ftmp dnalinux/minimap2 -d /ftmp/ref.mmi /ftmp/.openclaw/workspace/ncbi_dataset/data/GCA_000005845.2/GCA_000005845.2_ASM584v2_genomic.fna
```

To use the index for mapping:

```bash
docker run --network=none -v $(pwd):/ftmp dnalinux/minimap2 -a /ftmp/ref.mmi /ftmp/SSR3p.fastq > alignment.sam
```

When doing an alignment with an index, the output will be similar to the following:

```
[M::main::0.063*1.45] loaded/built the index for 1 target sequence(s)
[M::mm_mapopt_update::0.078*1.37] mid_occ = 12
[M::mm_idx_stat] kmer size: 15; skip: 10; is_hpc: 0; #seq: 1
[M::mm_idx_stat::0.091*1.32] distinct minimizers: 838542 (98.18% are singletons); average occurrences: 1.034; average spacing: 5.352; total length: 4641652
[M::worker_pipeline::6.530*2.68] mapped 8166 sequences
[M::main] Version: 2.30-r1287
[M::main] CMD: minimap2 -a /ftmp/ref.mmi /ftmp/SSR3p.fastq
[M::main] Real time: 6.536 sec; CPU: 17.485 sec; Peak RSS: 1.225 GB
```

From this use the last 3 lines to get the version, the command and the runtime information. Inform these parameters to the user.

Importantly, it should be noted that once you build the index, indexing parameters such as -k, -w, -H and -I can't be changed during mapping. If you are running minimap2 for different data types, you will probably need to keep multiple indexes generated with different parameters. This makes minimap2 different from BWA which always uses the same index regardless of query data types.


