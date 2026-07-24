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
---

## When This Skill Is Used

Use this workflow when you have:
- One raw text SAM alignments file
- A need to convert the raw text SAM alignments file to a compressed binary BAM format or highly compressed reference-based CRAM format.

This approach is **not** suitable for:
- Two or more files
- Pairwise assignment tasks
- Aligning genomic structural variants, whole chromosomes, or sequencing reads against a reference genome

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
# Check directly (returns 0 if @SQ exists, 1 if missing)
docker run --rm -v "$(pwd)":/ftmp -w /ftmp dnalinux/samtools \
  bash -c \
  "samtools \
  view \
  -H input.sam \
  | grep '^@SQ'"
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

#### Step 2.2a If there is no reference fasta file, generate one. Skip this step if there is.

```bash
docker run --rm -v "$(pwd)":/ftmp -w /ftmp dnalinux/samtools \
  samtools \
  faidx \
  reference.fa
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
### Workflow: Convert raw text SAM alignments into compressed binary BAM format.

### Step 1- [Convert SAM to BAM](#convert-sam-to-bam)
### Step 2- [Convert BAM to CRAM](#convert-bam-to-cram)

---

## Output

Each run of `samtools` produces at least one file:

- `output` — An output file
  - if [Convert SAM to BAM](#convert-sam-to-bam) was run, an (`output.bam`) file 
  - if [Convert BAM to CRAM](#convert-bam-to-cram) was run, an (`output.cram`) file
- `reference.fa` — One reference file
  if [Convert SAM to BAM](#convert-sam-to-bam) or [Convert SAM to CRAM](#convert-sam-to-cram) was run and there was no reference file

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
  -o /data_folder/data.rg2.bam \
  /data_folder/data.bam
```

**Example: Filter by Barcode Tag File (BC:barcodes.txt)**
- Only keep reads with tag BC and were the barcode matches the barcodes listed in the barcode file.

```bash
docker run --rm -v "$(pwd)":/ftmp -w /ftmp dnalinux/samtools \
  samtools \
  view \
  --tag-file BC:barcodes.txt \
  -o /data_folder/data.barcodes.bam \
  /data_folder/data.bam
```

**Example: Strict Tag Filtering (RG:grp2)**
- Only keep reads with tag RG and read group grp2. This does almost the same than -r grp2 but will not keep records without the RG tag.

```bash
docker run --rm -v "$(pwd)":/ftmp -w /ftmp dnalinux/samtools \
  samtools \
  view \
  --tag RG:grp2 \
  -o /data_folder/data.rg2_only.bam \
  /data_folder/data.bam
```

## Citation

If the user asks for a citation for samtools, provide the following:

Twelve years of SAMtools and BCFtools
Petr Danecek, James K Bonfield, Jennifer Liddle, John Marshall, Valeriu Ohan, Martin O Pollard, Andrew Whitwham, Thomas Keane, Shane A McCarthy, Robert M Davies, Heng Li
GigaScience, Volume 10, Issue 2, February 2021, giab008, https://doi.org/10.1093/gigascience/giab008