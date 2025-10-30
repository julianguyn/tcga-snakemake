# Data Sources

## Overview

This section should document all data sources used in your project.
Proper documentation ensures reproducibility and helps others
understand your research methodology.

```markdown
## TCGA Data

- **Name**: The Cancer Genome Atlas Clinical and Molecular Data
- **Version**: TCGAbiolinks version 2.37.3
- **Access Method**: GDC Data Transfer Tool
- **URL**: https://bioconductor.org/packages/release/bioc/vignettes/TCGAbiolinks/inst/doc/index.html
- **Citation**: 
-   * Colaprico, Antonio, et al. “TCGAbiolinks: an R/Bioconductor package for integrative analysis of TCGA data.” Nucleic acids research 44.8 (2015): e71-e71
-   * Silva, Tiago C., et al. “TCGA Workflow: Analyze cancer genomics and epigenomics data using Bioconductor packages.” F1000Research 5 (2016). (https://f1000research.com/articles/5-1542/v2)
-   * Mounir, Mohamed, et al. “New functionalities in the TCGAbiolinks package for the study and integration of cancer data from GDC and GTEx.” PLoS computational biology 15.3 (2019): e1006701. (https://doi.org/10.1371/journal.pcbi.1006701)
```

## Clinical Data Dictionary

For complex datasets, include a data dictionary that explains:

| Column Name | Data Type | Description | Units | Possible Values |
|-------------|-----------|-------------|-------|-----------------|
| patient_id  | string    | Unique patient identifier | N/A | TCGA-XX-XXXX format |
| age         | integer   | Patient age at diagnosis | years | 18-100 |
| expression  | float     | Gene expression value | TPM | Any positive value |
