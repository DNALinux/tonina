# action_10_annotate.R
# Companion script for the hermes skill "seurat-annotate"
# Action 10: AddModuleScore per marker set -> assign cluster labels by max score
#
# Input : /data/integrated_clustered.rds
#         /data/markers.tsv (columns: set, gene)
#
# Outputs: integrated_annotated.rds, celltype_evidence.csv, tsne_celltypes.png,
#          sessionInfo_annotate.txt
#
# Parameters via environment variables (docker run -e NAME=value):
#   MIN_MARKERS (2), NBIN (24), SCORE_SEED (1)
#
#   docker run --rm -v "$DATA_DIR":/data \
#     dnalinux/scrnaseq_r_workflow:latest Rscript /data/action_10_annotate.R

library(Seurat)
library(Matrix)

msg <- function(...) message(sprintf(...))

# ---- Parameters (defaults; overridable via docker run -e NAME=value) -------
DATA_DIR <- "/data"
RDS_IN   <- file.path(DATA_DIR, "integrated_clustered.rds")
MANIFEST <- file.path(DATA_DIR, "markers.tsv")

get_num <- function(name, default) {
  v <- suppressWarnings(as.numeric(Sys.getenv(name, "")))
  if (is.na(v)) default else v
}

MIN_MARKERS <- get_num("MIN_MARKERS", 2)
NBIN        <- get_num("NBIN",        24)
SCORE_SEED  <- get_num("SCORE_SEED",  1)

msg("PARAMS    min_markers=%g nbin=%g seed=%g", MIN_MARKERS, NBIN, SCORE_SEED)

# ---- Load clustered object and marker manifest --------------------------------
if (!file.exists(RDS_IN))
  stop("Missing input file: ", RDS_IN,
       " (run seurat-cluster first)")
integrated <- readRDS(RDS_IN)
stopifnot(inherits(integrated, "Seurat"),
          "seurat_clusters" %in% colnames(integrated@meta.data))

if (!file.exists(MANIFEST))
  stop("Missing input file: ", MANIFEST)

mk <- read.delim(MANIFEST, stringsAsFactors = FALSE)
stopifnot(all(c("set", "gene") %in% colnames(mk)),
          nrow(mk) >= 1)

# Ensure RNA assay is joinable (Seurat v5 safety after integration)
if (packageVersion("SeuratObject") >= "5.0.0")
  integrated[["RNA"]] <- JoinLayers(integrated[["RNA"]])

# ---- Score each marker set that has enough present genes -----------------------
marker_sets <- split(mk$gene, mk$set)
score_map   <- character(0)   # maps clean set name -> AddModuleScore column name
kept_sets   <- character(0)

for (set in names(marker_sets)) {
  genes <- marker_sets[[set]]
  avail <- genes[genes %in% rownames(integrated)]
  msg("SETS     %s: %d of %d genes present", set, length(avail), length(genes))
  if (length(avail) < MIN_MARKERS) {
    msg("SKIP     %s: only %d available (need >= %d)", set, length(avail), MIN_MARKERS)
    next
  }
  colname <- paste0(set, "1")               # what AddModuleScore actually creates
  integrated <- AddModuleScore(integrated,
                               features = list(avail),
                               name = set,
                               assay = "RNA",
                               nbin = NBIN,
                               seed = SCORE_SEED)
  score_map[[set]] <- colname
  kept_sets        <- c(kept_sets, set)
}

if (length(kept_sets) == 0)
  stop("No marker sets passed the min_markers threshold; check markers.tsv and reference genome")

msg("SCORE    %d module scores added (clean names, no trailing 1)", length(kept_sets))

# ---- Assign labels by highest mean score per cluster -------------------------
avg <- sapply(kept_sets, function(s) {
  colname <- score_map[[s]]
  tapply(integrated@meta.data[[colname]], integrated$seurat_clusters, mean)
})
rownames(avg) <- levels(integrated$seurat_clusters)

max_per_cluster <- apply(avg, 1, max, na.rm = TRUE)
cluster_label   <- colnames(avg)[max.col(avg)]
names(cluster_label) <- rownames(avg)

# Flag weak/conflicting evidence: any cluster whose best score is <= 0
# (below the module-score background baseline) is not meaningfully supported.
evidence_threshold <- 0.0

integrated$celltype_11 <- factor(unname(cluster_label[as.character(integrated$seurat_clusters)]),
                                   levels = kept_sets)

# Build evidence table
evidence <- as.data.frame(avg)
evidence$assigned <- cluster_label
evidence$evidence_score <- max_per_cluster
evidence$flag <- ifelse(max_per_cluster <= evidence_threshold, "WEAK", "OK")

write.csv(evidence, file.path(DATA_DIR, "celltype_evidence.csv"))
n_weak <- sum(evidence$flag == "WEAK")
msg("LABEL    cluster labels assigned by max mean score; %d of %d clusters flagged WEAK",
    n_weak, nrow(evidence))

# ---- Visualize labels ---------------------------------------------------------
library(ggplot2)
p <- DimPlot(integrated, reduction = "tsne", group.by = "celltype_11", label = TRUE)
ggsave(file.path(DATA_DIR, "tsne_celltypes.png"), plot = p, width = 8, height = 6, dpi = 150)

saveRDS(integrated, file.path(DATA_DIR, "integrated_annotated.rds"))
msg("SAVED    integrated_annotated.rds, celltype_evidence.csv, tsne_celltypes.png")

writeLines(capture.output(sessionInfo()),
           file.path(DATA_DIR, "sessionInfo_annotate.txt"))
msg("DONE: action 10 complete")
