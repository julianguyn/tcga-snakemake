# TCGAbiolinks Notes

The workflow uses the core `TCGAbiolinks` functions documented in the official package
manual and vignette:

- [`GDCquery`](https://bioconductor.org/packages/release/bioc/manuals/TCGAbiolinks/man/TCGAbiolinks.pdf)
- [`GDCdownload`](https://bioconductor.org/packages/release/bioc/manuals/TCGAbiolinks/man/TCGAbiolinks.pdf)
- [`GDCprepare`](https://bioconductor.org/packages/release/bioc/manuals/TCGAbiolinks/man/TCGAbiolinks.pdf)
- [`GDCquery_clinic`](https://bioconductor.org/packages/release/bioc/manuals/TCGAbiolinks/man/TCGAbiolinks.pdf)

## How The Workflow Uses The Package

For molecular profiles, the pipeline:

1. Builds a `GDCquery()` call from the selected profile key.
2. Downloads matching files with `GDCdownload()`.
3. Materializes an R object with `GDCprepare()`.
4. Stores a structured RDS containing the prepared object and query metadata.

For clinical data, the pipeline uses `GDCquery_clinic()` directly and then filters to
selected samples, when a sample file is provided.

## Profile-Specific Behavior

### Gene Expression

The workflow fixes `workflow.type = "STAR - Counts"` so expression matrices are
consistent across projects.

### DNA Methylation

TCGA methylation availability differs across projects, so the script tries these
platforms in order and uses the first one that returns files:

1. `Illumina Methylation Epic`
2. `Illumina Human Methylation 450`
3. `Illumina Human Methylation 27`

### SNV To MAE Conversion

The mutation query uses
`workflow.type = "Aliquot Ensemble Somatic Variant Merging and Masking"`, matching the
official TCGAbiolinks mutation vignette. SNV availability is determined by the actual
`GDCquery()` result rather than by `getProjectSummary()`, because the project summary
can be incomplete for mutation data.
Unlike the other profiles, the mutation query does not force `sample.type`, because the
masked somatic mutation workflow does not expose the same sample-type filter surface.

`GDCprepare()` returns SNV data as a tabular object. During MAE assembly, the workflow
converts it into a gene-by-sample mutation count matrix using `Hugo_Symbol` and
`Tumor_Sample_Barcode`.

### Clinical Integration

The MAE `colData` is keyed at the TCGA participant level, derived from the first
12 characters of the TCGA barcode. Clinical rows are deduplicated on that same
participant identifier before being matched back to assay samples.
