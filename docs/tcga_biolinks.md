# TCGA Biolinks Information

## Overview of Section

This section provides information on the TCGAbiolinks R package and arguments used to collect the TCGA data objects.

## TCGAbiolinks

TCGAbiolinks is a package available on [Bioconductor](https://bioconductor.org/packages/release/bioc/html/TCGAbiolinks.html) to faciliate access of GDC data. The package offers various methods for downstreama analyses, but those have not been incorporated into this pipeline. 

## Data Access Arguments

This pipeline currently can only collect the data categories listed in `config/config.yaml`. For each data category, TCGAbiolinks takes several arguments into its query:

```markdown
query <- GDCquery(
    project = <project>,                # TCGA Project Collection, e.g. "TCGA-ACC" 
    data.category = <data.category>,    # Data Category from config
    data.type = <data.type>             # More details of data to return
)
```

More information on the query can be found [here](https://bioconductor.org/packages/release/bioc/vignettes/TCGAbiolinks/inst/doc/query.html).

This pipeline uses standardized data types and platforms. Information on these arguments can be found [here](https://bioconductor.org/packages/release/bioc/vignettes/TCGAbiolinks/inst/doc/download_prepare.html).



A summary of alternative data options are listed below:

### Profile: DNA Methylation

**Query from pipeline:**
```markdown
query <- GDCquery(
    project = "TCGA-BRCA",                  # modified for each dataset               
    data.category = "DNA Methylation",    
    data.type = "Methylation Beta Value",
    platform = "Illumina Methylation Epic"           
)
```

**Platforms:**
1. `Illumina Methylation Epic` (default in pipeline): Returns methylation data from EPIC array.
2. `Illumina Human Methylation 450`: Returns methylation data from the 45k array
3. `Illumina Human Methylation 27`: Returns methylation data from the 27k array

**Data Type:**
1. `DNA Methylation` (default in pipeline): Returns methylation beta values
2. `Masked Intensities`: Retrieves IDAT files (input to `platform` can be one of the three arguments listed above)


TODO:: COMPLETE