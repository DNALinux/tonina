---
name: seurat-hvg-report
description: Extract, tabulate and visualize the highly variable genes selected in Action 5 (VST), per condition, with cross-condition membership comparison; consumes the .rds outputs of seurat-normalize-hvg
version: 1.0.0
platforms: [linux]
metadata:
  hermes:
    tags: [bioinformatics, scrna-seq, seurat, r, hvg, reporting, visualization, docker]
    category: bioinformatics
    requires_toolsets: [terminal]
---

# Seurat HVG Report (Action 5 verification & reporting)

Reads each `<condition>_norm.rds` (which already carries a VST-selected variable-feature set), and produces: a ranked HVG table with VST statistics per condition, VariableFeaturePlot PNGs (plain + labeled), and a cross-condition membership matrix showing which genes are shared vs condition-unique. Purely a reporting/verification step — it does not recompute anything.

Typical preceding step: `seurat-normalize-hvg` (computes the HVG sets in Action 5).

Companion code: `scripts/action_5_hvg_report.R` (shipped with this skill).

## When to Use

**Input requirements:**
- `<condition>_norm.rds` objects in the data directory, created by `seurat-normalize-hvg` (each must have a non-empty variable-feature set)
- `samples.tsv` manifest still present (defines the conditions)
- Docker with the `dnalinux/scrnaseq_r_workflow:latest` image available
- A host data directory to mount as `/data`

**Appropriate scenarios:**
- Inspecting which genes were selected as highly variable, with their VST scores
- Producing the mean-variance plots for review or publication figures
- Comparing HVG sets between conditions (shared vs condition-unique genes) before integration feature selection

**Not suitable for:**
- Computing the HVG sets from scratch → that is `seurat-normalize-hvg`'s job
- Integration-level feature reconciliation → `SelectIntegrationFeatures` is the next action downstream

## Procedure

### 1. Point at the data directory

```bash
DATA_DIR=/home/sb/projects/rnaseq   # host path; mounted as /data
ls "$DATA_DIR"/*_norm.rds
```

Every manifest row must have a matching `<condition>_norm.rds`.

### 2. Stage the analysis script

```bash
cp scripts/action_5_hvg_report.R "$DATA_DIR/"
```

(Paths are relative to the skill directory; adjust if invoking from elsewhere.)

### 3. Confirm the report parameters with the user (required gate)

Present the report knobs, then ask e.g.: *"Keep the report defaults, or change any?"* Do not proceed to step 4 until the user answers.

| Parameter | Env var | Default | What it controls |
|-----------|---------|---------|------------------|
| Labeled top genes | `TOP_N_LABELS` | 10 | How many of the most variable genes get name labels on the labeled plot. |
| Plot resolution | `PLOT_DPI` | 150 | DPI of the saved PNGs. |

### 4. Run the report

```bash
docker run --rm -v "$DATA_DIR":/data \
  dnalinux/scrnaseq_r_workflow:latest Rscript /data/action_5_hvg_report.R
```

With a user-confirmed override (example: label the top 15 genes):

```bash
docker run --rm -e TOP_N_LABELS=15 \
  -v "$DATA_DIR":/data \
  dnalinux/scrnaseq_r_workflow:latest Rscript /data/action_5_hvg_report.R
```

Expected log (counts below are the GSM5821748/GSM5821749 reference pair; yours differ by dataset):

```
PARAMS    top_n_labels=10 plot_dpi=150
HVG      Control: 1100 variable genes -> Control_hvgs.csv
PLOT     Control: Control_vfplot.png, Control_vfplot_labeled.png (top 10 labeled)
HVG      Irradiated: 1100 variable genes -> Irradiated_hvgs.csv
PLOT     Irradiated: Irradiated_vfplot.png, ... (top 10 labeled)
OVERLAP  shared in all 2 conditions: N genes; unique: Control=k, Irradiated=m
DONE: hvg report complete for 2 sample(s)
```

## Pitfalls

**`Missing input file: *_norm.rds`:**
This skill consumes the `seurat-normalize-hvg` outputs. Run the chain in order and keep the same manifest throughout.

**`could not find function "ggsave"`:**
`ggsave` belongs to ggplot2, which Seurat uses internally but does not attach to the user's session. The companion script already loads it; if you reproduce the steps interactively, run `library(ggplot2)` first.

**Ran fine but no plots appear on screen:**
Expected. Container runs have no graphics device; plots exist only as the PNG files written into the data directory. View them on the host.

**`variance.standardized` column missing:**
The report table assumes the VST method. If the HVG sets were produced with a different `HVG_METHOD` upstream, rename the ranking column in the script accordingly.

## Verification

After the run:

```bash
ls -lh "$DATA_DIR"/*_hvgs.csv "$DATA_DIR"/*_vfplot*.png "$DATA_DIR"/hvg_membership.csv
```

Row counts must match the number of selected HVGs per condition (1,100 by default + 1 header line):

```bash
awk 'NR>1 {print $1}' "$DATA_DIR/samples.tsv" | while read -r C; do
  L=$(wc -l < "$DATA_DIR/${C}_hvgs.csv")
  echo "$C: $L lines (expect NFEATURES + 1 header)"
done
```

Content check inside the container:

```bash
docker run --rm -v "$DATA_DIR":/data \
  dnalinux/scrnaseq_r_workflow:latest Rscript -e '
    library(Seurat)
    files <- list.files("/data", pattern = "_norm\\.rds$", full.names = TRUE)
    stopifnot(length(files) >= 1)
    for (f in files) {
      o <- readRDS(f)
      n <- length(VariableFeatures(o))
      stopifnot(n > 0)
      csv <- file.path("/data", paste0(o$condition[1], "_hvgs.csv"))
      tab <- read.csv(csv)
      stopifnot(nrow(tab) == n)
      cat("PASS:", basename(f), "|", n, "HVGs | table rows match\n")
    }'
```

Pass criteria: one `PASS` per condition; every CSV row count equals that sample's HVG count.

## Key Parameters

| Parameter | Value | Notes |
|-----------|-------|-------|
| Image | `dnalinux/scrnaseq_r_workflow:latest` | amd64 + arm64 |
| Mount | `-v $DATA_DIR:/data` | host dir holds inputs, manifest, script, outputs |
| Inputs | `<condition>_norm.rds`, `samples.tsv` | produced by `seurat-normalize-hvg` |
| Invocation | `Rscript /data/action_5_hvg_report.R` | runs headless |
| Script source | `scripts/action_5_hvg_report.R` | ships with the skill; copy to the data dir |
| Study-parameter gate | step 3 | agent presents defaults (TOP_N_LABELS=10, PLOT_DPI=150), user confirms or overrides |
| Outputs | `<condition>_hvgs.csv`, `<condition>_vfplot.png`, `<condition>_vfplot_labeled.png`, `hvg_membership.csv` | Action 5 report artifacts |

## Citation

Hao Y, et al. Integrated analysis of multimodal single-cell data. *Cell* 2021;184(13):3573-3587. doi:10.1016/j.cell.2021.04.048

Stuart T, et al. Comprehensive Integration of Single-Cell Data. *Cell* 2019;177(7):1888-1902. doi:10.1016/j.cell.2019.05.031
