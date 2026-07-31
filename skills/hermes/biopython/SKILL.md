---
name: biopython
description: Comprehensive Python toolkit for molecular biology - sequence manipulation, file parsing, BLAST, phylogenetics, and structural bioinformatics
version: 1.0.0
platforms: [macos, linux]
metadata:
  hermes:
    tags: [bioinformatics, python, sequences, blast, phylogenetics, pdb]
    category: bioinformatics
    requires_toolsets: [terminal]
---

# Biopython - Computational Molecular Biology in Python

Biopython is a comprehensive set of Python tools for biological computation: sequence manipulation, file I/O, database access, structural bioinformatics, phylogenetics, and more.

## When to Use

**Appropriate scenarios:**
- Working with biological sequences (DNA, RNA, protein)
- Reading, writing, or converting file formats (FASTA, GenBank, FASTQ, PDB)
- Accessing NCBI databases (GenBank, PubMed, Protein) via Entrez
- Running BLAST searches or parsing results
- Sequence alignments (pairwise or multiple)
- Protein structure analysis
- Phylogenetic tree manipulation
- Batch processing and custom pipelines

## Procedure

### 1. Read and parse FASTA files

```bash
docker run --rm -i dnalinux/biopython -v "$(pwd)":/ftmp -w /ftmp /biopython/bin/python - << 'EOF'
from Bio import SeqIO

for record in SeqIO.parse("sequences.fasta", "fasta"):
    print(f"{record.id}: {len(record.seq)} bp")
EOF
```

### 2. Convert GenBank to FASTA

```bash
docker run --rm -i dnalinux/biopython -v "$(pwd)":/ftmp -w /ftmp /biopython/bin/python - << 'EOF'
from Bio import SeqIO

SeqIO.convert("input.gb", "genbank", "output.fasta", "fasta")
EOF
```

### 3. Search PubMed via Entrez

```bash
docker run --rm -i dnalinux/biopython /biopython/bin/python - << 'EOF'
from Bio import Entrez
Entrez.email = "your.email@example.com"

handle = Entrez.esearch(db="pubmed", term="biopython", retmax=10)
results = Entrez.read(handle)
handle.close()
print(f"Found {results['Count']} results")
EOF
```

### 4. Run BLAST search

```bash
docker run --rm -i dnalinux/biopython /biopython/bin/python - << 'EOF'
from Bio.Blast import NCBIWWW, NCBIXML

result_handle = NCBIWWW.qblast("blastn", "nt", "ATCGATCGATCG")
blast_record = NCBIXML.read(result_handle)

for alignment in blast_record.alignments[:5]:
    print(f"{alignment.title}: E-value={alignment.hsps[0].expect}")
EOF
```

### 5. Pairwise alignment

```bash
docker run --rm -i dnalinux/biopython /biopython/bin/python - << 'EOF'
from Bio import Align

aligner = Align.PairwiseAligner()
aligner.mode = "global"
alignments = aligner.align("ACCGGT", "ACGGT")
print(alignments[0])
EOF
```

### 6. Parse PDB structures

```bash
docker run --rm -i dnalinux/biopython /biopython/bin/python - << 'EOF'
from Bio.PDB import PDBParser

parser = PDBParser(QUIET=True)
structure = parser.get_structure("1crn", "1crn.pdb")

chain = structure[0]["A"]
distance = chain[10]["CA"] - chain[20]["CA"]
print(f"Distance: {distance:.2f} Å")
EOF
```

### 7. Read and visualize phylogenetic tree

```bash
docker run --rm -i dnalinux/biopython -v "$(pwd)":/ftmp -w /ftmp /biopython/bin/python - << 'EOF'
from Bio import Phylo

tree = Phylo.read("tree.nwk", "newick")
Phylo.draw_ascii(tree)

distance = tree.distance("Species_A", "Species_B")
print(f"Distance: {distance:.3f}")
EOF
```

## Pitfalls

**Entrez requires email:**
Always set `Entrez.email` before using NCBI services. This is required by NCBI policy.

**API key for rate limits:**
Without an API key, rate is limited to 3 requests/second. With a key, it increases to 10/second.

**Handle network errors:**
Entrez calls can fail. Wrap in try/except for `HTTPError`.

**Close file handles:**
Use context managers (`with open(...)`) to ensure handles are closed.

## Verification

```bash
# Test Biopython installation
docker run --rm dnalinux/biopython /biopython/bin/python -c "from Bio import SeqIO; print('OK')"

# Check version
docker run --rm dnalinux/biopython /biopython/bin/python -c "import Bio; print(Bio.__version__)"
```

## Key Modules

| Module | Purpose |
|--------|---------|
| `Bio.SeqIO` | Read/write sequence files |
| `Bio.AlignIO` | Read/write alignments |
| `Bio.Entrez` | NCBI database access |
| `Bio.Blast` | BLAST searches |
| `Bio.Align` | Pairwise alignments |
| `Bio.PDB` | Protein structures |
| `Bio.Phylo` | Phylogenetic trees |
| `Bio.SeqUtils` | Sequence utilities (GC, MW, etc.) |

## Citation

Cock PJA, Antao T, Chang JT, Chapman BA, Cox CJ, Dalke A, Friedberg I, Hamelryck T, Kauff F, Wilczyński B, de Hoon MJL. Biopython: freely available Python tools for computational molecular biology and bioinformatics. Bioinformatics 25(11): 1422–1423 (2009). https://doi.org/10.1093/bioinformatics/btp163
