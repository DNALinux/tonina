---
name: seurat-cluster
description: Build the latent space and neighbor graph on the integrated object, then cluster (resolution scan toward a target cluster count) and compute t-SNE (scRNA-seq workflow Actions 8-9); consumes integrated.rds from seurat-integrate-rpca
version: 1.0.0
platforms: [linux]
metadata:
  hermes:
    tags: [bioinformatics, scrna-seq, seurat, r, clustering, tsne, docker]
    category: bioinformatics
    requires_toolsets: [terminal]
---

# Seurat Latent Space + Clustering + t-SNE (Actions 8-9)

On the integrated object: scales the integrated assay, computes PCA, builds the nearest-neighbor graph, scans clustering resolutions toward a user-confirmed target cluster count, and computes t-SNE. Produces the clustered object plus review plots (elbow, t-SNE by cluster and by condition) that gate the annotation step.

Typical preceding step: `seurat-integrate-rpca` with `RUN_INTEGRATION=yes`.

Companion code: `scripts/action_8_9_cluster.R` (shipped with this skill).

## When to Use

**Input requirements:**
- `integrated.rds` in the data directory, created by `seurat-integrate-rpca` with `RUN_INTEGRATION=yes`
- Docker with the `dnalinux/scrnaseq_r_workflow:latest` image available
- Enough container headroom for PCA/graph/t-SNE (16 GB recommended for ~10k cells)

**Appropriate scenarios:**
- Joint clustering of all conditions on the shared integrated embedding
- Resolution tuning with an explicit target cluster count (study structure)

**Not suitable for:**
- The `RUN_INTEGRATION=no` branch → that path produces per-sample `_prepped.rds`, which this skill does not consume
- Cell-type labeling → annotation (Action 10) is the next skill, gated on the cluster review here

## Procedure

### 1. Point at the data directory

```bash
DATA_DIR=/home/sb/projects/rnaseq   # host path; mounted as /data
ls -lh "$DATA_DIR"/integrated.rds
```

### 2. Stage the analysis script

```bash
cp scripts/action_8_9_cluster.R "$DATA_DIR/"
```

(Paths are relative to the skill directory; adjust if invoking from elsewhere.)

### 3. Confirm the clustering parameters with the user (required gate)

Present the parameters with defaults and meaning, and ask the user to keep or change them. **Do not proceed to step 4 until the user has explicitly answered.**

Present this table, then ask e.g.: *"These are the clustering parameters that will be applied. Keep all defaults, or change any?"*

| Parameter | Env var | Default | What it controls |
|-----------|---------|---------|------------------|
| PCA components | `NPCS` | `50` | PCs computed on the integrated assay. |
| Neighbor-graph dims | `CLUSTER_DIMS` | `1:35` | PCs used for the shared-neighbor graph → clustering. Elbow evidence from the integration step supports both the default and a tighter `1:10`-`1:15`; the default matches the reference workflow. |
| Resolution grid | `RES_GRID` | `0.2,0.3,0.4,0.6,0.8,1.0` | Louvain resolutions scanned; higher = more clusters. |
| Target cluster count | `TARGET_CLUSTERS` | `13` | The resolution closest to this count is chosen. **Study-specific** — reproduces the reference study's structure; on other datasets set from biological expectations or omit tuning. |
| t-SNE dims | `TSNE_DIMS` | `1:35` | PCs used for the 2D embedding. |
| t-SNE perplexity | `TSNE_PERPLEXITY` | `30` | Neighborhood balance for t-SNE (keep within ~10-30). |

### 4. Run Actions 8-9

```bash
docker run --rm --memory="16g" -v "$DATA_DIR":/data \
  dnalinux/scrnaseq_r_workflow:latest Rscript /data/action_8_9_cluster.R
```

With overrides (example: tighter dims window justified by the elbows):

```bash
docker run --rm --memory="16g" -e CLUSTER_DIMS=1:15 -e TSNE_DIMS=1:15 \
  -v "$DATA_DIR":/data \
  dnalinux/scrnaseq_r_workflow:latest Rscript /data/action_8_9_cluster.R
```

Expected log shape (cluster counts are dataset-dependent):

```
PARAMS    npcs=50 cluster_dims=1:35 tsne_dims=1:35 res_grid=0.2,0.3,0.4,0.6,0.8,1.0 target_clusters=13 tsne_perplexity=30
REDUCE   integrated assay scaled; 50 PCs computed -> integrated_elbow.png
NEIGHBORS SNN graph built over dims 1:35
SCAN     resolution 0.2 -> n clusters
SCAN     resolution 0.3 -> n clusters
...
CHOOSE   resolution r -> n clusters (closest to target 13)
TSNE     embedding computed (dims 1:35)
SAVED    integrated_clustered.rds (9562 cells, n clusters)
DONE: actions 8-9 complete
```

### 5. Review the clustering before annotation

Open on the host and check both:

- `tsne_clusters.png` — clusters well separated, no shard-like fragments
- `tsne_condition.png` — clusters shared across conditions rather than split by sample (integration quality)

This review gates the annotation skill. If clusters look biologically implausible or unstable, rerun step 4 with a different `RES_GRID`/`CLUSTER_DIMS` rather than annotating a bad partition.

## Pitfalls

**`Missing input file: /data/integrated.rds`:**
Run `seurat-integrate-rpca` first with `RUN_INTEGRATION=yes`; the no-integration branch intentionally produces only per-sample `_prepped.rds` files, which this skill does not consume.

**No resolution reaches the target count:**
`TARGET_CLUSTERS` is a study-specific value (≈13 reproduced the reference paper's structure). If the scan's counts all sit far from the target, the fix is to retune the target or grid for the dataset at hand — the PDF itself says not to generalize the 13.

**Clustering runs very slowly or the container is killed:**
`FindClusters` over several resolutions plus t-SNE on ~10k cells is moderately heavy; keep `--memory="16g"` and expect minutes, not seconds.

**Override did not take effect:**
The `PARAMS` line at the top of the log is the audit trail. `-e` flags belong before the image name in `docker run`; anything after the image name goes to `Rscript` as arguments.

## Verification

After the run:

```bash
ls -lh "$DATA_DIR"/integrated_clustered.rds "$DATA_DIR"/integrated_elbow.png \
       "$DATA_DIR"/tsne_clusters.png "$DATA_DIR"/tsne_condition.png \
       "$DATA_DIR"/resolution_scan.csv "$DATA_DIR"/cluster_sizes.csv
```

Content check inside the container (self-contained one-shot):

```bash
docker run --rm -v "$DATA_DIR":/data \
  dnalinux/scrnaseq_r_workflow:latest Rscript -e '
    library(Seurat)
    o <- readRDS("/data/integrated_clustered.rds")
    reds <- SeuratObject::Reductions(o)
    n_cl <- length(levels(o$seurat_clusters))
    n_meta <- sum(grepl("integrated_snn_res", colnames(o@meta.data)))
    stopifnot(inherits(o, "Seurat"),
              all(c("pca", "tsne") %in% reds),
              n_cl > 1, n_meta >= 1,
              "integrated_pca_snn" %in% names(o@graphs))
    cat("PASS: integrated_clustered.rds | reductions:", paste(reds, collapse = ","),
        "| resolutions scanned:", n_meta, "| clusters:", n_cl, "| cells:", ncol(o), "\n")'
  ```

Pass criteria: `integrated_clustered.rds` holds both `pca` and `tsne` reductions, the SNN graph, the scanned-resolution metadata, and a final `seurat_clusters` factor matching the cluster count logged at `CHOOSE`.

## Key Parameters

| Parameter | Value | Notes |
|-----------|-------|-------|
| Image | `dnalinux/scrnaseq_r_workflow:latest` | amd64 + arm64 |
| Mount | `-v $DATA_DIR:/data` | host dir holds inputs, script, outputs |
| Input | `integrated.rds` | produced by `seurat-integrate-rpca` (RUN_INTEGRATION=yes) |
| Invocation | `Rscript /data/action_8_9_cluster.R` | runs headless; `--memory="16g"` recommended |
| Script source | `scripts/action_8_9_cluster.R` | ships with the skill; copy to the data dir |
| Study-parameter gate | step 3 | defaults: NPCS=50, CLUSTER_DIMS=1:35, RES_GRID=0.2..1.0, TARGET_CLUSTERS=13 (study-specific), TSNE_DIMS=1:35, TSNE_PERPLEXITY=30 |
| Overrides | `-e NAME=value` | unset vars fall back to defaults; effective set echoed as `PARAMS` |
| Outputs | `integrated_clustered.rds`, `integrated_elbow.png`, `tsne_clusters.png`, `tsne_condition.png`, `resolution_scan.csv`, `cluster_sizes.csv`, `sessionInfo_cluster.txt` | state after Action 9; plots gate annotation |

## Citation

Stuart T, et al. Comprehensive Integration of Single-Cell Data. *Cell* 2019;177(7):1888-1902. doi:10.1016/j.cell.2019.05.031

Hao Y, et al. Integrated analysis of multimodal single-cell data. *Cell* 2021;184(13):3573-3587. doi:10.1016/j.cell.2021.04.048

van der Maaten L, Hinton G. Visualizing Data using t-SNE. *JMLR* 2008;9:2579-2605.
