# actions_1_to_3.R
# Companion script for the hermes skill "seurat-load-qc" (generic manifest runner)
# Actions 1-3: Load 10x -> CreateSeuratObject -> Cell-level QC -> save .rds
#
# Samples are declared in /data/samples.tsv (TAB-separated):
#   condition<TAB>features<TAB>barcodes<TAB>matrix
# One /data/<condition>_qc.rds is written per manifest row.
#
# Study parameters are confirmed with the user before running and passed as
# environment variables (docker run -e NAME=value); unset variables fall back
# to the defaults below. Effective values are echoed as the PARAMS log line.
#
# Run inside dnalinux/scrnaseq_r_workflow with the data dir mounted at /data:
#   docker run --rm -v "$DATA_DIR":/data \
#     dnalinux/scrnaseq_r_workflow:latest Rscript /data/actions_1_to_3.R

library(Seurat)
library(Matrix)

msg <- function(...) message(sprintf(...))

# ---- Study parameters (defaults; overridable via docker run -e NAME=value) --
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

MIN_CELLS    <- get_num("MIN_CELLS",    3)      # import: genes in >= N cells
MIN_FEAT     <- get_num("MIN_FEAT",     500)    # import: cells with >= N genes
QC_MIN_GENES <- get_num("QC_MIN_GENES", 500)    # QC: nFeature_RNA lower (excl.)
QC_MAX_GENES <- get_num("QC_MAX_GENES", 5000)   # QC: nFeature_RNA upper
QC_MAX_MITO  <- get_num("QC_MAX_MITO",  10)     # QC: percent.mito must be < N
MT_PATTERN   <- get_str("MT_PATTERN", "^MT-")   # human; mouse: "^mt-"

msg("PARAMS    min.cells=%g min.features=%g qc_genes=(%g,%g) max_mito=%g mt_pattern=%s",
    MIN_CELLS, MIN_FEAT, QC_MIN_GENES, QC_MAX_GENES, QC_MAX_MITO, MT_PATTERN)

# ---- Action 1: loader -------------------------------------------------------
read_10x_tsv_mtx <- function(features, barcodes, mtx) {
  genes <- read.delim(gzfile(features), header = FALSE, stringsAsFactors = FALSE)
  cells <- read.delim(gzfile(barcodes), header = FALSE, stringsAsFactors = FALSE)
  mat   <- Matrix::readMM(gzfile(mtx))
  namecol <- if (ncol(genes) >= 2) 2 else 1     # 10x features.tsv: id, name, type
  rownames(mat) <- make.unique(genes[[namecol]])
  colnames(mat) <- make.unique(cells[[1]])
  mat
}

# ---- Actions 2+3 for one sample ---------------------------------------------
process_sample <- function(feat_f, bc_f, mtx_f, condition, out_rds) {
  # Action 1 — load processed 10x matrix
  mat <- read_10x_tsv_mtx(file.path(DATA_DIR, feat_f),
                          file.path(DATA_DIR, bc_f),
                          file.path(DATA_DIR, mtx_f))
  msg("LOAD     %s: %d genes x %d cells", condition, nrow(mat), ncol(mat))

  # Action 2 — create Seurat object + import-level filters + condition metadata
  obj <- CreateSeuratObject(mat, project = condition,
                            min.cells = MIN_CELLS, min.features = MIN_FEAT)
  obj$condition <- condition
  rm(mat)
  msg("IMPORT   %s: %d genes x %d cells (after min.cells=%g, min.features=%g)",
      condition, nrow(obj), ncol(obj), MIN_CELLS, MIN_FEAT)

  # Action 3 — cell-level QC
  obj[["percent.mito"]] <- PercentageFeatureSet(obj, pattern = MT_PATTERN)
  n_before <- ncol(obj)
  obj <- subset(obj, subset = nFeature_RNA > QC_MIN_GENES &
                              nFeature_RNA < QC_MAX_GENES &
                              percent.mito < QC_MAX_MITO)
  # validation (workflow contract: QC columns exist; cells survive)
  stopifnot(all(c("percent.mito", "nFeature_RNA") %in% colnames(obj@meta.data)),
            ncol(obj) > 0,
            max(obj$percent.mito) < QC_MAX_MITO)
  msg("QC       %s: %d -> %d cells kept; percent.mito range [%.2f, %.2f]",
      condition, n_before, ncol(obj), min(obj$percent.mito), max(obj$percent.mito))

  saveRDS(obj, file.path(DATA_DIR, out_rds))
  msg("SAVED    %s -> %s", condition, out_rds)
  invisible(obj)
}

# ---- Read manifest; run every declared sample --------------------------------
samples <- read.delim(MANIFEST, stringsAsFactors = FALSE)
stopifnot(all(c("condition", "features", "barcodes", "matrix") %in% colnames(samples)),
          nrow(samples) >= 1)

for (i in seq_len(nrow(samples))) {
  s <- samples[i, ]
  for (p in c(s$features, s$barcodes, s$matrix))
    if (!file.exists(file.path(DATA_DIR, p))) stop("Missing input file: ", p)
  process_sample(s$features, s$barcodes, s$matrix,
                 s$condition, paste0(s$condition, "_qc.rds"))
}

writeLines(capture.output(sessionInfo()), file.path(DATA_DIR, "sessionInfo_qc.txt"))
msg("DONE: actions 1-3 complete for %d sample(s)", nrow(samples))
