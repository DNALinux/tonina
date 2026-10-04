---
name: seurat-normalize-hvg
description: Normalize each QC'd sample (LogNormalize) and select highly variable genes per sample (VST), scRNA-seq workflow Actions 4-5; consumes the .rds outputs of seurat-load-qc
version: 1.0.0
platforms: [linux]
metadata:
  hermes:
    tags: [bioinformatics, scrna-seq, seurat, r, normalization, hvg, docker]
    category: bioinformatics
    requires_toolsets: [terminal]
---

# Seurat Normalize + Variable Features (Actions 4-5)

For each condition produced by `seurat-load-qc`: normalizes library size per cell (LogNormalize, scale factor 10,000) into a new `data` layer, then identifies highly variable genes with the VST method. Writes one normalized, HVG-annotated `.rds` per condition.

Typical preceding step: `seurat-load-qc` (produces the `<condition>_qc.rds` inputs and the manifest).

Companion code: `scripts/actions_4_to_5.R` (shipped with this skill).

## When to Use

**Input requirements:**
- `<condition>_qc.rds` objects in the data directory (one per manifest row), created by `seurat-load-qc`
- `samples.tsv` manifest still present (defines which conditions to process)
- Docker with the `dnalinux/scrnaseq_r_workflow:latest` image available
- A host data directory to mount as `/data`

**Appropriate scenarios:**
- Headless execution of scRNA-seq Actions 4-5 between QC and integration
- Per-sample processing where each condition is normalized and HVG-selected independently

**Not suitable for:**
- Raw count matrices → run `seurat-load-qc` first
- Combined/integration feature selection → `SelectIntegrationFeatures` is a downstream step (Action 6) and deliberately needs these per-sample HVG lists as input

## Procedure

### 1. Point at the data directory

```bash
DATA_DIR=/home/sb/projects/rnaseq   # host path; mounted as /data
ls "$DATA_DIR"/*_qc.rds
```

Every manifest row must have a matching `<condition>_qc.rds`.

### 2. Stage the analysis script

```bash
cp scripts/actions_4_to_5.R "$DATA_DIR/"
```

(Paths are relative to the skill directory; adjust if invoking from elsewhere.)

### 3. Confirm the study parameters with the user (required gate)

Before running, present the parameters with defaults and meaning, and ask the user to keep or change them. **Do not proceed to step 4 until the user has explicitly answered.**

Present this table, then ask e.g.: *"These are the normalization and variable-feature parameters that will be applied. Keep all defaults, or change any?"*

| Parameter | Env var | Default | What it controls |
|-----------|---------|---------|------------------|
| Normalization method | `NORM_METHOD` | `LogNormalize` | Per-cell library-size normalization followed by `log1p(count / total × scale.factor)`. |
| Scale factor | `SCALE_FACTOR` | `10000` | Multiplier in the formula ("counts per 10,000"); a convention matching the reference study. |
| HVG selection method | `HVG_METHOD` | `vst` | Variance-stabilizing selection: models variance vs mean and keeps genes whose variance exceeds the technical trend. Runs on the normalized layer — that is why normalization comes first. |
| HVGs per sample | `NFEATURES` | `1100` | How many top variable genes to keep per sample. Study parameter; these per-sample lists feed `SelectIntegrationFeatures` downstream. |

- User confirms defaults → run step 4 unchanged.
- User changes values → pass each override as `-e ENV_VAR=value` in step 4.

### 4. Run Actions 4-5

```bash
docker run --rm -v "$DATA_DIR":/data \
  dnalinux/scrnaseq_r_workflow:latest Rscript /data/actions_4_to_5.R
```

With user-confirmed overrides (example: `NFEATURES=1500`):

```bash
docker run --rm -e NFEATURES=1500 \
  -v "$DATA_DIR":/data \
  dnalinux/scrnaseq_r_workflow:latest Rscript /data/actions_4_to_5.R
```

The container runs the script and exits when it finishes. The first log line echoes the effective parameters:

```
PARAMS    norm_method=LogNormalize scale_factor=10000 hvg_method=vst nfeatures=1100
NORM     Control: data layer created (log-normalized)
HVG      Control: 1100 variable features selected
SAVED    Control -> Control_norm.rds
NORM     Irradiated: data layer created (log-normalized)
HVG      Irradiated: 1100 variable features selected
SAVED    Irradiated -> Irradiated_norm.rds
DONE: actions 4-5 complete for 2 sample(s)
```

## Pitfalls

**`Missing input file: *_qc.rds`:**
The manifest references a condition whose QC object is absent — run `seurat-load-qc` first, and keep the same manifest for the whole chain.

**HVG step fails or behaves oddly on the input object:**
VST runs on the normalized `data` layer. These inputs come pre-QC'd but unnormalized *by design*; this script always normalizes first. Handing it an already-integrated object (with an `integrated` assay) instead of a per-sample QC object is the usual cause of confusing output.

**Override did not take effect:**
The log's first line is the audit trail — `PARAMS` shows exactly what was applied. `-e` flags must come before the image name in `docker run`; flags placed after the image name are passed to `Rscript` as arguments and do not reach the parameter readers.

**`nfeatures` larger than the gene set:**
If `NFEATURES` exceeds the number of genes with valid VST estimates, Seurat returns fewer HVGs than requested; the per-sample `HVG` log lines make this visible.

## Verification

After the run, one output per manifest row:

```bash
ls -lh "$DATA_DIR"/*_norm.rds
awk 'NR>1 {print $1}' "$DATA_DIR/samples.tsv" | while read -r C; do
  test -s "$DATA_DIR/${C}_norm.rds" && echo "found: ${C}_norm.rds"
done
```

Validate content inside the container (self-contained one-shot check):

```bash
docker run --rm -v "$DATA_DIR":/data \
  dnalinux/scrnaseq_r_workflow:latest Rscript -e '
    library(Seurat)
    files <- list.files("/data", pattern = "_norm\\.rds$", full.names = TRUE)
    stopifnot(length(files) >= 1)
    for (f in files) {
      o <- readRDS(f)
      n_hvg <- length(VariableFeatures(o))
      stopifnot(inherits(o, "Seurat"),
                "data" %in% SeuratObject::Layers(o[["RNA"]]),
                n_hvg > 0)
      cat("PASS:", basename(f), "|", o$condition[1], "|",
          n_hvg, "HVGs\n")
    }'
```

Pass criteria: one `PASS` line per manifest row, each confirming the `data` layer exists and HVGs were selected.

## Key Parameters

| Parameter | Value | Notes |
|-----------|-------|-------|
| Image | `dnalinux/scrnaseq_r_workflow:latest` | amd64 + arm64 |
| Mount | `-v $DATA_DIR:/data` | host dir holds inputs, manifest, script, outputs |
| Inputs | `<condition>_qc.rds`, `samples.tsv` | produced by `seurat-load-qc` |
| Invocation | `Rscript /data/actions_4_to_5.R` | runs headless |
| Script source | `scripts/actions_4_to_5.R` | ships with the skill; copy to the data dir |
| Study-parameter gate | step 3 | agent presents defaults, user confirms or overrides |
| Overrides | `-e NORM_METHOD=... -e SCALE_FACTOR=... -e HVG_METHOD=... -e NFEATURES=...` | unset vars fall back to defaults; effective set echoed as `PARAMS` |
| Outputs | `<condition>_norm.rds`, `sessionInfo_norm.txt` | state after Action 5 (normalized + HVGs, per sample) |

## Citation

Hao Y, et al. Integrated analysis of multimodal single-cell data. *Cell* 2021;184(13):3573-3587. doi:10.1016/j.cell.2021.04.048

Stuart T, et al. Comprehensive Integration of Single-Cell Data. *Cell* 2019;177(7):1888-1902. doi:10.1016/j.cell.2019.05.031
