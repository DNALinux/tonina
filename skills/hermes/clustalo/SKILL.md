---
name: clustalo
description: Multiple sequence alignment for protein and DNA/RNA sequences
version: 1.0.0
platforms: [macos, linux]
metadata:
  hermes:
    tags: [bioinformatics, alignment, msa, multiple-sequence-alignment, phylogenetics]
    category: bioinformatics
    requires_toolsets: [terminal]
---

# Clustal Omega Multiple Sequence Alignment

Clustal Omega generates high-quality multiple sequence alignments (MSAs) of proteins, DNA, or RNA. It scales efficiently from a few sequences to massive datasets using the mBed guide tree algorithm.

## When to Use

**Appropriate scenarios:**
- Three or more unaligned homologous sequences in a single file
- Identifying conserved regions to establish evolutionary relationships
- Revealing structural and functional domains
- Progressive alignment and external profile alignment

**Not suitable for:**
- Two or fewer sequences → Use pairwise alignment tools
- Aligning genomic structural variants
- Whole chromosomes or sequencing reads against a reference genome → Use BWA-MEM or minimap2

## Procedure

### 1. Basic multiple sequence alignment

For unaligned sequences in FASTA format:

```bash
docker run --rm -v $(pwd):/ftmp -w /ftmp dnalinux/clustalo \
  clustalo \
  -i /ftmp/sequences.fasta \
  -o /ftmp/aligned_output.fa \
  --threads=$(nproc) \
  --force
```

**Flags:**
- `-i` — Path to input file containing unaligned sequences
- `-o` — Path to output file for aligned sequences
- `--threads` — Number of processors to use
- `--force` — Overwrite output file if it exists

### 2. With guide tree and distance matrix

Generate additional outputs for phylogenetic analysis:

```bash
docker run --rm -v $(pwd):/ftmp -w /ftmp dnalinux/clustalo \
  clustalo \
  -i /ftmp/unaligned_seqs.fasta \
  -o /ftmp/alignment.fasta \
  --threads=$(nproc) \
  --force \
  --iter=2 \
  --guidetree-out=/ftmp/guide_tree.nwk \
  --distmat-out=/ftmp/distance_matrix.csv
```

**Additional flags:**
- `--iter` — Number of guide-tree/HMM iterations for refinement
- `--guidetree-out` — Save the generated guide tree
- `--distmat-out` — Save the pairwise distance matrix

### 3. External profile alignment (EPA)

For aligned sequences, convert to HMM and align new sequences:

```bash
docker run --rm -v $(pwd):/ftmp -w /ftmp dnalinux/clustalo \
  clustalo \
  -i /ftmp/existing_alignment.fasta \
  -o /ftmp/new_alignment.fasta \
  --threads=$(nproc) \
  --force
```

Clustal Omega will de-align the input, build an HMM, and realign using the HMM as an external profile.

## Pitfalls

**Minimum sequence count:**
Clustal Omega requires at least 3 sequences. For 2 sequences, use pairwise alignment tools like `water` or `needle` from EMBOSS.

**Large datasets need more memory:**
The mBed algorithm handles large datasets efficiently, but very large alignments (>100,000 sequences) may require significant memory.

**Input format detection:**
Clustal Omega auto-detects sequence type (protein/DNA/RNA). If detection fails, specify explicitly with `--seqtype`.

## Verification

Successful run produces:
- Aligned FASTA file with gaps (`-`) inserted
- All input sequences present in output

Quick validation:
```bash
# Count sequences (should match input)
grep -c "^>" aligned_output.fa

# Check alignment has gaps
head -50 aligned_output.fa

# Verify all sequences same length (aligned)
awk '/^>/ {if (seq) print length(seq); seq=""} !/^>/ {seq=seq$0} END {print length(seq)}' aligned_output.fa | sort -u
```

## Key Parameters

### Input/Output
| Flag | Description |
|------|-------------|
| `-i FILE` | Input sequences (FASTA, can be gzipped) |
| `-o FILE` | Output alignment file |
| `--infmt FORMAT` | Input format (fasta, clustal, phylip, etc.) |
| `--outfmt FORMAT` | Output format (fasta, clustal, phylip, etc.) |
| `--force` | Overwrite existing output file |

### Alignment Options
| Flag | Description |
|------|-------------|
| `--threads N` | Number of threads |
| `--iter N` | Guide-tree/HMM iterations (default 1) |
| `-t TYPE` | Sequence type: Protein, DNA, RNA (auto-detected) |
| `--dealign` | De-align input sequences before realigning |

### Additional Outputs
| Flag | Description |
|------|-------------|
| `--guidetree-out FILE` | Save guide tree in Newick format |
| `--distmat-out FILE` | Save pairwise distance matrix |

## Citation

Sievers F, Wilm A, Dineen DG, Gibson TJ, Karplus K, Li W, Lopez R, McWilliam H, Remmert M, Söding J, Thompson JD, Higgins D. Fast, scalable generation of high-quality protein multiple sequence alignments using Clustal Omega. Molecular Systems Biology 7:539. doi:10.1038/msb.2011.75
