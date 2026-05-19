---
name: minimap2
description: "Align long/short reads or assemblies to a reference with minimap2."
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

This skill uses the `dnalinux/minimap2:latest` docker image. The image has `minimap2` as its entrypoint, so flags go directly after the image name.

## When to use it

The decision between BWA, BWA-MEM2 and minimap2 is primarily driven by read length, sequencing technology, and computational priorities. If your data comes from long-read platforms — Oxford Nanopore or PacBio — minimap2 is the unambiguous choice: it was purpose-built for this data type, handles high error rates gracefully, supports splice-aware RNA alignment, and is orders of magnitude faster than adapting short-read tools to the task. If your data is short-read Illumina (typically 100–250bp) and you are working in a context where result reproducibility and compatibility with established pipelines (such as GATK best practices for germline or somatic variant calling) is critical, BWA or BWA-MEM2 are appropriate. Between those two, BWA-MEM2 is the straightforward upgrade: it produces identical alignments to BWA-MEM but is meaningfully faster, making it the better default for any new pipeline setup or for centers processing large volumes of samples where compute time is a cost. The only reason to prefer the original BWA over BWA-MEM2 would be legacy system constraints, strict software certification requirements in clinical settings that have already validated BWA, or memory-limited environments where BWA-MEM2's larger index footprint (requiring roughly 28× the reference genome size in RAM) is prohibitive. For projects that span both short and long reads — such as hybrid assembly or multi-platform comparative studies — minimap2's versatility with preset modes (-x sr, -x map-ont, -x asm5, etc.) makes it the most flexible single tool to standardize on.

## Minimap2 Usage

The docker command mounts your current directory to `/ftmp` inside the container. All file paths in the examples below are relative to `/ftmp/`, which maps to wherever you run the command from. `--network=none` is safe here because minimap2 is fully local (no internet required).

Minimap2 transparently reads gzip'd FASTA and FASTQ - no need to decompress first.

### Presets (`-x`)

Almost every real run should pass a preset that matches the data. The most common ones:

| Preset | Use case |
|--------|----------|
| `-x map-ont` | Oxford Nanopore reads vs reference. |
| `-x map-pb` | PacBio CLR reads vs reference. |
| `-x map-hifi` | PacBio HiFi / CCS reads vs reference. |
| `-x sr` | Short Illumina paired-end reads vs reference. |
| `-x asm5` / `-x asm10` / `-x asm20` | Assembly-to-reference at ~5/10/20 % divergence. |
| `-x splice` / `-x splice:hq` | Spliced alignment (mRNA / IsoSeq). |

### Output formats

- **Default (PAF, no CIGAR)** - approximate coordinates only.
- **`-c`** - PAF with CIGAR.
- **`-a`** - SAM (typically piped into `samtools` for sorting/indexing).

PAF column reference: <https://github.com/lh3/miniasm/blob/master/PAF.md>.

### Threads

Minimap2 defaults to **3** threads. On a modern host pass `-t $(nproc)` (or a specific number) - it scales nearly linearly up to ~16 threads.

### Examples

PAF output (no base-level alignment):

```bash
docker run --network=none -v $(pwd):/ftmp dnalinux/minimap2:latest -x map-ont -t 8 /ftmp/reference.fna /ftmp/query.fastq.gz > mapping.paf
```

PAF with CIGAR:

```bash
docker run --network=none -v $(pwd):/ftmp dnalinux/minimap2:latest -cx map-ont -t 8 /ftmp/reference.fna /ftmp/query.fastq.gz > align.paf
```

SAM output:

```bash
docker run --network=none -v $(pwd):/ftmp dnalinux/minimap2:latest -ax map-ont -t 8 /ftmp/reference.fna /ftmp/query.fastq.gz > alignment.sam
```

SAM piped into `samtools` for a sorted, indexed BAM (requires `samtools` on the host or in another container):

```bash
docker run --network=none -v $(pwd):/ftmp dnalinux/minimap2:latest -ax map-ont -t 8 /ftmp/reference.fna /ftmp/query.fastq.gz | samtools sort -@ 4 -o alignment.bam -
samtools index alignment.bam
```

Short-read paired-end Illumina:

```bash
docker run --network=none -v $(pwd):/ftmp dnalinux/minimap2:latest -ax sr -t 8 /ftmp/reference.fna /ftmp/R1.fastq.gz /ftmp/R2.fastq.gz | samtools sort -@ 4 -o illumina.bam -
```

### Reusing a pre-built index

For large references, build the index once and reuse it. **Pass the same preset when building the index**, since indexing parameters (`-k`, `-w`, `-H`, `-I`) are baked in and cannot be changed at mapping time:

```bash
docker run --network=none -v $(pwd):/ftmp dnalinux/minimap2:latest -x map-ont -d /ftmp/ref-ont.mmi /ftmp/reference.fna
```

Then use the index in place of the FASTA:

```bash
docker run --network=none -v $(pwd):/ftmp dnalinux/minimap2:latest -ax map-ont -t 8 /ftmp/ref-ont.mmi /ftmp/query.fastq.gz > alignment.sam
```

If you run minimap2 for different data types (ONT, HiFi, short reads, assemblies, splice), keep separate indexes per preset (e.g. `ref-ont.mmi`, `ref-hifi.mmi`, `ref-sr.mmi`). This is in contrast to BWA, which uses one index regardless of query data type.

### Reading minimap2's log

Minimap2 writes status / version / runtime to **stderr**. Capture it with `2> minimap2.log` if you need it programmatically. A typical tail looks like:

```text
[M::main::0.063*1.45] loaded/built the index for 1 target sequence(s)
[M::mm_mapopt_update::0.078*1.37] mid_occ = 12
[M::mm_idx_stat] kmer size: 15; skip: 10; is_hpc: 0; #seq: 1
[M::mm_idx_stat::0.091*1.32] distinct minimizers: 838542 (98.18% are singletons); average occurrences: 1.034; average spacing: 5.352; total length: 4641652
[M::worker_pipeline::6.530*2.68] mapped 8166 sequences
[M::main] Version: 2.30-r1287
[M::main] CMD: minimap2 -ax map-ont /ftmp/ref-ont.mmi /ftmp/query.fastq.gz
[M::main] Real time: 6.536 sec; CPU: 17.485 sec; Peak RSS: 1.225 GB
```

Use the last three lines (`Version`, `CMD`, `Real time / CPU / Peak RSS`) to report version, command and runtime back to the user.

## Citation

If the user asks for a citation, provide the following:

Heng Li, Minimap2: pairwise alignment for nucleotide sequences, Bioinformatics, Volume 34, Issue 18, September 2018, Pages 3094–3100, https://doi.org/10.1093/bioinformatics/bty191

