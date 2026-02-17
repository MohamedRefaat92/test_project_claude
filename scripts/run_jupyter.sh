#!/usr/bin/env bash
# run_jupyter.sh — Launch JupyterLab from the bioinformatics container
#
# Usage:
#   ./scripts/run_jupyter.sh
#
# Access:
#   Open http://localhost:8888 in your browser (no token/password by default)
#
# Environment variables:
#   JUPYTER_PORT     Port for JupyterLab      (default: 8888)
#   JUPYTER_TOKEN    Auth token               (default: empty = no auth)
#   BIND_PROJECTS    Host path for notebooks  (default: ./projects)
#   BIND_DATA        Host path for data       (default: ./data)
#
# Security note:
#   Token auth is disabled for local WSL2 use (only accessible on localhost).
#   To enable token auth: JUPYTER_TOKEN=your_secret_token ./scripts/run_jupyter.sh

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SIF="${REPO_ROOT}/bioinfo_latest.sif"

# ---------------------------------------------------------------
# Detect singularity / apptainer
# ---------------------------------------------------------------
if command -v apptainer &>/dev/null; then
    SNG="apptainer"
elif command -v singularity &>/dev/null; then
    SNG="singularity"
else
    echo "ERROR: Neither 'apptainer' nor 'singularity' found in PATH." >&2
    exit 1
fi

# ---------------------------------------------------------------
# Check image exists
# ---------------------------------------------------------------
if [[ ! -f "${SIF}" ]]; then
    echo "ERROR: Container image not found: ${SIF}" >&2
    echo "Build it first: ./scripts/build.sh" >&2
    exit 1
fi

# ---------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------
PORT="${JUPYTER_PORT:-8888}"
TOKEN="${JUPYTER_TOKEN:-}"
PROJECTS_DIR="${BIND_PROJECTS:-${REPO_ROOT}/projects}"
DATA_DIR="${BIND_DATA:-${REPO_ROOT}/data}"
CONDA_CACHE="${REPO_ROOT}/cache/conda_pkgs"

mkdir -p "${CONDA_CACHE}"

# ---------------------------------------------------------------
# Check port availability
# ---------------------------------------------------------------
if ss -tlnp 2>/dev/null | grep -q ":${PORT} "; then
    echo "WARNING: Port ${PORT} is already in use." >&2
    echo "Either stop the existing process or set JUPYTER_PORT to a different port." >&2
    echo "Example: JUPYTER_PORT=8889 ./scripts/run_jupyter.sh" >&2
    exit 1
fi

# ---------------------------------------------------------------
# Build token argument
# ---------------------------------------------------------------
if [[ -n "${TOKEN}" ]]; then
    TOKEN_ARG="--ServerApp.token=${TOKEN}"
    AUTH_MSG="Token: ${TOKEN}"
else
    TOKEN_ARG="--ServerApp.token=''"
    AUTH_MSG="No authentication (local access only)"
fi

# ---------------------------------------------------------------
# Launch
# ---------------------------------------------------------------
echo "========================================"
echo "  Starting JupyterLab"
echo "========================================"
echo "  URL:       http://localhost:${PORT}"
echo "  Auth:      ${AUTH_MSG}"
echo "  Notebooks: ${PROJECTS_DIR} → /projects"
echo "  Data:      ${DATA_DIR} → /data"
echo "========================================"
echo "  Press Ctrl+C to stop."
echo ""

exec ${SNG} exec \
    --bind "${PROJECTS_DIR}:/projects" \
    --bind "${DATA_DIR}:/data" \
    --bind "${CONDA_CACHE}:/opt/conda/pkgs" \
    --bind /tmp:/tmp \
    "${SIF}" \
    /opt/conda/envs/bioinfo/bin/jupyter lab \
        --ip=0.0.0.0 \
        --port="${PORT}" \
        --no-browser \
        --notebook-dir=/projects \
        "${TOKEN_ARG}" \
        --ServerApp.password='' \
        --ServerApp.allow_origin='*' \
        --ServerApp.disable_check_xsrf=False
