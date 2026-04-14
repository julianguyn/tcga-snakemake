# Usage Guide

## Configure Projects And Profiles

The workflow reads [`config/config.yaml`](/Users/michael/Projects/BHKLab/tcga-snakemake/config/config.yaml).
Use the `projects` key to list one or more TCGA projects:

```yaml
projects:
  - TCGA-BRCA
  - TCGA-COAD

profiles:
  - simple_nucleotide_variation
  - copy_number_variation
  - gene_expression
  - clinical
```

Supported profile keys are:

- `simple_nucleotide_variation`
- `copy_number_variation`
- `gene_expression`
- `dna_methylation`
- `protein_profiling`
- `clinical`

## Optional Sample Filters

You can restrict downloads to a subset of TCGA barcodes with either:

- `config/samples.txt` for one shared list applied to every configured project
- `config/samples/<PROJECT>.txt` for project-specific sample lists

Project-specific sample files take precedence over the shared file. Clinical data is
filtered at the participant level, using the first 12 characters of each TCGA barcode.

## Run The Workflow

Dry-run the DAG without executing any downloads:

```bash
pixi run snakemake --snakefile workflow/Snakefile --cores <N> --dry-run
```

Lint the Snakefile:

```bash
pixi run snakemake --snakefile workflow/Snakefile --lint
```

Before the first real run, bootstrap the Bioconductor data package required by
`TCGAbiolinks`:

```bash
PREFIX=$PWD/.pixi/envs/default pixi run installBiocDataPackage.sh tcgabiolinksgui.data-1.30.0
```

Execute the workflow when you are ready:

```bash
pixi run snakemake --snakefile workflow/Snakefile --cores <N>
```

## Output Layout

- `data/procdata/<PROJECT>/<PROFILE>.RDS`: one structured profile result per project/profile
- `data/procdata/_downloads/<PROJECT>/<PROFILE>/`: downloaded GDC files used by `GDCprepare`
- `data/results/<PROJECT>_MAE.RDS`: final `MultiAssayExperiment`

Each profile RDS contains:

- the project name
- the profile key
- a `status` field (`ok` or `unavailable`)
- the prepared data object when available
- the query arguments used to retrieve the data

## MAE Assembly Rules

- Clinical data becomes `colData`.
- Molecular assays become entries in the MAE `ExperimentList`.
- MAE sample mapping is done at the TCGA participant level by truncating assay column
  names to the first 12 characters of the barcode.
- SNV data is converted into a gene-by-sample mutation count matrix before inclusion in
  the MAE.
