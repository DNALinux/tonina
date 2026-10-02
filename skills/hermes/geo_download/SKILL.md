---
name: geo-gsm-download
description: Download the processed supplementary files of any GEO sample (GSM accession), e.g. 10x scRNA-seq count matrices (features.tsv.gz, barcodes.tsv.gz, matrix.mtx.gz)
version: 1.0.0
platforms: [linux]
metadata:
  hermes:
    tags: [bioinformatics, geo, ncbi, download, scrna-seq, 10x, counts]
    category: bioinformatics
    requires_toolsets: [terminal]
---

# GEO Sample (GSM) Supplementary File Download

Downloads the processed data files attached to any GEO **sample record** (GSM accession) from the NCBI FTP mirror over plain HTTP — no special tools or accounts required. For 10x scRNA-seq samples these are the three files needed to rebuild the gene × cell count matrix: `*_matrix.mtx.gz` (sparse counts), `*_features.tsv.gz` (genes), `*_barcodes.tsv.gz` (cells).

## When to Use

**Input requirements:**
- A GSM accession for a sample whose page shows "Processed data provided as supplementary file"
- Internet access; free disk space (a 10x `.mtx.gz` is typically 50–500 Mb per sample)

**Appropriate scenarios:**
- Fetching Cell Ranger-style 10x count matrices to start an scRNA-seq workflow (QC → normalize → integrate, e.g. the Seurat pipeline)
- Any analysis starting from processed per-sample matrices rather than raw reads

**Not suitable for:**
- Raw reads (FASTQ) → those live in SRA; use `sra-toolkit` (`prefetch`/`fasterq-dump`) on the SRR linked in the sample's Relations section
- Samples whose page says "Supplementary data files not provided" / "Processed data are available on Series record" → fetch from the parent **GSE** record instead
- Normalized data → GEO supplementaries for 10x are almost always **raw counts** ("Matrix table with raw gene counts..."); do not skip normalization downstream

## Procedure

### 1. Build the FTP directory URL from the accession

NCBI stores sample files under `/geo/samples/<GSM-prefix>nnn/<GSMID>/suppl/`, where the prefix is the accession with its **last 3 digits replaced by `nnn`**.

```bash
GSM=GSM1234567   # <- replace with the target accession
DIR=$(echo "$GSM" | sed -E 's/[0-9]{3}$/nnn/')
BASE="https://ftp.ncbi.nlm.nih.gov/geo/samples/${DIR}/${GSM}/suppl"
echo "$BASE"
# -> e.g. https://ftp.ncbi.nlm.nih.gov/geo/samples/GSM1234nnn/GSM1234567/suppl
```

### 2. List the available files

File names vary per submission (GSM prefix + sample-specific suffix), so always inspect the directory first instead of guessing names:

```bash
curl -s "$BASE/" | grep -oE 'href="[^"]+"' | cut -d'"' -f2 | grep '\.gz$' | sort -u
```

For a standard 10x submission the listing contains exactly the trio this workflow needs:

```
<GSMID>_<label>_barcodes.tsv.gz
<GSMID>_<label>_features.tsv.gz
<GSMID>_<label>_matrix.mtx.gz
```

### 3. Download everything that was listed

This downloads **all** supplementary `.gz` files regardless of the sample-specific label. Run it inside the data directory (e.g. the folder later mounted with `-v ...:/data`):

```bash
mkdir -p "$GSM" && cd "$GSM"

curl -s "$BASE/" | grep -oE 'href="[^"]+"' | cut -d'"' -f2 | grep '\.gz$' | sort -u \
  | while read -r F; do
      echo "Downloading $F"
      curl -fSL -C - -O "${BASE}/${F}"
    done
```

- `-f` fail on HTTP error, `-S` show errors, `-L` follow redirects
- `-C -` resume partial downloads (recommended for the large `.mtx.gz`)
- `-O` keep the remote file name — downstream tools expect those names
- The loop is sequential on purpose — see Pitfalls

## Pitfalls

**Processed ≠ normalized:**
GEO `Data processing` sections often mention Seurat `NormalizeData`, but the deposited 10x files are raw integer UMI counts (see `Supplementary_files_format_and_content`). A downstream `NormalizeData()` step is still required.

**Do not decompress:**
Keep the `.gz` files as-is. Downstream readers (`read.delim(gzfile(...))`, `Matrix::readMM(gzfile(...))`, Seurat's `Read10X()`) read gzip directly.

**Not every GSM has the 3-file 10x layout:**
Some deposit a single dense table (`.txt.gz`/`.csv.gz`) or extra files such as `aggregation.csv`. The step-3 loop downloads whatever exists; if the features/barcodes/matrix trio is absent, the sample is not directly usable as a 10x matrix — adapt the loader or fetch from the GSE series.

**curl vs wget on minimal Linux systems:**
Full server distributions ship both `curl` and `wget`, but minimal images may have only `wget` — or neither. The wget equivalent of the download step is:

```bash
wget -c "${BASE}/${F}"
```

(`wget -c` resumes partial downloads, equivalent to `curl -C -`.)

**Be polite to NCBI:**
Don't parallel-hammer the FTP mirror. The loop is sequential and supports resume (`-C -`) for that reason.

## Verification

```bash
# Run inside the download directory (same folder the files landed in)

# 1. Gzip integrity — must not print errors
gzip -t *.gz && echo "gzip integrity: OK"

# 2. Locate the 10x trio and cross-check dimensions
FEAT=$(ls *_features.tsv.gz | head -1)
BC=$(ls *_barcodes.tsv.gz  | head -1)
MTX=$(ls *_matrix.mtx.gz   | head -1)

L_GENES=$(zcat "$FEAT" | wc -l)
L_CELLS=$(zcat "$BC"   | wc -l)
HDR=$(zcat "$MTX" | grep -v '^%' | head -1)   # first non-comment line

echo "features lines: $L_GENES"
echo "barcodes lines: $L_CELLS"
echo "mtx dims line : $HDR"
```

Pass criteria:

- `HDR` is three numbers: `genes cells nnz`, where `genes == L_GENES` and `cells == L_CELLS`.
- The `%%MatrixMarket` header line (first line of the `.mtx`) contains the word `integer` → confirms **raw counts** (normalized data would say `real`).
- If any of `FEAT`/`BC`/`MTX` is empty, the 3-file 10x layout is missing — see Pitfalls.

## Key Parameters

| Parameter | Value | Notes |
|-----------|-------|-------|
| Base URL | `https://ftp.ncbi.nlm.nih.gov/geo/samples/<DIR>/<GSM>/suppl` | `<DIR>` = accession with last 3 digits → `nnn` |
| Expected 10x files | `*_features.tsv.gz`, `*_barcodes.tsv.gz`, `*_matrix.mtx.gz` | File bodies are sample-specific; discover via directory listing |
| curl flags | `-fSL -C - -O` | fail loudly, redirect-safe, resumable, keep name |
| wget fallback | `-c` | resume; use when curl is absent on minimal images |
| Download dir | one directory per GSM (`./<GSMID>/`) | keeps multi-sample datasets organized |

## Citation

Edgar R, Domrachev M, Lash AE. Gene Expression Omnibus: NCBI gene expression and hybridization array data repository. *Nucleic Acids Res.* 2002;30(1):207-10. doi:10.1093/nar/30.1.207

Always also cite the original publication of the dataset (see the Series/GSE record linked from the GSM page).
