# Developer Notes

## 2026-04-14

### Workflow Structure

The original Snakefile treated the workflow as a single-project pipeline and reused the
same output filenames for every profile regardless of project. The workflow now uses
`project` and `profile` wildcards so each selected TCGA project produces isolated
intermediates under `data/procdata/<PROJECT>/` and one final MAE at
`data/results/<PROJECT>_MAE.RDS`.

### Unavailable Profiles

Not every TCGA project exposes every selected data type. Instead of failing the entire
workflow when a profile is missing for a project, each profile rule now writes a
structured RDS with `status = "unavailable"`. MAE assembly skips those assays but
preserves the status in MAE metadata.

Mutation data is a special case: the workflow no longer relies on
`TCGAbiolinks:::getProjectSummary()` to decide whether SNV exists for a project, because
that summary can report false negatives. Availability is now determined by the actual
`GDCquery()` result.

### MAE Conventions

- Clinical data lives in `colData`.
- Molecular datasets live in the MAE `ExperimentList`.
- Sample mapping is done at the participant level using the first 12 characters of the
  TCGA barcode.
- SNV data is represented in the MAE as a gene-by-sample mutation count matrix.

### Environment Notes

The Pixi environment now pins the missing runtime packages that the workflow actually
needs:

- `bioconductor-tcgabiolinksgui.data` so `TCGAbiolinks` loads cleanly in the Pixi env
- `bioconductor-multiassayexperiment` for final MAE assembly
