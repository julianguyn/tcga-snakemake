# Data Sources

## TCGA Data

- **Name**: The Cancer Genome Atlas via the NCI Genomic Data Commons
- **Access Method**: `TCGAbiolinks` queries against the GDC API
- **Primary Documentation**: [TCGAbiolinks vignette](https://bioconductor.org/packages/release/bioc/vignettes/TCGAbiolinks/inst/doc/index.html)
- **Package Manual**: [TCGAbiolinks reference manual](https://bioconductor.org/packages/release/bioc/manuals/TCGAbiolinks/man/TCGAbiolinks.pdf)

## Default Query Choices In This Workflow

| Profile | Query Defaults |
| --- | --- |
| `simple_nucleotide_variation` | `data.category = "Simple Nucleotide Variation"`, `data.type = "Masked Somatic Mutation"`, `workflow.type = "Aliquot Ensemble Somatic Variant Merging and Masking"`, `access = "open"` |
| `copy_number_variation` | `data.category = "Copy Number Variation"`, `data.type = "Gene Level Copy Number"`, `access = "open"`, `sample.type = "Primary Tumor"` |
| `gene_expression` | `data.category = "Transcriptome Profiling"`, `data.type = "Gene Expression Quantification"`, `workflow.type = "STAR - Counts"`, `sample.type = "Primary Tumor"` |
| `dna_methylation` | `data.category = "DNA Methylation"`, `data.type = "Methylation Beta Value"`, `sample.type = "Primary Tumor"`, platform fallback `EPIC -> 450K -> 27K` |
| `protein_profiling` | `data.category = "Proteome Profiling"`, `data.type = "Protein Expression Quantification"`, `sample.type = "Primary Tumor"` |
| `clinical` | `GDCquery_clinic(project, type = "clinical")` |

## Citations

- Colaprico A, Silva TC, Olsen C, et al. TCGAbiolinks: an R/Bioconductor package for integrative analysis of TCGA data. *Nucleic Acids Research*. 2016.
- Silva TC, Colaprico A, Olsen C, et al. TCGA Workflow: Analyze cancer genomics and epigenomics data using Bioconductor packages. *F1000Research*. 2016.
- Mounir M, Lucchetta M, Silva TC, et al. New functionalities in the TCGAbiolinks package for the study and integration of cancer data from GDC and GTEx. *PLOS Computational Biology*. 2019.
