#' Map Phecodes to ICD codes
#'
#' This function takes input from large-scale ICD code data and outputs
#' a file with the corresponding phecodes. The output file is in long
#' format, where each row is a combination of ID and phecode, the first
#' and last date that phecode was recorded for that ID, the total number
#' of times the phecode was recorded for that ID, and whether that ID is
#' considered to use this healthcare system as their "medical home" (having
#' at least five visits over a period of three years). The defaults are
#' designed for the input from the Vanderbilt BioVU system, but all input
#' columns may be defined as arguments.
#'
#' @param input file path to the input file
#' @param output file path to the desired output
#' @param date name of column with entry date
#' @param date_format format of the date column (e.g., "%Y-%m-%d")
#' @param type name of column that denotes ICD code type, as "ICD9CM" and "ICD10CM"
#' @param code name of column with ICD codes
#' @param ID name of ID column
#' @import dplyr
#' @import magrittr
#' @export
phecode_mapping <- function(input, output, date = "ICD_DATE", date_format = "%Y-%m-%d",
                            type = "ICD_TYPE", code = "ICD_CODE", ID = "GRID"){

  # arguments needed: ICD_TYPE, ICD_CODE, ICD_DATE

### setup
`%>%` <- magrittr::`%>%`

### read in input
input <- read.csv(input)

### read in icd-phecode maps

icd9_phecode <- system.file("extdata", "ICD9_to_phecode_V2.csv", package = "phecodeICDmapping")
icd10_phecode <- system.file("extdata", "ICD10_to_phecode_V2.csv", package = "phecodeICDmapping")

### get phenotypes from phecode data
phecode_to_pheno <- system.file("extdata", "phecode_strings_V2.csv", package = "phecodeICDmapping")

### separate ICD9 and ICD10 codes for easier merging
dat_icd9 <- dplyr::filter(input, !!dplyr::sym(type) == "ICD9CM")

### merge icd9 with phecode
dat_icd9_phe <- merge(dat_icd9, icd9_phecode, by.x = code, by.y = "icd9", keep = T)

### filter out icd10
dat_icd10 <- dplyr::filter(input, !!dplyr::sym(type) == "ICD10CM")

### merge icd10 with phecode
dat_icd10_phe <- merge(dat_icd10, icd10_phecode, by.x = code, by.y = "icd10", keep = T)

### bind icd10 and icd9 back together
dat_phecode_all <- rbind(dat_icd9_phe, dat_icd10_phe)

### add in phecode explanations/umbrella terms
alldat <- merge(dat_phecode_all, phecode_to_pheno, by = "phecode")

### group by phenotype and ID, and keep only the first instance
phecode_freq <- alldat %>%
  dplyr::group_by(!!dplyr::sym(ID), phecode) %>%
  dplyr::summarise(n = dplyr::n())

### group by phecode and ID, and extract first and last dates each phecode was entered
alldat2 <- alldat %>%
  dplyr::group_by(!!dplyr::sym(ID), phecode) %>%
  dplyr::summarise(last_date = max(as.Date(!!dplyr::sym(date), date_format)), first_date = min(as.Date(!!dplyr::sym(date), date_format)))

### merge phecode frequency with the rest of the data
alldat3 <- merge(alldat2, phecode_freq, by = c(ID, "phecode"))

##### medical home
### need to find who had more than 5 visits for medical home
number_of_visits_morethan5 <- alldat %>%
  dplyr::group_by(!!dplyr::sym(ID)) %>%
  dplyr::summarise(visits = dplyr::n_distinct(!!dplyr::sym(date))) %>%
  dplyr::filter(visits >=5)

### filter by removing people with less than 5 visits or less than 3 total years in the system
medical_home <- alldat3 %>%
  dplyr::filter(as.Date(last_date, date_format) - as.Date(first_date, date_format) >= 1095) %>%
  dplyr::filter(!!dplyr::sym(ID) %in% number_of_visits_morethan5[[dplyr::sym(ID)]])

### add medical home into main dataset
alldat3$medical_home <- ifelse(alldat3[[dplyr::sym(ID)]] %in% medical_home[[dplyr::sym(ID)]], 1, 0)

### select phecode strings and categories
cols_for_merge <- phecode_to_pheno %>%
  dplyr::select(c("phecode", "phecode_category", "phecode_string"))

### merge phecode strings and categories
alldat4 <- merge(alldat3, cols_for_merge, by = "phecode", keep = F, all = F) # some phecodes have the exact same phecode string....ugh

### rearrange columns and rename for ease of understanding
out_file <- alldat4 %>%
  dplyr::select(c("GRID", "phecode", "phecode_string", "phecode_category", "first_date", "last_date", "n", "medical_home")) %>%
  dplyr::rename("times_recorded" = "n")

### save file
write.csv(out_file, file = output, row.names = F, quote = F)
}
