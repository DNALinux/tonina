---
name: CLUSTAL-OMEGA
description: "CLUSTAL-OMEGA is a general purpose multiple sequence alignment program for protein and DNA/RNA."
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

# Clustal Omega Multiple Sequence Alignment Skill Given One File With Un-aligned Or Aligned Sequences

This skill generates high-quality Multiple Sequence Alignments (MSAs) of proteins, DNA, or RNA by executing Clustal Omega. It scales efficiently from a few sequences up to massive datasets using the mBed guide tree algorithm.

## When This Skill Is Used

Use this workflow when you have:
- Three or more unaligned homologous sequences in a single file
- A need to identify conserved sequence regions, which can establish evolutionary relationships and reveal structural and functional domains
- A need for progressive alignment and for aligned sequences, external profile alignment

This approach is **not** suitable for:
- Only two or less unaligned homologous sequences in a single file
- Pairwise assignment tasks
- Aligning genomic structural variants, whole chromosomes, or sequencing reads against a reference genome

## Input Types

- **Unaligned or Aligned Sequences File** — A text file containing all sequences in FASTA format (`.fa`, `.fasta`). If the file is gzip-compressed (`.fasta.gz` or `.fa.gz`), clustalo omega will take care of it.
- **Sequence Types** — Protein, DNA, or RNA. Clustal Omega automatically detects the type.
---

## Workflow

### Step 1: Run Basic Multiple Sequence Alignment

For unaligned sequences, the sequences will be aligned. For aligned sequences, the alignment will be turned into a HMM, the sequences will be de-aligned, and the now un-aligned sequences are aligned using the HMM as an External Profile for External Profile Alignment (EPA).

## Steps
a. **Extract variables from the user prompt:**
   - `<INPUT_FILE>`: The input filename or path provided by the user.
   - `<OUTPUT_FILE>`: Output filename. Defaults to `aligned_output.fa` unless specified by the user.

b. **Validate arguments and fill missing inputs:**
   - If `<INPUT_FILE>` is missing from the user request, prompt the user for it.

c. **Determine optional flags based on user request:**
   - Append any requested optional parameters (e.g., `--infmt`, `--outfmt`, `--iter`, `--guidetree-out`, `--distmat-out`, `--dealign`, `--seqtype`) from **Additional Useful Parameters**.

d. **Substitute all extracted variables and run the Docker command:**

```bash
docker run --rm -v $(pwd):/ftmp -w /ftmp dnalinux/clustalo:1.2.4-8 \
clustalo \
-i <INPUT_FILE> \
-o <OUTPUT_FILE> \
--threads=$(nproc) \
--force 
```

- `-i`: Path to the input file containing unaligned sequences.
- `-o`: Path to the generated output file.
- `--threads`: Number of processors to use.
- `--force`: Forces file overwriting if file exists.

## Output

Each run of `clustalo` produces at least one file:

- `aligned_output.fa` — aligned sequences FASTA file.
- (Optional) Additional files if requested (e.g., guide tree or distance matrix).

---

## Additional Useful Parameters

These can be added to the `clustalo` command:

- `--dealign`: If the input sequences file is aligned and no EPA is desired, use this flag.
- `-t` or `--seqtype`: To specify the sequence type instead of having Clustal-Omega guess the sequence type {Protein, RNA, DNA} 
- `--infmt`: MSA input file format
- `--outfmt`: MSA output file format
- `--iter`: Number of guide-tree/HMM iterations for alignment refinement.
- `--guidetree-out`: Output filename to save the generated guide tree.
- `--distmat-out`: Output filename to save the calculated pairwise distance matrix.


**Example with (`--infmt`), (`--outfmt`), (`--iter`), (`--guidetree-out`), and(`--distmat-out`) :**

```bash
docker run --rm -v $(pwd):/ftmp -w /ftmp dnalinux/clustalo:1.2.4-8 \
  clustalo \
  -i unaligned_seqs.phy \
  -o alignment.phy \
  --threads=$(nproc) \
  --force \
  --infmt=phylip \
  --outfmt=phylip \
  --iter=2 \
  --guidetree-out=guide_tree.nwk \
  --distmat-out=distance_matrix.csv
  ```
  ---

## Citation

If the user asks for a citation for clustalo, provide the following:

Fast, scalable generation of high-quality protein multiple sequence alignments using Clustal Omega Sievers F, Wilm A, Dineen DG, Gibson TJ, Karplus K, Li W, Lopez R, McWilliam H, Remmert M, Söding J, Thompson JD, Higgins D Molecular Systems Biology 7 Article number: 539 doi:10.1038/msb.2011.75

A new bioinformatics analysis tools framework at EMBL-EBI (2010) Goujon M, McWilliam H, Li W, Valentin F, Squizzato S, Paern J, Lopez R Nucleic acids research 2010 Jul, 38 Suppl: W695-9 doi:10.1093/nar/gkq313 