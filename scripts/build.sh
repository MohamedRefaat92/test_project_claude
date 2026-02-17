#!/usr/bin/env bash
# build.sh — Build the bioinformatics Apptainer/Singularity container image
#
# Usage:
#   ./scripts/build.sh           # standard build
#   ./scripts/build.sh --force   # overwrite existing .sif
#   ./scripts/build.sh --sandbox # build to a directory (for iterative dev)
#   ./scripts/build.sh --test    # run smoke tests after build
#
# Requirements:
#   - singularity (CE 3.x+) or apptainer (1.x+)
#   - User namespace support (WSL2 has this by default)
#
# Build mode:
#   Uses --fakeroot which creates the image without requiring sudo.
#   If fakeroot fails, add your username to /etc/subuid and /etc/subgid.
#   Fallback: build with sudo (remove --fakeroot flag below).

set -euo pipefail

# ---------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEF_FILE="${REPO_ROOT}/container/bioinfo.def"
SIF_OUT="${REPO_ROOT}/bioinfo_latest.sif"
SANDBOX_DIR="${REPO_ROOT}/bioinfo_sandbox"
CACHE_DIR="${REPO_ROOT}/.singularity_cache"

# Detect singularity or apptainer
if command -v apptainer &>/dev/null; then
    SINGULARITY_CMD="apptainer"
elif command -v singularity &>/dev/null; then
    SINGULARITY_CMD="singularity"
else
    echo "ERROR: Neither 'apptainer' nor 'singularity' found in PATH." >&2
    exit 1
fi

# ---------------------------------------------------------------
# Parse arguments
# ---------------------------------------------------------------
BUILD_FORCE=""
BUILD_SANDBOX=false
BUILD_TEST=false

for arg in "$@"; do
    case "$arg" in
        --force)   BUILD_FORCE="--force" ;;
        --sandbox) BUILD_SANDBOX=true ;;
        --test)    BUILD_TEST=true ;;
        --help|-h)
            grep '^#' "$0" | head -20 | sed 's/^# \?//'
            exit 0
            ;;
        *)
            echo "Unknown argument: $arg" >&2
            exit 1
            ;;
    esac
done

# ---------------------------------------------------------------
# Pre-flight checks
# ---------------------------------------------------------------
if [[ ! -f "${DEF_FILE}" ]]; then
    echo "ERROR: Definition file not found: ${DEF_FILE}" >&2
    exit 1
fi

# Ensure files referenced in %files section exist
for f in container/environment.yml container/renv_setup.R; do
    if [[ ! -f "${REPO_ROOT}/${f}" ]]; then
        echo "ERROR: Required file not found: ${REPO_ROOT}/${f}" >&2
        exit 1
    fi
done

mkdir -p "${CACHE_DIR}"
export SINGULARITY_CACHEDIR="${CACHE_DIR}"
export APPTAINER_CACHEDIR="${CACHE_DIR}"

# ---------------------------------------------------------------
# Build
# ---------------------------------------------------------------
echo "=============================================="
echo "  Bioinformatics Container Build"
echo "=============================================="
echo "  Command:    ${SINGULARITY_CMD}"
echo "  Definition: ${DEF_FILE}"
echo "  Output:     ${SIF_OUT}"
echo "  Cache:      ${CACHE_DIR}"
echo "  Build dir:  ${REPO_ROOT}"
echo "=============================================="
echo ""

cd "${REPO_ROOT}"   # %files paths are relative to the build context

if $BUILD_SANDBOX; then
    # Sandbox mode: writable directory for iterative development
    echo "Building in sandbox mode → ${SANDBOX_DIR}"
    echo "To convert to .sif later:"
    echo "  ${SINGULARITY_CMD} build ${BUILD_FORCE} ${SIF_OUT} ${SANDBOX_DIR}"
    echo ""
    time ${SINGULARITY_CMD} build \
        --fakeroot \
        --sandbox \
        ${BUILD_FORCE} \
        "${SANDBOX_DIR}" \
        "${DEF_FILE}"
    echo ""
    echo "Sandbox built at: ${SANDBOX_DIR}"
    echo "Shell into it: ${SINGULARITY_CMD} shell --fakeroot --writable ${SANDBOX_DIR}"
else
    # Standard SIF build
    time ${SINGULARITY_CMD} build \
        --fakeroot \
        ${BUILD_FORCE} \
        "${SIF_OUT}" \
        "${DEF_FILE}"
    echo ""
    echo "Build complete: ${SIF_OUT}"
    ls -lh "${SIF_OUT}"

    if $BUILD_TEST; then
        echo ""
        echo "Running smoke tests..."
        ${SINGULARITY_CMD} test "${SIF_OUT}"
    fi
fi

echo ""
echo "Done. Next steps:"
echo "  RStudio Server: ./scripts/run_rstudio.sh"
echo "  JupyterLab:     ./scripts/run_jupyter.sh"
echo "  Shell:          ./scripts/run_shell.sh"
