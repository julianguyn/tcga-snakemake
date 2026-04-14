# TCGA Snakemake

This repository builds project-specific TCGA datasets from the GDC with
[`TCGAbiolinks`](https://bioconductor.org/packages/release/bioc/html/TCGAbiolinks.html)
and assembles them into one `MultiAssayExperiment` (MAE) per TCGA project.

## What The Pipeline Produces

- One intermediate RDS per selected profile and project under `data/procdata/<PROJECT>/`
- One MAE per configured project at `data/results/<PROJECT>_MAE.RDS`
- Clinical metadata in `colData`
- Molecular assays in the MAE `ExperimentList`

If a selected profile is unavailable for a given project, the workflow records that
status in the intermediate RDS and still builds the project MAE from the assays that
were available.

## Setup

1. Install Pixi.
2. From the repository root, install the environment:

```bash
pixi install
```

3. Edit [`config/config.yaml`](/Users/michael/Projects/BHKLab/tcga-snakemake/config/config.yaml)
   to choose TCGA projects and profiles.
4. Optionally add a shared `config/samples.txt` file or project-specific files such as
   `config/samples/TCGA-BRCA.txt`.

See the [Usage](usage.md) page for config details and execution examples.
