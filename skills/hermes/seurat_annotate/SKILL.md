---
name: seurat-annotate
description: Marker-driven cell-type annotation for clustered scRNA-seq data using AddModuleScore (scRNA-seq workflow Action 10); consumes integrated_clustered.rds from seurat-cluster
version: 1.0.1
platforms: [linux]
metadata:
  hermes:
    tags: [bioinformatics, scrna-seq, seurat, r, annotation, markers, docker]
    category: bioinformatics
    requires_toolsets: [terminal]
---

# Seurat Cell-Type Annotation (Action 10)

Scores known marker programs per cluster and assigns candidate cell-type labels to the integrated object. Marker sets are declared in a file, not hardcoded, so the skill stays reusable across tissues. Weak or conflicting labels are flagged for review rather than forced.

Typical preceding step: `seurat-cluster` (produces `integrated_clustered.rds`).

Companion code: `scripts/action_10_annotate.R` (shipped with this skill).

## When to Use

**Input requirements:**
- `integrated_clustered.rds` in the data directory, created by `seurat-cluster`
- `markers.tsv` in the data directory declaring the marker sets (columns: `set`, `gene`)
- Docker with the `dnalinux/scrnaseq_r_workflow:latest` image available

**Appropriate scenarios:**
- Labeling cell clusters using known marker panels
- Reproducing a marker-driven annotation from a reference study

**Not suitable for:**
- Marker-free annotation → use automated methods (SingleR, scANVI) separately
- Downstream DE or co-expression work → those use the unintegrated RNA assay; this skill only adds labels

## Procedure

### 1. Point at the data directory

```bash
DATA_DIR=/home/sb/projects/rnaseq   # host path; mounted as /data
ls -lh "$DATA_DIR"/integrated_clustered.rds
```

### 2. Create the markers manifest

Write `markers.tsv` (TAB-separated) with exactly two columns:

- `set` — cell-type / marker-program name (e.g., `Keratinocytes`)
- `gene` — one gene symbol per row

Example for the radiation skin study. This snippet uses `printf '%b\n'` so `set\tgene` is interpreted as a real TAB; after writing, verify with `awk -F'\t' 'NF!=2 {print "BAD:", $0}'`:

```bash
{
  printf 'set\tgene\n'
  printf '%b\n' \
    'Keratinocytes\tKRT14' \
    'Keratinocytes\tKRT5' \
    'Keratinocytes\tKRT1' \
    'Keratinocytes\tKRT10' \
    'Keratinocytes\tKRT6A' \
    'Fibroblasts\tCOL1A1' \
    'Fibroblasts\tCOL1A2' \
    'Fibroblasts\tDCN' \
    'Fibroblasts\tLUM' \
    'Fibroblasts\tSFRP2' \
    'Fibroblasts\tCTHRC1' \
    'Endothelial_cells\tPECAM1' \
    'Endothelial_cells\tVWF' \
    'Endothelial_cells\tKDR' \
    'Endothelial_cells\tCDH5' \
    'T_cells\tCD3D' \
    'T_cells\tCD3E' \
    'T_cells\tTRAC' \
    'T_cells\tIL7R' \
    'NK_cells\tNKG7' \
    'NK_cells\tGNLY' \
    'NK_cells\tKLRD1' \
    'NK_cells\tPRF1'
} > "$DATA_DIR/markers.tsv"

awk -F'\t' 'NF!=2 {print "BAD line:", $0; exit 1}' "$DATA_DIR/markers.tsv"
```

If the awk check fails, the file does not contain real TABs — recreate it with the snippet above (not by typing \t literally). Any other correctly-tabbed format is also valid.

Any number of marker sets and any gene count per set are valid.

### 3. Stage the analysis script

```bash
cp scripts/action_10_annotate.R "$DATA_DIR/"
```

(Paths are relative to the skill directory; adjust if invoking from elsewhere.)

### 4. Confirm the annotation parameters with the user (required gate)

Present the parameter table, then ask e.g.: *"These are the annotation parameters. Keep all defaults, or change any?"*

| Parameter | Env var | Default | What it controls |
|-----------|---------|---------|------------------|
| Min available markers per set | `MIN_MARKERS` | `2` | A set is skipped if fewer than this many genes are present in the object. The workflow requires at least 2 available markers before a module score is calculated. |
| Number of bins for control genes | `NBIN` | `24` | Passed to `AddModuleScore()`: how many expression-level bins of control genes are averaged for background subtraction. |
| Random seed | `SCORE_SEED` | `1` | Reproducibility seed for `AddModuleScore()`. |

The agent should also show the user the marker sets loaded from `markers.tsv` and how many genes per set are present in the object before running.

- User confirms → run step 5.
- User changes values → pass overrides as `-e ENV_VAR=value` in step 5.

### 5. Run Action 10

```bash
docker run --rm -v "$DATA_DIR":/data \
  dnalinux/scrnaseq_r_workflow:latest Rscript /data/action_10_annotate.R
```

Expected log shape:

```
PARAMS    min_markers=2 nbin=24 seed=1
SETS      Keratinocytes: 5 of 5 genes present
SETS      Fibroblasts: 6 of 6 genes present
SETS      Endothelial_cells: 4 of 4 genes present
SETS      T_cells: 3 of 4 genes present
SETS      NK_cells: 4 of 4 genes present
SCORE    5 module scores added (clean names, no trailing 1)
LABEL    cluster labels assigned by max mean score
SAVED    integrated_annotated.rds, celltype_evidence.csv, tsne_celltypes.png
DONE: action 10 complete
```

## Pitfalls

**`Missing input file: integrated_clustered.rds`:**
Run `seurat-cluster` first. This skill only consumes the clustered object.

**`No marker sets passed the min_markers threshold`:**
At least one set must have ≥ `MIN_MARKERS` genes present in the object. Check that the marker symbols match the reference genome used by the 10x dataset (e.g., human GRCh38 vs mouse mm10; gene-name casing).

**Most labels are flagged WEAK:**
This means the marker panel is too coarse for the dataset's true heterogeneity — likely untyped subtypes are being forced to the nearest label. Add more marker sets rather than trusting the weak labels.

## Verification

After the run:

```bash
ls -lh "$DATA_DIR"/integrated_annotated.rds \
       "$DATA_DIR"/celltype_evidence.csv \
       "$DATA_DIR"/tsne_celltypes.png
```

Content check inside the container (self-contained one-shot):

```bash
docker run --rm -v "$DATA_DIR":/data \
  dnalinux/scrnaseq_r_workflow:latest Rscript -e '
    library(Seurat)
    o <- readRDS("/data/integrated_annotated.rds")
    ev <- read.csv("/data/celltype_evidence.csv", row.names = 1)
    stopifnot(inherits(o, "Seurat"),
              "celltype_11" %in% colnames(o@meta.data),
              is.factor(o$celltype_11),
              nrow(ev) == length(levels(o$seurat_clusters)),
              nlevels(o$celltype_11) >= 1)
    cat("PASS:", nlevels(o$celltype_11), "labels |", ncol(o), "cells |",
        nrow(ev), "cluster rows\n")'
```

Pass criteria: `integrated_annotated.rds` contains a factor `celltype_11`, the evidence table has one row per cluster, and at least one label was assigned.

## Key Parameters

| Parameter | Value | Notes |
|-----------|-------|-------|
| Image | `dnalinux/scrnaseq_r_workflow:latest` | amd64 + arm64 |
| Mount | `-v $DATA_DIR:/data` | host dir holds inputs, marker manifest, script, outputs |
| Input | `integrated_clustered.rds` | produced by `seurat-cluster` |
| Marker manifest | `/data/markers.tsv` | TSV: `set` (program name) and `gene` (one gene per row) |
| Invocation | `Rscript /data/action_10_annotate.R` | runs headless |
| Script source | `scripts/action_10_annotate.R` | ships with the skill; copy to the data dir |
| Study-parameter gate | step 4 | defaults: MIN_MARKERS=2, NBIN=24, SCORE_SEED=1; marker sets are reviewed by gene availability |
| Overrides | `-e NAME=value` | unset vars fall back to defaults; effective set echoed as `PARAMS` |
| Outputs | `integrated_annotated.rds`, `celltype_evidence.csv`, `tsne_celltypes.png`, `sessionInfo_annotate.txt` | state after Action 10 |

## Citation

Tirosh I, et al. Dissecting the multicellular ecosystem of metastatic melanoma by single-cell RNA-seq. *Science* 2016;352(6282):189-196. doi:10.1126/science.aad0501

Hao Y, et al. Integrated analysis of multimodal single-cell data. *Cell* 2021;184(13):3573-3587. doi:10.1016/j.cell.2021.04.048
