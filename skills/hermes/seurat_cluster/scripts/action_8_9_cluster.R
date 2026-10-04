# action_8_9_cluster.R
# Companion script for the hermes skill "seurat-cluster"
# Actions 8-9: ScaleData + RunPCA + FindNeighbors on the integrated assay,
#              resolution scan toward TARGET_CLUSTERS, FindClusters, RunTSNE
#
# Input : /data/integrated.rds (created by seurat-integrate-rpca, RUN_INTEGRATION=yes)
# Outputs: integrated_clustered.rds, integrated_elbow.png, tsne_clusters.png,
#          tsne_condition.png, resolution_scan.csv, cluster_sizes.csv,
#          sessionInfo_cluster.txt
#
# Parameters via environment variables (docker run -e NAME=value):
#   NPCS (50), CLUSTER_DIMS ("1:35"), TSNE_DIMS ("1:35"),
#   RES_GRID ("0.2,0.3,0.4,0.6,0.8,1.0"), TARGET_CLUSTERS (13), TSNE_PERPLEXITY (30)
#
#   docker run --rm --memory="16g" -v "$DATA_DIR":/data \
#     dnalinux/scrnaseq_r_workflow:latest Rscript /data/action_8_9_cluster.R

library(Seurat)
library(Matrix)
library(ggplot2)   # required for ggsave(): Seurat does NOT attach it

msg <- function(...) message(sprintf(...))

# ---- Parameters (defaults; overridable via docker run -e NAME=value) -------
DATA_DIR <- "/data"
RDS_IN   <- file.path(DATA_DIR, "integrated.rds")

get_num <- function(name, default) {
  v <- suppressWarnings(as.numeric(Sys.getenv(name, "")))
  if (is.na(v)) default else v
}
get_str <- function(name, default) {
  v <- Sys.getenv(name, "")
  if (v == "") default else v
}
parse_dims <- function(s) {           # "1:35" -> 1:35
  d <- as.numeric(strsplit(s, ":", fixed = TRUE)[[1]])
  stopifnot(length(d) == 2, !any(is.na(d)), d[2] > d[1])
  d[1]:d[2]
}

NPCS            <- get_num("NPCS",            50)
CLUSTER_DIMS    <- parse_dims(get_str("CLUSTER_DIMS", "1:35"))
TSNE_DIMS       <- parse_dims(get_str("TSNE_DIMS",    "1:35"))
RES_GRID        <- as.numeric(strsplit(get_str("RES_GRID", "0.2,0.3,0.4,0.6,0.8,1.0"),
                                       ",", fixed = TRUE)[[1]])
TARGET_CLUSTERS <- get_num("TARGET_CLUSTERS", 13)   # study-specific target
TSNE_PERPLEXITY <- get_num("TSNE_PERPLEXITY", 30)

msg("PARAMS    npcs=%g cluster_dims=%s tsne_dims=%s res_grid=%s target_clusters=%g tsne_perplexity=%g",
    NPCS, paste(range(CLUSTER_DIMS), collapse = ":"),
    paste(range(TSNE_DIMS), collapse = ":"),
    paste(RES_GRID, collapse = ","), TARGET_CLUSTERS, TSNE_PERPLEXITY)

# ---- Load integrated object ---------------------------------------------------
if (!file.exists(RDS_IN))
  stop("Missing input file: ", RDS_IN,
       " (run seurat-integrate-rpca with RUN_INTEGRATION=yes first)")
integrated <- readRDS(RDS_IN)
stopifnot(inherits(integrated, "Seurat"),
          "integrated" %in% SeuratObject::Assays(integrated))

# ---- Action 8: latent space + neighbor graph ----------------------------------
DefaultAssay(integrated) <- "integrated"
integrated <- ScaleData(integrated)
integrated <- RunPCA(integrated, npcs = NPCS)
ggsave(file.path(DATA_DIR, "integrated_elbow.png"),
       plot = ElbowPlot(integrated, ndims = NPCS), width = 7, height = 5, dpi = 150)
msg("REDUCE   integrated assay scaled; %d PCs computed -> integrated_elbow.png", NPCS)

integrated <- FindNeighbors(integrated, dims = CLUSTER_DIMS)
msg("NEIGHBORS SNN graph built over dims %s", paste(range(CLUSTER_DIMS), collapse = ":"))

# ---- Action 9a: resolution scan toward the target cluster count ---------------
scan <- data.frame(resolution = RES_GRID,
                   n_clusters = NA_integer_)
for (i in seq_along(RES_GRID)) {
  integrated <- FindClusters(integrated, resolution = RES_GRID[i], verbose = FALSE)
  scan$n_clusters[i] <- length(levels(Idents(integrated)))
  msg("SCAN     resolution %g -> %d clusters", RES_GRID[i], scan$n_clusters[i])
}
write.csv(scan, file.path(DATA_DIR, "resolution_scan.csv"), row.names = FALSE)

best_idx <- which.min(abs(scan$n_clusters - TARGET_CLUSTERS))
best_res <- scan$resolution[best_idx]
if (abs(scan$n_clusters[best_idx] - TARGET_CLUSTERS) > 2)
  msg("WARN     closest grid point yields %d clusters, target was %d (study-specific; retune if intended)",
      scan$n_clusters[best_idx], TARGET_CLUSTERS)
msg("CHOOSE   resolution %g -> %d clusters (closest to target %d)",
    best_res, scan$n_clusters[best_idx], TARGET_CLUSTERS)

# ---- Action 9b: final clustering + t-SNE --------------------------------------
integrated <- FindClusters(integrated, resolution = best_res, verbose = FALSE)
integrated <- RunTSNE(integrated, dims = TSNE_DIMS, perplexity = TSNE_PERPLEXITY)
msg("TSNE     embedding computed (dims %s)", paste(range(TSNE_DIMS), collapse = ":"))

write.csv(as.data.frame(table(cluster = Idents(integrated))),
          file.path(DATA_DIR, "cluster_sizes.csv"), row.names = FALSE)
ggsave(file.path(DATA_DIR, "tsne_clusters.png"),
       plot = DimPlot(integrated, reduction = "tsne", label = TRUE),
       width = 8, height = 6, dpi = 150)
ggsave(file.path(DATA_DIR, "tsne_condition.png"),
       plot = DimPlot(integrated, reduction = "tsne", group.by = "condition"),
       width = 8, height = 6, dpi = 150)

saveRDS(integrated, file.path(DATA_DIR, "integrated_clustered.rds"))
msg("SAVED    integrated_clustered.rds (%d cells, %d clusters)",
    ncol(integrated), length(levels(integrated$seurat_clusters)))

writeLines(capture.output(sessionInfo()),
           file.path(DATA_DIR, "sessionInfo_cluster.txt"))
msg("DONE: actions 8-9 complete")
