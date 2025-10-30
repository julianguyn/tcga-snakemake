# load libraries
suppressPackageStartupMessages({
    library(TCGAbiolinks)
    library(sesame)
    library(sesameData)
    library(log4r)
})

# get args
args <- commandArgs(trailingOnly = TRUE)
project <- args[1]
output <- args[2]
samples <- args[3]

###########################################################
# Checks inputs
###########################################################

# if sample list provided, get samples
if (!is.na(samples)) barcodes <- scan(samples, what = "", quiet = TRUE)

#check_data(project, "dna_methylation", samples)

###########################################################
# Run query
###########################################################

## TODO:: try EPIC first, catch and try 450 second

if (!is.na(samples)) {
    message(paste("Running query on *selected* samples from", project))
    query <- GDCquery(
        project= project,
        data.category = "DNA Methylation",
        data.type = "Methylation Beta Value",
        platform = "Illumina Human Methylation 450",
        barcode = barcodes
    )
} else {
    message(paste("Running query on *all* samples from", project))
    query <- GDCquery(
        project= project,
        data.category = "DNA Methylation",
        data.type = "Methylation Beta Value",
        platform = "Illumina Human Methylation 450"
    )
}

###########################################################
# Download and save data
###########################################################

GDCdownload(query = query)
data <- GDCprepare(query = query)
saveRDS(data, output)
