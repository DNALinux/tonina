---
name: biopython
description: Comprehensive molecular biology toolkit. Use for sequence manipulation, file parsing (FASTA/GenBank/PDB), phylogenetics, and programmatic NCBI/PubMed access (Bio.Entrez). Best for batch processing, custom bioinformatics pipelines, BLAST automation. For quick lookups use gget; for multi-service integration use bioservices.
allowed-tools: Read Write Edit Bash
compatibility: Requires Python 3.10+, NumPy, and Biopython. Entrez and web BLAST examples require network access; local BLAST/MUSCLE examples require those command-line tools installed separately.
license: Biopython License Agreement
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
    envVars:
    - name: NCBI_EMAIL
      required: false
      description: Email for NCBI Entrez identification (required by NCBI policy for Entrez calls).
    - name: NCBI_API_KEY
      required: false
      description: NCBI API key to raise Entrez rate limits.
---

# Biopython: Computational Molecular Biology in Python

This skill is a comprehensive set of freely available Python tools for biological computation. It provides functionality for sequence manipulation, file I/O, database access, structural bioinformatics, phylogenetics, and many other bioinformatics tasks.

# Biopython Task Router

Select a specific operational path to jump directly to its complete configuration and parameters:

- **Sequence Operations**
  - [Read and Parse FASTA] -- see heading "Workflow: Read and parse FASTA files with Bio.SeqIO"
  - [Translate DNA Sequence] -- see heading "Workflow: Format Conversion (GenBank to FASTA) with Bio.SeqIO"
- **Alignment Analysis**
  - [Pairwise Alignment] -- see heading "Workflow: Pairwise Alignment with Bio.Align"
- **Database Access**
  - [Search PubMed via Entrez] -- see heading "Workflow: Search PubMed and fetch records with Bio.Entrez"
- **BLAST Operations** 
  - [Run BLAST Search] -- see heading "Workflow: Run BLAST Search and Display top hits with Bio.Blast"
- **Structural Bioinformatics**
  - [Parse PDB Structure] -- see heading "Workflow: Parse protein structures and Calculate distance between alpha carbons with Bio.PDB"
6. **Phylogenetics** 
  - [Read and Visualize Tree] -- see heading "Workflow: Read and visualize tree with Bio.Phylo"

## When to Use This Skill

Use this workflow when you have:
- Working with biological sequences (DNA, RNA, or protein)
- Reading, writing, or converting biological file formats (FASTA, GenBank, FASTQ, PDB, mmCIF, etc.)
- Accessing NCBI databases (GenBank, PubMed, Protein, Gene, etc.) via Entrez
- Running BLAST searches or parsing BLAST results
- Performing sequence alignments (pairwise or multiple sequence alignments)
- Analyzing protein structures from PDB files
- Creating, manipulating, or visualizing phylogenetic trees
- Finding sequence motifs or analyzing motif patterns
- Calculating sequence statistics (GC content, molecular weight, melting temperature, etc.)
- Performing structural bioinformatics tasks
- Working with population genetics data
- Any other computational molecular biology task

## Installation and Setup

- Note: Biopython is already pre-installed inside the virtual environment (/biopython/bin/python) within the dnalinux/biopython image.

For NCBI database access, always set your email address (required by NCBI). For reusable software, set a stable `Entrez.tool` value and register the tool/email with NCBI. For higher rate limits (10 req/s instead of 3 req/s), read only `NCBI_API_KEY` from the environment — do not hardcode keys or load unrelated environment variables:

```bash
docker run --rm -v $(pwd):/ftmp -w /ftmp dnalinux/biopython \
python3 -c '
import os
from Bio import Entrez

Entrez.email = "your.email@example.com"  # required — use your real email
Entrez.tool = "your_tool_name"  # optional but recommended for reusable software

# Optional: register at https://www.ncbi.nlm.nih.gov/account/settings/
if api_key := os.environ.get("NCBI_API_KEY"):
    Entrez.api_key = api_key
'
```

## General Workflow Guidelines

### Writing Biopython Code

Follow these principles when writing Biopython code:

1. **Import modules explicitly**
```bash
docker run --rm -v "$(pwd)":/ftmp -w /ftmp dnalinux/biopython \
/biopython/bin/python -c '
from Bio import SeqIO, Entrez
from Bio.Seq import Seq
'
```

2. **Set Entrez email** when using NCBI databases; load only `NCBI_API_KEY` from the environment if present
```bash
docker run --rm -v "$(pwd)":/ftmp -w /ftmp dnalinux/biopython \
/biopython/bin/python -c '
  import os
  from Bio import Entrez

  Entrez.email = "your.email@example.com"
  Entrez.tool = "your_tool_name"
  if api_key := os.environ.get("NCBI_API_KEY"):
      Entrez.api_key = api_key
'
```

3. **Use appropriate file formats** - Check which format best suits the task
```bash
docker run --rm -v "$(pwd)":/ftmp -w /ftmp dnalinux/biopython \
/biopython/bin/python -c '
  # Common formats: "fasta", "genbank", "fastq", "clustal","phylip" 
  '
```

4. **Handle files properly** - Close handles after use or use context managers
```bash
docker run --rm -v "$(pwd)":/ftmp -w /ftmp dnalinux/biopython \
/biopython/bin/python -c '
  with open("file.fasta") as handle:
    records = SeqIO.parse(handle, "fasta")
    '
```

5. **Use iterators for large files** - Avoid loading everything into memory
```bash
docker run --rm -v "$(pwd)":/ftmp -w /ftmp dnalinux/biopython \
/biopython/bin/python -c '
for record in SeqIO.parse("large_file.fasta", "fasta"):
    # Process one record at a time
    '
```

6. **Handle errors gracefully** - Network operations and file parsing can fail
```bash
docker run --rm -v "$(pwd)":/ftmp -w /ftmp dnalinux/biopython \
/biopython/bin/python -c '
from urllib.error import HTTPError

try:
    handle = Entrez.efetch(db="nucleotide", id=accession)
except HTTPError as e:
    print(f"Error: {e}")
'
```
7. **Reference Common Patterns if necessary**

## Workflows

### Workflow: Read and parse FASTA files with Bio.SeqIO

### Step 1- Read and parse FASTA files with Bio.SeqIO

```bash
docker run --rm -v "$(pwd)":/ftmp -w /ftmp dnalinux/biopython \
/biopython/bin/python -c '
from Bio import SeqIO

# Read sequences from FASTA file
for record in SeqIO.parse("sequences.fasta", "fasta"):
    print(f"{record.id}: {len(record.seq)} bp")
'
```

### Workflow: Format Conversion (GenBank to FASTA)

### Step 1: Format Conversion (GenBank to FASTA)

```bash
docker run --rm -v "$(pwd)":/ftmp -w /ftmp dnalinux/biopython \
/biopython/bin/python -c '
from Bio import SeqIO

# Convert GenBank to FASTA
SeqIO.convert("input.gb", "genbank", "output.fasta", "fasta")
'
```

### Workflow: Pairwise Alignment with Bio.Align

### Step 1: Pairwise Alignment with Bio.Align

```bash
docker run --rm -v "$(pwd)":/ftmp -w /ftmp dnalinux/biopython \
/biopython/bin/python -c '
from Bio import Align

# Pairwise alignment
aligner = Align.PairwiseAligner()
aligner.mode = "global"
alignments = aligner.align("ACCGGT", "ACGGT")
print(alignments[0])
'
```

### Workflow: Search PubMed and fetch records with Bio.Entrez

### Step 1: Search PubMed and fetch records with Bio.Entrez

```bash
docker run --rm -v "$(pwd)":/ftmp -w /ftmp dnalinux/biopython \
/biopython/bin/python -c '
from Bio import Entrez
Entrez.email = "your.email@example.com"

# Search PubMed
handle = Entrez.esearch(db="pubmed", term="biopython", retmax=10)
results = Entrez.read(handle)
handle.close()
print(f"Found {results['Count']} results")
'
```

### Workflow: Run BLAST Search and Display top hits with Bio.Blast

### Step 1: Run BLAST Search and Display top hits with Bio.Blast

```bash
docker run --rm -v "$(pwd)":/ftmp -w /ftmp dnalinux/biopython \
/biopython/bin/python -c '
from Bio.Blast import NCBIWWW, NCBIXML

# Run BLAST search
result_handle = NCBIWWW.qblast("blastn", "nt", "ATCGATCGATCG")
blast_record = NCBIXML.read(result_handle)

# Display top hits
for alignment in blast_record.alignments[:5]:
    print(f"{alignment.title}: E-value={alignment.hsps[0].expect}")
'
```

### Workflow: Parse protein structures and Calculate distance between alpha carbons with Bio.PDB

### Step 1: Parse protein structures and Calculate distance between alpha carbons with Bio.PDB

```bash
docker run --rm -v "$(pwd)":/ftmp -w /ftmp dnalinux/biopython \
/biopython/bin/python -c '
from Bio.PDB import PDBParser

# Parse structure
parser = PDBParser(QUIET=True)
structure = parser.get_structure("1crn", "1crn.pdb")

# Calculate distance between alpha carbons
chain = structure[0]["A"]
distance = chain[10]["CA"] - chain[20]["CA"]
print(f"Distance: {distance:.2f} Å")
'
```

### Workflow: Read and visualize tree with Bio.Phylo

### Step 1: Read and visualize tree with Bio.Phylo

```bash
docker run --rm -v "$(pwd)":/ftmp -w /ftmp dnalinux/biopython \
/biopython/bin/python -c '
from Bio import Phylo

# Read and visualize tree
tree = Phylo.read("tree.nwk", "newick")
Phylo.draw_ascii(tree)

# Calculate distance
distance = tree.distance("Species_A", "Species_B")
print(f"Distance: {distance:.3f}")
'
```

## Common Patterns

### Pattern 1: Fetch Sequence from GenBank

```bash
docker run --rm -v "$(pwd)":/ftmp -w /ftmp dnalinux/biopython \
/biopython/bin/python -c '
from Bio import Entrez, SeqIO

Entrez.email = "your.email@example.com"

# Fetch sequence
handle = Entrez.efetch(db="nucleotide", id="EU490707", rettype="gb", retmode="text")
record = SeqIO.read(handle, "genbank")
handle.close()

print(f"Description: {record.description}")
print(f"Sequence length: {len(record.seq)}")
'
```

### Pattern 2: Sequence Analysis Pipeline

```bash
docker run --rm -v "$(pwd)":/ftmp -w /ftmp dnalinux/biopython \
/biopython/bin/python -c '
from Bio import SeqIO
from Bio.SeqUtils import gc_fraction

for record in SeqIO.parse("sequences.fasta", "fasta"):
    # Calculate statistics
    gc = gc_fraction(record.seq)
    length = len(record.seq)

    # Find ORFs, translate, etc.
    protein = record.seq.translate()

    print(f"{record.id}: {length} bp, GC={gc:.2%}")
'
```

### Pattern 3: BLAST and Fetch Top Hits

```bash
docker run --rm -v "$(pwd)":/ftmp -w /ftmp dnalinux/biopython \
/biopython/bin/python -c '
from Bio.Blast import NCBIWWW, NCBIXML
from Bio import Entrez, SeqIO

Entrez.email = "your.email@example.com"

# Run BLAST
result_handle = NCBIWWW.qblast("blastn", "nt", sequence)
blast_record = NCBIXML.read(result_handle)

# Get top hit accessions
accessions = [aln.accession for aln in blast_record.alignments[:5]]

# Fetch sequences
for acc in accessions:
    handle = Entrez.efetch(db="nucleotide", id=acc, rettype="fasta", retmode="text")
    record = SeqIO.read(handle, "fasta")
    handle.close()
    print(f">{record.description}")
'
```

### Pattern 4: Build Phylogenetic Tree from Sequences

```bash
docker run --rm -v "$(pwd)":/ftmp -w /ftmp dnalinux/biopython \
/biopython/bin/python -c '
from Bio import AlignIO, Phylo
from Bio.Phylo.TreeConstruction import DistanceCalculator, DistanceTreeConstructor

# Read alignment
alignment = AlignIO.read("alignment.fasta", "fasta")

# Calculate distances
calculator = DistanceCalculator("identity")
dm = calculator.get_distance(alignment)

# Build tree
constructor = DistanceTreeConstructor()
tree = constructor.nj(dm)

# Visualize
Phylo.draw_ascii(tree)
'
```

## Citation

If the user asks for a citation for biopython, provide the following:

Biopython skill for Scientific Agent Skills, version 1.2.
K-Dense Inc. (2026).
https://github.com/K-Dense-AI/scientific-agent-skills/tree/main/skills/biopython

Peter J. A. Cock, Tiago Antao, Jeffrey T. Chang, Brad A. Chapman, Cymon J. Cox, Andrew Dalke, Iddo Friedberg, Thomas Hamelryck, Frank Kauff, Bartek Wilczyński, Michiel J. L. de Hoon: Biopython: freely available Python tools for computational molecular biology and bioinformatics. Bioinformatics 25 (11), 1422–1423 (2009). https://doi.org/10.1093/bioinformatics/btp163