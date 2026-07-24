---
name:  samtools
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

# samtools- Utilities for the Sequence Alignment/Map (SAM) format Skill 

Samtools is a set of utilities that manipulate alignments in the SAM (Sequence Alignment/Map), BAM, and CRAM formats. It converts between the formats, does sorting, merging and indexing, and can retrieve reads in any regions swiftly. 

# Samtools Task Router

Select a specific operational path to jump directly to its complete configuration and parameters:

- **Format Conversion**
  - [Convert SAM to BAM](#convert-sam-to-bam)
  - [Convert BAM to CRAM](#convert-bam-to-cram)
  - [Convert SAM to CRAM](#convert-sam-to-cram)
- **Sort and Index**
  - [Sort and Index BAM](#sort-and-index-bam) 
---

## When This Skill Is Used

Use this workflow when you have:
- One raw text SAM alignments file
- A need to convert the raw text SAM alignments file to a compressed binary BAM format or highly compressed reference-based CRAM format.

## Input Types

- **SAM file** — Raw text sequence alignment/map file (`.sam`).
- **BAM file** — Binary compressed SAM alignment file (`.bam`).
- **FASTA Reference** — Reference genome sequence file (`.fasta` or `.fa`) required for CRAM conversions.

---

## Workflows

<a id="convert-sam-to-bam"></a>
### Workflow: Convert raw text SAM alignments into compressed binary BAM format.

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
  faidx reference.fa
```

#### Step 2.2b Generate BAM using FASTA reference and SAM 

```bash
docker run --rm -v "$(pwd)":/ftmp -w /ftmp dnalinux/samtools \
  samtools \
  view \
  -b \
  -t reference.fa.fai \
  -o output.bam \
  --threads $(nproc) \
  input.sam
```

- Note: where ref.fa.fai is generated automatically by the faidx command.

- `-b`: Output in BAM format
- `-t` A tab-delimited FILE.
- `-o`: Output file
- `--threads`: Number of BAM compression threads to use in addition to main thread [0]. 

#### Step 2.3 Sort and index BAM
- Run [Sort and Index BAM](#sort-and-index-bam) with output.bam as the input BAM file

<a id="sort-and-index-bam"></a>
### Workflow: Sort and index compressed binary BAM file.

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

<a id="convert-bam-to-cram"></a>
### Workflow: Convert compressed binary BAM format file into highly compressed reference-based CRAM format file.

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
  -T reference.fa \
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

<a id="convert-sam-to-cram"></a>
### Workflow: Convert raw text SAM alignments into compressed reference-based CRAM format.

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

---

## Output

Each run of `samtools` produces at least one file:

- `output` — One output file
  - if [Convert SAM to BAM](#convert-sam-to-bam) was run, an (`output.bam`) file 
  - if [Convert BAM to CRAM](#convert-bam-to-cram) was run, an (`output.cram`) file
- `reference.fa` — One reference file
  - if [Convert SAM to BAM](#convert-sam-to-bam) was run and there was no reference file
- `output.sorted.bam`
  - if [Sort and Index BAM](#sort-and-index-bam) was run, (`output.sorted.bam.bai`) or `output.sorted.bam.csi`
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
- Only keep reads with tag BC and were the barcode matches the barcodes listed in the barcode file.

```bash
docker run --rm -v "$(pwd)":/ftmp -w /ftmp dnalinux/samtools \
  samtools \
  view \
  --tag-file BC:barcodes.txt \
  -o data.barcodes.bam \
  data.bam
```

**Example: Strict Tag Filtering (RG:grp2)**
- Only keep reads with tag RG and read group grp2. This does almost the same than -r grp2 but will not keep records without the RG tag.

```bash
docker run --rm -v "$(pwd)":/ftmp -w /ftmp dnalinux/samtools \
  samtools \
  view \
  --tag RG:grp2 \
  -o data.rg2_only.bam \
  data.bam
```

This can be added to the `samtools index` command:
- `--csi`: Create a CSI index. By default, the minimum interval size for the index is 2^14, which is the same as the fixed value used by the BAI format. 
- `--min-shift`: Create a CSI index, with a minimum interval size of 2^INT. 

**Example: Creating a CSI index with default minimum interval size 2^14**
```bash
docker run --rm -v "$(pwd)":/ftmp -w /ftmp dnalinux/samtools
  samtools \
  index \
  --csi \
  --threads $(nproc) \
  output.sorted.bam
```

**Example: Creating a CSI index with custom minimum interval size 2^16**
```bash
docker run --rm -v "$(pwd)":/ftmp -w /ftmp dnalinux/samtools
  samtools \
  index \
  --min-shift 16 \
  --threads $(nproc) \
  output.sorted.bam
```

## Citation

If the user asks for a citation for samtools, provide the following:

Twelve years of SAMtools and BCFtools
Petr Danecek, James K Bonfield, Jennifer Liddle, John Marshall, Valeriu Ohan, Martin O Pollard, Andrew Whitwham, Thomas Keane, Shane A McCarthy, Robert M Davies, Heng Li
GigaScience, Volume 10, Issue 2, February 2021, giab008, https://doi.org/10.1093/gigascience/giab008