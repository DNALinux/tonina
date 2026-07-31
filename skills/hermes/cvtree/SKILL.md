---
name: cvtree
description: Generate phylogenetic trees from whole-genome sequences using composition vector analysis
version: 1.0.0
platforms: [macos, linux]
metadata:
  hermes:
    tags: [bioinformatics, phylogenetics, genomics, alignment-free, whole-genome]
    category: bioinformatics
    requires_toolsets: [terminal]
---

# CVTree - Composition Vector Phylogeny

CVTree generates phylogenetic trees from whole-genome sequences using an alignment-free algorithm. It creates a dissimilarity matrix from DNA or amino acid sequences using composition vectors.

## When to Use

**Appropriate scenarios:**
- Whole-genome phylogenetic analysis
- Large collection of genomes for comparison
- Alignment-free phylogeny (no multiple sequence alignment needed)
- Prokaryotic taxonomy and classification

**Input types:**
- Genome list file (text file with genome names/accessions)
- Genome FASTA files (one file per genome)
- Amino acid sequences (faa) or nucleotide sequences

## Procedure

### 1. Prepare input files

Create a genome list file containing one genome accession per line:

```text
genome1
genome2
genome3
```

Place genome FASTA files in a directory, named to match the list.

### 2. Run CVTree

```bash
docker run --rm -v $(pwd):/ftmp -w /ftmp dnalinux/cvtree \
  cvtree \
  -i genome_list.txt \
  -k 5 6 7 \
  -m Hao
```

**Flags:**
- `-i` — Genome list file (default: list)
- `-k` — K-mer values for composition vectors (default: 5 6 7)
- `-m` — Method: Hao, InterList, or InterSet (default: Hao)

### 3. View composition vector data

```bash
docker run --rm -v $(pwd):/ftmp -w /ftmp dnalinux/cvtree \
  cvdump \
  -i input.cv \
  -g faa \
  -h
```

## Output

CVTree produces:

- `<Method><Suffix><K>` — Distance matrix (text file)
- `<Method><Suffix><K>.nwk` — Newick format phylogenetic tree

For example with `-m Hao -g faa -k 6`:
- `Haofaa6` — Distance matrix
- `Haofaa6.nwk` — Tree file

## Pitfalls

**K-mer selection:**
Different k-values produce different trees. Common practice is to run multiple k-values (e.g., 5, 6, 7) and compare results.

**Genome quality:**
Incomplete or low-quality genomes may produce unreliable trees. Use complete genomes when possible.

**File naming:**
Genome file names must match entries in the list file exactly.

## Verification

```bash
# Check distance matrix was created
ls -l Haofaa6

# Check tree file
ls -l Haofaa6.nwk

# View tree
cat Haofaa6.nwk
```

## Key Parameters

### CVTree
| Flag | Description |
|------|-------------|
| `-i FILE` | Genome list file (default: list) |
| `-k VALUES` | K-mer values (default: 5 6 7) |
| `-m METHOD` | Method: Hao, InterList, InterSet (default: Hao) |
| `-g TYPE` | Genome file type/suffix (default: faa) |
| `-G DIR` | Super directory of genome files |
| `-d NAME` | Output distance matrix name |
| `-t NAME` | Output Newick file name |
| `-V DIR` | Super directory of CV files |
| `-R FILE` | Reference distance matrix for updating |

### CVDump
| Flag | Description |
|------|-------------|
| `-i FILE` | Input CV file |
| `-g TYPE` | Genome file type (default: faa) |
| `-h` | Display help |

## Citation

Zuo G (2021) CVTree: A Parallel Alignment-free Phylogeny and Taxonomy Tool based on Composition Vectors of Genomes. BioRxiv doi:10.1101/2021.02.04.429726

Qi J, Wang B, Hao BL (2004) Whole proteome prokaryote phylogeny without sequence alignment: a K-string composition approach. J Mol Evol 58: 1–11

Zuo G, Hao BL (2015) CVTree3 web server for whole-genome-based and alignment-free prokaryotic phylogeny and taxonomy. Genomics Proteomics & Bioinformatics 13: 321–331
