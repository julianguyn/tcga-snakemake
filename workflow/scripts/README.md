# Workflow Scripts

The `workflow/scripts/` directory contains the R entrypoints used by the Snakemake
workflow.

## Current Layout

- `check_data.R`: shared helper functions for query construction, sample filtering,
  project/profile validation, profile result serialization, and Snakemake log setup
- `download_profile.R`: the Snakemake `script:` entrypoint for all project/profile
  downloads; it reads `project`, `profile`, output paths, and params from the injected
  `snakemake` S4 object
- `get_MAE.R`: assembles the selected project profiles into a
  `MultiAssayExperiment` using the injected `snakemake` S4 object

## Intermediate Object Contract

Each profile script writes a structured RDS with:

- `project`
- `profile`
- `status`
- `data`
- `message`
- `query_args`
- `sample_file`

`get_MAE.R` relies on that structure to skip unavailable assays and to preserve query
metadata in the final MAE object.
