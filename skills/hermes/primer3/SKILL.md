---
name: primer3
description: Design PCR primers from a DNA template using the industry-standard Primer3 tool
version: 1.0.0
platforms: [macos, linux]
metadata:
  hermes:
    tags: [bioinformatics, pcr, primer-design, molecular-biology, amplification]
    category: bioinformatics
    requires_toolsets: [terminal]
---

# Primer3 PCR Primer Design

Primer3 is the industry-standard software for designing PCR primers. It takes a DNA template sequence and designs optimal primer pairs based on thermodynamic properties, GC content, and user-specified constraints.

## When to Use

**Appropriate scenarios:**
- Designing PCR primers for a known DNA template
- Amplifying specific regions of a genome
- Cloning and sequencing applications
- Need to control primer properties (Tm, GC%, length)

**Input requirements:**
- DNA template sequence (FASTA or raw sequence)
- Target region coordinates (optional but recommended)
- Desired amplicon size range

## Procedure

### 1. Create the input file (Boulder-IO format)

Create a text file with the template sequence and parameters:

```text
SEQUENCE_ID=example
SEQUENCE_TEMPLATE=GTAGTCAGTAGACNATGACNACTGACGATGCAGACNACACACACACACACAGCACACAGGTATTAGTGGGCCATTCGATCCCGACCCAAATCGATAGCTACGATGACG
SEQUENCE_TARGET=37,21
PRIMER_TASK=generic
PRIMER_PICK_LEFT_PRIMER=1
PRIMER_PICK_RIGHT_PRIMER=1
PRIMER_OPT_SIZE=18
PRIMER_MIN_SIZE=15
PRIMER_MAX_SIZE=21
PRIMER_MAX_NS_ACCEPTED=1
PRIMER_PRODUCT_SIZE_RANGE=75-100
P3_FILE_FLAG=1
PRIMER_EXPLAIN_FLAG=1
=
```

**Key fields:**
- `SEQUENCE_ID` — Identifier for this record
- `SEQUENCE_TEMPLATE` — DNA template sequence
- `SEQUENCE_TARGET=start,length` — Target region (1-based position, length)
- `PRIMER_PRODUCT_SIZE_RANGE=min-max` — Allowed amplicon size
- `PRIMER_OPT_SIZE` — Optimal primer length
- `PRIMER_MIN_SIZE` / `PRIMER_MAX_SIZE` — Primer length range
- `P3_FILE_FLAG=1` — Write per-primer detail files
- `PRIMER_EXPLAIN_FLAG=1` — Explain why candidates were rejected
- `=` — Required record terminator

### 2. Run Primer3

```bash
docker run --network=none -v $(pwd):/ftmp dnalinux/primer3:2.6.1 /bin/bash -c \
  "cd /ftmp/ && primer3_core < /ftmp/inputfile"
```

The output is a Boulder-IO record to stdout.

### 3. Parse the output

Key output fields to extract:

```text
PRIMER_LEFT_0_SEQUENCE=AGGAGTGGGATGGAAGTCGA
PRIMER_RIGHT_0_SEQUENCE=GGCTTTGTCTTCTCTGCCGA
PRIMER_LEFT_0=97,20
PRIMER_RIGHT_0=456,20
PRIMER_LEFT_0_TM=59.959
PRIMER_RIGHT_0_TM=60.321
PRIMER_LEFT_0_GC_PERCENT=55.000
PRIMER_RIGHT_0_GC_PERCENT=55.000
PRIMER_PAIR_0_PRODUCT_SIZE=380
```

**Output format:**
- `PRIMER_LEFT_0=pos,len` — Forward primer position (1-based), length
- `PRIMER_RIGHT_0=pos,len` — Reverse primer position, length
- `*_TM` — Melting temperature in °C
- `*_GC_PERCENT` — GC content as percentage
- `PRIMER_PAIR_0_PRODUCT_SIZE` — Amplicon size in bp

### 4. Add internal oligo (optional)

If an internal probe is needed:

```text
PRIMER_PICK_INTERNAL_OLIGO=1
```

This produces `example.int` file with internal oligo details.

## Pitfalls

**Product size range too narrow:**
Very narrow ranges (e.g., `300-310`) often produce `PRIMER_PAIR_NUM_RETURNED=0`. Widen the range to recover.

**Target span exceeds product size:**
The amplicon must fully contain the `SEQUENCE_TARGET` region. Minimum product size must be at least as large as target length.

**Tm outside default range (57-63°C):**
If template local Tm is incompatible, relax with `PRIMER_MIN_TM` / `PRIMER_MAX_TM` or adjust `PRIMER_OPT_TM`.

**Missing SEQUENCE_TEMPLATE:**
The error `PRIMER_ERROR=Missing SEQUENCE_TEMPLATE tag` indicates the input file lacks the required template.

**Ambiguous bases (N's) in template:**
Increase `PRIMER_MAX_NS_ACCEPTED` if ambiguous bases must be kept.

## Verification

Successful run produces:
- Boulder-IO output record with `PRIMER_PAIR_NUM_RETURNED > 0`
- Per-primer detail files: `<SEQUENCE_ID>.for`, `<SEQUENCE_ID>.rev` (and `.int` if internal oligo picked)
- `PRIMER_*_EXPLAIN` tags showing candidate screening statistics

Quick validation:
```bash
# Check for returned primers
grep "PRIMER_PAIR_NUM_RETURNED" output.txt

# Check primer sequences exist
grep "PRIMER_LEFT_0_SEQUENCE" output.txt
grep "PRIMER_RIGHT_0_SEQUENCE" output.txt
```

## Key Parameters

### Input Definition
| Flag | Description |
|------|-------------|
| `SEQUENCE_ID=name` | Record identifier |
| `SEQUENCE_TEMPLATE=seq` | DNA template sequence |
| `SEQUENCE_TARGET=start,len` | Target region (1-based) |
| `SEQUENCE_INCLUDED_REGION=start,len` | Restrict primer search region |

### Primer Properties
| Flag | Description |
|------|-------------|
| `PRIMER_OPT_SIZE=N` | Optimal primer length (default 20) |
| `PRIMER_MIN_SIZE=N` | Minimum primer length (default 18) |
| `PRIMER_MAX_SIZE=N` | Maximum primer length (default 27) |
| `PRIMER_OPT_TM=F` | Optimal Tm °C (default 59) |
| `PRIMER_MIN_TM=F` | Minimum Tm (default 57) |
| `PRIMER_MAX_TM=F` | Maximum Tm (default 63) |
| `PRIMER_MIN_GC=F` | Minimum GC% (default 20) |
| `PRIMER_MAX_GC=F` | Maximum GC% (default 80) |

### Product Constraints
| Flag | Description |
|------|-------------|
| `PRIMER_PRODUCT_SIZE_RANGE=min-max` | Allowed amplicon size |
| `PRIMER_MAX_NS_ACCEPTED=N` | Max N bases in primer |

### Output Control
| Flag | Description |
|------|-------------|
| `P3_FILE_FLAG=1` | Write per-primer files |
| `PRIMER_EXPLAIN_FLAG=1` | Explain rejection reasons |
| `PRIMER_NUM_RETURN=N` | Return up to N primer pairs |

## Citation

Untergasser A, Cutcutache I, Koressaar T, Ye J, Faircloth BC, Remm M, Rozen SG. Primer3--new capabilities and interfaces. Nucleic Acids Res. 2012 Aug;40(15):e115. doi: 10.1093/nar/gks596. Epub 2012 Jun 22. PMID: 22730293; PMCID: PMC3424584.
