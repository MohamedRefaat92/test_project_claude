#!/usr/bin/env bash
# export_lockfiles.sh — Export fully-resolved package lockfiles for reproducibility
#
# Run this AFTER building the container to capture exact package versions.
# These lockfiles guarantee bit-identical rebuilds.
#
# Output files:
#   container/conda_explicit_spec.txt  — exact conda packages with build hashes
#   container/pip_freeze.txt           — pip packages in the conda env
#   container/r_installed_packages.tsv — R packages installed in the image

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SIF="${REPO_ROOT}/bioinfo_latest.sif"

if command -v apptainer &>/dev/null; then
    SNG="apptainer"
elif command -v singularity &>/dev/null; then
    SNG="singularity"
else
    echo "ERROR: Neither 'apptainer' nor 'singularity' found in PATH." >&2
    exit 1
fi

if [[ ! -f "${SIF}" ]]; then
    echo "ERROR: Container image not found: ${SIF}" >&2
    echo "Build it first: ./scripts/build.sh" >&2
    exit 1
fi

echo "Exporting lockfiles from ${SIF}..."

# Conda explicit spec (includes build hashes — fully reproducible)
echo "  → container/conda_explicit_spec.txt"
${SNG} exec "${SIF}" \
    /opt/conda/bin/conda list --name bioinfo --explicit \
    > "${REPO_ROOT}/container/conda_explicit_spec.txt"

# pip freeze for the conda env
echo "  → container/pip_freeze.txt"
${SNG} exec "${SIF}" \
    /opt/conda/envs/bioinfo/bin/pip freeze \
    > "${REPO_ROOT}/container/pip_freeze.txt"

# R installed packages
echo "  → container/r_installed_packages.tsv"
${SNG} exec "${SIF}" \
    Rscript -e 'write.table(as.data.frame(installed.packages()[,c("Package","Version","Built")]),
                 file=stdout(), sep="\t", quote=FALSE, row.names=FALSE)' \
    > "${REPO_ROOT}/container/r_installed_packages.tsv"

echo ""
echo "Lockfiles written to container/"
echo "Commit these to version control to enable exact reproduction of this environment."
