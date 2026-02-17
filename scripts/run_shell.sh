#!/usr/bin/env bash
# run_shell.sh — Drop into an interactive shell inside the container
#
# Usage:
#   ./scripts/run_shell.sh           # interactive shell
#   ./scripts/run_shell.sh <command> # run a single command and exit
#
# Examples:
#   ./scripts/run_shell.sh
#   ./scripts/run_shell.sh samtools view -c data/sample.bam
#   ./scripts/run_shell.sh STAR --version
#   ./scripts/run_shell.sh Rscript scripts/my_analysis.R

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

PROJECTS_DIR="${BIND_PROJECTS:-${REPO_ROOT}/projects}"
DATA_DIR="${BIND_DATA:-${REPO_ROOT}/data}"

BIND_OPTS=(
    --bind "${PROJECTS_DIR}:/projects"
    --bind "${DATA_DIR}:/data"
    --bind /tmp:/tmp
)

if [[ $# -eq 0 ]]; then
    # Interactive shell
    echo "Entering container shell. Type 'exit' to quit."
    echo "  /projects → ${PROJECTS_DIR}"
    echo "  /data     → ${DATA_DIR}"
    echo ""
    exec ${SNG} shell "${BIND_OPTS[@]}" "${SIF}"
else
    # Run a single command
    exec ${SNG} exec "${BIND_OPTS[@]}" "${SIF}" "$@"
fi
