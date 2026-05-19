---
name: SRAToolkit
description: "Download and convert NCBI SRA accessions to FASTQ/FASTA using fasterq-dump."
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

# SRA Toolkit Skill

The SRA Toolkit is a set of NCBI programs for downloading, validating and converting data from the SRA (Sequence Read Archive) database. This skill focuses on the consumer-side workflow: turning an SRA accession into FASTQ/FASTA files with `fasterq-dump`.

This skill uses the `dnalinux/sra-toolkit:latest` docker image (current upstream release of the SRA Toolkit). Run `docker run --rm dnalinux/sra-toolkit:latest fasterq-dump --version` to print the exact version in your local image.

> **Note:** Unlike most other skills in this collection, the container requires network access (it talks to NCBI, AWS and GCP). Do **not** pass `--network=none`.

## When to use it

Use the SRA Toolkit to:

- Download sequence data for a given SRA accession (`SRR...`, `ERR...`, `DRR...`).
- Convert local `.sra` files to FASTQ or FASTA.
- Inspect and validate SRA archives (`sra-stat`, `vdb-validate`).

Submission of new data to SRA is **not** done with these tools - it is handled by NCBI's submission portal and is out of scope here.

## SRA Toolkit Usage

The docker command mounts your current directory to `/ftmp` inside the container. All paths in the examples below are relative to `/ftmp/`, which maps to wherever you run the command from.

`fasterq-dump` is the successor to the older `fastq-dump`. It is significantly faster but **not** a drop-in replacement: options and defaults differ. The only mandatory argument is the accession (or path to a local `.sra` file).

### First-run configuration tip

The first invocation of any SRA tool can prompt about cloud usage / telemetry and stall in non-interactive contexts. To avoid that in scripts, initialize a default config inside the container (one-time):

```bash
docker run --rm -v $(pwd):/ftmp dnalinux/sra-toolkit:latest vdb-config --restore-defaults
```

### Recommended workflow: prefetch then fasterq-dump

For large accessions or unreliable networks, NCBI recommends downloading the `.sra` archive first with `prefetch`, then converting locally:

```bash
docker run --rm -v $(pwd):/ftmp dnalinux/sra-toolkit:latest prefetch SRR15536067 -O /ftmp
docker run --rm -v $(pwd):/ftmp dnalinux/sra-toolkit:latest fasterq-dump /ftmp/SRR15536067 --outdir /ftmp
```

### One-shot download with fasterq-dump

For a small/fast accession you can skip `prefetch` - `fasterq-dump` will fetch and convert in one step:

```bash
docker run --rm -v $(pwd):/ftmp dnalinux/sra-toolkit:latest fasterq-dump SRR15536067 --outdir /ftmp
```

### Expected output files

The default mode is `--split-3`, which yields different files depending on the experiment layout:

- **Paired-end** accession - produces `<acc>_1.fastq` and `<acc>_2.fastq` (plus `<acc>.fastq` for any orphan/unpaired reads).
- **Single-end** accession - produces a single `<acc>.fastq`.

If the output files already exist, the tool exits with an error. Pass `-f/--force` to overwrite.

### Choosing a temp directory

`fasterq-dump` needs scratch space roughly **10x** the size of the final FASTQ. By default it uses the current working directory. Override with `-t/--temp` and point it at a host-mounted path so it lands on a fast disk (and is not lost to the container):

```bash
docker run --rm -v $(pwd):/ftmp dnalinux/sra-toolkit:latest \
  fasterq-dump SRR15536067 --outdir /ftmp -t /ftmp/scratch
```

For maximum speed, mount a separate SSD or a `tmpfs` (`/dev/shm` on the host) as a second volume and point `-t` at it. Output-path and scratch-path on different filesystems noticeably improves throughput.

### Compressed output

`fasterq-dump` writes **uncompressed** FASTQ. To get gzipped output, pipe through `gzip`/`pigz` after the run, e.g.:

```bash
gzip -f SRR15536067_1.fastq SRR15536067_2.fastq SRR15536067.fastq
```

Alternatively use the older `fastq-dump --gzip SRR15536067` if you prefer compression-during-extraction at the cost of speed.

### Stream to stdout

Use `-Z/--stdout` to pipe FASTQ directly into a downstream tool without an intermediate file:

```bash
docker run --rm -v $(pwd):/ftmp dnalinux/sra-toolkit:latest \
  fasterq-dump -Z SRR15536067 | head
```

### Companion tools in the image

| Tool | Purpose |
|------|---------|
| `prefetch` | Download an SRA archive (`.sra`) by accession. Recommended first step. |
| `fasterq-dump` | Convert `.sra` (or accession) to FASTQ/FASTA. |
| `fastq-dump` | Older converter; supports `--gzip` and `--bzip2` natively. |
| `vdb-validate` | Check integrity of a downloaded `.sra` archive. |
| `sra-stat` | Print statistics (spot count, base count, etc.) for an accession. |
| `sam-dump` | Convert aligned SRA data to SAM. |
| `vdb-config` | Read/write toolkit configuration (cloud, telemetry, cache dir). |


## fasterq-dump modes

### fastq

| Mode | Variant | Command | Output |
|---|---|---|---|
| **split-3** | (default) | `fasterq-dump SRRXXXXXXX` or `fasterq-dump --split-3 SRRXXXXXXX` | Multiple files |
| **split-files** | without technical | `fasterq-dump --split-files SRRXXXXXXX` or `fasterq-dump --split-files --skip-technical SRRXXXXXXX` | Multiple files |
| **split-files** | with technical | `fasterq-dump --split-files --include-technical SRRXXXXXXX` | Single file |
| **split-spot** | without technical | `fasterq-dump --split-spot SRRXXXXXXX` or `fasterq-dump --split-spot --skip-technical SRRXXXXXXX` | Single file |
| **split-spot** | with technical | `fasterq-dump --split-spot --include-technical SRRXXXXXXX` | Single file |
| **concatenate-reads** | — | `fasterq-dump --concatenate-reads SRRXXXXXXX` | Single file |


### fasta

| Mode | Variant | Command | Output |
|---|---|---|---|
| **split-3** | (default) | `fasterq-dump --fasta SRRXXXXXXX` or `fasterq-dump --fasta --split-3 SRRXXXXXXX` | Multiple files |
| **split-files** | without technical | `fasterq-dump --fasta --split-files SRRXXXXXXX` or `fasterq-dump --fasta --split-files --skip-technical SRRXXXXXXX` | Multiple files |
| **split-files** | with technical | `fasterq-dump --fasta --split-files --include-technical SRRXXXXXXX` | Single file |
| **split-spot** | without technical | `fasterq-dump --fasta --split-spot SRRXXXXXXX` or `fasterq-dump --fasta --split-spot --skip-technical SRRXXXXXXX` | Single file |
| **split-spot** | with technical | `fasterq-dump --fasta --split-spot --include-technical SRRXXXXXXX` | Single file |
| **concatenate-reads** | — | `fasterq-dump --fasta --concatenate-reads SRRXXXXXXX` | Single file |
| **unsorted** | without technical | `fasterq-dump --fasta-unsorted SRRXXXXXXX` or `fasterq-dump --fasta-unsorted --skip-technical SRRXXXXXXX` | Single file |
| **unsorted** | with technical | `fasterq-dump --fasta-unsorted --include-technical SRRXXXXXXX` | Single file |



## Options (fasterq-dump)



| Flag | Long form | Description |
|---|---|---|
| | `<path>` or `<accession>` | Input: local path or SRA accession |
| `-F` | `--format` | Format: special, fastq (default=fastq) |
| `-o` | `--outfile` | Output file name |
| `-O` | `--outdir` | Output directory |
| `-b` | `--bufsize` | File buffer size (default=1MB) |
| `-c` | `--curcache` | Cursor cache size (default=10MB) |
| `-m` | `--mem` | Memory limit for sorting (default=100MB) |
| `-t` | `--temp` | Temp files location (default=current dir) |
| `-e` | `--threads` | Number of threads (default=6) |
| `-p` | `--progress` | Show progress |
| `-x` | `--details` | Print details |
| `-s` | `--split-spot` | Split spots into reads |
| `-S` | `--split-files` | Write reads into different files |
| `-3` | `--split-3` | Write single reads into special file (default) |
| | `--concatenate-reads` | Write whole spots into one file |
| `-Z` | `--stdout` | Print output to stdout |
| `-f` | `--force` | Force overwrite of existing file(s) |
| | `--skip-technical` | Skip technical reads |
| | `--include-technical` | Include technical reads |
| `-M` | `--min-read-len` | Filter by sequence length |
| | `--table` | Seq-table to use (PacBio) |
| `-B` | `--bases` | Filter by bases |
| `-A` | `--append` | Append to output file |
| | `--fasta` | Produce FASTA output |
| | `--fasta-unsorted` | Produce FASTA output, unsorted |
| | `--fasta-ref-tbl` | Produce FASTA from REFERENCE table |
| | `--fasta-concat-all` | Concatenate all rows into FASTA |
| | `--internal-ref` | Extract only internal REFERENCEs |
| | `--external-ref` | Extract only external REFERENCEs |
| | `--ref-name` | Extract only specified REFERENCEs |
| | `--ref-report` | Enumerate references |
| | `--use-name` | Print name instead of seq-id |
| | `--seq-defline` | Custom defline for sequence (`$ac`, `$sn`, `$sg`, `$si`, `$ri`, `$rl`) |
| | `--qual-defline` | Custom defline for qualities (same as `--seq-defline`) |
| `-U` | `--only-unaligned` | Process only unaligned reads |
| `-a` | `--only-aligned` | Process only aligned reads |
| | `--disk-limit` | Explicitly set disk limit |
| | `--disk-limit-tmp` | Explicitly set disk limit for temp files |
| | `--size-check` | Size check control: `on` (default), `off`, or `only` |
| | `--ngc <PATH>` | Path to ngc file |
| `-h` | `--help` | Show help |
| `-V` | `--version` | Display version and quit |
| `-L` | `--log-level` | Log level: `fatal\|sys\|int\|err\|warn\|info\|debug` or `0–6` (default=warn) |
| `-v` | `--verbose` | Increase verbosity (repeatable, negates quiet) |
| `-q` | `--quiet` | Suppress all status messages (negated by verbose) |
| | `--option-file <file>` | Read options from file |

## Citation

If the user asks for a citation, provide the SRA-specific reference:

Leinonen R, Sugawara H, Shumway M; International Nucleotide Sequence Database Collaboration. The Sequence Read Archive. Nucleic Acids Research. 2011 Jan;39(Database issue):D19-D21. doi:10.1093/nar/gkq1019.

For the SRA Toolkit itself, also point users to the NCBI repository: https://github.com/ncbi/sra-tools
