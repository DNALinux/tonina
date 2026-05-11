---
name: SRA-TOOLKIT
description: "Uses sra-toolkit docker to download sequences from the SRA (Sequence Read Archive) database."
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

# SRA TOOLKIT Skill

The SRA Toolkit is a set of programs for working with data in the SRA (Sequence Read Archive) database. It provides tools for downloading, uploading, and managing sequence data.

## When to use it

Use the SRA Toolkit to:

* Download sequence data from the SRA database
* Upload sequence data to the SRA database
* Manage sequence data in the SRA database


## SRA TOOLKIT Usage

Note that there is a docker (dnalinux/sra-toolkit) that provides the sra-toolkit commands.

The docker command mounts your current directory to `/ftmp` inside the container. All file paths in the examples below are relative to `/ftmp/`, which maps to wherever you run the command from.

The fasterq-dump tool extracts data in FASTQ- or FASTA-format from SRA-accessions. Fasterq-dump is the successor to the older fastq-dump tool, but faster. However: it is not a drop-in replacement, options and defaults are different.

The tool has one mandatory argument: the accession.

To download a sequence from the SRA database, if the accession number is SRR15536067:


```bash
docker run --rm -v $(pwd):/ftmp dnalinux/sra-toolkit:3.4.1-bin fasterq-dump SRR15536067 --outdir /ftmp
```

Note that the location (output directory) of the output-files can be changed with --outdir

If parts of the output-path do not exist, it will be created. If the output-files already exist, the tool will not overwrite them, but fail instead. If you want already existing output-files to be overwritten, use the force option -f.

The location of the temporary directory can be changed too:


```bash
docker run --rm -v $(pwd):/ftmp dnalinux/sra-toolkit:3.4.1-bin fasterq-dump SRR15536067 --outdir /ftmp -t /tmp/scratch
```

Now the temporary files will be created in the '/tmp/scratch' directory. These temporary files will be deleted on finish, but the directory itself will not be deleted. If the temporary directory does not exist, it will be created.

It is helpful for the speed-up, if the output-path and the scratch-path are on different file-systems. For instance it is a good idea to point the temporary directory to a SSD if available or a RAM-disk like /dev/shm if enough RAM is available.


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



# Options



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

# To cite

If the user asks for a citation, provide the following:

David L. Wheeler, Tanya Barrett, Dennis A. Benson, Stephen H. Bryant, Kathi Canese, Vyacheslav Chetvernin, Deanna M. Church, Michael DiCuccio, Ron Edgar, Scott Federhen, Lewis Y. Geer, Wolfgang Helmberg, Yuri Kapustin, David L. Kenton, Oleg Khovayko, David J. Lipman, Thomas L. Madden, Donna R. Maglott, James Ostell, Kim D. Pruitt, Gregory D. Schuler, Lynn M. Schriml, Edwin Sequeira, Stephen T. Sherry, Karl Sirotkin, Alexandre Souvorov, Grigory Starchenko, Tugba O. Suzek, Roman Tatusov, Tatiana A. Tatusova, Lukas Wagner, Eugene Yaschenko, Database resources of the National Center for Biotechnology Information, Nucleic Acids Research, Volume 34, Issue suppl_1, 1 January 2006, Pages D173–D180, https://doi.org/10.1093/nar/gkj158
