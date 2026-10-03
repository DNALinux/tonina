---
name: seurat-load-qc
description: Load 10x count matrices into Seurat, apply cell-level QC, and save per-condition QC'd .rds objects
version: 1.0.0
platforms: [linux]
metadata:
  hermes:
    tags: [bioinformatics, scrna-seq, seurat, r, 10x, qc, docker]
    category: bioinformatics
    requires_toolsets: [terminal]
---

# Seurat Load + Cell-Level QC (Actions 1-3)

Loads the processed 10x trio (features/barcodes/matrix) for two condition samples into Seurat objects, applies import filters and cell-level QC (gene-count band + mitochondrial %), and writes one QC'd `.rds` per condition. Everything runs inside the `dnalinux/scrnaseq_r_workflow` container; the host only holds data and results.

Typical preceding step: `geo-gsm-download` (fetches the input files).

Companion code: `scripts/actions_1_to_3.R` (shipped with this skill).

## When to Use

**Input requirements:**
- The 10x trio for each condition present in the data directory (sample-prefixed GEO names are fine — the loader takes explicit paths, no `Read10X()` rename needed)
- Docker with the `dnalinux/scrnaseq_r_workflow:latest` image available (`docker pull` it or build from `scrnaseq_r_workflow/1.0.0/Dockerfile`)
- A host data directory that will be mounted as `/data` in the container

**Appropriate scenarios:**
- Reproducible, headless execution of scRNA-seq upstream steps (load → object creation → QC)
- Condition-comparison studies where each condition is one 10x library

**Not suitable for:**
- Raw FASTQ input → upstream quantification (Cell Ranger) must run first
- Downstream steps (normalization, integration, clustering) → this skill covers Actions 1-3 only and stops before `NormalizeData()`

## Procedure

### 1. Point at your data directory

Must contain the six input files; will receive the analysis script and the two `.rds` outputs.

```bash
DATA_DIR=/home/sb/projects/rnaseq   # host path; mounted as /data
ls "$DATA_DIR"
```

### 2. Stage the analysis script

Copy the skill's companion script into the data directory so the container mount exposes it as `/data/actions_1_to_3.R`:

```bash
cp scripts/actions_1_to_3.R "$DATA_DIR/"
```

(Paths are relative to the skill directory; adjust if invoking from elsewhere.)

### 3. Run Actions 1-3

```bash
docker run --rm -v "$DATA_DIR":/data \
  dnalinux/scrnaseq_r_workflow:latest Rscript /data/actions_1_to_3.R
```

The container runs the script and exits when it finishes.

Expected log (cell counts shown are the validated reference values for the GSM5821748/GSM5821749 pair):

```
LOAD     Control: 36601 genes x 8647 cells
IMPORT   Control: ... genes x ... cells (after min.cells=3, min.features=500)
QC       Control: 8647 -> 4588 cells kept; percent.mito range [0.06, 10.00]
SAVED    Control -> con_qc.rds
LOAD     Irradiated: 36601 genes x 8355 cells
IMPORT   Irradiated: ...
QC       Irradiated: 8355 -> 4974 cells kept; percent.mito range [0.00, 9.99]
SAVED    Irradiated -> ir_qc.rds
DONE: actions 1-3 complete
```

## Pitfalls

**Missing QC line for one condition:**
The log must show exactly one `QC ... in -> kept` line per condition. If only one appears, one sample was measured but never subset — the pipeline half-ran.

**`percent.mito` all zero:**
The `^MT-` pattern matched no genes. Human GRCh38 references use `MT-`; mouse references use `^mt-`. Match the pattern case to the reference genome.

**`cannot open the connection` / empty `ls`:**
`$DATA_DIR` path or contents are wrong. Step 1's `ls` must show the six input files before step 3 runs.

## Verification

On the host, after the run:

```bash
ls -lh "$DATA_DIR"/*.rds          # expect con_qc.rds and ir_qc.rds
```

Inside the container, validate content (self-contained one-shot check):

```bash
docker run --rm -v "$DATA_DIR":/data \
  dnalinux/scrnaseq_r_workflow:latest Rscript -e '
    library(Seurat)
    for (f in c("/data/con_qc.rds", "/data/ir_qc.rds")) {
      o <- readRDS(f)
      stopifnot(inherits(o, "Seurat"),
                all(c("condition", "percent.mito") %in% colnames(o@meta.data)),
                max(o$percent.mito) < 10,
                ncol(o) > 0)
      cat("PASS:", f, "|", o$condition[1], "|",
          nrow(o), "genes x", ncol(o), "cells\n")
    }'
```

Pass criteria: both files print `PASS`, show `percent.mito < 10`, and `condition` reads Control / Irradiated respectively.

## Key Parameters

| Parameter | Value | Notes |
|-----------|-------|-------|
| Image | `dnalinux/scrnaseq_r_workflow:latest` | amd64 + arm64 |
| Mount | `-v $DATA_DIR:/data` | host dir holds inputs, script, outputs |
| Invocation | `Rscript /data/actions_1_to_3.R` | runs headless |
| Script source | `scripts/actions_1_to_3.R` | ships with the skill; copy to the data dir |
| `min.cells` / `min.features` | 3 / 500 | import filters (study parameters) |
| QC band | 500 < nFeature_RNA < 5000 | study parameters |
| `percent.mito` | `< 10`, pattern `^MT-` | human; `^mt-` for mouse |
| Outputs | `con_qc.rds`, `ir_qc.rds`, `sessionInfo_qc.txt` | state after Action 3 (pre-normalization) |

## Citation

Hao Y, et al. Integrated analysis of multimodal single-cell data. *Cell* 2021;184(13):3573-3587. doi:10.1016/j.cell.2021.04.048

Stuart T, et al. Comprehensive Integration of Single-Cell Data. *Cell* 2019;177(7):1888-1902. doi:10.1016/j.cell.2019.05.031
