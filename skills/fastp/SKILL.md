---
name: fastp
description: "Uses fastp docker to to provide ultrafast all-in-one preprocessing and quality control for FastQ data."
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

# Fastp Skill

Fastp is a tool for fast, versatile, and comprehensive preprocessing and quality control for FastQ data. It provides ultrafast all-in-one preprocessing and quality control for FastQ data.

This tool is designed for processing short reads (i.e. Illumina NovaSeq, MGI), if you are looking for tools to process long reads (i.e. Nanopore, PacBio, Cyclone), please use fastplong.

fastp supports batch processing of multiple FASTQ files in a folder.

## When to use it


After sequencing and running fastqc, if you need to clean your sequences, you can use fastp. You should clean your sequences before running any downstream analysis.




## Fastp Usage

Note that there is a docker (dnalinux/fastp) that provides the fastp command.

The docker command mounts your current directory to `/ftmp` inside the container. All file paths in the examples below are relative to `/ftmp/`, which maps to wherever you run the command from.

If the files to be analyzed are in the sra-output subdirectory, and the files are SRR30545881_1.fastqc and SRR30545881_2.fastqc you can use the following command:


```bash
podman run --rm --network=none -v $(pwd):/ftmp dnalinux/fastp:latest sh -c "fastp -i /ftmp/sra-output/SRR30545881_1.fastqc -I /ftmp/sra-output/SRR30545881_2.fastqc -o /ftmp/sra-output/SRR30545881_1_cleaned.fastqc -O /ftmp/sra-output/SRR30545881_2_cleaned.fastqc"
```

If it is only one file called SRR30545881.fastqc, you can use the following command:

```bash
podman run --rm --network=none -v $(pwd):/ftmp dnalinux/fastp:latest sh -c "fastp -i /ftmp/sra-output/SRR30545881.fastqc -o /ftmp/sra-output/SRR30545881_cleaned.fastqc"
```



# fastp CLI — Key Parameters Reference

## Input / Output
| Flag | Long Form | Description |
|------|-----------|-------------|
| `-i` | `--in1` | Read1 input file |
| `-o` | `--out1` | Read1 output file |
| `-I` | `--in2` | Read2 input file (PE) |
| `-O` | `--out2` | Read2 output file (PE) |
| | `--failed_out` | File to store reads that failed filters |
| | `--stdin` / `--stdout` | Stream input/output via STDIN/STDOUT |

## Adapter Trimming
| Flag | Long Form | Description |
|------|-----------|-------------|
| `-A` | `--disable_adapter_trimming` | Disable adapter trimming (enabled by default) |
| `-a` | `--adapter_sequence` | Adapter for read1 (auto-detected if not set) |
| | `--adapter_sequence_r2` | Adapter for read2 (PE only) |
| | `--adapter_fasta` | FASTA file with adapter sequences to trim |
| `-2` | `--detect_adapter_for_pe` | Enable stricter adapter detection for PE data |

## Quality Filtering
| Flag | Long Form | Description |
|------|-----------|-------------|
| `-Q` | `--disable_quality_filtering` | Disable quality filtering (enabled by default) |
| `-q` | `--qualified_quality_phred` | Minimum quality score per base. Default: `15` (Q15) |
| `-u` | `--unqualified_percent_limit` | Max % of unqualified bases allowed. Default: `40` |
| `-e` | `--average_qual` | Discard reads below this average quality. Default: `0` (off) |
| `-n` | `--n_base_limit` | Discard reads with more than N ambiguous bases. Default: `5` |

## Sliding Window Cutting
| Flag | Long Form | Description |
|------|-----------|-------------|
| `-5` | `--cut_front` | Trim low-quality bases from 5' end using sliding window |
| `-3` | `--cut_tail` | Trim low-quality bases from 3' end using sliding window |
| `-r` | `--cut_right` | Drop everything from the first low-quality window rightward |
| `-W` | `--cut_window_size` | Sliding window size. Default: `4` |
| `-M` | `--cut_mean_quality` | Min mean quality for sliding window. Default: `20` (Q20) |

## Length Filtering
| Flag | Long Form | Description |
|------|-----------|-------------|
| `-L` | `--disable_length_filtering` | Disable length filtering (enabled by default) |
| `-l` | `--length_required` | Discard reads shorter than this. Default: `15` |
| | `--length_limit` | Discard reads longer than this. Default: `0` (off) |

## Paired-End Specific
| Flag | Long Form | Description |
|------|-----------|-------------|
| `-m` | `--merge` | Merge overlapping PE reads into a single read |
| | `--merged_out` | Output file for merged reads |
| `-c` | `--correction` | Enable base correction in overlapping PE regions |

## PolyX Trimming
| Flag | Long Form | Description |
|------|-----------|-------------|
| `-g` | `--trim_poly_g` | Force polyG trimming (auto-enabled for NextSeq/NovaSeq) |
| `-G` | `--disable_trim_poly_g` | Disable polyG trimming |
| `-x` | `--trim_poly_x` | Enable polyX trimming at 3' end |

## Deduplication
| Flag | Long Form | Description |
|------|-----------|-------------|
| `-D` | `--dedup` | Enable deduplication |
| | `--dup_calc_accuracy` | Accuracy level `1–6` (higher = more memory). Default: `3` in dedup mode |

## Reporting
| Flag | Long Form | Description |
|------|-----------|-------------|
| `-j` | `--json` | JSON report filename. Default: `fastp.json` |
| `-h` | `--html` | HTML report filename. Default: `fastp.html` |
| `-R` | `--report_title` | Title for the HTML report |

## Performance
| Flag | Long Form | Description |
|------|-----------|-------------|
| `-w` | `--thread` | Number of worker threads. Default: `3` |
| `-z` | `--compression` | Gzip compression level `1–9`. Default: `4` |



# To cite

If the user asks for a citation, provide the following:

Chen, S. (2025). Fastp 1.0: An ultra‐fast all‐round tool for FASTQ data quality control and preprocessing. Imeta, 4(5), e70078.