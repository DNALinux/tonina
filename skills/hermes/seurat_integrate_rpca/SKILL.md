---
name: seurat-integrate-rpca
description: Select shared integration features, run per-sample PCA, and perform RPCA anchor integration (scRNA-seq workflow Actions 6-7); consumes the .rds outputs of seurat-normalize-hvg; integration itself is a user-confirmed decision
version: 1.0.0
platforms: [linux]
metadata:
  hermes:
    tags: [bioinformatics, scrna-seq, seurat, r, integration, rpca, docker]
    category: bioinformatics
    requires_toolsets: [terminal]
---

# Seurat Integration Features + RPCA Anchors (Actions 6-7)

Selects shared integration features across the normalized per-sample objects, runs scaled per-sample PCA on them (saving elbow plots for review), and — when the user confirms — performs RPCA anchor finding and integration into one combined object. 

Typical preceding step: `seurat-normalize-hvg` (produces the `<condition>_norm.rds` inputs).

Companion code: `scripts/action_6_7_integrate.R` (shipped with this skill).

## When to Use

**Input requirements:**
- `<condition>_norm.rds` objects in the data directory, created by `seurat-normalize-hvg` (each must have HVGs selected)
- `samples.tsv` manifest still present (defines the conditions)

**Appropriate scenarios:**
- Preparing a shared embedding across conditions (joint clustering / visualization)
- Deliberately skipping integration and keeping the per-sample PCA representations (the reference workflow documents integration as an analytical choice, not a rule)

**Not suitable for:**
- A single sample → integration needs at least two datasets; per-sample PCA alone suffices
- Differential expression input → DE later runs on the unintegrated RNA assay; the integrated assay is for clustering/visualization

## Procedure

### 1. Point at the data directory

```bash
DATA_DIR=/home/sb/projects/rnaseq   # host path; mounted as /data
ls "$DATA_DIR"/*_norm.rds
```

Every manifest row must have a matching `<condition>_norm.rds`.

### 2. Stage the analysis script

```bash
cp scripts/action_6_7_integrate.R "$DATA_DIR/"
```

(Paths are relative to the skill directory; adjust if invoking from elsewhere.)

### 3. Confirm the integration parameters with the user (required gate)

Present the parameters, including the yes/no integration decision itself, and ask the user to keep or change them. **Do not proceed to step 4 until the user has explicitly answered.**

Present this table, then ask e.g.: *"Integration setup below — including whether to run integration at all. Keep all defaults, or change any?"*

| Parameter | Env var | Default | What it controls |
|-----------|---------|---------|------------------|
| Run integration | `RUN_INTEGRATION` | `yes` | `yes` performs RPCA anchor integration; `no` stops after per-sample PCA and saves prepped objects (preserves the unintegrated-data path). |
| Integration features | `NFEATURES_INT` | `2000` | Shared variable genes selected across all samples for scaling/PCA/anchoring. |
| Per-sample PCs | `NPCS` | `50` | Principal components computed per sample. |
| RPCA dims | `RPCA_DIMS` | `1:30` | Which PCs anchor finding and integration use (first:last). |
| `k.anchor` | `K_ANCHOR` | `5` | Anchors found per neighborhood; smaller is more permissive. 5 is the study value for this two-sample pair. |

- User confirms defaults → run step 4 unchanged.
- User changes values or declines integration → pass overrides as `-e ENV_VAR=value` in step 4.

### 4. Run Actions 6-7

```bash
docker run --rm --memory="16g" -v "$DATA_DIR":/data \
  dnalinux/scrnaseq_r_workflow:latest Rscript /data/action_6_7_integrate.R
```

With overrides (example: skip integration):

```bash
docker run --rm --memory="16g" -e RUN_INTEGRATION=no \
  -v "$DATA_DIR":/data \
  dnalinux/scrnaseq_r_workflow:latest Rscript /data/action_6_7_integrate.R
```

Expected log (reference pair GSM5821748/GSM5821749, ~9,562 QC'd cells total):

```
PARAMS    nfeatures_int=2000 npcs=50 rpca_dims=1:30 k.anchor=5 run_integration=yes
LOADNORM Control: Control_norm.rds loaded
LOADNORM Irradiated: Irradiated_norm.rds loaded
FEATURES 2000 integration features selected -> integration_features.txt
PCA      Control: 50 PCs computed -> Control_elbow.png
PCA      Irradiated: 50 PCs computed -> Irradiated_elbow.png
INTEGRATE anchors found, integrating over dims 1:30
SAVED    integrated.rds (assay 'integrated'; 9562 cells)
DONE: actions 6-7 complete
```

Before interpreting integration results, open the elbow PNGs on the host — this is the last cheap inspection point before heavy compute. A sane curve shows variance dropping steeply over the first ~10-20 PCs.

## Pitfalls

**`Warning: ... features requested have zero variance; running reduction without them`:**
Informational. A shared integration feature can be flat inside one QC'd sample; PCA drops it for that run only.

**Container killed / out of memory during anchors or integration:**
RPCA on multi-thousand-cell samples is the heaviest step in the chain. Raise the docker memory limit (`--memory="16g"` or more) and rerun; everything before `INTEGRATE` is cheap and re-runs quickly.

**`RUN_INTEGRATION=no` leaves no `integrated.rds`:**
By design — the deliverables then are the per-sample `<condition>_prepped.rds` (scaled PCA states) plus the feature list and elbow plots. Downstream clustering skills require the `integrated.rds` (run=yes) path.

**Override did not take effect:**
First log line is the audit trail (`PARAMS`). `-e` flags must come before the image name in `docker run`; flags after the image are passed to `Rscript` as arguments and never reach the parameter readers.

**`Missing input file: *_norm.rds`:**
Run `seurat-normalize-hvg` first, with the same manifest.

## Verification

After the run:

```bash
ls -lh "$DATA_DIR"/integration_features.txt "$DATA_DIR"/*_elbow.png
ls -lh "$DATA_DIR"/*_prepped.rds          # always present
ls -lh "$DATA_DIR"/integrated.rds         # only when RUN_INTEGRATION=yes
```

Content check inside the container (self-contained one-shot, integration path):

```bash
docker run --rm -v "$DATA_DIR":/data \
  dnalinux/scrnaseq_r_workflow:latest Rscript -e '
    library(Seurat)
    feats <- readLines("/data/integration_features.txt")
    stopifnot(length(feats) > 0)
    o <- readRDS("/data/integrated.rds")
    stopifnot(inherits(o, "Seurat"),
              "integrated" %in% SeuratObject::Assays(o),
              ncol(o) > 0)
    cat("PASS: integrated.rds |", length(feats), "features |",
        ncol(o), "cells | assays:", paste(SeuratObject::Assays(o), collapse = ","), "\n")'
```

Pass criteria: features file non-empty; one elbow PNG and one `_prepped.rds` per condition; when integration ran, `integrated.rds` exists with an `integrated` assay and a cell count equal to the sum of QC'd cells.

## Key Parameters

| Parameter | Value | Notes |
|-----------|-------|-------|
| Image | `dnalinux/scrnaseq_r_workflow:latest` | amd64 + arm64 |
| Mount | `-v $DATA_DIR:/data` | host dir holds inputs, manifest, script, outputs |
| Inputs | `<condition>_norm.rds`, `samples.tsv` | produced by `seurat-normalize-hvg` |
| Invocation | `Rscript /data/action_6_7_integrate.R` | runs headless; `--memory="16g"` recommended |
| Script source | `scripts/action_6_7_integrate.R` | ships with the skill; copy to the data dir |
| Study-parameter gate | step 3 | defaults: NFEATURES_INT=2000, NPCS=50, RPCA_DIMS=1:30, K_ANCHOR=5, RUN_INTEGRATION=yes |
| Overrides | `-e NAME=value` | unset vars fall back to defaults; effective set echoed as `PARAMS` |
| Outputs | `integration_features.txt`, `<condition>_elbow.png`, `<condition>_prepped.rds`, `integrated.rds` (if run=yes), `sessionInfo_integrate.txt` | state after Action 7 |

## Citation

Stuart T, et al. Comprehensive Integration of Single-Cell Data. *Cell* 2019;177(7):1888-1902. doi:10.1016/j.cell.2019.05.031

Hao Y, et al. Integrated analysis of multimodal single-cell data. *Cell* 2021;184(13):3573-3587. doi:10.1016/j.cell.2021.04.048
