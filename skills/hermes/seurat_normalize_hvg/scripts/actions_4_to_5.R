# actions_4_to_5.R
# Companion script for the hermes skill "seurat-normalize-hvg"
# Actions 4-5: NormalizeData (per sample) -> FindVariableFeatures (VST, per sample)
#
# Inputs: /data/<condition>_qc.rds for every row of /data/samples.tsv
#         (TAB-separated manifest with column "condition"; created during
#         seurat-load-qc).
# Outputs: /data/<condition>_norm.rds per condition + /data/sessionInfo_norm.txt
#
# Parameters via environment variables (docker run -e NAME=value);
# unset variables fall back to the defaults below. Effective values are
# echoed as the PARAMS log line.
#
#   docker run --rm -v "$DATA_DIR":/data \
#     dnalinux/scrnaseq_r_workflow:latest Rscript /data/actions_4_to_5.R

library(Seurat)
library(Matrix)

msg <- function(...) message(sprintf(...))

# ---- Parameters (defaults; overridable via docker run -e NAME=value) -------
DATA_DIR <- "/data"
MANIFEST <- file.path(DATA_DIR, "samples.tsv")

get_num <- function(name, default) {
  v <- suppressWarnings(as.numeric(Sys.getenv(name, "")))
  if (is.na(v)) default else v
}
get_str <- function(name, default) {
  v <- Sys.getenv(name, "")
  if (v == "") default else v
}

NORM_METHOD  <- get_str("NORM_METHOD",  "LogNormalize")  # Action 4 method
SCALE_FACTOR <- get_num("SCALE_FACTOR", 10000)           # Action 4 scale.factor
HVG_METHOD   <- get_str("HVG_METHOD",   "vst")           # Action 5 selection.method
NFEATURES    <- get_num("NFEATURES",    1100)            # Action 5 nfeatures/sample

msg("PARAMS    norm_method=%s scale_factor=%g hvg_method=%s nfeatures=%g",
    NORM_METHOD, SCALE_FACTOR, HVG_METHOD, NFEATURES)

# ---- Actions 4+5 for one sample ---------------------------------------------
process_sample <- function(condition) {
  in_rds  <- file.path(DATA_DIR, paste0(condition, "_qc.rds"))
  out_rds <- file.path(DATA_DIR, paste0(condition, "_norm.rds"))
  if (!file.exists(in_rds)) stop("Missing input file: ", in_rds,
                                 " (run seurat-load-qc first)")

  obj <- readRDS(in_rds)
  stopifnot(inherits(obj, "Seurat"))

  # Action 4 — normalize library size (adds/overwrites the "data" layer)
  obj <- NormalizeData(obj, normalization.method = NORM_METHOD,
                       scale.factor = SCALE_FACTOR)
  stopifnot("data" %in% SeuratObject::Layers(obj[["RNA"]]))
  msg("NORM     %s: data layer created (log-normalized)", condition)

  # Action 5 — highly variable genes, per sample
  obj <- FindVariableFeatures(obj, selection.method = HVG_METHOD,
                              nfeatures = NFEATURES)
  n_hvg <- length(VariableFeatures(obj))
  stopifnot(n_hvg > 0)
  msg("HVG      %s: %d variable features selected", condition, n_hvg)

  saveRDS(obj, out_rds)
  msg("SAVED    %s -> %s", condition, basename(out_rds))
  invisible(obj)
}

# ---- Read manifest; run every declared condition ------------------------------
samples <- read.delim(MANIFEST, stringsAsFactors = FALSE)
stopifnot("condition" %in% colnames(samples), nrow(samples) >= 1)

for (cond in samples$condition) process_sample(cond)

writeLines(capture.output(sessionInfo()),
           file.path(DATA_DIR, "sessionInfo_norm.txt"))
msg("DONE: actions 4-5 complete for %d sample(s)", nrow(samples))
