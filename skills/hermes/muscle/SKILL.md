---
name: muscle
description: Multiple sequence alignment for protein and nucleotide sequences with high accuracy
version: 1.0.0
platforms: [macos, linux]
metadata:
  hermes:
    tags: [bioinformatics, alignment, msa, multiple-sequence-alignment, phylogenetics]
    category: bioinformatics
    requires_toolsets: [terminal]
---

# MUSCLE Multiple Sequence Alignment

MUSCLE generates high-quality multiple sequence alignments (MSAs) of proteins, DNA, or RNA. It offers two main algorithms: standard PPP/Ensemble for maximum accuracy, and Super5 for large datasets.

## When to Use

**Appropriate scenarios:**
- Three or more unaligned homologous sequences in a single file
- Identifying conserved regions to establish evolutionary relationships
- Revealing structural and functional domains

**Not suitable for:**
- Two or fewer sequences → Use pairwise alignment tools
- Aligning genomic structural variants
- Whole chromosomes or sequencing reads against a reference genome → Use BWA-MEM or minimap2

**Algorithm selection:**
- **Standard (`-align`):** Small-to-medium datasets (<1,000 sequences) where maximum precision is required
- **Fast (`-super5`):** Large datasets (>1,000 sequences) where speed and memory efficiency matter

## Procedure

### 1. Standard alignment (PPP/Ensemble)

Use for small-to-medium datasets requiring maximum precision:

```bash
docker run --rm -v $(pwd):/ftmp -w /ftmp dnalinux/muscle \
  muscle \
  -align /ftmp/sequences.fasta \
  -output /ftmp/alignment.fasta
```

**Flags:**
- `-align` — Uses standard PPP/Ensemble algorithm
- `-output` — Path to save aligned FASTA file

### 2. Fast alignment for large datasets (Super5)

Use for large sequence sets (>1,000 sequences):

```bash
docker run --rm -v $(pwd):/ftmp -w /ftmp dnalinux/muscle \
  muscle \
  -super5 /ftmp/sequences.fasta \
  -output /ftmp/alignment.afa \
  -threads $(nproc)
```

**Flags:**
- `-super5` — Uses Super5 algorithm for speed
- `-output` — Path to save aligned FASTA file
- `-threads` — Number of threads (default: CPU cores, max 20)

### 3. Check alignment quality (optional)

Generate stratified ensemble and measure dispersion to verify robustness:

**Step 3a: Generate stratified ensemble:**
```bash
docker run --rm -v $(pwd):/ftmp -w /ftmp dnalinux/muscle \
  muscle \
  -align /ftmp/sequences.fasta \
  -stratified \
  -output /ftmp/ensemble.efa
```

**Step 3b: Measure ensemble dispersion:**
```bash
docker run --rm -v $(pwd):/ftmp -w /ftmp dnalinux/muscle \
  muscle \
  -disperse /ftmp/ensemble.efa
```

**Interpreting dispersion:**
- **0.00** — All replicate MSAs are identical; highly robust, likely error-free
- **>0.05** — Significant variation between replicates; alignment errors present; evaluate downstream impacts across individual replicates

**Note:** Quality checking only works with standard PPP algorithm (`-align`), not Super5.

## Pitfalls

**Minimum sequence count:**
MUSCLE requires at least 3 sequences for meaningful alignment. For 2 sequences, use pairwise alignment tools.

**Dispersion check requires PPP:**
The `-disperse` command only works with ensembles created using `-align`, not `-super5`.

**Memory usage for large datasets:**
Standard PPP algorithm consumes significant memory for large sequence sets. Switch to `-super5` when memory becomes limiting.

**Output file extension:**
By convention, use `.fasta` for PPP output and `.afa` for Super5 output, though any extension works.

## Verification

Successful run produces:
- Aligned FASTA file with gaps inserted
- All input sequences present in output

Quick validation:
```bash
# Count sequences (should match input)
grep -c "^>" alignment.fasta

# Check alignment has gaps
head -50 alignment.fasta

# Verify all sequences same length (aligned)
awk '/^>/ {if (seq) print length(seq); seq=""} !/^>/ {seq=seq$0} END {print length(seq)}' alignment.fasta | sort -u
```

## Key Parameters

### Algorithm Selection
| Flag | Description |
|------|-------------|
| `-align FILE` | Standard PPP/Ensemble algorithm (high accuracy) |
| `-super5 FILE` | Fast algorithm for large datasets (>1,000 sequences) |
| `-output FILE` | Output aligned FASTA file |
| `-threads N` | Thread count for Super5 (default: cores, max 20) |

### Quality Assessment
| Flag | Description |
|------|-------------|
| `-stratified` | Generate stratified ensemble for quality check |
| `-disperse FILE.efa` | Measure dispersion of ensemble |

### Super5 Options
| Flag | Description |
|------|-------------|
| `-perturb N` | Random seed for HMM perturbation (default 0) |
| `-perm PERM` | Guide tree permutation: none, abc, acb, bca, all |

## Citation

Edgar RC. Muscle5: High-accuracy alignment ensembles enable unbiased assessments of sequence homology and phylogeny. Nature Communications 13.1 (2022): 6968. https://www.nature.com/articles/s41467-022-34630-w.pdf

Edgar RC and Tolstoy I. Muscle-3D: scalable multiple protein structure alignment (2024) BioRxiv.
