---
name: geo-gsm-download
description: Download the processed supplementary files of any GEO sample (GSM accession), e.g. 10x scRNA-seq count matrices (features.tsv.gz, barcodes.tsv.gz, matrix.mtx.gz)
version: 1.1.0
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

**For raw reads (FASTQ):**
Use `sra-toolkit` (`prefetch`/`fasterq-dump`) on the SRR linked in the sample's Relations section — raw reads live in SRA, while this skill fetches the processed supplementaries.

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


### 4. (Optional) Prepare a Seurat Read10X() view

Seurat's `Read10X()` requires files literally named `matrix.mtx.gz`, `features.tsv.gz`, and `barcodes.tsv.gz` in one directory per sample. GEO files carry a sample prefix, so create a **symlink view** instead of renaming or copying (preserves provenance; no data duplication):

```bash
# run from the parent of ./<GSMID>/  (e.g. ~/geo_data)
GSM=GSM1234567          # same accession used in step 1
DEST="read10x/${GSM}"
mkdir -p "$DEST"
for KIND in features.tsv barcodes.tsv matrix.mtx; do
  ln -sf "$(pwd)/${GSM}/"*_"${KIND}.gz" "${DEST}/${KIND}.gz"
done
ls -l "$DEST"
```

## Pitfalls

**Keep the `.gz` files compressed:**
Downstream readers (`read.delim(gzfile(...))`, `Matrix::readMM(gzfile(...))`, Seurat's `Read10X()`) read gzip directly — compressed is the expected on-disk state.

**Dense-table deposits:**
Some samples deposit a single dense table (`.txt.gz`/`.csv.gz`) or extra files such as `aggregation.csv`. The step-3 loop downloads whatever exists; treat the features/barcodes/matrix trio as the marker for direct 10x usability — with the trio present, proceed to the Seurat workflow; with a dense table or extras, adapt the loader or fetch from the GSE series.

**Sequential, resumable transfers are the NCBI-friendly mode:**
The FTP mirror serves many concurrent clients well; keep the download loop sequential and rely on resume (`-C -`) to recover interrupted transfers.

**Flat-name consumers:**
This layout (`./<GSMID>/` subfolders) coexists with skills that expect the six files flat in the data dir — e.g. `seurat-load-qc`'s script opens `/data/<GSM>_<label>_*.gz` paths directly. Bridge the gap non-destructively:
```bash
cd "$DATA_DIR" && ln -sf GSM*/GSM*_*.gz .
```
See `seurat-load-qc` Pitfalls for the full worked example.

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
- `FEAT`/`BC`/`MTX` all non-empty → the 3-file 10x layout is present; with a dense table or extras instead, see Pitfalls for the 10x-usability check.

### Identifying conditions / sample metadata (when the file name suffix is not enough)

Resolve the sample's series metadata through **NCBI E-utilities** — structured XML, machine-readable, two calls:

```bash
GSM=GSM5821748

# 1. Resolve the GSM to its gds UID ([ACCN] filter, URL-encoded).
#    Name the lookup variable GID (bash reserves `UID` as a readonly builtin).
GID=$(curl -s "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?db=gds&term=${GSM}%5BACCN%5D" \
  | grep -oE "<Id>[0-9]+</Id>" | grep -oE "[0-9]+" | head -1)

# 2. Fetch series + per-sample metadata in one file
curl -s "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esummary.fcgi?db=gds&id=$GID" -o esum.xml
```

Series-level signal — items named `title`/`summary` (study-design prose):

```bash
grep -oE '<Item Name="(title|summary)"[^>]*>[^<]*' esum.xml | sed 's/<[^>]*>//g'
```

Per-sample titles — the strongest, machine-readable signal for declaring conditions
in a downstream `seurat-load-qc` manifest (one `GSM = title` pair per sample). Each
sample's Accession and Title travel in separate `<Item>` elements, so keep records
at `</Item>` granularity for the pairing to capture every sample:

```bash
awk 'BEGIN{RS="</Item>"}
     /<Item Name="Accession"[^>]*>GSM[0-9]+/ { acc=$0; sub(/.*>GSM/,"GSM",acc) }
     acc!="" && /<Item Name="Title"/ { t=$0; sub(/.*>/,"",t); print acc" = "t; acc="" }' esum.xml
```

Validated example — GSE193807 (nuclear-accident patient, skin scRNA-seq):

```
GSM5821749 = IR
GSM5821748 = non-irradiated control
```

(study design: control = belly skin, IR = irradiated right-hand skin)

Cross-check the per-sample titles against the file-name suffixes (`_con_`, `_IR_`,
...) before declaring conditions in a manifest; when they disagree, the per-sample
title wins.

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
