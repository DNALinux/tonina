#!/usr/bin/env python3
"""Unit tests for randomsplit/main.py.

Usage
-----
Run from this directory (skills/randomsplit/):

    python3 -m unittest main_test            # run all tests
    python3 -m unittest main_test -v         # verbose output
    python3 main_test.py                     # equivalent (uses unittest.main)

Run a single test class or method:

    python3 -m unittest main_test.CLIHeadTailTests
    python3 -m unittest main_test.CLIHeadTailTests.test_head_fastq_keeps_first_n

Run from any directory:

    python3 -m unittest discover -s /Users/sb/projects/dnalinux/tonina/skills/randomsplit -p 'main_test.py'

Requirements
------------
- Python 3 (standard library only; no external packages).
- The fixture files `sample.fasta` and `sample.fastq` (50 entries each) must
  sit next to this file. They are created once and committed alongside the
  tests; if missing, regenerate them with:

      python3 -c "
      bases='ACGT'
      with open('sample.fasta','w') as fa, open('sample.fastq','w') as fq:
          for i in range(1, 51):
              seq = ''.join(bases[(i*j)%4] for j in range(20))
              fa.write(f'>seq{i}\n{seq}\n')
              fq.write(f'@read{i}\n{seq}\n+\n{\"I\"*20}\n')
      "

What is tested
--------------
- Fixture sanity (50 records in each sample file).
- Content-based format detection (FASTQ/FASTA) and gzip detection by magic
  bytes (no reliance on file extensions).
- FASTQ and FASTA record iterators, including multi-line FASTA sequences.
- CLI behavior of `main.py`:
    * random mode is reproducible with `-s`, keeps all at `-p 100`,
      and rejects out-of-range percentages.
    * `--order head` / `--order tail` keep the exact first/last N records.
    * `-o/--output` writes a file identical to the stdout output.
    * Gzipped input is handled end-to-end even without a `.gz` extension.
"""

import gzip
import io
import math
import os
import subprocess
import sys
import tempfile
import unittest

HERE = os.path.dirname(os.path.abspath(__file__))
MAIN = os.path.join(HERE, "main.py")
SAMPLE_FASTA = os.path.join(HERE, "sample.fasta")
SAMPLE_FASTQ = os.path.join(HERE, "sample.fastq")

sys.path.insert(0, HERE)
import main as rs  # noqa: E402


def run_cli(*args, check=True):
    """Run main.py as a subprocess and return (stdout, stderr, returncode)."""
    result = subprocess.run(
        [sys.executable, MAIN, *args],
        capture_output=True, text=True,
    )
    if check and result.returncode != 0:
        raise AssertionError(
            f"CLI failed ({result.returncode}): {result.stderr}"
        )
    return result.stdout, result.stderr, result.returncode


def count_fastq_records(text):
    lines = text.splitlines()
    assert len(lines) % 4 == 0, "FASTQ output not a multiple of 4 lines"
    return len(lines) // 4


def count_fasta_records(text):
    return sum(1 for line in text.splitlines() if line.startswith(">"))


class FixtureSanityTests(unittest.TestCase):
    def test_fasta_has_50(self):
        with open(SAMPLE_FASTA) as f:
            self.assertEqual(count_fasta_records(f.read()), 50)

    def test_fastq_has_50(self):
        with open(SAMPLE_FASTQ) as f:
            self.assertEqual(count_fastq_records(f.read()), 50)


class FormatDetectionTests(unittest.TestCase):
    def test_detect_fastq(self):
        fh = io.StringIO("@r1\nACGT\n+\nIIII\n")
        fmt, first = rs.detect_format(fh)
        self.assertEqual(fmt, "fastq")
        self.assertEqual(first, "@r1\n")

    def test_detect_fasta(self):
        fh = io.StringIO(">s1\nACGT\n")
        fmt, first = rs.detect_format(fh)
        self.assertEqual(fmt, "fasta")
        self.assertEqual(first, ">s1\n")

    def test_detect_unknown_exits(self):
        fh = io.StringIO("garbage\n")
        with self.assertRaises(SystemExit):
            rs.detect_format(fh)

    def test_detect_empty_exits(self):
        fh = io.StringIO("")
        with self.assertRaises(SystemExit):
            rs.detect_format(fh)

    def test_open_by_content_plain(self):
        with tempfile.NamedTemporaryFile("w", suffix=".txt", delete=False) as tf:
            tf.write(">s1\nACGT\n")
            path = tf.name
        try:
            fh = rs.open_by_content(path)
            self.assertEqual(fh.read(), ">s1\nACGT\n")
            fh.close()
        finally:
            os.unlink(path)

    def test_open_by_content_gzip_without_extension(self):
        # File has NO .gz extension but real gzip content — must still be detected.
        with tempfile.NamedTemporaryFile(suffix=".bin", delete=False) as tf:
            path = tf.name
        with gzip.open(path, "wt") as gz:
            gz.write(">s1\nACGT\n")
        try:
            fh = rs.open_by_content(path)
            self.assertEqual(fh.read(), ">s1\nACGT\n")
            fh.close()
        finally:
            os.unlink(path)


class IteratorTests(unittest.TestCase):
    def test_iter_fastq_yields_4_line_records(self):
        with open(SAMPLE_FASTQ) as fh:
            _, first = rs.detect_format(fh)
            records = list(rs.iter_fastq(fh, first))
        self.assertEqual(len(records), 50)
        for rec in records:
            self.assertEqual(len(rec), 4)
            self.assertTrue(rec[0].startswith("@"))
            self.assertTrue(rec[2].startswith("+"))

    def test_iter_fasta_yields_all_records(self):
        with open(SAMPLE_FASTA) as fh:
            _, first = rs.detect_format(fh)
            records = list(rs.iter_fasta(fh, first))
        self.assertEqual(len(records), 50)
        for rec in records:
            self.assertTrue(rec[0].startswith(">"))

    def test_iter_fasta_multiline(self):
        text = ">s1\nACGT\nACGT\n>s2\nTTTT\n"
        fh = io.StringIO(text)
        _, first = rs.detect_format(fh)
        records = list(rs.iter_fasta(fh, first))
        self.assertEqual(len(records), 2)
        self.assertEqual(records[0], [">s1\n", "ACGT\n", "ACGT\n"])
        self.assertEqual(records[1], [">s2\n", "TTTT\n"])


class CLIRandomTests(unittest.TestCase):
    def test_random_fastq_seeded_is_reproducible(self):
        out1, _, _ = run_cli("-i", SAMPLE_FASTQ, "-p", "40", "-s", "7")
        out2, _, _ = run_cli("-i", SAMPLE_FASTQ, "-p", "40", "-s", "7")
        self.assertEqual(out1, out2)
        # Output must be valid FASTQ (multiple of 4 lines).
        self.assertEqual(len(out1.splitlines()) % 4, 0)

    def test_random_fasta_seeded_is_reproducible(self):
        out1, _, _ = run_cli("-i", SAMPLE_FASTA, "-p", "40", "-s", "7")
        out2, _, _ = run_cli("-i", SAMPLE_FASTA, "-p", "40", "-s", "7")
        self.assertEqual(out1, out2)
        self.assertTrue(all(
            line.startswith(">") or set(line) <= set("ACGTN")
            for line in out1.splitlines()
        ))

    def test_random_100_percent_keeps_everything(self):
        out, _, _ = run_cli("-i", SAMPLE_FASTQ, "-p", "100", "-s", "1")
        self.assertEqual(count_fastq_records(out), 50)

    def test_percent_out_of_range_exits_nonzero(self):
        _, _, rc = run_cli("-i", SAMPLE_FASTQ, "-p", "0", check=False)
        self.assertNotEqual(rc, 0)
        _, _, rc = run_cli("-i", SAMPLE_FASTQ, "-p", "150", check=False)
        self.assertNotEqual(rc, 0)


class CLIHeadTailTests(unittest.TestCase):
    def _read(self, path):
        with open(path) as f:
            return f.read()

    def test_head_fastq_keeps_first_n(self):
        out, _, _ = run_cli("-i", SAMPLE_FASTQ, "-p", "10", "--order", "head")
        n_keep = math.ceil(50 * 0.10)  # 5
        self.assertEqual(count_fastq_records(out), n_keep)
        expected = "".join(self._read(SAMPLE_FASTQ).splitlines(keepends=True)[: n_keep * 4])
        self.assertEqual(out, expected)

    def test_tail_fastq_keeps_last_n(self):
        out, _, _ = run_cli("-i", SAMPLE_FASTQ, "-p", "10", "--order", "tail")
        n_keep = math.ceil(50 * 0.10)  # 5
        self.assertEqual(count_fastq_records(out), n_keep)
        all_lines = self._read(SAMPLE_FASTQ).splitlines(keepends=True)
        expected = "".join(all_lines[-n_keep * 4:])
        self.assertEqual(out, expected)

    def test_head_fasta_keeps_first_n(self):
        out, _, _ = run_cli("-i", SAMPLE_FASTA, "-p", "20", "--order", "head")
        n_keep = math.ceil(50 * 0.20)  # 10
        self.assertEqual(count_fasta_records(out), n_keep)
        # First record header must be seq1.
        self.assertTrue(out.startswith(">seq1\n"))

    def test_tail_fasta_keeps_last_n(self):
        out, _, _ = run_cli("-i", SAMPLE_FASTA, "-p", "20", "--order", "tail")
        n_keep = math.ceil(50 * 0.20)  # 10
        self.assertEqual(count_fasta_records(out), n_keep)
        # Last record header must be seq50.
        headers = [l for l in out.splitlines() if l.startswith(">")]
        self.assertEqual(headers[0], ">seq41")
        self.assertEqual(headers[-1], ">seq50")


class CLIOutputFlagTests(unittest.TestCase):
    def test_output_file_matches_stdout(self):
        stdout_out, _, _ = run_cli("-i", SAMPLE_FASTQ, "-p", "30", "-s", "3")
        with tempfile.NamedTemporaryFile("w", suffix=".fq", delete=False) as tf:
            out_path = tf.name
        try:
            run_cli("-i", SAMPLE_FASTQ, "-p", "30", "-s", "3", "-o", out_path)
            with open(out_path) as f:
                file_out = f.read()
            self.assertEqual(stdout_out, file_out)
        finally:
            os.unlink(out_path)


class CLIGzipTests(unittest.TestCase):
    def test_gzip_input_without_extension(self):
        # Verify content-based gzip detection end-to-end.
        with tempfile.NamedTemporaryFile(suffix=".bin", delete=False) as tf:
            gz_path = tf.name
        with open(SAMPLE_FASTQ, "rb") as src, gzip.open(gz_path, "wb") as dst:
            dst.write(src.read())
        try:
            out, _, _ = run_cli("-i", gz_path, "-p", "100", "-s", "1")
            self.assertEqual(count_fastq_records(out), 50)
        finally:
            os.unlink(gz_path)


class GenerateModeTests(unittest.TestCase):
    def test_generate_records_fasta_count_and_shape(self):
        rng = __import__("random").Random(0)
        records = list(rs.generate_records(7, "fasta", 30, rng))
        self.assertEqual(len(records), 7)
        for i, rec in enumerate(records, 1):
            self.assertEqual(len(rec), 2)
            self.assertEqual(rec[0], f">seq{i}\n")
            self.assertEqual(len(rec[1].rstrip("\n")), 30)
            self.assertTrue(set(rec[1].rstrip("\n")) <= set("ACGT"))

    def test_generate_records_fastq_count_and_shape(self):
        rng = __import__("random").Random(0)
        records = list(rs.generate_records(4, "fastq", 12, rng))
        self.assertEqual(len(records), 4)
        for i, rec in enumerate(records, 1):
            self.assertEqual(len(rec), 4)
            self.assertEqual(rec[0], f"@read{i}\n")
            self.assertEqual(len(rec[1].rstrip("\n")), 12)
            self.assertEqual(rec[2], "+\n")
            self.assertEqual(rec[3].rstrip("\n"), "I" * 12)

    def test_cli_generate_fasta(self):
        out, _, _ = run_cli("-u", "20", "-t", "fasta", "-s", "1", "-l", "25")
        self.assertEqual(count_fasta_records(out), 20)
        # Every sequence line has length 25.
        for line in out.splitlines():
            if not line.startswith(">"):
                self.assertEqual(len(line), 25)

    def test_cli_generate_fastq(self):
        out, _, _ = run_cli("-u", "15", "-t", "fastq", "-s", "1", "-l", "10")
        self.assertEqual(count_fastq_records(out), 15)
        lines = out.splitlines()
        for i in range(0, len(lines), 4):
            self.assertTrue(lines[i].startswith("@"))
            self.assertEqual(len(lines[i + 1]), 10)
            self.assertEqual(lines[i + 2], "+")
            self.assertEqual(lines[i + 3], "I" * 10)

    def test_cli_generate_seeded_reproducible(self):
        out1, _, _ = run_cli("-u", "10", "-t", "fasta", "-s", "42")
        out2, _, _ = run_cli("-u", "10", "-t", "fasta", "-s", "42")
        self.assertEqual(out1, out2)

    def test_cli_generate_requires_type(self):
        _, _, rc = run_cli("-u", "5", check=False)
        self.assertNotEqual(rc, 0)

    def test_cli_no_input_no_unit_errors(self):
        _, _, rc = run_cli("-p", "10", check=False)
        self.assertNotEqual(rc, 0)


class CLIUnitFromInputTests(unittest.TestCase):
    """-u combined with -i: select exactly N records from input."""

    def _read(self, path):
        with open(path) as f:
            return f.read()

    def test_unit_random_fastq_exact_count(self):
        out, _, _ = run_cli("-i", SAMPLE_FASTQ, "-u", "7", "-s", "1")
        self.assertEqual(count_fastq_records(out), 7)

    def test_unit_random_fasta_exact_count(self):
        out, _, _ = run_cli("-i", SAMPLE_FASTA, "-u", "12", "-s", "1")
        self.assertEqual(count_fasta_records(out), 12)

    def test_unit_random_seeded_reproducible(self):
        out1, _, _ = run_cli("-i", SAMPLE_FASTQ, "-u", "7", "-s", "9")
        out2, _, _ = run_cli("-i", SAMPLE_FASTQ, "-u", "7", "-s", "9")
        self.assertEqual(out1, out2)

    def test_unit_head_first_n_fastq(self):
        out, _, _ = run_cli("-i", SAMPLE_FASTQ, "-u", "5", "--order", "head")
        self.assertEqual(count_fastq_records(out), 5)
        expected = "".join(self._read(SAMPLE_FASTQ).splitlines(keepends=True)[: 5 * 4])
        self.assertEqual(out, expected)

    def test_unit_tail_last_n_fasta(self):
        out, _, _ = run_cli("-i", SAMPLE_FASTA, "-u", "3", "--order", "tail")
        self.assertEqual(count_fasta_records(out), 3)
        headers = [l for l in out.splitlines() if l.startswith(">")]
        self.assertEqual(headers, [">seq48", ">seq49", ">seq50"])

    def test_percent_and_unit_mutually_exclusive(self):
        _, _, rc = run_cli("-i", SAMPLE_FASTQ, "-p", "10", "-u", "5", check=False)
        self.assertNotEqual(rc, 0)

    def test_input_without_p_or_u_errors(self):
        _, _, rc = run_cli("-i", SAMPLE_FASTQ, check=False)
        self.assertNotEqual(rc, 0)

    def test_unit_larger_than_total_random_returns_all(self):
        # Reservoir sampling with k > N keeps all N records.
        out, _, _ = run_cli("-i", SAMPLE_FASTQ, "-u", "999", "-s", "1")
        self.assertEqual(count_fastq_records(out), 50)

    def test_unit_larger_than_total_head_returns_all(self):
        out, _, _ = run_cli("-i", SAMPLE_FASTQ, "-u", "999", "--order", "head")
        self.assertEqual(count_fastq_records(out), 50)

    def test_unit_larger_than_total_tail_returns_all(self):
        out, _, _ = run_cli("-i", SAMPLE_FASTQ, "-u", "999", "--order", "tail")
        self.assertEqual(count_fastq_records(out), 50)


if __name__ == "__main__":
    unittest.main()
