# action_6_7_integrate.R
# Companion script for the hermes skill "seurat-integrate-rpca"
# Actions 6-7: SelectIntegrationFeatures -> per-sample ScaleData/RunPCA
#              -> (user-confirmed) FindIntegrationAnchors + IntegrateData
#
# Inputs : /data/<condition>_norm.rds for each row of /data/samples.tsv
#          (created by seurat-normalize-hvg; manifest column: condition)
# Outputs: integration_features.txt, <condition>_elbow.png,
#          <condition>_prepped.rds, integrated.rds (when RUN_INTEGRATION=yes),
#          sessionInfo_integrate.txt
#
# Parameters via environment variables (docker run -e NAME=value):
#   NFEATURES_INT (2000), NPCS (50), RPCA_DIMS ("1:30"), K_ANCHOR (5),
#   RUN_INTEGRATION ("yes"/"no")
#
#   docker run --rm --memory="16g" -v "$DATA_DIR":/data \
#     dnalinux/scrnaseq_r_workflow:latest Rscript /data/action_6_7_integrate.R

library(Seurat)
library(Matrix)
library(ggplot2)   # required for ggsave(): Seurat does NOT attach it

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

NFEATURES_INT   <- get_num("NFEATURES_INT", 2000)
NPCS            <- get_num("NPCS",          50)
RPCA_DIMS_STR   <- get_str("RPCA_DIMS",     "1:30")
K_ANCHOR        <- get_num("K_ANCHOR",      5)
RUN_INTEGRATION <- tolower(get_str("RUN_INTEGRATION", "yes")) == "yes"

# parse "1:30" -> 1:30
d_range   <- as.numeric(strsplit(RPCA_DIMS_STR, ":", fixed = TRUE)[[1]])
stopifnot(length(d_range) == 2, !any(is.na(d_range)), d_range[2] > d_range[1])
RPCA_DIMS <- d_range[1]:d_range[2]

msg("PARAMS    nfeatures_int=%g npcs=%g rpca_dims=%s k.anchor=%g run_integration=%s",
    NFEATURES_INT, NPCS, RPCA_DIMS_STR, K_ANCHOR, RUN_INTEGRATION)

# ---- Load normalized per-sample objects --------------------------------------
samples    <- read.delim(MANIFEST, stringsAsFactors = FALSE)
stopifnot("condition" %in% colnames(samples), nrow(samples) >= 1)
conditions <- samples$condition

objs <- lapply(conditions, function(cond) {
  f <- file.path(DATA_DIR, paste0(cond, "_norm.rds"))
  if (!file.exists(f)) stop("Missing input file: ", f,
                            " (run seurat-normalize-hvg first)")
  obj <- readRDS(f)
  stopifnot(inherits(obj, "Seurat"), length(VariableFeatures(obj)) > 0)
  msg("LOADNORM %s: %s loaded", cond, basename(f))
  obj
})
names(objs) <- conditions

# ---- Action 6: shared features + per-sample scaled PCA -----------------------
features <- SelectIntegrationFeatures(object.list = objs, nfeatures = NFEATURES_INT)
writeLines(features, file.path(DATA_DIR, "integration_features.txt"))
msg("FEATURES %d integration features selected -> integration_features.txt",
    length(features))

for (cond in conditions) {
  obj <- ScaleData(objs[[cond]], features = features)
  obj <- RunPCA(obj, features = features, npcs = NPCS)
  ggsave(file.path(DATA_DIR, paste0(cond, "_elbow.png")),
         plot = ElbowPlot(obj, ndims = NPCS), width = 7, height = 5, dpi = 150)
  objs[[cond]] <- obj
  saveRDS(obj, file.path(DATA_DIR, paste0(cond, "_prepped.rds")))
  msg("PCA      %s: %d PCs computed -> %s_elbow.png",
      cond, ncol(Embeddings(obj, "pca")), cond)
}

# ---- Action 7: RPCA integration (user-confirmed) -----------------------------
if (RUN_INTEGRATION) {
  anchors <- FindIntegrationAnchors(object.list = objs,
                                    anchor.features = features,
                                    reduction = "rpca",
                                    dims = RPCA_DIMS,
                                    k.anchor = K_ANCHOR)
  msg("INTEGRATE anchors found, integrating over dims %s", RPCA_DIMS_STR)
  integrated <- IntegrateData(anchorset = anchors, dims = RPCA_DIMS)
  saveRDS(integrated, file.path(DATA_DIR, "integrated.rds"))
  msg("SAVED    integrated.rds (assay 'integrated'; %d genes x %d cells)",
      nrow(integrated[["integrated"]]), ncol(integrated))
} else {
  msg("INTEGRATE skipped by user choice (RUN_INTEGRATION=no); per-sample *_prepped.rds saved")
}

writeLines(capture.output(sessionInfo()),
           file.path(DATA_DIR, "sessionInfo_integrate.txt"))
msg("DONE: actions 6-7 complete")
