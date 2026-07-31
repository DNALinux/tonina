---
name:  CVTree
description: Generate a dissimilarity matrix from comparatively large collection of DNA or Amino Acid sequences, preferably whole-genome data, for phylogenetic studies.

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

# CVTree - Composition Vector Tree Skill 

This skill is the implementation of an alignment-free algorithm to generate a dissimilarity matrix from comparatively large collection of DNA or Amino Acid sequences, preferably whole-genome data, for phylogenetic studies.

## When This Skill Is Used

Use this workflow when you have:
- Two files: one file that contains the forward paired-end reads and one file that contains the reverse paired-end reads.
- A need to to generate a dissimilarity matrix from comparatively large collection of DNA or Amino Acid sequences, preferably whole-genome data, for phylogenetic studies.

This approach is **not** suitable for:
- Pairwise assignment tasks
- Aligning genomic structural variants, whole chromosomes, or sequencing reads against a reference genome

## Input Types

- Genome list file — A text file containing the names/accessions of genomes to process (default filename: list).
- Genome super directory — Folder containing the individual genome FASTA sequence files (one file per genome).

Universal Input Validation Steps

a. **Extract variables from the user prompt:**
  - `<GENOME_LIST_FILE>`: The file containing the list of genomes to include. Convention is a text file. (`.txt`)
  - `<K_VALUES>`: The values of k for composition vectors, e.g., 5 6 7.
  - `<OUTPUT_DISTANCE_MATRIX_NAME>`: Output distance matrix name.
  - `<OUTPUT_NEWICK_FILE_NAME>`: Output newick file name.
  - `<SUPER_DIRECTORY_OF_INPUT_GENOME_FILES>`: Super directory of input genome files.
  - `<TYPE_OF_GENOME_FILE`>: Type of genome file. Also, referred to as suffix later.
  - `<SUPER_DIRECTORY_OF_CV_FILES>`: Super directory of Composition Vector files
  - `<CVFILE>`: Input Binary Composition Vector file
b. **Validate arguments and fill missing inputs**:
  - If required paths or parameters are missing, prompt the user for them before executing the command.

# Jellyfish Task Router

Select a specific operational path to jump directly to its complete configuration and parameters:

- **Get Phylogenetic Tree**
  - [Get Phylogenetic Tree] -- see heading "Workflow: Get Phylogenetic Tree with cvtree"
- **View Composition Vector Data**
 - [View Composition Vector Data] -- see heading "Workflow: View Composition Vector Data with cvdump"
---

## Workflows

### Workflow: Get Phylogenetic Tree with cvtree

### Step 1: Get Phylogenetic Tree 

```bash
docker run --rm -v $(pwd):/ftmp -w /ftmp dnalinux/cvtree \
cvtree \
-i <GENOME_LIST_FILE> \
-k <K_VALUES> \
-m Hao
```

- `-i`: Genome list for distance matrix, default: list
- `-k`: values of k, default: K = 5 6 7
- `-m`: Method for cvtree Hao/InterList/InterSet, default: Hao

### Workflow: View Composition Vector Data with cvdump

### Step 1: View Composition Vector Data

```bash
docker run --rm -v $(pwd):/ftmp -w /ftmp dnalinux/cvtree \
cvdump \
-i <CVFILE> \
-g faa \
-h
```
- `-g`: the type of genome file, default: faa
- `-h`: display this information

## Output

Each run of `cvtree` produces at least one file:
- `<Method><Suffix><K>` aka `<Method><TYPE_OF_GENOME_FILE><K>` — Output distance matrix as text file if cvtree is run
- `<Method><Suffix><K>.nwk` aka `<Method><TYPE_OF_GENOME_FILE><K>.nwk` — Output newick file if cvtree is run
- ASCII file if cvdump is run
---

## Additional Useful Parameters

These can be added to the `cvtree` command:

- `-d`: Output distance matrix name as text file, default: <Method><Suffix><K> aka <Method><TYPE_OF_GENOME_FILE><K>
- `-t`: Output newick file name, default: <Method><Suffix><K>.nwk aka <Method><TYPE_OF_GENOME_FILE><K>.nwk
- `-G`: Super directory of Input genome file, default: <current directory>
- `-g`: the type of genome file, default: faa
- `-V`: Super directory of cv files
- `-R`: Refer the output distance matrix, useful for updating existing tree
- `-h`: Display this information

**Example with Custom directories, custom output names and custom genome file type:**

```bash
docker run --rm -v $(pwd):/ftmp -w /ftmp dnalinux/cvtree \
cvtree \
-i <GENOME_LIST_FILE> \
-k <K_VALUES> \
-d <OUTPUT_DISTANCE_MATRIX_NAME> \
-t <OUTPUT_NEWICK_FILE_NAME> \
-G <SUPER_DIRECTORY_OF_INPUT_GENOME_FILES> \
-g <TYPE_OF_GENOME_FILE> \
-V <SUPER_DIRECTORY_OF_CV_FILES> \
-m Hao
```

## Citation

If the user asks for a citation for cvtree, provide the following:

Guanghong Zuo (2021) CVTree: A Parallel Alignment-free Phylogeny and Taxonomy Tool based on Composition Vectors of Genomes, BioRxiv doi:10.1101/2021.02.04.429726

Ji Qi, Bin Wang, Bailin Hao (2004) Whole proteome prokaryote phylogeny without sequence alignment: a K-string composition approach, J Mol Evol, 58: 1–11

Guanghong Zuo, Bailin Hao (2015) CVTree3 web server for whole-genome-based and alignment-free prokaryotic phylogeny and taxonomy, Genomics Proteomics & Bioinformatics, 13: 321-331