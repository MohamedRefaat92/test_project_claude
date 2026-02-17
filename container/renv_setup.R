# renv_setup.R
# Installs baseline Bioconductor + CRAN packages INTO the container image.
# This provides a system-wide R library inside the .sif for common packages.
#
# Per-project reproducibility is handled by renv on the HOST:
#   1. Open project in RStudio → renv::init()
#   2. Install project-specific packages → renv::snapshot()
#   3. Share renv.lock with collaborators → renv::restore()
#
# The renv project library is stored in the bind-mounted host directory,
# so it persists across container rebuilds.

cat("=== R Package Installation for Container Image ===\n")
cat(paste("R version:", R.version$major, ".", R.version$minor, "\n"))
cat(paste("Date:", Sys.time(), "\n\n"))

# ---------------------------------------------------------------
# CRAN mirror and options
# ---------------------------------------------------------------
options(
  repos          = c(CRAN = "https://packagemanager.posit.co/cran/__linux__/jammy/latest"),
  Ncpus          = parallel::detectCores(),   # parallel compilation
  install.packages.compile.from.source = "always"
)

# ---------------------------------------------------------------
# BiocManager and Bioconductor version
# ---------------------------------------------------------------
if (!requireNamespace("BiocManager", quietly = TRUE)) {
  install.packages("BiocManager")
}
BiocManager::install(version = "3.22", ask = FALSE, update = FALSE)

# ---------------------------------------------------------------
# CRAN packages
# ---------------------------------------------------------------
cran_pkgs <- c(
  # Tidyverse
  "tidyverse", "dplyr", "tidyr", "ggplot2", "readr",
  "purrr", "forcats", "stringr", "lubridate",

  # Visualization
  "ggrepel", "ggpubr", "patchwork", "cowplot",
  "pheatmap", "RColorBrewer", "viridis", "viridisLite",
  "scales", "ggridges", "ggbeeswarm",

  # Statistics
  "lme4", "lmerTest", "emmeans", "broom", "broom.mixed",
  "survival", "survminer",

  # Data I/O
  "data.table", "arrow", "openxlsx", "readxl", "writexl",
  "jsonlite", "yaml",

  # Reproducibility & workflow
  "renv",
  "targets",       # Make-like pipeline toolkit
  "tarchetypes",   # Common targets patterns (tar_quarto, tar_rmarkdown, etc.)
  "crew",          # Distributed targets workers

  # Reporting
  "rmarkdown", "knitr", "DT", "plotly", "htmlwidgets",
  "quarto",        # R interface to the Quarto CLI

  # Bioinformatics utilities (CRAN)
  "BiocParallel", "Matrix", "MatrixExtra",
  "Rtsne", "umap",

  # Misc
  "here", "fs", "glue", "cli", "crayon", "progress"
)

cat("Installing CRAN packages...\n")
install.packages(cran_pkgs, ask = FALSE, quiet = FALSE)

# ---------------------------------------------------------------
# Bioconductor packages
# ---------------------------------------------------------------
bioc_pkgs <- c(
  # Bulk RNA-seq
  "DESeq2",
  "edgeR",
  "limma",
  "voom",
  "tximport",
  "tximeta",
  "fishpond",

  # Single-cell RNA-seq
  "SingleCellExperiment",
  "scran",
  "scater",
  "scuttle",
  "glmGamPoi",
  "scDblFinder",
  "slingshot",

  # Genomic ranges / intervals
  "GenomicRanges",
  "GenomicFeatures",
  "GenomicAlignments",
  "IRanges",
  "rtracklayer",
  "Rsamtools",

  # Annotation
  "AnnotationDbi",
  "org.Hs.eg.db",
  "org.Mm.eg.db",
  "TxDb.Hsapiens.UCSC.hg38.knownGene",
  "TxDb.Mmusculus.UCSC.mm39.knownGene",
  "EnsDb.Hsapiens.v86",
  "BSgenome",
  "Biostrings",

  # Pathway / enrichment analysis
  "clusterProfiler",
  "enrichplot",
  "fgsea",
  "GSVA",
  "msigdbr",
  "ReactomePA",

  # Variant analysis
  "VariantAnnotation",

  # Visualization
  "ComplexHeatmap",
  "InteractiveComplexHeatmap",
  "EnhancedVolcano",

  # QC
  "FastqCleaner"
)

cat("\nInstalling Bioconductor packages...\n")
BiocManager::install(bioc_pkgs, ask = FALSE, update = FALSE)

# ---------------------------------------------------------------
# CRAN single-cell packages (large; install after Bioconductor)
# ---------------------------------------------------------------
cat("\nInstalling Seurat...\n")
install.packages(c("Seurat", "SeuratObject", "SeuratDisk"), ask = FALSE)

# ---------------------------------------------------------------
# Verify all installations
# ---------------------------------------------------------------
cat("\n=== Installation Verification ===\n")
all_pkgs <- c(cran_pkgs, bioc_pkgs, "Seurat", "SeuratObject")
installed <- rownames(installed.packages())
missing   <- setdiff(all_pkgs, installed)

for (p in all_pkgs) {
  status <- if (p %in% installed) "OK" else "MISSING"
  cat(sprintf("  [%s] %s\n", status, p))
}

if (length(missing) > 0) {
  warning(paste("Missing packages:", paste(missing, collapse = ", ")))
} else {
  cat("\nAll packages installed successfully.\n")
}
