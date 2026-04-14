# Shared helpers for TCGAbiolinks-backed profile downloads and MAE assembly.

activate_snakemake_log <- function(snakemake) {
  if (length(snakemake@log) == 0) {
    return(function() invisible(NULL))
  }

  log_file <- as.character(snakemake@log[[1]])
  dir.create(dirname(log_file), recursive = TRUE, showWarnings = FALSE)

  log_con <- file(log_file, open = "wt")
  sink(log_con, split = TRUE)
  sink(log_con, type = "message")

  function() {
    sink(type = "message")
    sink()
    close(log_con)
  }
}

profile_query_specs <- function() {
  list(
    simple_nucleotide_variation = list(
      list(
        data.category = "Simple Nucleotide Variation",
        data.type = "Masked Somatic Mutation",
        workflow.type = "Aliquot Ensemble Somatic Variant Merging and Masking",
        access = "open"
      )
    ),
    copy_number_variation = list(
      list(
        data.category = "Copy Number Variation",
        data.type = "Gene Level Copy Number",
        access = "open",
        sample.type = "Primary Tumor"
      )
    ),
    gene_expression = list(
      list(
        data.category = "Transcriptome Profiling",
        data.type = "Gene Expression Quantification",
        workflow.type = "STAR - Counts",
        sample.type = "Primary Tumor"
      )
    ),
    dna_methylation = list(
      list(
        data.category = "DNA Methylation",
        data.type = "Methylation Beta Value",
        platform = "Illumina Methylation Epic",
        sample.type = "Primary Tumor"
      ),
      list(
        data.category = "DNA Methylation",
        data.type = "Methylation Beta Value",
        platform = "Illumina Human Methylation 450",
        sample.type = "Primary Tumor"
      ),
      list(
        data.category = "DNA Methylation",
        data.type = "Methylation Beta Value",
        platform = "Illumina Human Methylation 27",
        sample.type = "Primary Tumor"
      )
    ),
    protein_profiling = list(
      list(
        data.category = "Proteome Profiling",
        data.type = "Protein Expression Quantification",
        sample.type = "Primary Tumor"
      )
    )
  )
}


normalize_optional_path <- function(path) {
  if (is.null(path) || length(path) == 0) {
    return(NA_character_)
  }

  value <- trimws(as.character(path[[1]]))
  if (
    identical(value, "") || identical(value, "NA") || identical(value, "NULL")
  ) {
    return(NA_character_)
  }

  value
}


read_sample_barcodes <- function(samples_file) {
  samples_file <- normalize_optional_path(samples_file)
  if (is.na(samples_file)) {
    return(NULL)
  }

  if (!file.exists(samples_file)) {
    stop("Sample file does not exist: ", samples_file, call. = FALSE)
  }

  barcodes <- unique(scan(samples_file, what = "", quiet = TRUE))
  if (length(barcodes) == 0) {
    stop("Sample file is empty: ", samples_file, call. = FALSE)
  }

  barcodes
}


tcga_participant_id <- function(barcodes) {
  ids <- as.character(barcodes)
  ids[is.na(ids)] <- NA_character_

  usable <- !is.na(ids) & nchar(ids) >= 12
  ids[usable] <- substr(ids[usable], 1, 12)

  ids
}


detect_identifier_column <- function(data_frame) {
  candidates <- c(
    "submitter_id",
    "case_submitter_id",
    "bcr_patient_barcode",
    "patient_id",
    "submitted_id"
  )

  matches <- candidates[candidates %in% names(data_frame)]
  if (length(matches) > 0) {
    return(matches[[1]])
  }

  NA_character_
}


new_profile_result <- function(
  project,
  profile,
  status,
  data = NULL,
  message = NULL,
  query_args = list(),
  sample_file = NA_character_
) {
  structure(
    list(
      project = project,
      profile = profile,
      status = status,
      data = data,
      message = message,
      query_args = query_args,
      sample_file = normalize_optional_path(sample_file)
    ),
    class = c("tcga_profile_result", "list")
  )
}


save_profile_result <- function(result, output) {
  dir.create(dirname(output), recursive = TRUE, showWarnings = FALSE)
  saveRDS(result, output)
}


format_query_args <- function(query_args) {
  fields <- c(
    "data.category",
    "data.type",
    "workflow.type",
    "platform",
    "access"
  )
  present <- fields[fields %in% names(query_args)]

  details <- vapply(
    present,
    function(field) paste0(field, "=", query_args[[field]]),
    character(1)
  )

  paste(details, collapse = ", ")
}


query_profile_data <- function(project, profile, barcodes = NULL) {
  candidates <- profile_query_specs()[[profile]]
  if (is.null(candidates)) {
    stop("Unknown profile: ", profile, call. = FALSE)
  }

  empty_messages <- character()
  error_messages <- character()

  for (candidate in candidates) {
    query_args <- c(list(project = project), candidate)
    if (!is.null(barcodes)) {
      query_args$barcode <- unique(barcodes)
    }

    query <- tryCatch(
      do.call(TCGAbiolinks::GDCquery, query_args),
      error = function(error) error
    )

    if (inherits(query, "error")) {
      error_messages <- c(
        error_messages,
        paste0(format_query_args(query_args), ": ", conditionMessage(query))
      )
      next
    }

    query_results <- tryCatch(
      TCGAbiolinks::getResults(query),
      error = function(error) error
    )

    if (
      !inherits(query_results, "error") &&
        !is.null(query_results) &&
        nrow(query_results) > 0
    ) {
      return(list(
        available = TRUE,
        query = query,
        query_args = query_args,
        message = format_query_args(query_args)
      ))
    }

    empty_messages <- c(
      empty_messages,
      paste0(format_query_args(query_args), ": no files returned")
    )
  }

  if (length(empty_messages) > 0) {
    return(list(
      available = FALSE,
      message = paste(c(empty_messages, error_messages), collapse = "; ")
    ))
  }

  stop(
    "All query attempts failed for ",
    project,
    " / ",
    profile,
    ": ",
    paste(unique(error_messages), collapse = "; "),
    call. = FALSE
  )
}


fetch_clinical_data <- function(project, barcodes = NULL) {
  clinical_data <- tryCatch(
    TCGAbiolinks::GDCquery_clinic(project = project, type = "clinical"),
    error = function(error) error
  )

  if (inherits(clinical_data, "error")) {
    stop(
      "Unable to retrieve clinical data for ",
      project,
      ": ",
      conditionMessage(clinical_data),
      call. = FALSE
    )
  }

  if (is.null(barcodes)) {
    return(clinical_data)
  }

  target_ids <- unique(tcga_participant_id(barcodes))
  target_ids <- target_ids[!is.na(target_ids)]

  id_column <- detect_identifier_column(clinical_data)
  if (is.na(id_column)) {
    stop(
      "Unable to identify a clinical identifier column for sample filtering.",
      call. = FALSE
    )
  }

  clinical_ids <- tcga_participant_id(clinical_data[[id_column]])
  keep_rows <- !is.na(clinical_ids) & clinical_ids %in% target_ids

  clinical_data[keep_rows, , drop = FALSE]
}


download_tcga_profile <- function(
  profile,
  project,
  output,
  samples = NA_character_
) {
  samples <- normalize_optional_path(samples)
  barcodes <- read_sample_barcodes(samples)

  if (identical(profile, "clinical")) {
    clinical_data <- fetch_clinical_data(project, barcodes)
    status <- if (nrow(clinical_data) > 0) "ok" else "unavailable"
    message <- if (identical(status, "ok")) {
      NULL
    } else {
      "No clinical records matched the current project and sample filters."
    }

    save_profile_result(
      new_profile_result(
        project = project,
        profile = profile,
        status = status,
        data = clinical_data,
        message = message,
        sample_file = samples
      ),
      output
    )

    return(invisible(output))
  }

  queried <- query_profile_data(project, profile, barcodes)
  if (!queried$available) {
    save_profile_result(
      new_profile_result(
        project = project,
        profile = profile,
        status = "unavailable",
        message = queried$message,
        sample_file = samples
      ),
      output
    )

    return(invisible(output))
  }

  download_dir <- file.path("data", "procdata", "_downloads", project, profile)
  dir.create(download_dir, recursive = TRUE, showWarnings = FALSE)

  message(
    "Downloading ",
    profile,
    " for ",
    project,
    " with query: ",
    queried$message
  )

  TCGAbiolinks::GDCdownload(
    query = queried$query,
    files.per.chunk = 20,
    directory = download_dir
  )

  prepared_data <- TCGAbiolinks::GDCprepare(
    query = queried$query,
    directory = download_dir
  )

  save_profile_result(
    new_profile_result(
      project = project,
      profile = profile,
      status = "ok",
      data = prepared_data,
      query_args = queried$query_args,
      sample_file = samples
    ),
    output
  )

  invisible(output)
}
