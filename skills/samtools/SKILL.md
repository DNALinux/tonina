---
name: samtools
description: "Manipulates, converts, sorts, indexes, and queries sequence alignments in SAM, BAM, and CRAM formats. Use when converting raw SAM files to compressed BAM/CRAM formats, inspecting headers (@SQ lines), or filtering alignment tags."
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

# samtools - Utilities for the Sequence Alignment/Map (SAM) format Skill 

Samtools is a set of utilities that manipulate alignments in the SAM (Sequence Alignment/Map), BAM, and CRAM formats. It converts between the formats, does sorting, merging and indexing, and can retrieve reads in any regions swiftly. 

# Samtools Task Router

Select a specific operational path to jump directly to its complete configuration and parameters:

- **Format Conversions**
  - [Convert SAM to BAM] -- see heading "Workflow: Convert SAM files to BAM files with samtools view"
  - [Convert BAM to CRAM] -- see heading "Workflow: Convert BAM files to CRAM files with samtools view"
  - [Convert SAM to CRAM] -- see heading "Workflow: Convert SAM files to CRAM files with samtools view"
- **Sort and Index**
  - [Sort and Index BAM] -- see heading "Workflow: Sort and Index BAM file with samtools sort and samtools index"
- **Statistics**
  - [Generate Simple Alignment Statistics] -- see heading "Workflow: Sort and Index BAM file with samtools sort and samtools index"
  - [Report Alignment Summary Statistics] -- see heading "Workflow: Reports alignment summary statistics using samtools idxstats"
  - [Compute Depth Statistics] -- see heading "Workflow: Compute Depth Statistics with samtools depth"
- **File operations**
  - [Multi-way Pileup] -- see heading "Produces "pileup" textual format from an alignment using samtools mpileup"
  - [Merge BAMs] -- see heading "Workflow: Merge BAM Files with samtools merge"
  ---

## When This Skill Is Used

Use this workflow when you have:
- A need to convert one raw text SAM alignments file to a compressed binary BAM format or highly compressed reference-based CRAM format.
- A need to generate alignment or read depth statistics for a raw text SAM alignments file, compressed binary BAM format, or highly compressed reference-based CRAM format
- A need to merge multiple sorted files

## Input Types

- **SAM file** — Raw text sequence alignment/map file (`.sam`).
- **BAM file** — Binary compressed SAM alignment file (`.bam`).
- **CRAM file** - Highly compressed reference-based CRAM file (`.cram`)
- **FASTA Reference** — Reference genome sequence file (`.fasta` or `.fa`) required for CRAM conversions.


## Universal Input Validation Steps

- Before running any statistics, depth calculation, or merging workflow, perform the following general steps:

a. **Extract variables from the user prompt:**
  - `<INPUT_FILE>`: The input filename or path provided by the user.
  - `<CUSTOM_INDEX_FILE_LOCATION>`: The custom index file location provided by the user (usually for idxstats specifically)
  - `<BED_FILE>`: The specified BED file provided by the user (usually for depth specifically)
  - `<SORTED_FILES>`: The input filename or path provided by the user, e.g. input1.bam input2.bam input3.bam  (usually for merge specifically)
  - `<OUTPUT_FILE>`: The specified output file provided by the user 


b. **Validate arguments and fill missing inputs:**
  - If any required file parameters are missing from the user request, prompt the user for them before executing the command.

c. **Determine optional flags based on user request:**
   - Append any requested optional parameters from **Additional Useful Parameters**.
---

## Workflows

### Workflow: Convert SAM files to BAM files with samtools view

### Step 1- Determine if @SQ lines are present in the header

```bash
# If @SQ line exists, it should return:
# @SQ SN:test_ref LN:17637

docker run --rm -v "$(pwd)":/ftmp -w /ftmp dnalinux/samtools \
  samtools \
  view \
  -H input.sam \
  | grep -i '^@SQ'
```

### Step 2- Convert SAM to BAM
- If @SQ lines are present in header, run Step 2.1
- Else (If @SQ lines are NOT present in header), run Step 2.2

#### Step 2.1- Generate BAM when @SQ lines are present in header
```bash
docker run --rm -v "$(pwd)":/ftmp -w /ftmp dnalinux/samtools \
  samtools \
  view \
  -b \
  -o output.bam \
  input.sam
```

#### Step 2.2- Generate BAM when @SQ lines are NOT present in header

#### Step 2.2a If there is no indexed reference fasta file, generate one.

```bash
docker run --rm -v "$(pwd)":/ftmp -w /ftmp dnalinux/samtools \
  samtools \
  faidx reference.fasta
```

#### Step 2.2b Generate BAM using FASTA reference and SAM 

```bash
docker run --rm -v "$(pwd)":/ftmp -w /ftmp dnalinux/samtools \
  samtools \
  view \
  -b \
  -t reference.fasta.fai \
  -o output.bam \
  --threads $(nproc) \
  input.sam
```

- Note: where reference.fasta.fai is generated automatically by the faidx command.

- `-b`: Output in BAM format
- `-t` A tab-delimited FILE.
- `-o`: Output file
- `--threads`: Number of BAM compression threads to use in addition to main thread [0]. 

#### Step 2.3 Sort and index BAM
- Run [Sort and Index BAM] -- see heading "Workflow: Sort and Index BAM file with samtools sort and samtools index" with output.bam as the input BAM file

### Workflow: Sort and Index BAM file with samtools sort and samtools index

#### Step 1- Sort and index compressed binary BAM file for efficient access

#### Step 1.1a- Sort compressed binary BAM file
- To index, the BAM file must first be sorted
-  Note that if the sorted output file is to be indexed with samtools index, the default coordinate sort must be used. Thus the -n, -N and -t options are incompatible with samtools index. 

```bash
docker run --rm -v "$(pwd)":/ftmp -w /ftmp dnalinux/samtools \
  samtools \
  sort \
  -m 768M \
  -o output.sorted.bam \
  --threads $(nproc) \
  input.bam
```
- `-m`:  Approximately the maximum required memory per thread, specified either in bytes or with a K, M, or G suffix. [768 MiB]. To prevent sort from creating a huge number of temporary files, it enforces a minimum value of 1M for this setting. 

#### Step 1.1b- Index sorted compressed binary BAM file
- After the BAM file is sorted, it can be indexed
- Note:  The BAI index format can handle individual chromosomes up to 512 Mbp (2^29 bases) in length. If your input file might contain reads mapped to positions greater than that, you will need to use a CSI index (`--csi`). 

```bash
docker run --rm -v "$(pwd)":/ftmp -w /ftmp dnalinux/samtools \
  samtools \
  index \
  --threads $(nproc) \
  output.sorted.bam
```

### Workflow: Convert BAM files to CRAM files with samtools view

### Step 1- Convert a BAM file to a CRAM file using a local reference sequence.
- Determine if user wants to convert a BAM file to a CRAM with NM and MD tags stored verbatim rather than calculating on the fly during CRAM decode, so that mixed data sets with MD/NM only on some records, or NM calculated using different definitions of mismatch, can be decoded without change.
- If without, run Step 1.1
- If with, run Step 1.2

#### Step 1.1- Convert a BAM file to a CRAM with NM (edit distance) and MD (mismatch string) tags calculated on the fly during CRAM decode
```bash
docker run --rm -v "$(pwd)":/ftmp -w /ftmp dnalinux/samtools \
  samtools \
  view \
  -C \
  -T reference.fasta \
  -o output.cram input.bam \
  --threads $(nproc)
```
- `-C`: Output in CRAM format
- `-T`  A FASTA format reference FILE  
- `-o`: Output file
- `--threads`: Number of BAM compression threads to use in addition to main thread [0]. 

#### Step 1.2- Convert a BAM file to a CRAM with NM (edit distance) and MD (mismatch string) tags stored verbatim rather than calculated on the fly during CRAM decode
- This is done so that mixed data sets with MD/NM only on some records, or NM calculated using different definitions of mismatch, can be decoded without change.
- Decoding will have to include (`--input-fmt-option decode_md=0`)

```bash
docker run --rm -v "$(pwd)":/ftmp -w /ftmp dnalinux/samtools \
  samtools \
  view \
  -C \
  --output-fmt-option store_md=1 \
  --output-fmt-option store_nm=1 \
  -o output.cram \
  --threads $(nproc) \
  input.bam
```
- `-C`: Output in CRAM format
- `--output-fmt-option store_md`: Stores MD (mismatch string) tags (uses =)
- `--output-fmt-option store_nm`: Stores NM (edit distance) tags (uses =)
- `-o`: Output file
- `--threads`: Number of BAM compression threads to use in addition to main thread [0]. 

### Workflow: Convert BAM files to CRAM files with samtools view

### Step 1- Convert SAM to CRAM

```bash
docker run --rm -v "$(pwd)":/ftmp -w /ftmp dnalinux/samtools \
  samtools \
  view \
  -C \
  -T reference.fasta \
  -o output.cram \
  input.sam
```

### Workflow: Counts the number of alignments for each FLAG type using samtools flagstat

-  Does a full pass through the input file to calculate and print statistics to stdout.
- Provides counts for each of 13 categories based primarily on bit flags in the FLAG field. Information on the meaning of the flags is given in the SAM specification document <https://samtools.github.io/hts-specs/SAMv1.pdf>.
- Each category in the output is broken down into QC pass and QC fail. In the default output format, these are presented as "#PASS + #FAIL" followed by a description of the category.
- The first row of output gives the total number of reads that are QC pass and fail (according to flag bit 0x200). For example: 122 + 28 in total (QC-passed reads + QC-failed reads) Which would indicate that there are a total of 150 reads in the input file, 122 of which are marked as QC pass and 28 of which are marked as "not passing quality controls" 

### Step 1. Generate simple alignment stats
```bash
docker run --rm -v "$(pwd)":/ftmp -w /ftmp dnalinux/samtools \
  samtools \
  flagstat <INPUT_FILE> \
  -O default \
  -@ $(nproc)
``` 

- `-O`:  Set the output format. FORMAT can be set to 'default', 'json' or 'tsv' to select the default, JSON or tab-separated values output format. If this option is not used, the default format will be selected. 
- `-@`: Set number of additional threads to use when reading the file.  

### Workflow: Reports alignment summary statistics using samtools idxstats

-   Retrieve and print stats in the index file corresponding to the input file. Before calling idxstats, the input BAM file should be indexed by samtools index.
- The output is TAB-delimited with each line consisting of reference sequence name, sequence length, # mapped read-segments and # unmapped read-segments. It is written to stdout. Note this may count reads multiple times if they are mapped more than once or in multiple fragments. 

### Step 1. Generate simple alignment stats
-  **WARNING:  If run on a SAM or CRAM file or an unindexed BAM file, this command will still produce the same summary statistics, but does so by reading through the entire file. This is far slower than using the BAM indices.**

```bash
docker run --rm -v "$(pwd)":/ftmp -w /ftmp dnalinux/samtools \
  samtools \
  idxstats <INPUT_FILE> 
``` 

### Workflow: Compute Depth Statistics with samtools depth

### Step 1. Generate read depth stats

```bash
docker run --rm -v "$(pwd)":/ftmp -w /ftmp dnalinux/samtools \
  samtools \
  depth \
  <INPUT_FILE>
``` 

### Workflow: Produces "pileup" textual format from an alignment using samtools mpileup 
- Generate text pileup output for one or multiple BAM files. Each input file produces a separate group of pileup columns in the output. 

### Step 1. Show all possible alignments

```bash
docker run --rm -v "$(pwd)":/ftmp -w /ftmp dnalinux/samtools \
    samtools \
    mpileup \
    --count-orphans \
    --no-BAQ \
    --max-depth 0 \
    --fasta-ref ref_file.fasta \
    --min-BQ 0 \
    --excl-flags 0 \
    --disable-overlap-removal \
    <INPUT_FILE>
```
- `--count-orphans`: Do not skip anomalous read pairs in variant calling. Anomalous read pairs are those marked in the FLAG field as paired in sequencing but without the properly-paired flag set.
- `--no-BAQ`: Disable base alignment quality (BAQ) computation. 
- `--max-depth`: At a position, read maximally INT reads per input file. Setting this limit reduces the amount of memory and time needed to process regions with very high coverage. Passing zero for this option sets it to the highest possible value, effectively removing the depth limit. [8000] 
- `--fasta-ref`:  The faidx-indexed reference file in the FASTA format. The file can be optionally compressed by bgzip. [null] Supplying a reference file will enable base alignment quality calculation for all reads aligned to a reference in the file.
- `--min-BQ`: Minimum base quality for a base to be considered. [13] Note base-quality 0 is used as a filtering mechanism for overlap removal which marks bases as having quality zero and lets the base quality filter remove them. Hence using --min-BQ 0 will make the overlapping bases reappear, albeit with quality zero. 
- `--excl-flags`:  Filter flags: skip reads with any of the mask bits set. This defaults to SECONDARY,QCFAIL,DUP. The option is not accumulative, so specifying e.g. --ff QCFAIL will reenable output of secondary and duplicate alignments. Note this does not override the --incl-flags option. 
- `--disable-overlap-removal`: Overlap detection and removal is enabled by default. This option turns it off. 

### Workflow: Merge BAM Files with samtools merge

- Merge multiple sorted alignment files, producing a single sorted output file that contains all the input records and maintains the existing sort order. 

### Step 1. Merge
  - **WARNING:  Ensure all input BAMs are sorted in the same way (coordinate or query name).**
  - **WARNING: Problems may arise when attempting to merge thousands of files together. The operating system may impose a limit on the maximum number of simultaneously open files. Additionally many files being read from simultaneously may cause a certain amount of "disk thrashing". To partially alleviate this the merge command will load 1MB of data at a time from each file, but this in turn adds to the overall merge program memory usage. Please take this into account when setting memory limits. In extreme cases, it may be necessary to reduce the problem to fewer files by successively merging subsets before a second round of merging.**

```bash
docker run --rm -v "$(pwd)":/ftmp -w /ftmp dnalinux/samtools \
  samtools \
  merge \
  --threads $(nproc) \
  output.bam \
  <SORTED_FILES>
```
---

## Output

Each run of `samtools` produces output:

- format conversions
  - `output` — One output file
    - if [Convert SAM to BAM] was run, an (`output.bam`) file 
    - if [Convert BAM to CRAM] was run, an (`output.cram`) file
  - `reference.fasta` — One reference file
    - if [Convert SAM to BAM] was run and there was no reference file
  - `output.sorted.bam` - One corresponding index file
    - if [Sort and Index BAM] was run, (`output.sorted.bam.bai`) or `output.sorted.bam.csi`
- statistics
  - if [Generate Simple Alignment Statistics] was run, it defaults output to stdout, but the -O parameter allows output format to be (`.json`) or (`.tsv`).
  - if [Report Alignment Summary Statistics] was run, it defaults output to stdout.
  - if [Compute Depth Statistics] was run, it defaults output to stdout.
- file operations
  - if [Multi-way Pileup] was run, it defaults output to stdout.
  - `output.bam`- if [Merge BAMs] was run, it produces a single sorted output file.

---

## Additional Useful Parameters

These can be added to the `samtools view` command:

- `--read-group`: Output alignments in read group STR [null]. Note that records with no RG tag will also be output when using this option. This behaviour may change in a future release. 
- `--tag`: Only output alignments with tag STR1 and associated value STR2, which can be a string or an integer [null]. The value can be omitted, in which case only the tag is considered.
- `--tag-file`: Only output alignments with tag STR and associated values listed in FILE [null].  
 
**Example: Filter by Read Group (grp2)**
- Output alignments in read group grp2 (records with no RG tag will also be in the output).

```bash
docker run --rm -v "$(pwd)":/ftmp -w /ftmp dnalinux/samtools \
  samtools \
  view \
  --read-group grp2 \
  -o data.rg2.bam \
  data.bam
```

**Example: Filter by Barcode Tag File (BC:barcodes.txt)**
- Only keep reads with tag BC and where the barcode matches the barcodes listed in the barcode file.

```bash
docker run --rm -v "$(pwd)":/ftmp -w /ftmp dnalinux/samtools \
  samtools \
  view \
  --tag-file BC:barcodes.txt \
  -o data.barcodes.bam \
  data.bam
```

**Example: Strict Tag Filtering (RG:grp2)**
- Only keep reads with tag RG and read group grp2. This does almost the same as -r grp2 but will not keep records without the RG tag.

```bash
docker run --rm -v "$(pwd)":/ftmp -w /ftmp dnalinux/samtools \
  samtools \
  view \
  --tag RG:grp2 \
  -o data.rg2_only.bam \
  data.bam
```

These can be added to the `samtools index` command:
- `--csi`: Create a CSI index. By default, the minimum interval size for the index is 2^14, which is the same as the fixed value used by the BAI format. 
- `--min-shift`: Create a CSI index, with a minimum interval size of 2^INT. 

**Example: Creating a CSI index with default minimum interval size 2^14**
```bash
docker run --rm -v "$(pwd)":/ftmp -w /ftmp dnalinux/samtools \
  samtools \
  index \
  --csi \
  --threads $(nproc) \
  output.sorted.bam
```

**Example: Creating a CSI index with custom minimum interval size 2^16**
```bash
docker run --rm -v "$(pwd)":/ftmp -w /ftmp dnalinux/samtools \
  samtools \
  index \
  --min-shift 16 \
  --threads $(nproc) \
  output.sorted.bam
```

This can be added to the `samtools idxstats` command:

- `-X`: Interpret the extra positional argument as the index file.
-  **WARNING:  If run on a SAM or CRAM file or an unindexed BAM file, this command will still produce the same summary statistics, but does so by reading through the entire file. This is far slower than using the BAM indices.**

**Example:**

```bash
docker run --rm -v "$(pwd)":/ftmp -w /ftmp dnalinux/samtools \
  samtools \
  idxstats \
  -X <INPUT_FILE> <CUSTOM_INDEX_FILE_LOCATION>
``` 

These can be added to the `samtools depth` command:

- `-b`: Compute depth at list of positions or regions in specified BED FILE. [] 
- `-aa`: Output absolutely all positions, including unused reference sequences. Note that when used in conjunction with a BED file the -a option may sometimes operate as if -aa was specified if the reference sequence has coverage outside of the region specified in the BED file. 
- `-o`: Write output to FILE. Using “-” for FILE will send the output to stdout (also the default if this option is not used). 

```bash
docker run --rm -v "$(pwd)":/ftmp -w /ftmp dnalinux/samtools \
  samtools \
  depth \
  -aa \
  -b <BED_FILE> \
  -o <OUTPUT_FILE> \
  <INPUT_FILE>
``` 

These can be added to the `samtools merge` command:

- `-r`: Attach an RG tag to each alignment. The tag value is inferred from file names. 
- `-h`: The @SQ headers of input files will be merged into the specified header, otherwise they will be merged into a composite header created from the input headers. If in the process of merging @SQ lines for coordinate sorted input files, a conflict arises as to the order (for example input1.bam has @SQ for a,b,c and input2.bam has b,a,c) then the resulting output file will need to be re-sorted back into coordinate order. 
- `-c`: When several input files contain @RG headers with the same ID, emit only one of them (namely, the header line from the first file we find that ID in) to the merged output file. Combining these similar headers is usually the right thing to do when the files being merged originated from the same file. Without -c, all @RG headers appear in the output file, with random suffixes added to their IDs where necessary to differentiate them. 
- `-p`: Similarly, for each @PG ID in the set of files to merge, use the @PG line of the first file we find that ID in rather than adding a suffix to differentiate similar IDs. 


**Example: Attach the RG tag while merging sorted alignments**

### Step 1 — create rg.txt on the host in CWD (which is mounted into the container)
```bash
printf '@RG\tID:ga\tSM:hs\tLB:ga\tPL:ILLUMINA\n@RG\tID:454\tSM:hs\tLB:454\tPL:LS454\n' > rg.txt
```

### Step 2 — merge inside the container
```bash
docker run --rm -v "$(pwd)":/ftmp -w /ftmp dnalinux/samtools \
  samtools \
  merge \
  --threads $(nproc) \
  -rh rg.txt \
  merged.bam \
  ga.bam 454.bam
```

## Citation

If the user asks for a citation for samtools, provide the following:

Twelve years of SAMtools and BCFtools
Petr Danecek, James K Bonfield, Jennifer Liddle, John Marshall, Valeriu Ohan, Martin O Pollard, Andrew Whitwham, Thomas Keane, Shane A McCarthy, Robert M Davies, Heng Li
GigaScience, Volume 10, Issue 2, February 2021, giab008, https://doi.org/10.1093/gigascience/giab008