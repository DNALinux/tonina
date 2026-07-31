---
name: fastqc
description: Quality control analysis for high-throughput sequencing data using FastQC docker container
metadata:
  openclaw:
    emoji: "🧬"
    requires:
      bins: ["docker"]
---

# FastQC Skill

FastQC analyzes sequencing quality, adapters, contamination, and GC content.

## When to use it

**Before cleaning:** Diagnose raw FASTQ quality, adapter presence, contamination.

**After cleaning:** Verify adapters removed, quality improved, acceptable read loss.

## FastQC Usage

Use `dnalinux/fastqc` Docker container. Mounts current directory to `/ftmp`.

```bash
podman run --rm --network=none -v $(pwd):/ftmp dnalinux/fastqc:latest sh -c \
  "fastqc /ftmp/sra-output/SRR30545881*.fastq -o /ftmp/tmp/ --extract"
```

**Key flags:**
- `-o` — Output directory (must exist)
- `--extract` — Extract ZIP contents

## Output

For input file `SRR30545881_1.fastq`, creates directory `SRR30545881_1_fastqc/` containing:
- `summary.txt` — Quick PASS/WARN/FAIL overview
- `fastqc_report.html` — Full interactive report
- `fastqc_data.txt` — Raw metrics

Read summary:
```bash
cat tmp/SRR30545881_1_fastqc/summary.txt
```

Example:
```
PASS    Basic Statistics        SRR30545881_1.fastq
FAIL    Adapter Content         SRR30545881_1.fastq
```

## Key Parameters

| Flag | Description |
|------|-------------|
| `-o, --outdir` | Output directory (required, must exist) |
| `-t, --threads N` | Process N files simultaneously |
| `--extract` | Extract ZIP contents |
| `-k, --kmers N` | Kmer length 2-10 (default 7) |
| `-c, --contaminants FILE` | Custom contaminants file |
| `-a, --adapters FILE` | Custom adapters file |

## Citation

Andrews S. (2010). FastQC: A quality control tool for high throughput sequence data. http://www.bioinformatics.babraham.ac.uk/projects/fastqc/
