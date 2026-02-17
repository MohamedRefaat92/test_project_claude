# Bioinformatics Analysis Container

[![Binder](https://mybinder.org/badge_logo.svg)](https://mybinder.org/v2/gh/MohamedRefaat92/test_project_claude/HEAD)
[![Build Container](https://github.com/MohamedRefaat92/test_project_claude/actions/workflows/build-container.yml/badge.svg)](https://github.com/MohamedRefaat92/test_project_claude/actions/workflows/build-container.yml)

Reproducible bioinformatics environment using Apptainer/Singularity.
Provides RStudio Server and JupyterLab with a comprehensive suite of
bioinformatics tools.

## Two-Tier Workflow

| | Binder | Full Container (.sif) |
|---|---|---|
| **Launch** | Click badge above | `./scripts/run_rstudio.sh` or `run_jupyter.sh` |
| **Install** | None — runs in browser | Apptainer on local machine or HPC |
| **RAM** | ~2 GB (mybinder.org limit) | Limited by your hardware |
| **Tools** | Python + R analysis packages | Everything, including aligners |
| **Use for** | Code review, demos, teaching | Full pipelines on real data |
| **Data** | Small example datasets only | Any size (bind-mounted from host) |

Notebooks developed in Binder run identically in the full container —
the Binder packages are a strict subset of what is in the `.sif`.

## For Reviewers — No Installation Required

Click the Binder badge above to launch JupyterLab in your browser with:

- **Python 3.11:** scanpy, PyDESeq2, biopython, pandas, scikit-learn
- **R 4.4:** DESeq2, edgeR, clusterProfiler, ggplot2, ComplexHeatmap

> The Binder environment does not include alignment tools (STAR, HISAT2)
> or large genome databases, as those require data files that cannot be
> hosted on mybinder.org.

## Pulling the Full Container (HPC / Local)

The `.sif` image is built automatically by GitHub Actions on every push to
`main` that modifies the container definition, and pushed to GHCR:

```bash
# Pull latest image
apptainer pull bioinfo_latest.sif oras://ghcr.io/mohamedrefaat92/test_project_claude/bioinfo:latest

# Pin to a specific commit (reproducible)
apptainer pull bioinfo_latest.sif oras://ghcr.io/mohamedrefaat92/test_project_claude/bioinfo:abcd1234
```

## Quick Start (Local Build)

```bash
# 1. Build the container (~60-90 min, ~10 GB image)
./scripts/build.sh

# 2a. Start RStudio Server → http://localhost:8787
./scripts/run_rstudio.sh

# 2b. Start JupyterLab → http://localhost:8888
./scripts/run_jupyter.sh

# 2c. Interactive shell (for CLI tools: STAR, samtools, bcftools, etc.)
./scripts/run_shell.sh
```

## Directory Structure

```
postdoc_claude/
├── binder/                          # repo2docker config — used by Binder
│   ├── environment.yml              # Lightweight Python conda spec
│   ├── apt.txt                      # System packages (R, dev libs)
│   ├── runtime.txt                  # Python version declaration
│   └── postBuild                    # Install R packages after conda
├── .github/
│   └── workflows/
│       └── build-container.yml      # CI: build .sif → push to GHCR
├── container/
│   ├── bioinfo.def              # Apptainer build recipe (source of truth)
│   ├── environment.yml          # Full pinned conda/Python environment
│   ├── renv_setup.R             # R packages installed in the image
│   ├── conda_explicit_spec.txt  # Generated after build (exact lockfile)
│   └── r_installed_packages.tsv # Generated after build
├── scripts/
│   ├── build.sh                 # Build the .sif image locally
│   ├── run_rstudio.sh           # Launch RStudio Server
│   ├── run_jupyter.sh           # Launch JupyterLab
│   ├── run_shell.sh             # Drop into container shell
│   └── export_lockfiles.sh      # Export exact package versions post-build
├── projects/
│   ├── r_project/               # R analyses (mounted at /home/rstudio/projects)
│   │   └── init_renv.R          # Bootstrap renv for per-project reproducibility
│   └── notebooks/               # Jupyter notebooks (mounted at /projects)
│       └── example_analysis.ipynb
├── data/                        # Raw/processed data (mounted at /data)
├── cache/
│   ├── r_libs/                  # renv package cache (persists across rebuilds)
│   └── conda_pkgs/              # Conda package cache
└── bioinfo_latest.sif           # Built image (not in git — pull from GHCR)
```

## Included Software

### Alignment & Quantification
| Tool | Version | Purpose |
|------|---------|---------|
| STAR | 2.7.11b | RNA-seq alignment |
| HISAT2 | 2.2.1 | Spliced alignment |
| bowtie2 | 2.5.4 | DNA alignment |
| minimap2 | 2.28 | Long-read alignment |
| kallisto | 0.51.1 | Pseudoalignment quantification |
| salmon | 1.10.3 | Quasi-mapping quantification |
| featureCounts | 2.0.6 | Read counting (subread) |

### Quality Control & Trimming
| Tool | Version |
|------|---------|
| FastQC | apt |
| MultiQC | 1.21 |
| fastp | 0.23.4 |
| Trim Galore | 0.6.10 |
| cutadapt | 4.9 |

### Variant Analysis
| Tool | Version |
|------|---------|
| bcftools | apt |
| samtools | apt |
| bedtools | apt |
| vcftools | 0.1.16 |

### R Packages (Bioconductor 3.22 / R 4.5.0)
**Bulk RNA-seq:** DESeq2, edgeR, limma, tximport, tximeta
**Single-cell:** Seurat, SingleCellExperiment, scran, scater, slingshot
**Annotation:** clusterProfiler, fgsea, GSVA, org.Hs.eg.db, org.Mm.eg.db
**Genomics:** GenomicRanges, GenomicFeatures, Biostrings, VariantAnnotation
**Visualization:** ggplot2, ComplexHeatmap, EnhancedVolcano, patchwork
**Workflow & reporting:** targets, tarchetypes, crew, quarto, rmarkdown

### Python Packages (Python 3.11)
**Single-cell:** scanpy, anndata, scvi-tools
**RNA-seq:** PyDESeq2, HTSeq
**Genomics:** biopython, pysam, pybedtools
**ML:** scikit-learn, scipy, statsmodels
**Workflows:** snakemake, papermill

## Configuration

### RStudio Server
```bash
# Custom port and password
RSTUDIO_PORT=8790 RSTUDIO_PASSWORD=mypass ./scripts/run_rstudio.sh
```
Default: port `8787`, password `change_me_please`, username = your Linux username.

### JupyterLab
```bash
# Enable token authentication
JUPYTER_TOKEN=my_secret_token ./scripts/run_jupyter.sh

# Custom port
JUPYTER_PORT=8889 ./scripts/run_jupyter.sh
```
Default: port `8888`, no token (local WSL2 access only).

### Bind Mounts
Both services bind-mount these host directories into the container:
- `./projects` → `/projects` (or `/home/rstudio/projects` in RStudio)
- `./data` → `/data` (or `/home/rstudio/data` in RStudio)

Override with environment variables:
```bash
BIND_PROJECTS=/path/to/my/analyses BIND_DATA=/mnt/shared/data ./scripts/run_rstudio.sh
```

## Running CLI Tools

```bash
# Interactive shell
./scripts/run_shell.sh

# Single command
./scripts/run_shell.sh samtools flagstat data/sample.bam
./scripts/run_shell.sh STAR --runMode genomeGenerate ...
./scripts/run_shell.sh snakemake --cores 8 -s projects/workflow/Snakefile
```

## Reproducibility

### Three-layer approach:

**1. Container image** (`bioinfo.def` + `bioinfo_latest.sif`)
All software versions are pinned in `bioinfo.def`. The `.sif` is immutable.
GitHub Actions builds and pushes it to GHCR automatically on every relevant commit:
```bash
# Pull by commit SHA (fully reproducible — references a specific build)
apptainer pull bioinfo_latest.sif oras://ghcr.io/mohamedrefaat92/test_project_claude/bioinfo:abcd1234

# Or copy to HPC shared storage
rsync -avP bioinfo_latest.sif hpc:/shared/containers/
```

**2. Python environment** (`environment.yml` + `conda_explicit_spec.txt`)
After building, export exact package specs including build hashes:
```bash
./scripts/export_lockfiles.sh
# Commit container/conda_explicit_spec.txt to git
```
Rebuild from lockfile: `conda create --name bioinfo --file container/conda_explicit_spec.txt`

**3. R projects** (`renv.lock` per project)
```bash
# Inside RStudio or run_shell.sh:
Rscript projects/r_project/init_renv.R  # initialize once
renv::snapshot()                         # after installing packages
renv::restore()                          # on a new machine
```
Commit `renv.lock` to git. The renv library cache at `cache/r_libs/` persists across
container rebuilds so packages don't need to be reinstalled.

## Build Options

```bash
./scripts/build.sh           # standard build (--fakeroot)
./scripts/build.sh --force   # overwrite existing .sif
./scripts/build.sh --sandbox # build writable directory (faster iteration)
./scripts/build.sh --test    # run smoke tests after build
```

**Sandbox workflow** (for testing changes to the definition file):
```bash
./scripts/build.sh --sandbox
singularity shell --fakeroot --writable bioinfo_sandbox/
# Test changes interactively, then convert to .sif:
singularity build --fakeroot --force bioinfo_latest.sif bioinfo_sandbox/
```

## Running Both Services Simultaneously

Open two terminals:
```bash
# Terminal 1
./scripts/run_rstudio.sh   # → http://localhost:8787

# Terminal 2
./scripts/run_jupyter.sh   # → http://localhost:8888
```

Both services bind-mount the same `./projects` and `./data` directories,
so files created in RStudio are immediately visible in JupyterLab and vice versa.

## Troubleshooting

**Build fails with "fakeroot" error:**
```bash
# Check if user namespaces are enabled
singularity config fakeroot --list

# If your user isn't listed, add subuid/subgid entries:
sudo usermod --add-subuids 100000-165535 $(whoami)
sudo usermod --add-subgids 100000-165535 $(whoami)
```

**RStudio shows "Unable to connect":**
- Verify port is not in use: `ss -tlnp | grep 8787`
- Check the container is running: the terminal should show no errors
- Ensure you're accessing `http://` not `https://`

**"R package X not found" in RStudio:**
- The container has common packages pre-installed
- For project-specific packages, use renv: `renv::install("X"); renv::snapshot()`
- The renv library at `cache/r_libs/` persists across sessions

**JupyterLab kernel not found:**
- The `Python (bioinfo)` kernel should appear automatically
- If missing: `./scripts/run_shell.sh /opt/conda/envs/bioinfo/bin/python -m ipykernel install --user --name bioinfo`

**Port already in use:**
```bash
RSTUDIO_PORT=8790 ./scripts/run_rstudio.sh
JUPYTER_PORT=8889 ./scripts/run_jupyter.sh
```
