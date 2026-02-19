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
  repos          = c(CRAN = "https://packagemanager.posit.co/cran/__linux__/noble/latest"),
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
  "ggrepel", "patchwork", "cowplot",
  "pheatmap", "RColorBrewer", "viridis", "viridisLite",
  "scales", "ggridges", "ggbeeswarm",

  # Data I/O
  "data.table", "openxlsx", "readxl", "writexl",
  "jsonlite", "yaml", "Matrix",

  # Reproducibility & workflow
  "renv",
  "targets",       # Make-like pipeline toolkit
  "tarchetypes",   # Common targets patterns (tar_quarto, tar_rmarkdown, etc.)
  "crew",          # Distributed targets workers

  # Reporting
  "rmarkdown", "knitr", "DT", "plotly", "htmlwidgets",
  "quarto",        # R interface to the Quarto CLI

  # Single-cell utilities (CRAN)
  "Rtsne", "umap",

  # Misc
  "here", "fs", "glue", "cli", "crayon", "progress"
)

cat("Installing CRAN packages...\n")
# magick must compile from source to link against the system ImageMagick;
# the noble binary from Posit PM expects libMagick++-6 which may not match.
install.packages("magick", ask = FALSE, type = "source")
install.packages(cran_pkgs, ask = FALSE, quiet = FALSE)

# ---------------------------------------------------------------
# Bioconductor packages
# ---------------------------------------------------------------
bioc_pkgs <- c(
  # Single-cell RNA-seq
  "SingleCellExperiment",
  "scran",
  "scater",
  "scuttle",
  "glmGamPoi",
  "scDblFinder",
  "slingshot",

  # Pathway / enrichment analysis
  "clusterProfiler",
  "enrichplot",
  "fgsea",
  "GSVA",
  "msigdbr",
  "ReactomePA",

  # Visualization
  "ComplexHeatmap",
  "InteractiveComplexHeatmap",
  "EnhancedVolcano"
)

cat("\nInstalling Bioconductor packages...\n")
BiocManager::install(bioc_pkgs, ask = FALSE, update = FALSE)

# ---------------------------------------------------------------
# CRAN single-cell packages (large; install after Bioconductor)
# ---------------------------------------------------------------
cat("\nInstalling Seurat...\n")
install.packages(c("Seurat", "SeuratObject"), ask = FALSE)

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
  stop(paste("Missing packages:", paste(missing, collapse = ", ")))
} else {
  cat("\nAll packages installed successfully.\n")
}
