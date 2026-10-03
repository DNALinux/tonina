---
name: seurat-load-qc
description: Load 10x count matrices into Seurat, apply cell-level QC, and save per-condition QC'd .rds objects (scRNA-seq workflow Actions 1-3); manifest-driven, any files and any conditions; study parameters are confirmed with the user before running
version: 1.2.0
platforms: [linux]
metadata:
  hermes:
    tags: [bioinformatics, scrna-seq, seurat, r, 10x, qc, docker]
    category: bioinformatics
    requires_toolsets: [terminal]
---

# Seurat Load + Cell-Level QC (Actions 1-3)

Loads the processed 10x trio (features/barcodes/matrix) for each sample declared in a manifest, creates one Seurat object per condition, applies import filters and cell-level QC (gene-count band + mitochondrial %), and writes one QC'd `.rds` per condition. Everything runs inside the `dnalinux/scrnaseq_r_workflow` container; the host only holds data, the manifest, and results.

Typical preceding step: `geo-gsm-download` (fetches the input files).

Companion code: `scripts/actions_1_to_3.R` (shipped with this skill).

## When to Use

**Input requirements:**
- One 10x trio (`*_features.tsv.gz`, `*_barcodes.tsv.gz`, `*_matrix.mtx.gz`) per condition, present in the data directory. Any file names work — they are declared in the manifest, not assumed.
- Docker with the `dnalinux/scrnaseq_r_workflow:latest` image available (`docker pull` it or build from `scrnaseq_r_workflow/1.0.0/Dockerfile`)
- A host data directory to mount as `/data`

**Appropriate scenarios:**
- Reproducible, headless execution of scRNA-seq upstream steps (load → object creation → QC)
- Condition-comparison studies, one 10x library per condition; any number of conditions

**Not suitable for:**
- Raw FASTQ input → upstream quantification (Cell Ranger) must run first
- Downstream steps (normalization, integration, clustering) → this skill covers Actions 1-3 only and stops before `NormalizeData()`

## Procedure

### 1. Point at the data directory

```bash
DATA_DIR=/home/sb/projects/rnaseq   # host path; mounted as /data
ls "$DATA_DIR"
```

All the 10x files listed in the manifest (next step) must appear in this listing.

### 2. Create the samples manifest

Write `samples.tsv` (TAB-separated) into the data directory. Columns are exactly: `condition`, `features`, `barcodes`, `matrix`. One row per condition; `condition` is free text — it becomes the Seurat project name, the per-cell condition metadata, and the output file name `<condition>_qc.rds`.

Generic shape:

```
condition	features	barcodes	matrix
YourConditionA	features_file_A.tsv.gz	barcodes_file_A.tsv.gz	matrix_file_A.mtx.gz
YourConditionB	features_file_B.tsv.gz	barcodes_file_B.tsv.gz	matrix_file_B.mtx.gz
```

Explicit-tab version (robust against editors mangling tabs), using the radiation study as the example:

```bash
{
  printf 'condition\tfeatures\tbarcodes\tmatrix\n'
  printf 'Control\t%s\t%s\t%s\n' \
    GSM5821748_con_features.tsv.gz GSM5821748_con_barcodes.tsv.gz GSM5821748_con_matrix.mtx.gz
  printf 'Irradiated\t%s\t%s\t%s\n' \
    GSM5821749_IR_features.tsv.gz GSM5821749_IR_barcodes.tsv.gz GSM5821749_IR_matrix.mtx.gz
} > "$DATA_DIR/samples.tsv"
```

Any number of rows is valid; labels like `Control`/`Irradiated` are just example values for the `condition` column.

### 3. Stage the analysis script

Copy the companion script into the data directory so the container mount exposes it as `/data/actions_1_to_3.R`:

```bash
cp scripts/actions_1_to_3.R "$DATA_DIR/"
```

(Paths are relative to the skill directory; adjust if invoking from elsewhere.)

### 4. Confirm the study parameters with the user (required gate)

Before running, present the parameters that will be applied, with defaults and meaning, and ask the user to keep or change them. **Do not proceed to step 5 until the user has explicitly answered.**

Present this table, then ask e.g.: *"These are the filter parameters that will be applied. Keep all defaults, or change any?"*

| Parameter | Env var | Default | What it controls |
|-----------|---------|---------|------------------|
| `min.cells` | `MIN_CELLS` | 3 | Import filter: a gene is kept only if detected in ≥ this many cells. Genes seen in 1-2 cells are usually ambient RNA / noise and carry no usable statistic. |
| `min.features` | `MIN_FEAT` | 500 | Import filter: a cell is kept only if ≥ this many genes are detected. Below this, a barcode is likely an empty droplet or a broken cell; healthy mammalian cells typically express ~1,000-3,000+ genes. |
| QC gene floor | `QC_MIN_GENES` | 500 | Cell QC: discard cells with nFeature_RNA ≤ this value (same floor as `min.features`, applied after import). |
| QC gene ceiling | `QC_MAX_GENES` | 5000 | Cell QC: discard cells above this nFeature_RNA (potential high-complexity / doublet-like events). |
| `percent.mito` cap | `QC_MAX_MITO` | 10 | Cell QC: discard cells whose mitochondrial fraction is ≥ this % (dying/broken-cell signature). |
| MT gene pattern | `MT_PATTERN` | `^MT-` | Regex selecting mitochondrial genes. Human GRCh38: `^MT-`; mouse: `^mt-`. |

These are **study parameters, not universal defaults** — on a new dataset they should be informed by its QC distributions (e.g., the valley in the nFeature_RNA violin plot).

- User confirms defaults → run step 5 unchanged.
- User changes values → pass each override as `-e ENV_VAR=value` in step 5.

### 5. Run Actions 1-3

```bash
docker run --rm -v "$DATA_DIR":/data \
  dnalinux/scrnaseq_r_workflow:latest Rscript /data/actions_1_to_3.R
```

With user-confirmed overrides (example: `MIN_CELLS=5`, `MIN_FEAT=400`):

```bash
docker run --rm -e MIN_CELLS=5 -e MIN_FEAT=400 \
  -v "$DATA_DIR":/data \
  dnalinux/scrnaseq_r_workflow:latest Rscript /data/actions_1_to_3.R
```

The container runs the script and exits when it finishes. The first log line echoes the effective parameters:

```
PARAMS    min.cells=5 min.features=400 qc_genes=(500,5000) max_mito=10 mt_pattern=^MT-
LOAD     Control: 36601 genes x 8647 cells
IMPORT   Control: ... (after min.cells=5, min.features=400)
QC       Control: 8647 -> 4588 cells kept; percent.mito range [0.06, 10.00]
SAVED    Control -> Control_qc.rds
LOAD     Irradiated: 36601 genes x 8355 cells
QC       Irradiated: 8355 -> 4974 cells kept; percent.mito range [0.00, 9.99]
SAVED    Irradiated -> Irradiated_qc.rds
DONE: actions 1-3 complete for 2 sample(s)
```

(Cell counts above are the validated reference values for the GSM5821748/GSM5821749 pair **at default parameters**; they change with overrides and differ by dataset.)

## Pitfalls

**Override did not take effect:**
The log's first line is the audit trail — `PARAMS` shows exactly what was applied. `-e` flags must come **before** the image name in `docker run`; anything after the image name is treated as arguments to `Rscript`, not as environment for the script's parameter readers.

**Manifest parse problems (`undefined columns selected`, wrong splits):**
The file must be TAB-separated with the exact header `condition TAB features TAB barcodes TAB matrix`. Use the `printf` form, not spaces.

**`percent.mito` all zero:**
The `MT_PATTERN` matched no genes. Human GRCh38 references use `^MT-`; mouse references use `^mt-`. Match the pattern (and its case) to the reference genome.

**`Error: Missing input file: ...`:**
A file named in the manifest is absent from the data directory. Compare manifest rows against step 1's `ls`; names must match exactly, including case and `.gz` suffix.

## Verification

After the run, every manifest row must have produced an output:

```bash
ls -lh "$DATA_DIR"/*_qc.rds
awk 'NR>1 {print $1}' "$DATA_DIR/samples.tsv" | while read -r C; do
  test -s "$DATA_DIR/${C}_qc.rds" && echo "found: ${C}_qc.rds"
done
```

Validate content inside the container (self-contained one-shot check):

```bash
docker run --rm -v "$DATA_DIR":/data \
  dnalinux/scrnaseq_r_workflow:latest Rscript -e '
    library(Seurat)
    files <- list.files("/data", pattern = "_qc\\.rds$", full.names = TRUE)
    stopifnot(length(files) >= 1)
    for (f in files) {
      o <- readRDS(f)
      stopifnot(inherits(o, "Seurat"),
                all(c("condition", "percent.mito") %in% colnames(o@meta.data)),
                max(o$percent.mito) < 10,
                ncol(o) > 0)
      cat("PASS:", basename(f), "|", o$condition[1], "|",
          nrow(o), "genes x", ncol(o), "cells\n")
    }'
```

Pass criteria: one `PASS` line per manifest row, each showing `percent.mito < 10` and a non-zero cell count.

## Key Parameters

| Parameter | Value | Notes |
|-----------|-------|-------|
| Image | `dnalinux/scrnaseq_r_workflow:latest` | amd64 + arm64 |
| Mount | `-v $DATA_DIR:/data` | host dir holds inputs, manifest, script, outputs |
| Manifest | `/data/samples.tsv` | TSV: `condition`, `features`, `barcodes`, `matrix`; one row per condition |
| Invocation | `Rscript /data/actions_1_to_3.R` | runs headless |
| Script source | `scripts/actions_1_to_3.R` | ships with the skill; copy to the data dir |
| Study-parameter gate | step 4 | agent presents defaults (3 / 500 / 500 / 5000 / 10 / `^MT-`), user confirms or overrides |
| Overrides | `-e MIN_CELLS=5 -e MIN_FEAT=400 ...` | docker env vars; unset vars fall back to script defaults; effective set echoed as the `PARAMS` log line |
| Outputs | `<condition>_qc.rds` per manifest row, `sessionInfo_qc.txt` | state after Action 3 (pre-normalization) |

## Citation

Hao Y, et al. Integrated analysis of multimodal single-cell data. *Cell* 2021;184(13):3573-3587. doi:10.1016/j.cell.2021.04.048

Stuart T, et al. Comprehensive Integration of Single-Cell Data. *Cell* 2019;177(7):1888-1902. doi:10.1016/j.cell.2019.05.031
