# actions_1_to_3.R
# Companion script for the hermes skill "seurat-load-qc"
# Actions 1-3: Load 10x -> CreateSeuratObject -> Cell-level QC -> save .rds
#
# Runs inside dnalinux/scrnaseq_r_workflow (R + Seurat + Matrix present),
# with the host data directory mounted at /data:
#   docker run --rm -v "$DATA_DIR":/data \
#     dnalinux/scrnaseq_r_workflow:latest Rscript /data/actions_1_to_3.R

library(Seurat)
library(Matrix)

msg <- function(...) message(sprintf(...))

# ---- Study parameters (configurable; see workflow doc S04) ----------------
DATA_DIR     <- "/data"
MIN_CELLS    <- 3        # import filter: genes must appear in >= 3 cells
MIN_FEAT     <- 500      # import filter: cells must have >= 500 genes
QC_MIN_GENES <- 500      # cell QC: nFeature_RNA lower bound (exclusive)
QC_MAX_GENES <- 5000     # cell QC: nFeature_RNA upper bound
QC_MAX_MITO  <- 10       # cell QC: mitochondrial % must be < this
MT_PATTERN   <- "^MT-"   # human mitochondrial genes (mouse: "^mt-")

# ---- Action 1: loader ------------------------------------------------------
read_10x_tsv_mtx <- function(features, barcodes, mtx) {
  genes <- read.delim(gzfile(features), header = FALSE, stringsAsFactors = FALSE)
  cells <- read.delim(gzfile(barcodes), header = FALSE, stringsAsFactors = FALSE)
  mat   <- Matrix::readMM(gzfile(mtx))
  namecol <- if (ncol(genes) >= 2) 2 else 1     # 10x features.tsv: id, name, type
  rownames(mat) <- make.unique(genes[[namecol]])
  colnames(mat) <- make.unique(cells[[1]])
  mat
}

# ---- Actions 2+3 per sample ------------------------------------------------
process_sample <- function(feat_f, bc_f, mtx_f, project, condition, out_rds) {
  # Action 1 — load processed 10x matrix
  mat <- read_10x_tsv_mtx(file.path(DATA_DIR, feat_f),
                          file.path(DATA_DIR, bc_f),
                          file.path(DATA_DIR, mtx_f))
  msg("LOAD     %s: %d genes x %d cells", condition, nrow(mat), ncol(mat))

  # Action 2 — create Seurat object + import-level filters + condition metadata
  obj <- CreateSeuratObject(mat, project = project,
                            min.cells = MIN_CELLS, min.features = MIN_FEAT)
  obj$condition <- condition
  rm(mat)
  msg("IMPORT   %s: %d genes x %d cells (after min.cells=%d, min.features=%d)",
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

# ---- Run both conditions ---------------------------------------------------
con <- process_sample("GSM5821748_con_features.tsv.gz",
                      "GSM5821748_con_barcodes.tsv.gz",
                      "GSM5821748_con_matrix.mtx.gz",
                      "Control",    "Control",    "con_qc.rds")
ir  <- process_sample("GSM5821749_IR_features.tsv.gz",
                      "GSM5821749_IR_barcodes.tsv.gz",
                      "GSM5821749_IR_matrix.mtx.gz",
                      "Irradiated", "Irradiated", "ir_qc.rds")

writeLines(capture.output(sessionInfo()), file.path(DATA_DIR, "sessionInfo_qc.txt"))
msg("DONE: actions 1-3 complete")
