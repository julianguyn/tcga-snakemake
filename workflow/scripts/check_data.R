#' Function to check validity of query inputs
#' 
#' TODO:: IMPLEMENT

check_data <- function(project, profile, samples) {


    avail <- TCGAbiolinks:::getProjectSummary(project)$data_categories

}


## would be nice if it can check the platforms and whatnot here too

# check clinical information retrieval:data_categories
information.clinical <- GDCquery_clinic(project = "TCGA-BRCA",type = "clinical") 