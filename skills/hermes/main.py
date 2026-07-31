#!/usr/bin/env python3
"""
randomsplit.py — Randomly subsample a FASTQ or FASTA file by percentage.

File type (FASTQ vs FASTA) and compression (gzip) are detected from the
file content, not from the file extension.

Usage:
    python randomsplit.py -p 10 -i input.fastq            # 10% to stdout
    python randomsplit.py -p 25 -i input.fasta.gz         # gzip input supported
    python randomsplit.py -p 10 -i input.fa  -s 42        # fixed random seed
    python randomsplit.py -u 5  -i input.fastq            # exactly 5 random records from input
    python randomsplit.py -u 5  -i input.fastq --order head  # first 5 records
    python randomsplit.py -u 20 -t fasta                  # generate 20 random FASTA records
    python randomsplit.py -u 50 -t fastq -s 1 -o x.fq     # generate 50 FASTQ records to file
"""

import argparse
import gzip
import math
import random
import sys


def parse_args():
    """Parse command-line arguments for randomsplit.

    Parameters
    ----------
    (none) — reads from sys.argv via argparse.

    Returns
    -------
    argparse.Namespace
        Parsed arguments with attributes: input (str|None), percent (float|None),
        seed (int|None), output (str|None), order (str), unit (int|None),
        type (str|None), length (int).
    """
    parser = argparse.ArgumentParser(
        description="Subsample a FASTQ file by a given percentage."
    )
    parser.add_argument(
        "-i", "--input", default=None,
        help="Input FASTQ or FASTA file (plain or gzip-compressed); type detected by content. Omit to generate random sequences (see -u/--unit)."
    )
    parser.add_argument(
        "-p", "--percent", type=float, default=None,
        help="Percentage of reads to keep (e.g. 10 for 10%%). Use with -i/--input (mutually exclusive with -u)."
    )
    parser.add_argument(
        "-s", "--seed", type=int, default=None,
        help="Random seed for reproducibility (optional)."
    )
    parser.add_argument(
        "-o", "--output", default=None,
        help="Output filename (optional). Defaults to stdout."
    )
    parser.add_argument(
        "--order", choices=["random", "head", "tail"], default="random",
        help="Selection strategy: 'random' (default), 'head' (first X%%), or 'tail' (last X%%)."
    )
    parser.add_argument(
        "-u", "--unit", type=int, default=None,
        help="With -i: keep exactly N records from input. Without -i: generate N random sequences (requires -t)."
    )
    parser.add_argument(
        "-t", "--type", choices=["fasta", "fastq"], default=None,
        help="Output format when generating with -u/--unit: 'fasta' or 'fastq'."
    )
    parser.add_argument(
        "-l", "--length", type=int, default=100,
        help="Sequence length when generating with -u/--unit (default: 100)."
    )
    return parser.parse_args()


def open_by_content(path):
    """Open a file as text, transparently handling gzip based on magic bytes.

    Detection uses the first two bytes (0x1f 0x8b for gzip), so the file's
    extension is irrelevant.

    Parameters
    ----------
    path : str
        Filesystem path to the file (e.g. "sample.fastq", "sample.fq.gz",
        or even "sample.bin" if it contains gzip data).

    Returns
    -------
    io.TextIOBase
        A file handle opened in text mode ("rt"). The caller is responsible
        for closing it.
    """
    with open(path, "rb") as fh:
        magic = fh.read(2)
    if magic == b"\x1f\x8b":
        return gzip.open(path, "rt")
    return open(path, "r")


def detect_format(fh):
    """Peek the first non-empty line to detect FASTQ ('@') or FASTA ('>').

    Parameters
    ----------
    fh : io.TextIOBase
        Readable text file handle positioned at the start of the file
        (e.g. `open("sample.fastq")` or `io.StringIO(">s1\nACGT\n")`).
        After this call the handle is advanced past the peeked line.

    Returns
    -------
    tuple of (str, str)
        (format, first_line) where format is 'fastq' or 'fasta' and
        first_line is the consumed header line (must be re-fed to the iterator).
    """
    first = ""
    while True:
        line = fh.readline()
        if not line:
            sys.exit("ERROR: Input file is empty or contains no records.")
        if line.strip():
            first = line
            break
    if first.startswith("@"):
        return "fastq", first
    if first.startswith(">"):
        return "fasta", first
    sys.exit("ERROR: Unrecognized file format (expected FASTQ '@' or FASTA '>').")


def iter_fastq(fh, first_line):
    """Yield one FASTQ record at a time as a list of 4 lines.

    Parameters
    ----------
    fh : io.TextIOBase
        Readable text file handle positioned just after the first header line
        (e.g. the handle returned by `open_by_content` after `detect_format`).
    first_line : str
        The header line already consumed by `detect_format` (e.g. '@read1\n');
        re-injected as the header of the first yielded record.

    Yields
    ------
    list of str
        A 4-element list: [header, sequence, plus, quality], each ending in '\n'.
    """
    header = first_line
    while header:
        seq    = fh.readline()
        plus   = fh.readline()
        qual   = fh.readline()
        if not qual:
            sys.exit("ERROR: Incomplete FASTQ record. File may be truncated.")
        yield [header, seq, plus, qual]
        header = fh.readline()
        if not header:
            break


def generate_records(count, fmt, length, rng):
    """Yield `count` random records as list-of-lines, in FASTA or FASTQ format.

    Sequences are uniformly random over {A,C,G,T}. FASTQ quality is a constant
    'I' (Phred 40). One record at a time — memory-efficient.

    Parameters
    ----------
    count : int
        Number of records to yield. Must be > 0 (e.g. 20).
    fmt : str
        Output format; either 'fasta' or 'fastq' (e.g. 'fasta').
    length : int
        Length (in bases) of each generated sequence. Must be > 0 (e.g. 100).
    rng : random.Random
        Pre-seeded RNG instance used for base sampling (e.g. `random.Random(42)`).

    Yields
    ------
    list of str
        Lines of one record. 2 lines for FASTA ([header, seq]); 4 lines for
        FASTQ ([header, seq, '+', quality]). Each line ends in '\n'.
    """
    bases = "ACGT"
    for i in range(1, count + 1):
        seq = "".join(rng.choice(bases) for _ in range(length))
        if fmt == "fasta":
            yield [f">seq{i}\n", f"{seq}\n"]
        else:  # fastq
            qual = "I" * length
            yield [f"@read{i}\n", f"{seq}\n", "+\n", f"{qual}\n"]


def iter_fasta(fh, first_line):
    """Yield one FASTA record at a time as a list of lines (header + seq lines).

    Supports multi-line sequences.

    Parameters
    ----------
    fh : io.TextIOBase
        Readable text file handle positioned just after the first header line
        (e.g. the handle returned by `open_by_content` after `detect_format`).
    first_line : str
        The header line already consumed by `detect_format` (e.g. '>seq1\n');
        re-injected as the header of the first yielded record.

    Yields
    ------
    list of str
        Variable-length list: [header, seq_line_1, seq_line_2, ...]. Each
        element ends in '\n'.
    """
    header = first_line
    seq_lines = []
    for line in fh:
        if line.startswith(">"):
            yield [header] + seq_lines
            header = line
            seq_lines = []
        else:
            seq_lines.append(line)
    if header:
        yield [header] + seq_lines


def main():
    """CLI entry point.

    Parameters
    ----------
    (none) — reads arguments from sys.argv via `parse_args`.

    Returns
    -------
    None
        Writes selected/generated records to the output handle (stdout by
        default, or the file given by -o/--output). Exits with a non-zero
        status via `sys.exit` on validation errors.
    """
    args = parse_args()

    # Top-level mode validation.
    if args.input is None and args.unit is None:
        sys.exit("ERROR: must provide either -i/--input (subsample) or -u/--unit (generate).")
    if args.input is not None and args.percent is not None and args.unit is not None:
        sys.exit("ERROR: -p/--percent and -u/--unit are mutually exclusive.")
    if args.unit is not None and args.unit <= 0:
        sys.exit("ERROR: -u/--unit must be a positive integer.")

    rng = random.Random(args.seed)

    # Pure-generate mode: -u without -i.
    if args.input is None:
        if args.type is None:
            sys.exit("ERROR: -t/--type is required when generating with -u/--unit and no -i/--input.")
        if args.length <= 0:
            sys.exit("ERROR: -l/--length must be a positive integer.")
        try:
            out_fh = open(args.output, "w") if args.output else sys.stdout
            try:
                for record in generate_records(args.unit, args.type, args.length, rng):
                    out_fh.writelines(record)
            finally:
                if args.output:
                    out_fh.close()
        except BrokenPipeError:
            pass
        return

    # Subsample mode (-i is set). Selection size comes from either -p or -u.
    if args.percent is None and args.unit is None:
        sys.exit("ERROR: with -i/--input, must provide either -p/--percent or -u/--unit.")
    if args.percent is not None and not (0 < args.percent <= 100):
        sys.exit("ERROR: --percent must be between 0 (exclusive) and 100 (inclusive).")

    def open_iter():
        """Open input and return (file_handle, iterator) for one streaming pass."""
        fh = open_by_content(args.input)
        fmt, first_line = detect_format(fh)
        it = iter_fastq(fh, first_line) if fmt == "fastq" else iter_fasta(fh, first_line)
        return fh, it

    def count_records():
        fh, iterator = open_iter()
        try:
            return sum(1 for _ in iterator)
        finally:
            fh.close()

    try:
        out_fh = open(args.output, "w") if args.output else sys.stdout
        try:
            # --- Percent + random: classic Bernoulli, single pass, no count needed.
            if args.unit is None and args.order == "random":
                probability = args.percent / 100.0
                fh, iterator = open_iter()
                try:
                    for record in iterator:
                        if rng.random() < probability:
                            out_fh.writelines(record)
                finally:
                    fh.close()

            # --- Unit + random: reservoir sampling, single pass, O(unit) memory.
            elif args.unit is not None and args.order == "random":
                k = args.unit
                reservoir = []
                fh, iterator = open_iter()
                try:
                    for i, record in enumerate(iterator):
                        if i < k:
                            reservoir.append(record)
                        else:
                            j = rng.randint(0, i)
                            if j < k:
                                reservoir[j] = record
                finally:
                    fh.close()
                for record in reservoir:
                    out_fh.writelines(record)

            # --- head/tail: need n_keep then a (second) streaming pass.
            else:
                if args.unit is not None:
                    # head needs no total; tail does.
                    if args.order == "tail":
                        total = count_records()
                        n_keep = min(args.unit, total)
                    else:  # head
                        n_keep = args.unit  # cap implicitly by early break
                        total = None
                else:
                    total = count_records()
                    n_keep = math.ceil(total * (args.percent / 100.0))

                if n_keep > 0:
                    fh, iterator = open_iter()
                    try:
                        if args.order == "head":
                            emitted = 0
                            for record in iterator:
                                if emitted >= n_keep:
                                    break
                                out_fh.writelines(record)
                                emitted += 1
                        else:  # tail
                            skip = total - n_keep
                            for i, record in enumerate(iterator):
                                if i >= skip:
                                    out_fh.writelines(record)
                    finally:
                        fh.close()
        finally:
            if args.output:
                out_fh.close()
    except FileNotFoundError:
        sys.exit(f"ERROR: File not found: {args.input}")
    except BrokenPipeError:
        pass  # e.g. piped into `head` — silent exit is correct behaviour


if __name__ == "__main__":
    main()