suppressPackageStartupMessages({
  library(MultiAssayExperiment)
  library(S4Vectors)
  library(SummarizedExperiment)
})


normalize_profile_result <- function(path, object, project) {
  if (inherits(object, "tcga_profile_result")) {
    return(object)
  }

  profile <- tools::file_path_sans_ext(basename(path))
  status <- if (is.null(object)) "unavailable" else "ok"
  message <- if (identical(status, "ok")) {
    NULL
  } else {
    "Legacy profile output was NULL."
  }

  new_profile_result(
    project = project,
    profile = profile,
    status = status,
    data = object,
    message = message
  )
}


data_frame_to_matrix <- function(data_object) {
  if (ncol(data_object) < 2) {
    stop(
      "Cannot coerce a single-column data.frame into a matrix-like assay.",
      call. = FALSE
    )
  }

  row_id_candidates <- c(
    "gene_name",
    "gene_id",
    "external_gene_name",
    "gene",
    "Hugo_Symbol",
    "symbol"
  )
  row_id_column <- row_id_candidates[row_id_candidates %in% names(data_object)]

  if (length(row_id_column) == 0) {
    row_id_column <- names(data_object)[[1]]
  } else {
    row_id_column <- row_id_column[[1]]
  }

  matrix_columns <- setdiff(names(data_object), row_id_column)
  matrix_data <- as.matrix(data_object[, matrix_columns, drop = FALSE])
  row_ids <- as.character(data_object[[row_id_column]])
  row_ids[is.na(row_ids) | row_ids == ""] <- paste0("row_", seq_along(row_ids))

  rownames(matrix_data) <- make.unique(row_ids)
  matrix_data
}


mutations_to_matrix <- function(mutation_data) {
  if (!is.data.frame(mutation_data)) {
    stop(
      "SNV input must be a data.frame produced by GDCprepare.",
      call. = FALSE
    )
  }

  required_columns <- c("Hugo_Symbol", "Tumor_Sample_Barcode")
  missing_columns <- setdiff(required_columns, names(mutation_data))
  if (length(missing_columns) > 0) {
    stop(
      "SNV input is missing required columns: ",
      paste(missing_columns, collapse = ", "),
      call. = FALSE
    )
  }

  mutation_data <- mutation_data[
    !is.na(mutation_data$Hugo_Symbol) &
      !is.na(mutation_data$Tumor_Sample_Barcode),
    required_columns,
    drop = FALSE
  ]

  if (nrow(mutation_data) == 0) {
    return(matrix(numeric(0), nrow = 0, ncol = 0))
  }

  as.matrix(xtabs(~ Hugo_Symbol + Tumor_Sample_Barcode, data = mutation_data))
}


prepare_experiment <- function(profile, data_object) {
  if (identical(profile, "simple_nucleotide_variation")) {
    return(mutations_to_matrix(data_object))
  }

  if (
    inherits(data_object, "RangedSummarizedExperiment") ||
      inherits(data_object, "SummarizedExperiment") ||
      is.matrix(data_object)
  ) {
    return(data_object)
  }

  if (is.data.frame(data_object)) {
    return(data_frame_to_matrix(data_object))
  }

  stop(
    "Unsupported experiment type for profile ",
    profile,
    ": ",
    paste(class(data_object), collapse = ", "),
    call. = FALSE
  )
}


subset_experiment_columns <- function(experiment, keep_columns) {
  if (
    inherits(experiment, "RangedSummarizedExperiment") ||
      inherits(experiment, "SummarizedExperiment")
  ) {
    return(experiment[, keep_columns])
  }

  experiment[, keep_columns, drop = FALSE]
}


experiment_sample_ids <- function(experiment) {
  if (
    inherits(experiment, "RangedSummarizedExperiment") ||
      inherits(experiment, "SummarizedExperiment")
  ) {
    experiment_coldata <- SummarizedExperiment::colData(experiment)
    candidate_columns <- c(
      "barcode",
      "submitter_id",
      "sample_submitter_id",
      "aliquot_submitter_id",
      "cases",
      "patient"
    )
    present_columns <- candidate_columns[
      candidate_columns %in% colnames(experiment_coldata)
    ]

    if (length(present_columns) > 0) {
      return(as.character(experiment_coldata[[present_columns[[1]]]]))
    }
  }

  colnames(experiment)
}


build_coldata <- function(primary_ids, clinical_result, project) {
  if (!is.null(clinical_result) && identical(clinical_result$status, "ok")) {
    clinical_data <- as.data.frame(
      clinical_result$data,
      stringsAsFactors = FALSE
    )
  } else {
    clinical_data <- NULL
  }

  if (
    length(primary_ids) == 0 &&
      !is.null(clinical_data) &&
      nrow(clinical_data) > 0
  ) {
    id_column <- detect_identifier_column(clinical_data)
    if (!is.na(id_column)) {
      primary_ids <- unique(tcga_participant_id(clinical_data[[id_column]]))
      primary_ids <- primary_ids[!is.na(primary_ids)]
    }
  }

  if (length(primary_ids) == 0) {
    return(S4Vectors::DataFrame(
      project = character(0),
      row.names = character(0)
    ))
  }

  if (is.null(clinical_data) || nrow(clinical_data) == 0) {
    return(
      S4Vectors::DataFrame(
        project = rep(project, length(primary_ids)),
        row.names = primary_ids
      )
    )
  }

  id_column <- detect_identifier_column(clinical_data)
  if (is.na(id_column)) {
    warning(
      "Unable to identify a clinical identifier column. Building minimal colData."
    )
    return(
      S4Vectors::DataFrame(
        project = rep(project, length(primary_ids)),
        row.names = primary_ids
      )
    )
  }

  clinical_data$primary <- tcga_participant_id(clinical_data[[id_column]])
  clinical_data <- clinical_data[!is.na(clinical_data$primary), , drop = FALSE]
  clinical_data <- clinical_data[
    !duplicated(clinical_data$primary),
    ,
    drop = FALSE
  ]
  clinical_data <- clinical_data[
    match(primary_ids, clinical_data$primary),
    ,
    drop = FALSE
  ]
  rownames(clinical_data) <- primary_ids

  if (!"project" %in% names(clinical_data)) {
    clinical_data$project <- project
  }
  clinical_data$primary <- primary_ids

  S4Vectors::DataFrame(clinical_data, row.names = primary_ids)
}


run_get_mae <- function(snakemake) {
  snakemake@source("check_data.R")
  close_log <- activate_snakemake_log(snakemake)
  on.exit(close_log(), add = TRUE)

  project <- as.character(snakemake@wildcards[["project"]])
  output <- as.character(snakemake@output[["mae"]])
  input_files <- as.character(unlist(snakemake@input))

  if (length(input_files) == 0) {
    stop("get_MAE.R requires at least one profile input file.", call. = FALSE)
  }

  profile_results <- Map(
    function(path, object) normalize_profile_result(path, object, project),
    input_files,
    lapply(input_files, readRDS)
  )

  names(profile_results) <- vapply(
    profile_results,
    `[[`,
    character(1),
    "profile"
  )
  clinical_result <- profile_results[["clinical"]]

  experiments <- list()
  sample_map_rows <- list()
  primary_ids <- character()

  for (profile_name in names(profile_results)) {
    profile_result <- profile_results[[profile_name]]

    if (
      !identical(profile_result$status, "ok") ||
        identical(profile_name, "clinical")
    ) {
      next
    }

    experiment <- prepare_experiment(profile_name, profile_result$data)
    experiment_columns <- colnames(experiment)
    assay_sample_ids <- experiment_sample_ids(experiment)

    if (is.null(experiment_columns) || length(experiment_columns) == 0) {
      next
    }

    if (
      is.null(assay_sample_ids) ||
        length(assay_sample_ids) != length(experiment_columns)
    ) {
      assay_sample_ids <- experiment_columns
    }

    mapped_primary <- tcga_participant_id(assay_sample_ids)
    keep_columns <- !is.na(mapped_primary)

    if (!all(keep_columns)) {
      experiment <- subset_experiment_columns(experiment, keep_columns)
      experiment_columns <- colnames(experiment)
      assay_sample_ids <- assay_sample_ids[keep_columns]
      mapped_primary <- mapped_primary[keep_columns]
    }

    if (length(experiment_columns) == 0) {
      next
    }

    experiments[[profile_name]] <- experiment
    sample_map_rows[[profile_name]] <- S4Vectors::DataFrame(
      assay = rep(profile_name, length(experiment_columns)),
      primary = mapped_primary,
      colname = experiment_columns
    )
    primary_ids <- unique(c(primary_ids, mapped_primary))
  }

  coldata <- build_coldata(primary_ids, clinical_result, project)

  metadata <- list(
    project = project,
    profile_status = lapply(
      profile_results,
      function(result) {
        result[c("status", "message", "query_args", "sample_file")]
      }
    ),
    included_profiles = names(experiments)
  )

  dir.create(dirname(output), recursive = TRUE, showWarnings = FALSE)

  if (length(experiments) == 0) {
    mae <- MultiAssayExperiment(
      colData = coldata,
      metadata = metadata
    )
  } else {
    sample_map <- do.call(rbind, sample_map_rows)
    mae <- MultiAssayExperiment(
      experiments = experiments,
      colData = coldata,
      sampleMap = sample_map,
      metadata = metadata
    )
  }

  saveRDS(mae, output)
}


run_get_mae(snakemake)
