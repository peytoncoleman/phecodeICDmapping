# phecodeICDmapping
R package to map ICD codes to phecodes

### Installation
Using the devtools package

```
devtools::install_github("peytoncoleman/phecodeICDmapping")
```

### Function
Used to map phecodes onto ICD codes. See ?phecode_mapping for more information.

#### Description
This function takes input from large-scale ICD code data and outputs a file with the corresponding phecodes. The output file is in long format, where each row is a combination of ID and phecode, the first and last date that phecode was recorded for that ID, the total number of times the phecode was recorded for that ID, and whether that ID is considered to use this healthcare system as their "medical home" (having at least five visits over a period of three years). The defaults are designed for the input from the Vanderbilt BioVU system, but all input columns may be defined as arguments.

#### Usage
```
phecode_mapping(
  input,
  output,
  date = "ICD_DATE",
  date_format = "%Y-%m-%d",
  type = "ICD_TYPE",
  code = "ICD_CODE",
  ID = "GRID"
)
```

#### Arguments
`input`	- file path to the input file

`output` - file path to the desired output

`date` - name of column with entry date

`date_format` - format of the date column (e.g., "%Y-%m-%d")

`type` - name of column that denotes ICD code type, as "ICD9CM" and "ICD10CM"

`code` - name of column with ICD codes

`ID` - name of ID column
