# Developer Notes

## Overview of Section

This section documents technical decisions in creating the TCGA data objects.

### Design Decisions

Document important decisions about your project's architecture, algorithms, or methodologies:

``` markdown
## Choice of RNA-Seq Analysis Pipeline

[2025-04-25] We chose the kallisto over STAR pipeline for the following reasons:
    1. The CCLE dataset is very large, and kallisto is faster for quantifying large datasets
    2. GDSC used kallisto, so we can compare our results with theirs
```

### Technical Challenges

Record significant problems you encountered and how you solved them

``` markdown
## Sample Name Format Issue

[2025-04-25] We encountered a problem with sample name formats between the CCLE and GDSC datasets.
    The CCLE dataset uses "BRCA-XX-XXXX" format, while the GDSC dataset uses "BRCA-XX-XXXX-XX".
    We had to write a script to remove the last two characters from the sample names in the GDSC dataset.
```

### Dependencies and Environment

Document specific version requirements or compatibility issues:

``` markdown
## Critical Version Dependencies

[2025-04-25] SimpleITK 2.4.1 introduced a bug that flips images, so we froze version 2.4.0
```

## Best Practices

- Date your entries when appropriate
- Link to relevant code files or external resources
- Include small code snippets when helpful
- Note alternatives you considered and why they were rejected
- Document failed approaches to prevent others from repeating mistakes
- Update notes when major changes are made to the approach
