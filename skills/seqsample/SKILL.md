---
name: SeqSample
description: "Sample or generate sequences from a FASTA or FASTQ file using main.py."
metadata:
  openclaw:
    emoji: "🧬"
    requires:
      bins: ["python3"]
---

# SeqSample Skill

SeqSample is a small, dependency-free Python tool that extracts a subset of
sequences from a FASTA or FASTQ file (random sample, the first N, or the last
N) and can also generate brand-new random sequences when no input is provided.

It is implemented as a single script: `main.py` (in this skill's directory).
There is no Docker image and no third-party Python package required — only a
working `python3` interpreter (3.7+).

## When to use it

Use SeqSample when you need to:

- Extract a **random subset** of sequences from a FASTA/FASTQ file (e.g. to
  create a smaller test dataset or speed up downstream analysis).
- Take the **first N** or **last N** records from a file (e.g. peek at the
  head or tail of a large dataset).
- **Generate** synthetic FASTA or FASTQ records with random `ACGT` sequences
  (e.g. to build fixtures or sanity-check a pipeline).

Both plain and gzip-compressed inputs are supported. **The file format
(FASTA vs FASTQ) and gzip compression are detected from the file's content,
not from its extension** — so files named `data.bin`, `reads.fa.gz`, or
`x.fastq` all work as long as the content is well-formed.

## How it works

`main.py` operates in one of two modes:

1. **Subsample mode** — when `-i/--input` is given, sequences are read from
   that file and a subset is written to stdout (or to `-o/--output`). The
   subset size is controlled by either:
     - `-p/--percent N` — keep ~N% of records (e.g. `-p 10` for 10%), **or**
     - `-u/--unit N` — keep exactly N records.
   The selection strategy is controlled by `--order`:
     - `random` (default) — uniformly random records (reservoir sampling
       when combined with `-u`, Bernoulli when combined with `-p`).
     - `head` — the first N records.
     - `tail` — the last N records.
2. **Generate mode** — when `-i` is omitted and `-u` is given, `main.py`
   generates `N` random records of length `-l/--length` (default 100) in the
   format chosen by `-t/--type` (`fasta` or `fastq`).

The script is **memory-efficient**: it streams one record at a time and
never loads the whole file. `head`/`tail` and unit-mode random use at most
two streaming passes (or O(N) memory for reservoir sampling).

## CLI reference

```
python3 main.py [-i INPUT] [-p PERCENT | -u UNIT] [--order {random,head,tail}]
                [-t {fasta,fastq}] [-l LENGTH] [-s SEED] [-o OUTPUT]
```

| Flag | Meaning |
|------|---------|
| `-i, --input PATH` | Input FASTA/FASTQ file (plain or gzip). Format auto-detected. |
| `-p, --percent N` | Keep N% of records (only with `-i`; mutually exclusive with `-u`). |
| `-u, --unit N` | With `-i`: keep exactly N records. Without `-i`: generate N records. |
| `--order MODE` | `random` (default), `head`, or `tail`. |
| `-t, --type FMT` | `fasta` or `fastq`; required only for generate mode. |
| `-l, --length N` | Sequence length when generating (default 100). |
| `-s, --seed N` | RNG seed for reproducible sampling/generation. |
| `-o, --output PATH` | Output file (defaults to stdout). |

## Usage examples

Run from this skill's directory (or pass the absolute path to `main.py`):

Take a random 10% sample of a FASTQ file:

```bash
python3 main.py -i input.fastq -p 10 > sample.fastq
```

Take exactly 100 random records from a gzipped FASTA, reproducibly:

```bash
python3 main.py -i reads.fa.gz -u 100 -s 42 -o sample.fa
```

Take the **first** 50 records (head):

```bash
python3 main.py -i input.fastq -u 50 --order head > head.fastq
```

Take the **last** 5% of records (tail):

```bash
python3 main.py -i input.fastq -p 5 --order tail > tail.fastq
```

Generate 20 random FASTA records of length 150:

```bash
python3 main.py -u 20 -t fasta -l 150 -s 1 -o synthetic.fa
```

Generate 50 random FASTQ records and pipe straight into another tool:

```bash
python3 main.py -u 50 -t fastq -l 100 | head -8
```

## Notes and constraints

- Exactly **one** of `-i` (subsample) or `-u`-without-`-i` (generate) must
  be given. With `-i`, exactly **one** of `-p` or `-u` must be given.
- For `-p`, the value must be in `(0, 100]`.
- `-u` must be a positive integer; if it exceeds the number of records in
  the input, all records are returned.
- Output is always uncompressed text (FASTA or FASTQ); pipe into `gzip` if
  you need a compressed result, e.g. `... | gzip > out.fq.gz`.
- A test suite is provided in `main_test.py` and can be run with
  `python3 -m unittest main_test` from this directory.
