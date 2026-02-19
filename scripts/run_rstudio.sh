#!/usr/bin/env bash
# run_rstudio.sh — Launch RStudio Server from the bioinformatics container
#
# Usage:
#   ./scripts/run_rstudio.sh
#
# Access:
#   Open http://localhost:8787 in your browser
#   Username: your Linux username (auto-detected)
#   Password: set via RSTUDIO_PASSWORD env var (default: change_me_please)
#
# Environment variables:
#   RSTUDIO_PORT      Port for RStudio Server (default: 8787)
#   RSTUDIO_PASSWORD  Login password          (default: change_me_please)
#   BIND_PROJECTS     Host path for projects  (default: ./projects)
#   BIND_DATA         Host path for data      (default: ./data)
#
# Example with custom settings:
#   RSTUDIO_PORT=8888 RSTUDIO_PASSWORD=mypass ./scripts/run_rstudio.sh

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
# Configuration (override via environment variables)
# ---------------------------------------------------------------
PORT="${RSTUDIO_PORT:-8787}"
PASSWORD="${RSTUDIO_PASSWORD:-change_me_please}"
PROJECTS_DIR="${BIND_PROJECTS:-${REPO_ROOT}/projects}"
DATA_DIR="${BIND_DATA:-${REPO_ROOT}/data}"
R_LIBS_DIR="${REPO_ROOT}/cache/r_libs"

# RStudio Server needs writable runtime dirs; use a single tmpfs overlay
# rather than enumerating individual /var/* paths.
# Pre-create dirs that rserver needs so it doesn't try to chmod them.
RSTUDIO_VAR="${REPO_ROOT}/.rstudio_var"
RSTUDIO_RUN="${REPO_ROOT}/.rstudio_run"
mkdir -p "${RSTUDIO_VAR}" "${RSTUDIO_RUN}" "${R_LIBS_DIR}"
# Pre-create the sqlite file so rserver skips the chmod call
touch "${RSTUDIO_VAR}/rstudio-os.sqlite"
chmod 600 "${RSTUDIO_VAR}/rstudio-os.sqlite"

# ---------------------------------------------------------------
# Check port availability
# ---------------------------------------------------------------
if ss -tlnp 2>/dev/null | grep -q ":${PORT} "; then
    echo "WARNING: Port ${PORT} is already in use." >&2
    echo "Either stop the existing process or set RSTUDIO_PORT to a different port." >&2
    echo "Example: RSTUDIO_PORT=8790 ./scripts/run_rstudio.sh" >&2
    exit 1
fi

# ---------------------------------------------------------------
# Launch
# ---------------------------------------------------------------
echo "========================================"
echo "  Starting RStudio Server"
echo "========================================"
echo "  URL:      http://localhost:${PORT}"
echo "  User:     $(whoami)"
echo "  Password: ${PASSWORD}"
echo "  Projects: ${PROJECTS_DIR} → /home/rstudio/projects"
echo "  Data:     ${DATA_DIR} → /home/rstudio/data"
echo "========================================"
echo "  Press Ctrl+C to stop."
echo ""

exec ${SNG} exec \
    --writable-tmpfs \
    --bind "${PROJECTS_DIR}:/home/rstudio/projects" \
    --bind "${DATA_DIR}:/home/rstudio/data" \
    --bind "${R_LIBS_DIR}:/home/rstudio/.R/library" \
    --bind "${RSTUDIO_VAR}:/var/lib/rstudio-server" \
    --bind "${RSTUDIO_RUN}:/var/run/rstudio-server" \
    --bind /tmp:/tmp \
    --env "PASSWORD=${PASSWORD}" \
    --env "RSTUDIO_SESSION_TIMEOUT=0" \
    --env "RS_LOG_LEVEL=WARN" \
    --env "RSTUDIO_WHICH_R=/usr/local/bin/R" \
    "${SIF}" \
    /usr/lib/rstudio-server/bin/rserver \
        --www-address=0.0.0.0 \
        --www-port="${PORT}" \
        --server-daemonize=0 \
        --server-app-armor-enabled=0 \
        --server-user="$(whoami)" \
        --auth-none=0 \
        --auth-pam-helper-path=/usr/lib/rstudio-server/bin/pam-helper \
        --rsession-which-r=/usr/local/bin/R
