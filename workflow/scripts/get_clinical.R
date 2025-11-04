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
# Get clinical information
###########################################################

metadata <- GDCquery_clinic(
    project = project,
    type = "clinical"
)

###########################################################
# Subset for provided sample list
###########################################################

# if sample list provided, subset for samples
if (!is.na(samples)) {
    barcodes <- scan(samples, what = "", quiet = TRUE)
    metadata <- metadata[match(barcodes, metadata$submitted_id),]
}

###########################################################
# Save clinical metadata
###########################################################

saveRDS(metadata, output)
