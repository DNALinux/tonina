# action_5_hvg_report.R
# Companion script for the hermes skill "seurat-hvg-report"
# Reports the Action 5 (VST) HVG selection per condition:
#   - <condition>_hvgs.csv          ranked selected genes with VST stats
#   - <condition>_vfplot.png        mean-variance scatter (selected in red)
#   - <condition>_vfplot_labeled.png  same, top N genes labeled
#   - hvg_membership.csv            gene x condition membership matrix
#
# Inputs : /data/<condition>_norm.rds for each row of /data/samples.tsv
#          (created by seurat-normalize-hvg; manifest column: condition)
#
# Parameters via environment variables (docker run -e NAME=value):
#   TOP_N_LABELS (default 10), PLOT_DPI (default 150)
#
#   docker run --rm -v "$DATA_DIR":/data \
#     dnalinux/scrnaseq_r_workflow:latest Rscript /data/action_5_hvg_report.R

library(Seurat)
library(Matrix)
library(ggplot2)   # required for ggsave(); Seurat does NOT attach it

msg <- function(...) message(sprintf(...))

# ---- Parameters --------------------------------------------------------------
DATA_DIR <- "/data"
MANIFEST <- file.path(DATA_DIR, "samples.tsv")

get_num <- function(name, default) {
  v <- suppressWarnings(as.numeric(Sys.getenv(name, "")))
  if (is.na(v)) default else v
}
TOP_N <- get_num("TOP_N_LABELS", 10)
DPI   <- get_num("PLOT_DPI",     150)
msg("PARAMS    top_n_labels=%g plot_dpi=%g", TOP_N, DPI)

# ---- Read manifest ------------------------------------------------------------
samples <- read.delim(MANIFEST, stringsAsFactors = FALSE)
stopifnot("condition" %in% colnames(samples), nrow(samples) >= 1)
conditions <- samples$condition

# ---- Per-condition report ------------------------------------------------------
hvg_sets <- list()

for (cond in conditions) {
  in_rds <- file.path(DATA_DIR, paste0(cond, "_norm.rds"))
  if (!file.exists(in_rds))
    stop("Missing input file: ", in_rds, " (run seurat-normalize-hvg first)")

  obj <- readRDS(in_rds)
  stopifnot(inherits(obj, "Seurat"))

  hvgs <- VariableFeatures(obj)
  stopifnot(length(hvgs) > 0)
  hvg_sets[[cond]] <- hvgs

  # ranked table of the selected genes with VST statistics
  info <- HVFInfo(obj)
  info <- info[rownames(info) %in% hvgs, , drop = FALSE]
  info <- info[order(-info$variance.standardized), , drop = FALSE]
  tab  <- data.frame(gene = rownames(info), rank = seq_len(nrow(info)),
                     info, row.names = NULL, check.names = FALSE)
  write.csv(tab, file.path(DATA_DIR, paste0(cond, "_hvgs.csv")), row.names = FALSE)
  msg("HVG      %s: %d variable genes -> %s_hvgs.csv", cond, length(hvgs), cond)

  # plots (saved: container has no graphics device)
  p <- VariableFeaturePlot(obj)
  ggsave(file.path(DATA_DIR, paste0(cond, "_vfplot.png")),
         plot = p, width = 7, height = 5, dpi = DPI)
  p2 <- LabelPoints(plot = p, points = head(hvgs, TOP_N), repel = TRUE)
  ggsave(file.path(DATA_DIR, paste0(cond, "_vfplot_labeled.png")),
         plot = p2, width = 8, height = 6, dpi = DPI)
  msg("PLOT     %s: %s_vfplot.png, %s_vfplot_labeled.png (top %d labeled)",
      cond, cond, cond, TOP_N)

  rm(obj)
}

# ---- Cross-condition membership -----------------------------------------------
all_hvgs   <- unique(unlist(hvg_sets))
membership <- data.frame(gene = all_hvgs, stringsAsFactors = FALSE)
for (cond in conditions) membership[[cond]] <- all_hvgs %in% hvg_sets[[cond]]
write.csv(membership, file.path(DATA_DIR, "hvg_membership.csv"), row.names = FALSE)

if (length(conditions) > 1) {
  n_sets   <- rowSums(membership[, conditions, drop = FALSE])
  in_all   <- n_sets == length(conditions)
  per_cond <- sapply(conditions, function(cn) sum(membership[[cn]] & n_sets == 1))
  msg("OVERLAP  shared in all %d conditions: %d genes; unique: %s",
      length(conditions), sum(in_all),
      paste(sprintf("%s=%d", conditions, per_cond), collapse = ", "))
}

writeLines(capture.output(sessionInfo()),
           file.path(DATA_DIR, "sessionInfo_hvg_report.txt"))
msg("DONE: hvg report complete for %d sample(s)", length(conditions))
