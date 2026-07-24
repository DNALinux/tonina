---
name: MUSCLE
description: "MUSCLE is a program for creating multiple alignments of amino acid or nucleotide sequences."
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

# MUSCLE Multiple Sequence Alignment Skill

This skill generates high-quality Multiple Sequence Alignments (MSAs) of proteins, DNA, or RNA by executing MUSCLE. 

## When This Skill Is Used

Use this workflow when you have:
- Three or more unaligned homologous sequences in a single file
- A need to identify conserved sequence regions, which can establish evolutionary relationships and reveal structural and functional domains

This approach is **not** suitable for:
- Only two or less unaligned homologous sequences in a single file
- Pairwise assignment tasks
- Aligning genomic structural variants, whole chromosomes, or sequencing reads against a reference genome

## Input Types

- **Unaligned or Aligned Sequences File** — A text file containing all sequences in FASTA format (`.fa`, `.fasta`). 
- **Sequence Types** — Protein, DNA, or RNA. MUSCLE automatically detects the type.
---

## Workflow

### Step 1: Run Multiple Sequence Alignment

Determine which algorithm to use based on the input size:

### Option A: Standard Alignment (`-align`)
*Use for default or small-to-medium sequence sets (<1,000 sequences) where maximum precision is required.*

```bash
docker run --rm -v $(pwd):/ftmp -w /ftmp dnalinux/muscle \ 
  muscle \
  -align sequences.fasta \
  -output alignment.fasta
```

- `-align`: Uses the standard PPP/Ensemble algorithm.
- `-output`: Path to saving the resulting aligned FASTA file (.fasta).

### Option B: Fast Alignment for Large Datasets (`-super5`)
*Use for large sequence sets (>1,000 sequences) where `-align` becomes too slow or consumes excess memory.*

```bash
docker run --rm -v $(pwd):/ftmp -w /ftmp dnalinux/muscle \
  muscle \
  -super5 sequences.fasta \
  -output alignment.afa \
  -threads $(nproc)
```

- `-super5`: Uses the Super5 algorithm.
- `-output`: Path to saving the resulting aligned FASTA file (.fasta).
- `-threads`: Number of threads. Default is the number of CPU cores, or 20 if the CPU has more than 20 cores. Note: No assignment operator (=) is necessary in this case.

### Step 2: Checking Alignment Quality & Errors
**Prerequisite: This step requires the standard PPP algorithm (-align) used in Option 1A. It cannot be run on alignments created via Option 1B (-super5).**

To verify whether an alignment is robust or contains errors, construct a stratified ensemble and measure its dispersion:

### Step 2A: Generate Stratified Ensemble (.efa)

```bash
docker run --rm -v $(pwd):/ftmp -w /ftmp dnalinux/muscle \
  muscle \
  -align sequences.fasta \
  -stratified \
  -output ensemble.efa
```

### Step 2B: Measure Ensemble Dispersion

```bash
docker run --rm -v $(pwd):/ftmp -w /ftmp dnalinux/muscle \
  muscle \
  -disperse ensemble.efa 
```

#### Interpreting Dispersion Results:
- Dispersion = 0.00: All replicate MSAs are identical; the alignment is highly robust and likely free of errors.
- Dispersion > 0.05: Significant variation exists between replicates, indicating alignment errors. Evaluate downstream impacts (e.g., phylogenetic trees) across individual replicates.

## Output

Each run of `muscle` produces at least one file:

- `alignment.fasta/afa` — aligned FASTA file (`.fasta` if PPP, `.afa` if super5)

- If Step 2A is run, an ensemble FASTA file is produced.
- `ensemble.efa` — ensemble FASTA file

- If Step 2B is run, dispersion metrics to stdout (presumably). 

## Additional Useful Parameters
**Prerequisite: These paramters can only be added to commands that use Option 1B (-super5).**

These can be added to the `muscle` command if `-super5` is used:
- `-perturb`: Integer random number seed for generating HMM perturbations. Default SEED=0, which uses default HMM parameters.
- `-perm`: Specifies the guide tree permutation. PERM can be none, abc, acb and bca, default is none.

**Example with (`-perturb`) and (`-perm`):**

```bash
docker run --rm -v $(pwd):/ftmp -w /ftmp dnalinux/muscle \
  muscle \
  -super5 sequences.fasta \
  -output replicate.@.afa \
  -threads $(nproc) \
  -perturb 3 \
  -perm all
```
- You can generate all guide tree permutations for a single HMM perturbation by using -perm all , this creates four alignments, one for each variant of the guide tree. If -perm all is set, and the output filename contains @ , then alignments are written to four different FASTA files where @ is replaced by is replaced by the replicate name, e.g. abc.3

---

## Citation

If the user asks for a citation for muscle, provide the following:

Edgar RC., Muscle5: High-accuracy alignment ensembles enable unbiased assessments of sequence homology and phylogeny. Nature Communications 13.1 (2022): 6968.
https://www.nature.com/articles/s41467-022-34630-w.pdf

Edgar RC. and Tolstoy I., Muscle-3D: scalable multiple protein structure alignment (2024) BioRxiv.