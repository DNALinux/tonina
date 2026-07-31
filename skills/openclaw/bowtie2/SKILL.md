---
name: Bowtie2
description: Ultrafast and memory-efficient tool for aligning sequencing reads to long reference sequences. 
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

# Bowtie2 - Sequence Alignment Skill 

This skill is particularly good at aligning reads of about 50 up to 100s or 1,000s of characters, and particularly good at aligning to relatively long (e.g. mammalian) genomes. Bowtie 2 indexes the genome with an FM Index to keep its memory footprint small: for the human genome, its memory footprint is typically around 3.2 GB. Bowtie 2 supports gapped, local, and paired-end alignment modes.

# Biopython Task Router

Select a specific operational path to jump directly to its complete configuration and parameters:

- **Bowtie2 Index**
  - [Build Bowtie2 Index] -- see heading "Workflow: Build Bowtie2 Index with bowtie2-build"
  - [Inspect Bowtie2 Index] -- see heading "Workflow: Inspect Bowtie2 Index with bowtie2-inspect"
- **Alignments**
  - [Run Unpaired Reads] -- see heading "Workflow: Run Unpaired Reads BowTie2 Alignment with bowtie2"
  - [Run Paired Reads] -- see heading "Workflow: Run Paired Reads BowTie2 Alignment with bowtie2"

## When This Skill Is Used

Use this workflow when you have:
- Reads in some format: FASTA file, FASTQ file, QSEQ (Illumina's qseq format) file, raw files with one input sequence per line, without any other information (no read names, no qualities), or comma-separated lists of reads rather than lists of read files.
- At least one reference file in FASTA format 
- A need to to align reads, build bowtie indices, or inspect bowtie indices.

This approach is **not** suitable for:
- Tasks with variants such as variant reconstruction

## Input Types

- **Reference FASTA file** — One FASTA file
- **Reads in some format** — A FASTA file (`.fa` or `.fasta`), FASTQ file (`.fq` or `.fastq`), QSEQ (Illumina's qseq format) file (`.qseq`), raw files with one input sequence per line, without any other information (no read names, no qualities), or comma-separated lists of reads rather than lists of read files.
- **Bowtie2 Index files** — A set of 6 files with suffixes (`.1.bt2`), (`.2.bt2`), (`.3.bt2`), (`.4.bt2`), (`.rev.1.bt2`), and (`.rev.2.bt2`) exist.
---

## Workflows

### Workflow: Build Bowtie2 Index with bowtie2-build

- Skip if 6 files with suffixes (`.1.bt2`), (`.2.bt2`), (`.3.bt2`), (`.4.bt2`), (`.rev.1.bt2`), and (`.rev.2.bt2`) exist.

### Step 1: Get BowTie2 Index

```bash
docker run --rm -v $(pwd):/ftmp -w /ftmp dnalinux/bowtie2 \
bowtie2-build \
--threads $(nproc) \
-f input_reference.fasta \
index_prefix 
```

- `-f`: The reference input files (specified as <reference_in>) are FASTA files (usually having extension .fa, .mfa, .fna or similar).
- `--threads`: By default bowtie2-build is using only one thread. Increasing the number of threads will speed up the index building considerably in most cases.
example/index/lambda_virus

### Workflow: Run Unpaired Reads BowTie2 Alignment with bowtie2

### Step 1: Build Bowtie2 Index

- [Build Bowtie2 Index] -- see heading "Workflow: Build Bowtie2 Index with bowtie2-build"

### Step 2: Run Unpaired Reads BowTie2 Alignment with bowtie2

```bash
docker run --rm -v $(pwd):/ftmp -w /ftmp dnalinux/bowtie2 \
bowtie2 \
--threads $(nproc) \
-x index_prefix \
-f \
-U input_reads.fasta \
-S bowtie2_alignments.sam
```

- `-x`: The basename of the index for the reference genome. The basename is the name of any of the index files up to but not including the final .1.bt2 / .rev.1.bt2 / etc. bowtie2 looks for the specified index first in the current directory, then in the directory specified in the BOWTIE2_INDEXES environment variable.
- `-f`: Reads (specified with <m1>, <m2>, <s>) are FASTA files. FASTA files usually have extension .fa, .fasta, .mfa, .fna or similar. FASTA files do not have a way of specifying quality values, so when -f is set, the result is as if --ignore-quals is also set.
- `-U`: Comma-separated list of files containing unpaired reads to be aligned, e.g. lane1.fq,lane2.fq,lane3.fq,lane4.fq. Reads may be a mix of different lengths. If - is specified, bowtie2 gets the reads from the "standard in" or "stdin" filehandle.
- `-S`: File to write SAM alignments to. By default, alignments are written to the "standard out" or "stdout" filehandle (i.e. the console).

### Workflow: Run Paired Reads BowTie2 Alignment with bowtie2 

### Step 1: Build Bowtie2 Index

- [Build Bowtie2 Index] -- see heading "Workflow: Build Bowtie2 Index with bowtie2-build"

### Step 2: Run Paired Reads BowTie2 Alignment with bowtie2

```bash
docker run --rm -v $(pwd):/ftmp -w /ftmp dnalinux/bowtie2 \
bowtie2 \
--threads $(nproc) \
-x index_prefix \
-1 reads_1.fq \
-2 reads_2.fq \
-S bowtie2_alignments.sam
```

- `-1` <m1>: Comma-separated list of files containing mate 1s (filename usually includes _1), e.g. -1 flyA_1.fq,flyB_1.fq. Sequences specified with this option must correspond file-for-file and read-for-read with those specified in <m2>. Reads may be a mix of different lengths. If - is specified, bowtie2 will read the mate 1s from the "standard in" or "stdin" filehandle.
- `-2` <m2>: Comma-separated list of files containing mate 2s (filename usually includes _2), e.g. -2 flyA_2.fq,flyB_2.fq. Sequences specified with this option must correspond file-for-file and read-for-read with those specified in <m1>. Reads may be a mix of different lengths. If - is specified, bowtie2 will read the mate 2s from the "standard in" or "stdin" filehandle.

### Workflow: Inspect Bowtie2 Index with bowtie2-inspect

### Step 1: Inspect Bowtie2 Index

```bash
docker run --rm -v $(pwd):/ftmp -w /ftmp dnalinux/bowtie2 \
bowtie2-inspect \
--summary index_prefix \
--output inspection_report
```
- `--summary`: Print a summary that includes information about index settings, as well as the names and lengths of the input sequences. The summary has this format:
  - Colorspace  <0 or 1>
  - SA-Sample   1 in <sample>
  - FTab-Chars  <chars>
  - Sequence-1  <name>  <len>
  - Sequence-2  <name>  <len>
  - ...
  - Sequence-N  <name>  <len>

  - Fields are separated by tabs. Colorspace is always set to 0 for Bowtie 2.
- `--output`: Save output to user-specified filename (default: stdout)

## Output

Each run of `bowtie` produces some output:

- `.1.bt2`, `.2.bt2`, `.3.bt2`, `.4.bt2`, `.rev.1.bt2`, and `.rev.2.bt2` — `bowtie2-build` builds a Bowtie index from a set of DNA sequences. `bowtie2-build` outputs a set of 6 files with suffixes `.1.bt2`, `.2.bt2`, `.3.bt2`, `.4.bt2`, `.rev.1.bt2`, and `.rev.2.bt2`. In the case of a large index these suffixes will have a `bt2l` termination. These files together constitute the index: they are all that is needed to align reads to that reference. The original sequence FASTA files are no longer used by Bowtie 2 once the index is built.
- `bowtie2_alignments.sam` — `bowtie2` outputs a SAM file if `-S` is specified
- `.fasta` — `bowtie2-inspect` extracts information from a Bowtie 2 index about what kind of index it is and what reference sequences were used to build it. When run without any options, the tool will output a FASTA file containing the sequences of the original references (with all non-A/C/G/T characters converted to Ns).
- output of `bowtie2-inspect` can be saved to user-specified file if `--output` is used (default is stdout)
---

## Additional Useful Parameters

These can be added to the `bowtie2-build` command:

- `--large-index`: bowtie2-build can generate either small or large indexes. The wrapper will decide which based on the length of the input genome. If the reference does not exceed 4 billion characters but a large index is preferred, the user can specify --large-index to force bowtie2-build to build a large index instead.
Performance tuning

- `--offrate`: To map alignments back to positions on the reference sequences, it's necessary to annotate ("mark") some or all of the Burrows-Wheeler rows with their corresponding location on the genome. -o/--offrate governs how many rows get marked: the indexer will mark every 2^<int> rows. Marking more rows makes reference-position lookups faster, but requires more memory to hold the annotations at runtime. The default is 5 (every 32nd row is marked; for human genome, annotations occupy about 340 megabytes).
  - If reporting many alignments per read, try reducing bowtie2-build --offrate. 
    - If you are using -k or -a options and Bowtie 2 is reporting many alignments per read, using an index with a denser SA sample can speed things up considerably. To do this, specify a smaller-than-default -o/--offrate value when running bowtie2-build. A denser SA sample yields a larger index, but is also particularly effective at speeding up alignment when many alignments are reported per read.
  - If bowtie2 "thrashes", try increasing bowtie2-build --offrate
    - If bowtie2 runs very slowly on a relatively low-memory computer, try setting -o/--offrate to a larger value when building the index. This decreases the memory footprint of the index.

These can be added to the `bowtie2` command:
 - `-q`: specify format of input files as fastq format
 - `--qseq`: specify format of input files as Illumina's qseq format
 - `-r`: specify format of input files as raw one sequence per line
 - `-c`: specify format of input files as sequences given on command line
 - `--local`: In this mode, Bowtie 2 does not require that the entire read align from one end to the other. Rather, some characters may be omitted ("soft clipped") from the ends in order to achieve the greatest possible alignment score. The match bonus --ma is used in this mode, and the best possible alignment score is equal to the match bonus (--ma) times the length of the read. Specifying --local and one of the presets (e.g. --local --very-fast) is equivalent to specifying the local version of the preset (--very-fast-local). This is mutually exclusive with --end-to-end. --end-to-end is the default mode.

## Citation

If the user asks for a citation for bowtie2, provide the following:

Langmead B, Wilks C., Antonescu V., Charles R. Scaling read aligners to hundreds of threads on general-purpose processors. Bioinformatics. bty648.

Langmead B, Salzberg S. Fast gapped-read alignment with Bowtie 2. Nature Methods. 2012, 9:357-359.

Langmead B, Trapnell C, Pop M, Salzberg SL. Ultrafast and memory-efficient alignment of short DNA sequences to the human genome. Genome Biology 10:R25.
