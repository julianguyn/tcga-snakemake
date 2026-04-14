suppressPackageStartupMessages({
  library(TCGAbiolinks)
})


run_download_profile <- function(snakemake) {
  snakemake@source("check_data.R")
  close_log <- activate_snakemake_log(snakemake)
  on.exit(close_log(), add = TRUE)

  download_tcga_profile(
    profile = as.character(snakemake@wildcards[["profile"]]),
    project = as.character(snakemake@wildcards[["project"]]),
    output = as.character(snakemake@output[["profile"]]),
    samples = snakemake@params[["sample_file"]]
  )
}


run_download_profile(snakemake)
