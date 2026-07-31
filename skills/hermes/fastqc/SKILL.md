---
name: fastqc
description: Quality control analysis for high-throughput sequencing data using FastQC docker container
version: 1.0.0
platforms: [macos, linux]
metadata:
  hermes:
    tags: [bioinformatics, qc, sequencing, quality-control, fastq, illumina]
    category: bioinformatics
    requires_toolsets: [terminal]
---

# FastQC Quality Control

FastQC analyzes high-throughput sequencing data to identify quality issues, adapter contamination, GC bias, and other problems before biological analysis.

## When to Use

Use FastQC at two points in your sequencing workflow:

**Before cleaning (diagnostic phase):**
- Right after receiving raw FASTQ files from the sequencer
- Identify if quality is sufficient to proceed
- Detect adapter contamination
- Check for unexpected contamination or GC content anomalies
- Make informed decisions about cleaning parameters

**After cleaning (verification phase):**
- After running fastp, Trimmomatic, or other cleaning tools
- Verify adapters were removed
- Confirm quality scores improved
- Ensure read loss is acceptable

## Procedure

### 1. Run FastQC on FASTQ files

Use the `dnalinux/fastqc` Docker container. The container mounts your current directory to `/ftmp`.

```bash
podman run --rm --network=none -v $(pwd):/ftmp dnalinux/fastqc:latest sh -c \
  "fastqc /ftmp/sra-output/SRR30545881*.fastq -o /ftmp/tmp/ --extract"
```

**Key flags:**
- `-o /ftmp/tmp/` — Output directory (must already exist)
- `--extract` — Extract ZIP contents automatically

### 2. Check the summary

FastQC creates a directory per input file (e.g., `SRR30545881_1_fastqc/`). Read the `summary.txt` file:

```bash
cat tmp/SRR30545881_1_fastqc/summary.txt
```

Example output:
```
PASS    Basic Statistics        SRR30545881_1.fastq
PASS    Per base sequence quality       SRR30545881_1.fastq
FAIL    Per base sequence content       SRR30545881_1.fastq
FAIL    Per sequence GC content SRR30545881_1.fastq
FAIL    Adapter Content SRR30545881_1.fastq
```

### 3. Interpret results

- **PASS** — No issues detected
- **WARN** — Slightly unusual, may be expected
- **FAIL** — Problematic, requires attention

Common failures:
- **Adapter Content FAIL** → Run fastp or trimmomatic
- **Per base sequence quality FAIL** → Quality trimming needed
- **GC content FAIL** → May indicate contamination

### 4. View detailed HTML report

Open `fastqc_report.html` in a browser for interactive plots and per-module details.

## Pitfalls

**Output directory must exist:**
The `-o` flag requires a pre-existing directory. FastQC won't create it. If you get an error, create the directory first:
```bash
mkdir -p tmp/
```

**Very long reads can crash nogroup mode:**
The `--nogroup` flag disables base grouping for reads >50bp, showing every base individually. This can crash on very long reads (Nanopore, PacBio) and produce enormous plots. Avoid unless analyzing short, fixed-length reads.

**Multiple files pattern matching:**
When using wildcards (`*.fastq`), ensure they're inside the Docker container's `/ftmp` path, not the host path:
```bash
# Correct
/ftmp/sra-output/*.fastq

# Wrong (won't expand correctly)
$(pwd)/sra-output/*.fastq
```

## Verification

Successful run produces:
- `<filename>_fastqc/` directory for each input file
- `summary.txt` with PASS/WARN/FAIL per module
- `fastqc_report.html` with full report
- `fastqc_data.txt` with raw metrics

Check the summary file was created:
```bash
ls -l tmp/SRR30545881_1_fastqc/summary.txt
```

## CLI Reference

### Input/Output
| Flag | Description |
|------|-------------|
| `-o, --outdir` | Output directory (must exist) |
| `-f, --format` | Force format: `bam`, `sam`, `fastq` |
| `--extract` | Extract ZIP contents after creation |
| `--noextract` | Keep ZIPs compressed (recommended for automation) |

### Analysis Options
| Flag | Description |
|------|-------------|
| `-t, --threads N` | Process N files simultaneously (default 1) |
| `-k, --kmers N` | Kmer length 2-10 (default 7) |
| `--nogroup` | Don't group bases >50bp (warning: can crash on long reads) |
| `--nano` | Process Nanopore fast5 files |
| `--casava` | Handle CASAVA-formatted files |

### Custom References
| Flag | Description |
|------|-------------|
| `-c, --contaminants FILE` | Custom contaminants file (name<tab>sequence per line) |
| `-a, --adapters FILE` | Custom adapters file (same format) |
| `-l, --limits FILE` | Custom warn/error thresholds |

### Performance
| Flag | Description |
|------|-------------|
| `-t, --threads N` | Simultaneous file processing (each uses ~250MB RAM) |
| `--memory N` | Memory per file in MB (default 512) |
| `-d, --dir PATH` | Temp directory for image generation |

## Citation

Andrews S. (2010). FastQC: A quality control tool for high throughput sequence data. http://www.bioinformatics.babraham.ac.uk/projects/fastqc/
