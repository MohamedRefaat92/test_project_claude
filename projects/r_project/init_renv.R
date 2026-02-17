# init_renv.R — Bootstrap renv for this R project
#
# Run this script ONCE inside RStudio (or via run_shell.sh) to initialize renv:
#   ./scripts/run_shell.sh Rscript projects/r_project/init_renv.R
#
# After initialization:
#   - Install project-specific packages: install.packages("...")
#   - Record exact versions:             renv::snapshot()
#   - Restore on another machine:        renv::restore()
#   - Commit renv.lock to git — this is your reproducibility artifact

# Verify we're inside the container
if (!nchar(Sys.getenv("SINGULARITY_CONTAINER")) && !nchar(Sys.getenv("APPTAINER_CONTAINER"))) {
  warning("Not running inside a Singularity/Apptainer container.")
}

cat("Initializing renv...\n")
cat("Project path:", getwd(), "\n\n")

# Initialize renv in bare mode — use the container's system library as the base.
# This means container-pre-installed packages (DESeq2, Seurat, etc.) are used
# as-is without being copied into the renv library (saves disk space).
renv::init(
  bare       = FALSE,    # FALSE = include currently attached packages
  restart    = FALSE,    # don't restart R session (we're in a script)
  settings   = list(
    snapshot.type = "explicit",  # only snapshot packages listed in DESCRIPTION
    use.cache     = TRUE         # use renv's cross-project package cache
  )
)

cat("\nrenv initialized.\n")
cat("Next steps:\n")
cat("  1. Install project packages: install.packages('mypackage')\n")
cat("  2. Record the lockfile:      renv::snapshot()\n")
cat("  3. Commit renv.lock to git\n")
cat("  4. On a new machine:         renv::restore()\n")
