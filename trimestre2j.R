install.packages("data.table")
install.packages("readr")
install.packages("tidyverse")
install.packages("readxl")
install.packages("writexl")
install.packages("dplyr")
install.packages("lubridate")
install.packages("foreign")
install.packages("haven")
install.packages("pracma")
install.packages("scales")

library(data.table)
library(readr)
library(tidyverse)
library(readxl)
library(writexl)
library(dplyr)
library(lubridate)
library(foreign)
library(haven)
library(pracma)
library(scales)
library(stringr)

#---

work_directory = "~/Dropbox/BDE/UK_Narrative/Datasets"

original_filename  = "CloyneNarrativeDataset-2.xlsx"
original_sheetname = "TaxData"
original_skiprows  = 0

restoftax_filename  = "RestOfData.xlsx"
restoftax_sheetname = "Sheet1"
restoftax_skiprows  = 2


#----USEFUL FUNCTIONS-----------------------------------------------------------------------------------------------

# C-like printf for formatted printing
printf = function(...) cat(sprintf(...))

# Read excel sheet into a data frame
my_read_excel = function(pathname, sheetname, skiprows) {
  print("-------------------------------------------------------")
  printf("Opening \"%s\"...\n", pathname)
  new_df = read_excel(pathname, sheet=sheetname, skip=skiprows)
  printf("  %d rows, %d columns\n", nrow(new_df), ncol(new_df))
#  print(colnames(new_df))
  new_df   # return value
}


# Write a data frame into an excel sheet
my_write_excel = function(pathname, df) {
  print("-------------------------------------------------------")
  printf("Writing \"%s\"...\n", pathname)
  write_xlsx(df, pathname)
}


# Replace whitespaces in column names with underscores, brackets removed
clean_column_names = function(df) {
  colnames(df) = gsub("\\s", "_", colnames(df))      # replace whitespace with _
  colnames(df) = gsub("\\(|\\)", "", colnames(df))   # replace () with nothing
  df   # return this
}


# Replace multiple copies of \r\n with space
fix_nonprinting_chars = function(df_col) {
  df_col = str_replace_all(df_col, c("\\r\\n"=" "))
}


# Fix spelling mistakes and terms
fix_spelling = function(df) {
  df = str_replace_all(df, c("Aggreagtes"="Aggregates"))
  df = str_replace_all(df, c("RESERVE"="REVERSE"))
  df = str_replace_all(df, c("Incresae"="Increase"))
  df = str_replace_all(df, c("aIIowance"="allowance"))
  df = str_replace_all(df, c("rnortgage"="mortgage"))
  df = str_replace_all(df, c("Withdrawl"="Withdrawal"))
  df = str_replace_all(df, c("deducation"="deduction"))
  df = str_replace_all(df, c("chariable"="charitable"))
  df = str_replace_all(df, c("Authroised"="Authorised"))
  df = str_replace_all(df, c("EIS"="enterprise investment scheme"))
  df = str_replace_all(df, c("VCT"="venture capital trust"))
  df = str_replace_all(df, c("Increase PA"="Increase personal allowance"))
  df = str_replace_all(df, c("Research and development"="r&d"))
  df = str_replace_all(df, c("small and medium sized enterprise"="SME"))
  df = str_replace_all(df, c("first year capital allowance"="FYC"))
  df = str_replace_all(df, c("national insurance contribution"="nic"))
  df = str_replace_all(df, c("Controlled Foreign Companies"="cfcs"))
  df = str_replace_all(df, c("Individual Savings Account"="isa"))
}



# Combine the Tax_Type and Sub_Type strings, Sub_Type may be NA, which paste()
# turns into "NA", then have to remove a trailing space
combine_two_columns = function(df)  {
  temp_df = lapply(df$Sub_Type, function(x) {x[is.na(x)] = ""; x})  # return NA as ""
  trimws(paste(df$Tax_Type, temp_df, sep=" "), which = c("right"))
}


# Return the unique values of a column as a vector
get_column_unique = function(df, col_name) {
  unique_vector = unlist(unique(df[col_name]))       # unique list to vector
  unique_vector = na.omit(unique_vector)             # remove NAs
  unname(unique_vector)                              # remove meaningless column names
}


# Return the unique values of a column  as a vector - case-insensitive
get_column_unique_nocase = function(df) {
  cleaned = apply(na.omit(df), MARGIN=2, FUN=tolower)
  unique_nocase_vector = unlist(unique(data.frame(fixed = cleaned)))
  unname(unique_nocase_vector)                       # remove meaningless column names
}


find_all_unique_pairs = function(pairs_df) {
  unique_list_df = data.frame("tax" = NULL, "description" = NULL)
  dscr_col_name = names(pairs_df)[1]
  tax_col_name  = names(pairs_df)[2]
  
  # Make lower case for future comparions
  pairs_df[1] = apply(pairs_df[1], MARGIN=2, FUN=tolower)
  pairs_df[2] = apply(pairs_df[2], MARGIN=2, FUN=tolower)
  
  # Get unique tax names
  unique_taxes = get_column_unique_nocase(pairs_df[tax_col_name])
  for (tax_name in unique_taxes) {
    indices = which(pairs_df[tax_col_name] == tax_name)
    data_subset = pairs_df[indices,]
    unique_descriptions = get_column_unique_nocase(data_subset[dscr_col_name])
    for (description in unique_descriptions) {
      unique_list_df = rbind(unique_list_df, c(tax_name, description))
    }
  }
  colnames(unique_list_df) = c("tax", "description")
  unique_list_df   # return this
}


find_keywords2 = function(df) {
  df_lowercase = tolower(df)
  keywords = strsplit(df_lowercase[[2]], "\\W")
  if(!is.na(df_lowercase[[1]])) {
    description = fix_description(df_lowercase[[1]])
    keywords = append(keywords, strsplit(description, "\\W"))
  }
  unlist(keywords)   # return as vector
}


find_keywords3 = function(df) {
  df_lowercase = tolower(df)
  keywords = strsplit(df_lowercase[[2]], "\\W")
  if(!is.na(df_lowercase[[3]])) {
    keywords = append(keywords, strsplit(df_lowercase[[3]], "\\W"))
  }
  if(!is.na(df_lowercase[[1]])) {
    description = fix_description(df_lowercase[[1]])
    keywords = append(keywords, strsplit(description, "\\W"))
  }
  unlist(keywords)   # return as vector
}


fix_description = function(df_col) {
  fixed = gsub('[^[:alnum:]]+',' ', df_col)
  fixed = str_replace_all(fixed, "sur.tax", "surtax")
  fixed = str_replace_all(fixed, "per.cent", "percent")
#  fixed = str_replace_all(fixed, "ved", "vehicle excise duty")
  
  small_str_list = c("a", "in", "at", "of", "on", "to", "is", "the", "and", "for", "that", "from", "which")
  for (small_str in small_str_list)  {
    search_str = sprintf("\\b%s\\b", small_str)
    fixed = str_replace_all(fixed, search_str, "")
  }
#  fixed = str_replace_all(fixed, "s\\b", "")
#  fixed = str_replace_all(fixed, "\\b(.+)ed\\b", "\\1")
  fixed = str_replace_all(fixed, " +", " ")
  fixed
}


# Make new df with the Tax and Descriptions columns, rename columns, lower case
get_2cols_fix = function(df, col_name_list, new_name_list) {
  fix_df = df[,col_name_list]
  colnames(fix_df)[which(names(fix_df) == col_name_list[1])] = new_name_list[1]
  colnames(fix_df)[which(names(fix_df) == col_name_list[2])] = new_name_list[2]
  fix_df[[1]] = tolower(fix_df[[1]])  # need double sq brackets cos tibble nor df
  fix_df[[2]] = tolower(fix_df[[2]])
  fix_df
}


# Make new df with the Year, Tax and Descriptions columns, rename columns, lower case
get_3cols_fix = function(df, col_name_list, new_name_list) {
  fix_df = data.frame(year=integer(), tax=character(), description=character())
  fix_df = df[,col_name_list]
  colnames(fix_df)[which(names(fix_df) == col_name_list[1])] = new_name_list[1]
  colnames(fix_df)[which(names(fix_df) == col_name_list[2])] = new_name_list[2]
  colnames(fix_df)[which(names(fix_df) == col_name_list[3])] = new_name_list[3]
  fix_df[[2]] = tolower(fix_df[[2]])  # need double sq brackets cos tibble not df
  fix_df[[3]] = tolower(fix_df[[3]])
  fix_df
}


# This does some re-ordering, may not want this so make a parallel function that just
# converts into this format.
find_unique_tax_descr_by_year = function(df_3cols) {
  summary_df = data.frame(year=integer(), tax=character(), description=character())
  for (year in min(df_3cols$Year):max(df_3cols$Year)) {
    df_3cols_year = subset(df_3cols, Year==year)
    unique_tax_types = get_column_unique(df_3cols_year, "Tax")
    for (tax in sort(unique_tax_types)) {
      tax_type_subset = subset(df_3cols_year, Tax == tax)
      unique_description = get_column_unique(tax_type_subset, "Description")
      for (description in sort(unique_description)) {
        summary_df[nrow(summary_df)+1,] = c(year, tax, description)
      }
    }
  }
# gets converted to char, turn back into integer
  summary_df$year = as.integer(summary_df$year)
  summary_df
}

# This replacement for find_unique_tax_descr_by_year() just converts into this format -
# really just remove capitalization of column names. This can be dispensed with.
find_unique_tax_descr_by_year2 = function(df_3cols) {
  summary_df = data.frame(year=integer(), tax=character(), description=character())
  for (this_row in 1:nrow(df_3cols))  {
    summary_df[nrow(summary_df)+1,] = c(df_3cols$Year[this_row], df_3cols$Tax[this_row], df_3cols$Description[this_row])
  }
  # gets converted to char, turn back into integer
  summary_df$year = as.integer(summary_df$year)
  summary_df
}


# Use stringdist library to find the most similar entries
# Combine the two columns for each table into 1 string for the comparison
match_rows = function(table1, table2) {
  indicies1 = vector()
  indicies2 = vector()
  # We want to find a match in table2 for each table1 entry, not the other way around
  for (index1 in 1:nrow(table1)) {
    table1_entry = tolower(paste(table1[index1,1], table1[index1,2]))
    for (index2 in 1:nrow(table2)) {
      table2_entry = tolower(paste(table2[index2,1], table2[index2,2]))
      the_dist = stringdist(table1_entry, table2_entry)
      printf("Dist: %4d   Entry1 = %s; Entry2 = %s\n", the_dist, table1_entry, table2_entry)
    }
    indicies1 = append(indicies1, index)
    indicies2 = append(indicies2, index)
  }
  table1_entries = vector()
  for (index in 1:nrow(table1)) {
    this_entry = tolower(paste(table1[index,1], table1[index,2]))
    this_entry = fix_description(this_entry)
    table1_entries = append(table1_entries, this_entry)
  }
  table2_entries = vector()
  for (index in 1:nrow(table2)) {
    this_entry = tolower(paste(table2[index,1], table2[index,2]))
    this_entry = fix_description(this_entry)
    table2_entries = append(table2_entries, this_entry)
  }
  the_dist = stringdistmatrix(table1_entries, table2_entries, method = 'soundex')
  print(the_dist)
  print(max.col(-the_dist))
  #  return(c(1, 4))
  print("Indicies1 = ", indicies1)
  return(list(indicies1, indicies2))
}


# this_year = 1975
# rest_this_year = subset(restoftax_df, Year == this_year, select=c("Tax_head",   "Measure_description"))
# orig_this_year = subset(original_df,  Year == this_year, select=c("TaxSubType", "Description_as_reported_in_FSBR"))
# printf("TestOfData rows: %d    Original rows: %d\n", nrow(rest_this_year), nrow(orig_this_year))
# matched_row_indices_list = match_rows(rest_this_year, orig_this_year)
# rest_matched_indices = matched_row_indices_list[[1]]
# orig_matched_indices = matched_row_indices_list[[2]]
# rest_matched = rest_this_year[rest_matched_indices, ]
# orig_matched = orig_this_year[orig_matched_indices, ]
# print_sbs_table(rest_matched, orig_matched)


print_sbs_table = function(table1, table2) {
  max_rows = max(nrow(table1), nrow(table2))
  for (index in 1:max_rows) {
    if (index<=nrow(table1)) {
      table1_text = sprintf("%-20s  %-40s", table1[index,1], table1[index,2])
    }
    else {
      table1_text = sprintf("%-20s  %-40s", " ", " ")
    }
    if (index<=nrow(orig_this_year)) {
      table2_text = sprintf("%-20s  %-40s", table2[index,1], table2[index,2])
    }
    else {
      table2_text = sprintf("%-20s  %-40s", " ", " ")
    }
    printf("%4d %4d: %s  | %s\n", this_year, index, table1_text, table2_text)
  }
}


# for (index in 1:nrow(original_df))  {
#   subset_col_indices = which(names(original_df) %in% c("Description_as_reported_in_FSBR", "Tax_Type", "Sub_Type"))
#   subset_df = original_df[index, subset_col_indices]
#   keywords = find_keywords3(subset_df)
#   printf("Keywords: ")
#   for (kw in 1:(length(keywords)-1))  {
#     printf("%s_", keywords[kw])
#   }
#   printf("%s\n", keywords[length(keywords)])
# }

 
# for (index in 1:nrow(restoftax_df))  {
#   subset_col_indices = which(names(restoftax_df) %in% c("Measure description", "Tax head"))
#   subset_df = restoftax_df[index, subset_col_indices]
#   keywords = find_keywords2(subset_df)
#   printf("Keywords: ")
#   for (kw in 1:(length(keywords)-1))  {
#     printf("%s_", keywords[kw])
#   }
#   printf("%s\n", keywords[length(keywords)])
# }



# Fixing the 'REVERSE' entries so that tax amount is the opposite for everything,
# thus covering any sporadic change I've made
fix_reverse = function(tax_df, classification_df) {
  for( i in 1:nrow(tax_df) ) {
    if ( !is.na(classification_df[i,stop]) ) {   # stop column
      opposite = (tax_df[i,])*(-1)
      tax_df[i+1,] = opposite
      print(c("Index of the REVERSE is   ", i+1))
    }
  }
}


#----DATA IMPORTING AND CLEANING------------------------------------------------------------------------------------

# First import, including all info

printf("Importing original Excel file: %s\n", original_filename)
printf("Sheet name imported is: %s\n", original_sheetname)
printf("Working directory is: %s\n", work_directory)
printf("Ignore messages: Expecting numeric in A123 / R123C1: got '*'\n")
original_pathname = paste(work_directory, original_filename, sep="/")
original_df = my_read_excel(original_pathname, sheet=original_sheetname, skip=original_skiprows)
print("Ignore messages: Expecting numeric in A123 / R123C1: got '*'\n")

printf("Importing RestOfTax Excel file: %s\n", restoftax_filename)
printf("Sheet name imported is: %s\n", restoftax_sheetname)
printf("Working directory is: %s\n", work_directory)
restoftax_pathname = paste(work_directory, restoftax_filename, sep="/")
restoftax_df  = my_read_excel(restoftax_pathname, sheet=restoftax_sheetname, skip=restoftax_skiprows)

# Replace spaces in column names with underscore to allow better column addressing
original_df  = clean_column_names(original_df)
restoftax_df = clean_column_names(restoftax_df)

# Check date ranges in both data frames
# Original date already in dttm format
original_date_range = range(original_df$Date, na.rm = TRUE)
printf("Original date range: %s - %s\n", original_date_range[1], original_date_range[2])

# Fix non-printing characters in this column
original_df$Description_as_reported_in_FSBR = fix_nonprinting_chars(original_df$Description_as_reported_in_FSBR)

# Fix spelling mistakes that affect identifying identical tax types and descriptions
original_df$Tax_Type = fix_spelling(original_df$Tax_Type)
original_df$Description_as_reported_in_FSBR = fix_spelling(original_df$Description_as_reported_in_FSBR)
restoftax_df$Measure_description = fix_spelling(restoftax_df$Measure_description)

# Combine the Tax Type and Sub Type columns into a new column
original_df$TaxSubType = combine_two_columns(original_df)

# Pull out the year as integer, save to new Year column, find ranges
original_df$Year = as.integer(format(original_df$Date, "%Y"))
original_date_range = range(original_df$Year)

restoftax_df$Year = as.integer(apply(restoftax_df["Event"], 2, str_extract, pattern="\\b(19|20)\\d{2}\\b"))
restoftax_date_range = range(restoftax_df$Year)

printf("Original    date range:      %s - %s\n", original_date_range[1],  original_date_range[2])
printf("RestOfTax   date range:      %s - %s\n", restoftax_date_range[1], restoftax_date_range[2])

# Limit all work to the years that overlap between RESTOF table AND ORIGINAL table

start_year = restoftax_date_range[1]
final_year = original_date_range[2]

# Get subset table for the overlapping years
original_ovlp_df  = subset(original_df,  Year >= start_year & Year <= final_year)
restoftax_ovlp_df = subset(restoftax_df, Year >= start_year & Year <= final_year)

printf("Overlapping date range:      %s - %s\n", start_year, final_year)
printf("Original  table %d rows; overlaps %d rows\n", nrow(original_df),  nrow(original_ovlp_df))
printf("RestOfTax table %d rows; overlaps %d rows\n", nrow(restoftax_df), nrow(restoftax_ovlp_df))

# Ali says to stop at 2003
final_year = 2003

printf("======================================================\n")
printf("=========   N O T E - we will stop at %d   =========\n", final_year)
printf("======================================================\n")

# Get updated subset table for the focus years
original_ovlp_df  = subset(original_df,  Year >= start_year & Year <= final_year)
restoftax_ovlp_df = subset(restoftax_df, Year >= start_year & Year <= final_year)

printf("Overlapping date range:      %s - %s\n", start_year, final_year)
printf("Original  table %d rows; overlaps %d rows\n", nrow(original_df),  nrow(original_ovlp_df))
printf("RestOfTax table %d rows; overlaps %d rows\n", nrow(restoftax_df), nrow(restoftax_ovlp_df))


#----BUILD MATCHES BETWEEN RESTOFTAX TABLE AND ORIGIAL TABLE (OVERLAPS ONLY)----------------------------------------

# Get Tax and Description columns, change names to the same in each case: Tax and Description
# Also set to lower case because of some variability in capitalization

original_3cols  = get_3cols_fix(original_ovlp_df,  c("Year", "TaxSubType", "Description_as_reported_in_FSBR"), c("Year", "Tax", "Description"))
restoftax_3cols = get_3cols_fix(restoftax_ovlp_df, c("Year", "Tax_head",   "Measure_description"),             c("Year", "Tax", "Description"))

# For each year, find the unique tax and descriptions in each of the two tables
# NOTE: using find_unique_tax_descr_by_year() re-orders rows, try without

restoftax_summary = find_unique_tax_descr_by_year2(restoftax_3cols)
original_summary  = find_unique_tax_descr_by_year2(original_3cols)

# Do some tidy-ups: remove tax, taxes, duty, levy; vehicle excise duty -> ved; onshore ct -> ct
# Only for restoftax, the other is too mixed up

restoftax_summary$tax = tidy_up_tax_names_rest(restoftax_summary$tax)
original_summary$tax  = tidy_up_tax_names_orig(original_summary$tax)

# Build output dataframes - start empty, add rows as needed
# The restoftax and original dfs will have the same number of rows and will be merged for output
# Im also making a table of the 3-column summaries for troubleshooting

restoftax_out = restoftax_df[FALSE,]
original_out  = original_df[FALSE,]
restoftax_summary_out = restoftax_summary[FALSE,]
original_summary_out  = original_summary[FALSE,]
out_index = 0
match_table = create_match_table()

# Cycle through years looking for original row(s) corresponding to restoftax rows (starts 1970, ends 2003)

#for (this_year in min(restoftax_summary$year):max(restoftax_summary$year)) {
for (this_year in 1970:2000) {
  restoftax_year = subset(restoftax_ovlp_df, Year==this_year)    # Data to write from here
  original_year  = subset(original_ovlp_df,  Year==this_year)    # Data to write from here
  restoftax_summary_year = subset(restoftax_summary, year==this_year)  # Data to match
  original_summary_year  = subset(original_summary,  year==this_year)  # Data to match
  printf("Year %d: counts = %4d   %4d\n", this_year, nrow(restoftax_summary_year), nrow(original_summary_year))

  for (index in 1:nrow(restoftax_summary_year)) {
    tax = restoftax_summary_year$tax[index]
    description = restoftax_summary_year$description[index]
    printf("%d, index %d: %20s, %40s\n", this_year, index, substring(tax,1,15), substring(description, 1, 40))
  }
  # For each restoftax entry, look for matching entry(s) in original - may be none
  for (index in 1:nrow(restoftax_summary_year)) {
    tax = restoftax_summary_year$tax[index]
    description = restoftax_summary_year$description[index]
    printf("%d, index %d: %20s, %40s", this_year, index, substring(tax,1,15), substring(description, 1, 40))
    orig_match_indices = find_match(tax, description, original_summary_year)
    if (length(orig_match_indices) == 0) {
      printf(" - no match\n")
      out_index = out_index + 1
      restoftax_out[out_index,] = restoftax_year[index,]
      original_out[out_index,]  = NA
      restoftax_summary_out[out_index,] = restoftax_summary_year[index,]
      original_summary_out[out_index,]  = NA
    }
    else {
      printf(" - %d matches\n", length(orig_match_indices))
      orig_summary_match = original_summary_year[orig_match_indices,]
      orig_match = original_year[orig_match_indices,]
      print_3cols(orig_summary_match)
      for (this_row in 1:nrow(orig_match)) {
        out_index = out_index + 1
        restoftax_out[out_index,] = restoftax_year[index,]
        original_out[out_index,]  = orig_match[this_row,]
        restoftax_summary_out[out_index,] = restoftax_summary_year[index,]
        original_summary_out[out_index,]  = orig_summary_match[this_row,]
      }
    }
  }
}

# Join the two data frames side-by-side (should have same number of rows)

combined_df = cbind(restoftax_out, original_out)
combined_summary_df = cbind(restoftax_summary_out, original_summary_out)

# Write output to Excel file

my_write_excel("test_ouput.xlsx", combined_df)
my_write_excel("test_summary_ouput.xlsx", combined_summary_df)


# Given the tax and description strings from the restoftax line, check they are in the
# match_table and then in the target_df (original)

find_match = function(tax, description, target_df) {
  printf("\n***** find_match for: \"%s\",\"%s\"\n\n", tax, description)
  target_tax_indicies = vector()   # if there is no match, this will remain empty
# First check that there are 1 or more entries in the match table and target_df for the "tax"
  match_tax_indices = which(match_table$tax_name==tax)
  if(length(match_tax_indices) == 0)  {
    printf("No entry in match table for tax \"%s\"\n", tax)
    return(target_tax_indicies)
  }
  target_tax_indicies = which(grepl(tax, target_df$tax, ignore.case=TRUE))
  if(length(target_tax_indicies) == 0)  {
    printf("No entry in target table for tax \"%s\"\n", tax)
    return(target_tax_indicies)
  }

# Second check that there are entries in the match table for the description
  printf("Finding entries in match_tax\n")
  match_tax_subset = match_table[match_tax_indices,]   # subset of matching tax entries to use for matching descriptions
  # printf("====================\n")
  # print(match_tax_subset)
  # printf("Search for these in \"%s\"\n", description)
  # printf("====================\n")
  match_subset_indicies = vector()
  for (match_index in 1:nrow(match_tax_subset))  {
    match_description = match_tax_subset$description_names[match_index]
#    printf("match_description is \"%s\"\n", match_description)
    match_subset_indicies = find_matching_descriptions(match_description, c(description))
    if (length(match_subset_indicies) > 0)  {
      match_subset_indicies = match_index
      break
    }
  }
  if (length(match_subset_indicies) == 0)  {
    # SHOULD DO SOMETHING HERE - Nothing in table matches
  }
  match_subset = match_tax_subset[match_subset_indicies,]
  printf("\nMatched subset from match table:\n")
  print_2cols(match_subset)

# Third, check the target table for matches with the description

  target_tax_subset = target_df[target_tax_indicies, ]   # subset of target tax entries to match to
  target_subset_indicies = find_matching_descriptions(match_subset$description_names, target_tax_subset$description)

  printf("\nMatched subset from target table:\n")
  print_2cols(target_tax_subset[target_subset_indicies,])
  
  # Re-index for target_df
  target_description_indicies = vector()
  for (item in target_subset_indicies)  {
    target_index = target_tax_indicies[item]
    target_description_indicies = append(target_description_indicies, target_index)
  }
  target_description_indicies
}


find_matching_descriptions = function(source_words, target_strings)  {
#  printf("Match table has %d rows to match; target has %d rows to match\n", length(source_words), length(target_strings))

  target_indicies = vector()   # if any matches, these will be returned
  for (match_row in 1:length(source_words))  {
    # for each row in the tax-subset of the match subset table
    for (target_row in 1:length(target_strings)) {
      # check against each row of the target subset table
      match_flag = TRUE
     # printf(
     #   "Matching words in \"%s\" to \"%s\":\n",
     #   source_words[match_row],
     #   target_strings[target_row]
     # )
      word_list = strsplit(source_words[match_row], split = ",")
      if(length(word_list) > 0) {  # if no words to match, assume a match
        for (word in unlist(word_list)) {
          # test all words present
          if (!grepl(word, target_strings[target_row], ignore.case = TRUE)) {
            # printf("... matching word \"%s\"...not matched\n", word)
            match_flag = FALSE
            break
          }
          # printf("... matching word \"%s\"...matched\n", word)
        }
      }
      if (match_flag == TRUE)  {
        # all matched, save this row index
        target_indicies = append(target_indicies, target_row)
        # printf(" Found a match! 1. search: \"%s\"\n", source_words[match_row])
        # printf(" Found a match! 2. match:  \"%s\"\n", target_strings[target_row])
        # printf("Target index is %d. List of indices saved is: ", target_row)
        # print(target_indicies)
      }
      else {
#        printf(" Not matched\n")
      }
    }
    if(length(target_indicies) > 0) {  # found 1 or more matches in both tax and descriptions
      break;    # so stop here
    }
  }
# Return indices where both taxes and descriptions match
  # printf("Matched target table indices are: ")
  # print(target_indicies)

  target_indicies
}


#   match_indicies_description1 = vector()
#   match_indicies_description2 = vector()
#   if(grepl('allowance', description, ignore.case ="True")) {
#     match_indicies_description1 = which(grepl('allowance', target_df$description, ignore.case=TRUE), target_df)
#     printf("allowance - %d matches\n", length(match_indicies_description1))
#     if(grepl('child', description, ignore.case ="True")) {
#       match_indicies_description2 = which(grepl('child', target_df$description, ignore.case=TRUE), target_df)
#       printf("child - %d matches\n", length(match_indicies_description2))
#     }
#   }
#   match_indicies = intersect(match_indicies_tax, intersect(match_indicies_description1, match_indicies_description2))
#   match_indicies
# }

# 1993 in two parts - how to deal with this
# Order is important - stops at the first match
create_match_table = function() {
  match_table = data.frame(tax_name = character(), description_names = character())
  index = 0

  index = index + 1
  match_table[index,] = c("income", "allowance,child")
  index = index + 1
  match_table[index,] = c("income", "allowance,elder")
  index = index + 1
  match_table[index,] = c("income", "allowance, age")
  index = index + 1
  match_table[index,] = c("income", "allowance,change,marri")
  index = index + 1
  match_table[index,] = c("income", "allowance,increase,marri")
  index = index + 1
  match_table[index,] = c("income", "married,couple,allowance")
  index = index + 1
  match_table[index,] = c("income", "all-employee share plan")
  index = index + 1
  match_table[index,] = c("income", "abolition of withholding tax")
  index = index + 1
  match_table[index,] = c("income", "enterprise management incentives")
  index = index + 1
  match_table[index,] = c("income", "plant,machinery")
  index = index + 1
  match_table[index,] = c("income", "married,single")
  index = index + 1
  match_table[index,] = c("income", "basic,higher,rate")
  index = index + 1
  match_table[index,] = c("income", "increase,basic,rate")
  index = index + 1
  match_table[index,] = c("income", "changes,higher,threshold")
  index = index + 1
  match_table[index,] = c("income", "increase,higher,threshold")
  index = index + 1
  match_table[index,] = c("income", "investment,income,surcharge,threshold")
  index = index + 1
  match_table[index,] = c("income", "introduction,children,tax credit")
  index = index + 1
  match_table[index,] = c("income", "countering avoidance in provision of personal services")
  index = index + 1
  match_table[index,] = c("income", "action on offshore trusts")
  index = index + 1
  match_table[index,] = c("income", "investment,income,threshold")
  index = index + 1
  match_table[index,] = c("income", "introduction,lower,rate")
  index = index + 1
  match_table[index,] = c("income", "abolition of vocational training relief")
  index = index + 1
  match_table[index,] = c("income", "new 10,rate from april,99")
  index = index + 1
  match_table[index,] = c("income", "mortgage,interest")
  index = index + 1
  match_table[index,] = c("income", "relief,interest")
  index = index + 1
  match_table[index,] = c("income", "relief,profit")
  index = index + 1
  match_table[index,] = c("income", "insurance,life")
  index = index + 1
  match_table[index,] = c("income", "assurance,life")
  index = index + 1
  match_table[index,] = c("income", "insurance,reserve")
  index = index + 1
  match_table[index,] = c("income", "insurance,medical")
  index = index + 1
  match_table[index,] = c("income", "insurance,premium")
  index = index + 1
  match_table[index,] = c("income", "insurance,national")
  index = index + 1
  match_table[index,] = c("income", "retirement,annuity,relief")
  index = index + 1
  match_table[index,] = c("income", "fringe")
  index = index + 1
  match_table[index,] = c("income", "exten,band")
  index = index + 1
  match_table[index,] = c("income", "change,band")
  index = index + 1
  match_table[index,] = c("income", "lower rate band")
  index = index + 1
  match_table[index,] = c("income", "reduc,rate")
  index = index + 1
  match_table[index,] = c("income", "leased,car")
  index = index + 1
  match_table[index,] = c("income", "abolition,rate")
  index = index + 1
  match_table[index,] = c("income", "stock,deferral,recovery")
  index = index + 1
  match_table[index,] = c("income", "capital,allowances,leasing")
  index = index + 1
  match_table[index,] = c("income", "business,start-up,scheme")
  index = index + 1
  match_table[index,] = c("income", "other,direct,tax")
  index = index + 1
  match_table[index,] = c("income", "stock,relief")
  index = index + 1
  match_table[index,] = c("income", "isa ,limits")
  index = index + 1
  match_table[index,] = c("income", "construction industry scheme")
  index = index + 1
  match_table[index,] = c("income", "visiting,sports")
  index = index + 1
  match_table[index,] = c("income", "rules,pension,fund,surplus")
  index = index + 1
  match_table[index,] = c("income", "abolish payable tax credits,pension schemes")
  index = index + 1
  match_table[index,] = c("income", "profit,related,pay")
  index = index + 1
  match_table[index,] = c("income", "abolition,tax,relief,home")
  index = index + 1
  match_table[index,] = c("income", "abolition,tax,relief,non-charitable,covenant")
  index = index + 1
  match_table[index,] = c("income", "car,benefit,scale")
  index = index + 1
  match_table[index,] = c("income", "rent factoring")
  index = index + 1
  match_table[index,] = c("income", "schedule e")
  index = index + 1
  match_table[index,] = c("income", "life,assurance,companies")
  index = index + 1
  match_table[index,] = c("income", "revised,tax,regime,construction,buildings,land")
  index = index + 1
  match_table[index,] = c("income", "land,property,threshold")
  index = index + 1
  match_table[index,] = c("income", "tessa")
  index = index + 1
  match_table[index,] = c("income", "composite rate,aboli")
  index = index + 1
  match_table[index,] = c("income", "it ,allowances change")
  index = index + 1
  match_table[index,] = c("income", "it ,basic rate limit raised")
  index = index + 1
  match_table[index,] = c("income", "quarterly,paye,small")
  index = index + 1
  match_table[index,] = c("income", "quarterly,paye,payment")
  index = index + 1
  match_table[index,] = c("income", "20,rate")
  index = index + 1
  match_table[index,] = c("income", "20,band,widened")
  index = index + 1
  match_table[index,] = c("income", "tax,savings,cut,20")
  index = index + 1
  match_table[index,] = c("income", "company,car")
  index = index + 1
  match_table[index,] = c("income", "incapacity,benefit")
  index = index + 1
  match_table[index,] = c("income", "employers ni rate cut")
  index = index + 1
  match_table[index,] = c("income", "relocation")
  index = index + 1
  match_table[index,] = c("income", "paye, ni ,avoidance")
  index = index + 1
  match_table[index,] = c("income", "enterprise investment scheme")
  index = index + 1
  match_table[index,] = c("income", "venture capital trusts")
  index = index + 1
  match_table[index,] = c("income", "capital allowance,smes")
  index = index + 1
  match_table[index,] = c("income", "40,fycs,smes")
  index = index + 1
  match_table[index,] = c("income", "100,fycs,smes")
  index = index + 1
  match_table[index,] = c("income", "wftc")
  index = index + 1
  match_table[index,] = c("income", "increase ctc")
  index = index + 1
  match_table[index,] = c("income", "personal allowance")
  index = index + 1
  match_table[index,] = c("income", "allowance")   # this is very general, put it last of "income"s
  index = index + 1
  match_table[index,] = c("income", "")
  index = index + 1
  match_table[index,] = c("inheritance", "surviving,spouse")
  index = index + 1
  match_table[index,] = c("inheritance", "abolition,lifetime,charge")
  index = index + 1
  match_table[index,] = c("inheritance", "")
  index = index + 1
  match_table[index,] = c("vat", "residential conversions")
  index = index + 1
  match_table[index,] = c("vat", "higher,rate")
  index = index + 1
  match_table[index,] = c("vat", "higher,increase")
  index = index + 1
  match_table[index,] = c("vat", "higher,reduc")
  index = index + 1
  match_table[index,] = c("vat", "bad debt,relief")
  index = index + 1
  match_table[index,] = c("vat", "enlarging,exemption,financing")
  index = index + 1
  match_table[index,] = c("vat", "registration")
  index = index + 1
  match_table[index,] = c("vat", "petrol")
  index = index + 1
  match_table[index,] = c("vat", "withdrawal,postponed,accounting,import")
  index = index + 1
  match_table[index,] = c("vat", "alterations,coverage")
  index = index + 1
  match_table[index,] = c("vat", "deduction,input,tax,exempt,trader")
  index = index + 1
  match_table[index,] = c("vat", "rate increase,17.5")
  index = index + 1
  match_table[index,] = c("vat", "payment,on account")
  index = index + 1
  match_table[index,] = c("vat", "domestic fuel")
  index = index + 1
  match_table[index,] = c("vat", "reform,vat penalties")
  index = index + 1
  match_table[index,] = c("vat", "business,car")
  index = index + 1
  match_table[index,] = c("vat", "second,hand,goods")
  index = index + 1
  match_table[index,] = c("vat", "land,property")
  index = index + 1
  match_table[index,] = c("vat", "threshold")
  index = index + 1
  match_table[index,] = c("vat", "")
  index = index + 1
  match_table[index,] = c("ct", "1,cut,main,rate")
  index = index + 1
  match_table[index,] = c("ct", "1,cut,rate")
  index = index + 1
  match_table[index,] = c("ct", "1,cut")
  index = index + 1
  match_table[index,] = c("ct", "cut,small,rate")
  index = index + 1
  match_table[index,] = c("ct", "reduce main,31")
  index = index + 1
  match_table[index,] = c("ct", "reduction,small,compan,rate,increase,limit")
  index = index + 1
  match_table[index,] = c("ct", "insurance equalisation reserves,relief")
  index = index + 1
  match_table[index,] = c("ct", "insurance,reserves")
  index = index + 1
  match_table[index,] = c("ct", "corporate venturing scheme")
  index = index + 1
  match_table[index,] = c("ct", "cfc tightening")
  index = index + 1
  match_table[index,] = c("ct", "r&d,credit")
  index = index + 1
  match_table[index,] = c("ct", "transfer pricing")
  index = index + 1
  match_table[index,] = c("ct", "limiting foreign tax relief")
  index = index + 1
  match_table[index,] = c("ct", "decrease,dividend")
  index = index + 1
  match_table[index,] = c("ct", "plant,machinery")
  index = index + 1
  match_table[index,] = c("ct", "group,relief")
  index = index + 1
  match_table[index,] = c("ct", "group,rules")
  index = index + 1
  match_table[index,] = c("ct", "stock,relief")
  index = index + 1
  match_table[index,] = c("ct", "cfcs")
  index = index + 1
  match_table[index,] = c("ct", "payments")
  index = index + 1
  match_table[index,] = c("ct", "capital,gains")
  index = index + 1
  match_table[index,] = c("ct", "stock")
  index = index + 1
  match_table[index,] = c("ct", "leased,car")
  index = index + 1
  match_table[index,] = c("ct", "capital,allowances,leasing")
  index = index + 1
  match_table[index,] = c("ct", "tax,rate")
  index = index + 1
  match_table[index,] = c("ct", "act reduced")
  index = index + 1
  match_table[index,] = c("ct", "reduc,rate, act")
  index = index + 1
  match_table[index,] = c("ct", "long life assets")
  index = index + 1
  match_table[index,] = c("ct", "harmonisation,payment,date")
  index = index + 1
  match_table[index,] = c("ct", "taxation,indexed,gains")
  index = index + 1
  match_table[index,] = c("ct", "non,allowance,double,deduction,dual,resident,companies")
  index = index + 1
  match_table[index,] = c("ct", "relief,sovereign debt")
  index = index + 1
  match_table[index,] = c("ct", "carry,back,loss")
  index = index + 1
  match_table[index,] = c("ct", "capital allowance,smes")
  index = index + 1
  match_table[index,] = c("ct", "40,fycs,smes")
  index = index + 1
  match_table[index,] = c("ct", "100,fycs,smes")
  index = index + 1
  match_table[index,] = c("ct", "foreign income dividend")
  index = index + 1
  match_table[index,] = c("ct", "abolish foreign dividends income")
  index = index + 1
  match_table[index,] = c("ct", "abolish foreign earnings deduction")
  index = index + 1
  match_table[index,] = c("ct", "abolish act,introduce")
  index = index + 1
  match_table[index,] = c("ct", "abolish quarterly accounting,gilts")
  index = index + 1
  match_table[index,] = c("ct", "small,companies,rate")
  index = index + 1
  match_table[index,] = c("ct", "reduc,rate")
  index = index + 1
  match_table[index,] = c("ct", "avoidance")
  index = index + 1
  match_table[index,] = c("ct", "")
  index = index + 1
  match_table[index,] = c("stamp", "exemption for property within disadvantaged communities")
  index = index + 1
  match_table[index,] = c("stamp", "rate,dut")
  index = index + 1
  match_table[index,] = c("stamp", "reduction,rate")
  index = index + 1
  match_table[index,] = c("stamp", "rais,threshold")
  index = index + 1
  match_table[index,] = c("stamp", "other charges")
  index = index + 1
  match_table[index,] = c("stamp", "abolition,capital,duty")
  index = index + 1
  match_table[index,] = c("stamp", "duties,share,aboli")
  index = index + 1
  match_table[index,] = c("stamp", "stamp")
  index = index + 1
  match_table[index,] = c("stamp", "")
  index = index + 1
  match_table[index,] = c("tobacco", "conversion")
  index = index + 1
  match_table[index,] = c("tobacco", "product")
  index = index + 1
  match_table[index,] = c("tobacco", "increase,tobacco,duty")
  index = index + 1
  match_table[index,] = c("tobacco", "cigarette,dut")
  index = index + 1
  match_table[index,] = c("tobacco", "escalator")
  index = index + 1
  match_table[index,] = c("tobacco", "")
  index = index + 1
  match_table[index,] = c("alcohol", "beer")
  index = index + 1
  match_table[index,] = c("alcohol", "spirit")
  index = index + 1
  match_table[index,] = c("alcohol", "wine")
  index = index + 1
  match_table[index,] = c("alcohol", "")
  index = index + 1
  match_table[index,] = c("ved", "no change,cars,light vans,lorry")
  index = index + 1
  match_table[index,] = c("ved", "revalorisation")
  index = index + 1
  match_table[index,] = c("ved", "graduated,small cars")
  index = index + 1
  match_table[index,] = c("ved", "graduat")
  index = index + 1
  match_table[index,] = c("ved", "threshold")
  index = index + 1
  match_table[index,] = c("ved", "freeze")
  index = index + 1
  match_table[index,] = c("ved", "")
  index = index + 1
  match_table[index,] = c("fuel", "no change,petrol")
  index = index + 1
  match_table[index,] = c("fuel", "no change,derv")
  index = index + 1
  match_table[index,] = c("fuel", "change,duty,petrol")
  index = index + 1
  match_table[index,] = c("fuel", "oil,heavy")
  index = index + 1
  match_table[index,] = c("fuel", "oil,light")
  index = index + 1
  match_table[index,] = c("fuel", "increase,rebat,oil")
  index = index + 1
  match_table[index,] = c("fuel", "increase minor oil,duties")
  index = index + 1
  match_table[index,] = c("fuel", "reduction,unleaded,duty")
  index = index + 1
  match_table[index,] = c("fuel", "bring forward road fuel escalator")
  index = index + 1
  match_table[index,] = c("fuel", "increase,petrol,diesel,differential")
  index = index + 1
  match_table[index,] = c("fuel", "one year nominal freeze")
  index = index + 1
  match_table[index,] = c("fuel", "gas,fuel oils")
  index = index + 1
  match_table[index,] = c("fuel", "increase,road")
  index = index + 1
  match_table[index,] = c("fuel", "increase,petrol")
  index = index + 1
  match_table[index,] = c("fuel", "increase,derv")
  index = index + 1
  match_table[index,] = c("fuel", "diesel")
  index = index + 1
  match_table[index,] = c("fuel", "unleaded petrol")
  index = index + 1
  match_table[index,] = c("fuel", "leaded petrol")
  index = index + 1
  match_table[index,] = c("fuel", "excise")
  index = index + 1
  match_table[index,] = c("fuel", "")
  index = index + 1
  match_table[index,] = c("cgt", "exemption,band")
  index = index + 1
  match_table[index,] = c("cgt", "reform of policy holder taxation")
  index = index + 1
  match_table[index,] = c("cgt", "exempt,slice,individual")
  index = index + 1
  match_table[index,] = c("cgt", "counter capital gain buying")
  index = index + 1
  match_table[index,] = c("cgt", "indexation,capital,gains")
  index = index + 1
  match_table[index,] = c("cgt", "increase,threshold,individual")
  index = index + 1
  match_table[index,] = c("cgt", "rebasing,compan")
  index = index + 1
  match_table[index,] = c("cgt", "sale,of companies")
  index = index + 1
  match_table[index,] = c("cgt", "charging,gains,individuals")
  index = index + 1
  match_table[index,] = c("cgt", "avoidance")
  index = index + 1
  match_table[index,] = c("cgt", "capital")
  index = index + 1
  match_table[index,] = c("cgt", "reform")
  index = index + 1
  match_table[index,] = c("cgt", "")
  index = index + 1
  match_table[index,] = c("oil", "increase,rate")
  index = index + 1
  match_table[index,] = c("oil", "advance,petroleum,revenue,tax")
  index = index + 1
  match_table[index,] = c("oil", "supplement,petroleum")
  index = index + 1
  match_table[index,] = c("oil", "change,prt")
  index = index + 1
  match_table[index,] = c("oil", "abolition,spd,increase,prt")
  index = index + 1
  match_table[index,] = c("oil", "")
  index = index + 1
  match_table[index,] = c("levy", "gas")
  index = index + 1
  match_table[index,] = c("levy", "")
  index = index + 1
  match_table[index,] = c("ni", "company,car")
  index = index + 1
  match_table[index,] = c("ni", "unapproved share options")
  index = index + 1
  match_table[index,] = c("ni", "alignment,threshold")
  index = index + 1
  match_table[index,] = c("ni", "increases to u")
  index = index + 1
  match_table[index,] = c("ni", "reform of self-employment")
  index = index + 1
  match_table[index,] = c("ni", "reduc,employer nic")
  index = index + 1
  match_table[index,] = c("ni", "reduc,rate")
  index = index + 1
  match_table[index,] = c("ni", "exten,employer")
  index = index + 1
  match_table[index,] = c("ni", "double taxation")
  index = index + 1
  match_table[index,] = c("ni", "surcharge")
  index = index + 1
  match_table[index,] = c("ni", "")
  index = index + 1
  match_table[index,] = c("landfill", "introduce,tax")
  index = index + 1
  match_table[index,] = c("landfill", "")
  index = index + 1
  match_table[index,] = c("gambling", "")
  index = index + 1
  match_table[index,] = c("apd", "")
  index = index + 1
  match_table[index,] = c("insurance premium", "4")
  index = index + 1
  match_table[index,] = c("insurance premium", "17.5")
  index = index + 1
  match_table[index,] = c("insurance premium", "")
  index = index + 1
  match_table[index,] = c("ccl", "")
  index = index + 1
  match_table[index,] = c("aggregates", "aggregates levy")
  index = index + 1
  match_table[index,] = c("aggregates", "")
  
  print(match_table)
}
#a = create_match_table()

print_2cols = function(df_2cols) {
  printf("index tax                   description\n")
  printf("-----------------------------------------------------------------\n")
  for (index in 1:nrow(df_2cols)) {
    printf("%4d: %-20s  %-80s\n", index, substring(df_2cols$tax[index],1,20), substring(df_2cols$description[index],1,80))
  }
  printf("-----------------------------------------------------------------\n")
}

print_3cols = function(df_3cols) {
  printf("index year  tax                   description\n")
  printf("-----------------------------------------------------------------\n")
  for (index in 1:nrow(df_3cols)) {
    printf("%4d: %4d  %-20s  %-80s\n", index, df_3cols$year[index], substring(df_3cols$tax[index],1,20), substring(df_3cols$description[index],1,80))
  }
  printf("-----------------------------------------------------------------\n")
}

tidy_up_tax_names_rest = function(df) {
  df = str_replace_all(df, "north sea taxes", "oil")
  df = str_replace_all(df, "vehicle excise duty", "ved")
  df = str_replace_all(df, "climate change levy", "ccl")
  df = str_replace_all(df, "air passenger duty", "apd")
#  df = str_replace_all(df, "inheritance", "estate")
  df = str_replace_all(df, "capital gains", "cgt")
  df = str_replace_all(df, "onshore ct", "ct")
  df = str_replace_all(df, "aggregates levy", "aggregates")
  df = str_replace_all(df, "betting", "gambling")
  df = str_replace_all(df, "other tax", "levy")
  df = str_replace_all(df, "nics", "ni")
  df = str_replace_all(df, "duties", "")
  df = str_replace_all(df, "duty", "")
  df = str_replace_all(df, "taxes", "")
  df = str_replace_all(df, "tax", "")
  df = str_replace_all(df, "  ", " ")   # multiple spaces to single
  df = trimws(df, which = c("both"))    # trim leading and trailing spaces
  df
}

tidy_up_tax_names_orig = function(df) {
  df = str_replace_all(df, "estate duty", "inheritance")
  df = str_replace_all(df, "tax credit", "income")
  df
}


#----MATCH ROWS BY TAX TYPE & DESCRIPTION---------------------------------------------------------------------------


# Big loop over years in the RestOfData table
for (this_year in start_year:final_year) {   # for is inclusive
  printf("==================== %d ====================\n", this_year)
  rest_this_year = subset(restoftax_df, Year == this_year, select=c("Tax_head",   "Measure_description"))
  orig_this_year = subset(original_df,  Year == this_year, select=c("TaxSubType", "Description_as_reported_in_FSBR"))
  printf("TestOfData rows: %d    Original rows: %d\n", nrow(rest_this_year), nrow(orig_this_year))
  if(nrow(rest_this_year) == 0 | nrow(orig_this_year) == 0) {
    printf("Missing year in one of the datasets - skipping\n")
    next
  }
  matched_row_indices_list = match_rows(rest_this_year, orig_this_year)
  rest_matched_indices = matched_row_indices_list[1]
  orig_matched_indices = matched_row_indices_list[2]
  rest_matched = rest_this_year[rest_matched_indices, ]
  orig_matched = orig_this_year[orig_matched_indices, ]
  print_sbs_table(rest_matched, orig_matched)
  
  if (this_year > 1975) {
    break
  }
  
}

  # First we are going to filter the corresponding entries from both tables:
  # original: Tax Type & Sub Type   vs  restoftax: Tax head
  # We need to match the words in whatever order
  
# Compare the "Measure Description" column in restoftax_df with the new
# TaxSubType column in original_df. We don't care about rows in original_df
# that don't have a matching description in restoftax_df.

unique_original_taxes  = get_column_unique_nocase(original_df$Tax_Type)
unique_restoftax_taxes = get_column_unique_nocase(restoftax_df$Tax_head)
nrow_unique_original_taxes  = length(unique_original_taxes)
nrow_unique_restoftax_taxes = length(unique_restoftax_taxes)
printf("Idx  %-25s   %-25s\n", " ", " ")
for (index in 1:max(nrow_unique_original_taxes, nrow_unique_restoftax_taxes)) {
  str1 = sprintf("%-25s", " ")
  str2 = sprintf("%-25s", " ")
  if (index <= nrow_unique_original_taxes)  {
    str1 = sprintf("%-25s", unique_original_taxes[index])
  }
  if (index <= nrow_unique_restoftax_taxes)  {
    str2 = sprintf("%-25s", unique_restoftax_taxes[index])
  }
  printf("%3d: %-20s   %-25s\n", index, str1, str2)
}

subset_col_indices = which(names(original_df) %in% c("Tax_Type", "Description_as_reported_in_FSBR"))
subset_df = original_df[, subset_col_indices]
unique_originals = find_all_unique_pairs(subset_df)
printf("Unique originals has %d rows\n", nrow(unique_originals))
printf("Indx: %-20s  %-40s\n", colnames(unique_originals)[1], colnames(unique_originals)[2])
#for (index in 1:nrow(unique_originals)) {
for (index in 1:20) {
  printf("%4d: %-20s  %-40s\n", index, unique_originals[index, 1], unique_originals[index, 2])
}

subset_col_indices = which(names(restoftax_df) %in% c("Tax_head", "Measure_description"))
subset_df = restoftax_df[, subset_col_indices]
unique_restoftax = find_all_unique_pairs(subset_df)
printf("Unique restoftax has %d rows, %d cols\n", nrow(unique_restoftax), ncol(unique_restoftax))
printf("Indx: %-20s  %-40s\n", colnames(unique_restoftax)[1], colnames(unique_restoftax)[2])
#for (index in 1:nrow(unique_restoftax)) {

get_lower_case = restoftax_df[,c("Tax_head", "Measure_description")]
get_lower_case$Tax_head = tolower(get_lower_case$Tax_head)
get_lower_case$Measure_description = tolower(get_lower_case$Measure_description)
test_subset = subset(get_lower_case, Tax_head == "income tax")
#for (index in 1:20) {
for (index in 1:nrow(test_subset)) {
    printf("%4d: %-10s  %-40s\n", index, test_subset[index,1], test_subset[index,2])
}
printf("%s : count = %d\n", test_subset[1,1], nrow(test_subset))
test_unique_tax_types = get_column_unique(get_lower_case, "Tax_head")
printf("test_subset 'Tax head' column has %d unique entries\n", length(test_unique_tax_types))
for (tax_type in sort(test_unique_tax_types)) {
  printf("%-20s\n", tax_type)
}


original_unique_tax_types = get_column_unique(original_df, "Tax_Type")
printf("Original  'Tax Type' column has %d unique entries\n", length(original_unique_tax_types))

restoftax_unique_tax_types = get_column_unique(restoftax_df, "Tax_head")
printf("Restoftax 'Tax head' column has %d unique entries\n", length(restoftax_unique_tax_types))

tax_type_lookup = make_tax_types_lookup(restoftax_unique_tax_types, original_unique_tax_types)

printf("Lookup table has %d entries\n", nrow(tax_type_lookup))
print(tax_type_lookup)









#----ALI STUFF------------------------------------------------------------------------------------------------------


# Cleaning and setting up table

data <- rename(data, imp_Q_cal = imp_Q)
data <- rename(data, ann_Q_cal = ann_Q)
data <- rename(data, tax_data_cal = tax_data)
data <- rename(data, tax_type_OBR = tax_type)

data <- data %>% 
  add_column(tax_data_fis = numeric(length = nrow(data))) %>%
  relocate(tax_data_fis, .after = imp_year)

data <- data %>% 
  add_column(imp_Q_fis = numeric(length = nrow(data))) %>%
  relocate(imp_Q_fis, .after = tax_data_fis)

data <- data %>% 
  add_column(tax_data_1 = numeric(length = nrow(data))) %>%
  relocate(tax_data_1, .after = imp_Q_fis)

data<- data %>%
  add_column(tax_type = character(length = nrow(data))) %>%
  relocate(tax_type, .after = tax_type_OBR)

for (row in 1:nrow(data)) {
  if (data[row, tax_type_OBR] == "income tax") {
    data[row, tax_type_OBR:= "Income tax"]
  }
  else if (data[row, tax_type_OBR] == "Alcohol Duty") {
    data[row, tax_type_OBR:= "Alcohol duty"]
  }
  else if (data[row, tax_type_OBR] == "Fuel duties") {
    data[row, tax_type_OBR:= "Fuel duty"]
  }
  else if (data[row, tax_type_OBR] == "Business Rates") {
    data[row, tax_type_OBR:= "Business rates"]
  }
}

bank_levy_i = c(grep("Bank Levy", data[, measure]), grep("Bank levy", data[, measure]))
for (row in bank_levy_i ) {
  if ( data[row, tax_type_OBR] == "Other tax") {

 data[row, tax_type_OBR := "Bank levy"]
  }
  else{
    next
  }
}
rm(bank_levy_i)


#EXOGENOUS ONLY
exos = which(data[, endo_exo] == 'X')
data <- data[exos,]
tax_df <- tax_df[exos,]
#---

#HOUSEHOLDS ONLY
hh = which(data[, target] == 'H')
data <- data[hh,]
tax_df <- tax_df[hh,]
#---

years = c(2004:2023)
GDP_growth_ORIG <- read_excel("/Users/ali/Desktop/Lavori/UK_Narrative/Data/NomGDPgrowth_OBR.xlsx")
GDP_growth_ORIG <- GDP_growth_ORIG[, c(grep("2004", colnames(GDP_growth_ORIG)): grep("2023", colnames(GDP_growth_ORIG)) )]
colnames(GDP_growth_ORIG) = years
GDP_growth = GDP_growth_ORIG[1, ]
GDP_nom = GDP_growth_ORIG[2, ]
rm(GDP_growth_ORIG)

tax_df_propGDP = tax_df
for(row in 1:nrow(tax_df)){
  tax_df_propGDP[row, ] = tax_df[row, ]/GDP_nom*100
}
#---------------------------------------------------


#----POLICY GROUPING--------------------------------------------------------------------------------------

#--------- GROUPING POLICIES BY TYPE
group_numbers = count(data, tax_type_OBR)  # get how many policies are of each type


# TAX TYPE
for ( row in 1:nrow(data) ) {
  if (data[row,tax_type_OBR] == "VAT" ) {
    data[row, tax_type := "VAT"]
  }
  else if ( data[row,tax_type_OBR] == "CGT" ) {
    data[row, tax_type := "CGT"]
  }
  else if ( data[row,tax_type_OBR] == "IHT" ) {
    data[row, tax_type := "Inheritance"]
  }
  else if ( data[row,tax_type_OBR] == "Council tax" ) {
    data[row, tax_type := "Property"]
  }
  else if ( data[row,tax_type_OBR] == "Immigration health surcharge" ) {
    data[row, tax_type := "Healthcare"]
  }
  else if ( data[row,tax_type_OBR] == "IPT" ) {
    data[row, tax_type := "Insurance"]
  }
  else if ( data[row,tax_type_OBR] %in% c("Alcohol duty", "APD", "Betting", "Fuel duty", 
                                          "Tobacco duty", "VED") ) {
    data[row, tax_type := "Duty"]
  }
  else if ( data[row,tax_type_OBR] == "Income tax" ) {
    data[row, tax_type := "Income"]
  }
  else if ( data[row,tax_type_OBR] == "NICs" ) {
    data[row, tax_type := "NI"]
  }
  else if ( data[row,tax_type_OBR] == "Pay to stay" ) {
    data[row, tax_type := "Housing"]
  }
  else if ( data[row,tax_type_OBR] == "Stamp duty" ) {
    data[row, tax_type := "SDLT"]
  }
  else if ( data[row,tax_type_OBR] == "Other tax" ) {
    data[row, tax_type := "Other"]
  }
  else {
    print(c(row, data[row, group]))
    data[row, tax_type := NA]
    next
  }
}
#---

# GROUP
for ( row in 1:nrow(data) ) {
  if (data[row,tax_type_OBR] %in% c("Apprenticeship levy", "Bank levy", "Bank surcharge", 
                                    "Business rates", "CCL", "Digital services tax", "Diverted profits tax", 
                                    "EU ETS", "Landfill tax", "North sea taxes", "On-shore CT", "PCGOS", 
                                    "Probate fees", "Soft drinks levy" ) ) {
    data[row, group := "Business"]
  }
  else if ( data[row,tax_type_OBR] %in% c("CGT", "Council tax", "IHT", "Stamp duty") ) {
    data[row, group := "Capital"]
  }
  else if ( data[row,tax_type_OBR] %in% c("Alcohol duty", "APD", "Betting", "Fuel duty", "Immigration health surcharge", "IPT", "Pay to stay", 
                                          "Tobacco duty", "VAT", "VED") ) {
    data[row, group := "Consumption"]
  }
  else if ( data[row,tax_type_OBR] %in% c("Income tax") ) {
    data[row, group := "Income"]
  }
  else if ( data[row,tax_type_OBR] %in% c("NICs") ) {
    data[row, group := "Social Security"]
  }
  else if ( data[row,tax_type_OBR] %in% c("Other tax") ) {
    data[row, group := "Other"]
  }
  else {
    data[row, group := "MISTAKE SOMEWHERE"]
    
    print(row)
    break
  }
}
#---

#---------------------------------------------------

#----USEFUL VECTORS---------------------------------------------------------------------------------------
#### for imp and announcement dates

# Implementation dates
allImpDates = data[,implement]  #use data.table because it keeps the POSIXlt date format for the month() formula
allImpYears = data.frame(year(allImpDates))
allImpMonths = data.frame(month(allImpDates))
allImpDays = data.frame(day(allImpDates))

data <- data[, imp_year := allImpYears]

# Announcement dates
allAnnDates = data[, announce]  #use data.table because it keeps the POSIXlt date format for the month() formula
allAnnYears = data.frame(year(allAnnDates))
allAnnMonths = data.frame(month(allAnnDates))
allAnnDays = data.frame(day(allAnnDates))

data <- data[, ann_year := allAnnYears]
#---

#---------------------------------------------------

#----FUNCTIONS--------------------------------------------------------------------------------------------
#### For calculating quarters and years from implementation and announcement dates

# Calendar_yr
#   Quarters start at beginning of solar year, with first half of month belonging to earlier Q and second half to following Q
#     Special case is Dec-15 onward that belongs to the 1st quarter of the NEXT year

findQuarter_cal = function(theYear, theMonth, theDay) {
  
  if ( is.na(theYear) || is.na(theMonth) || is.na(theDay) ) {
    return(list(NA, NA))
  }
  
  theQuarterYear = theYear   # In most cases, this is correct. For Dec-15 on, it's the next year.
  
  #--- Quarter 1 (part 1)
  if ( theMonth %in% c(1,2) ) {
    theQuarter = 1
  }
  else if ( theMonth == 3 && theDay <=15 ) {
    theQuarter = 1
  }
  #--- Quarter 2
  else if ( theMonth == 3 && theDay >15 ) {
    theQuarter = 2
  }
  else if ( theMonth %in% c(4,5) ) {
    theQuarter = 2
  }
  else if ( theMonth == 6 && theDay <=15 ) {
    theQuarter = 2
  }
  #--- Quarter 3
  else if ( theMonth == 6 && theDay >15 ) {
    theQuarter = 3
  }
  else if ( theMonth %in% c(7,8) ) {
    theQuarter = 3
  }
  else if ( theMonth == 9 && theDay <=15 ) {
    theQuarter = 3
  }
  #--- Quarter 4
  else if ( theMonth == 9 && theDay >15 ) {
    theQuarter = 4
  }
  else if ( theMonth %in% c(10,11) ) {
    theQuarter = 4
  }
  else if ( theMonth == 12 && theDay <=15 ) {
    theQuarter = 4
  }
  #--- Quarter 1 (part 2)
  else if ( theMonth == 12 && theDay >15 ) {
    theQuarter = 1
    theQuarterYear = theYear + 1
  }
  else {
    print(c("findQuarter_cal(): Month ", theMonth, " or Day ", theDay, " are Bad"))
    exit
  }
  return(list(theQuarterYear, theQuarter))
}
#---

# Fiscal year
#   Quarters start at beginning of fiscal year (April), with first half of month belonging to earlier Q and second half to following Q
#     Special cases:
#       - Dec-15 onward that belongs to the 4th quarter of the same fiscal year
#       - Jan, Feb, to Mar-15 belong to Q4 of the previous year's fiscal year (i.e. Feb 2010 is part of 2009-2010 fiscal year)

findQuarter_fis = function(theYear, theMonth, theDay) {
  
  if ( is.na(theYear) || is.na(theMonth) || is.na(theDay) ) {
    return(list(NA, NA))
  }
  
  theQuarterYear = theYear   # In most cases, this is correct. For Dec-15 on, it's the next year.
  
  #--- Quarter 1
  if ( theMonth == 3 && theDay >15 ) {
    theQuarter = 1
  }
  else if ( theMonth %in% c(4,5) ) {
    theQuarter = 1
  }
  else if ( theMonth == 6 && theDay <=15 ) {
    theQuarter = 1
  }
  #--- Quarter 2
  else if ( theMonth == 6 && theDay >15 ) {
    theQuarter = 2
  }
  else if ( theMonth %in% c(7,8) ) {
    theQuarter = 2
  }
  else if ( theMonth == 9 && theDay <=15 ) {
    theQuarter = 2
  }
  #--- Quarter 3
  else if ( theMonth == 9 && theDay >15 ) {
    theQuarter = 3
  }
  else if ( theMonth %in% c(10,11) ) {
    theQuarter = 3
  }
  else if ( theMonth == 12 && theDay <=15 ) {
    theQuarter = 3
  }
  #--- Quarter 4
  else if ( theMonth == 12 && theDay >15 ) {
    theQuarter = 4
  }
  else if ( theMonth %in% c(1,2) ) {
    theQuarter = 4
    theQuarterYear = theYear - 1
  }
  else if ( theMonth == 3 && theDay <=15 ) {
    theQuarter = 4
    theQuarterYear = theYear - 1
  }
  else {
    print(c("findQuarter_fis(): Month ", theMonth, " or Day ", theDay, " are Bad"))
    exit
  }
  return(list(theQuarterYear, theQuarter))
}
#---

# Present Value
PVfunc = function(FV_table, rate) {
  # FV is future value, r is GDP growth rate, n is number of time periods
  PV_table = array(data= NA, dim= dim(FV_table))
  
  years_length = length(FV_table[1,]) 
  
  for(pol in 1:nrow(PV_table)){
    # taylor product vector to each policy row with NAs or not
    prod_vec = numeric(length = years_length)
    # find the index of starting point <=> Year 1
    start_indices = which(!is.na(FV_table[pol,]))
    
    # if no implementation date
    if(length(start_indices) == 0){
      # don't need to do anything as this FV_table row is all NA and PV_table is already full of NA
      next
    }
    
    # if implementation date exists
    start_index = min(start_indices)
    
    reached_end_NA = FALSE
    
    for(year in start_index:years_length ){
      
      if(is.na(FV_table[pol, year])){
        # PV_table[pol, year] = NA
        reached_end_NA = TRUE
      }
      else if(year == start_index){
        # if the same year, PV = FV
        PV_table[pol, year] = FV_table[pol, year]
        prod_vec[year] = 1
      }
      else if(year > start_index){
        # any year after, value FV must be multiplied by product of 1/(that year's R) going backwards until hit PV = FV
        if(reached_end_NA){
          print(c("ERROR - found value in year ", year, "*after* an NA year was read"))
          print(c("Row is ", pol))
          stop()
        }
        product = rate[year]
        prod_vec[year] = product
        PV_table[pol, year] = FV_table[pol, year]/prod(prod_vec[start_index:year])
      }
      else{
        print(c("No IF condition matched: year = ", year, "  start_index = ", start_index))
      }
    } # next year - col
    
  }  # next pol - row
  
  return(PV_table)
}
#---

# Quarter Spread
Qspread = function(tax_table, quarter_year_map, quarters){
  # Fill quarter table with spread
  quar_table = matrix(data = NA, nrow = nrow(tax_table), ncol = length(quarters))
  
  for (pol in 1:nrow(tax_table)){
    for (year in 1:ncol(quar_year_map)) {
      year_index = year
      
      if ( is.na(quar_year_map[pol,year_index]) ){
        quar_table[pol, 4*(year_index - 1) + 1] = NA
        quar_table[pol, 4*(year_index - 1) + 2] = NA
        quar_table[pol, 4*(year_index - 1) + 3] = NA
        quar_table[pol, 4*(year_index - 1) + 4] = NA
      }
      else if ( quar_year_map[pol,year_index] == 1 ){
        pol_spread = as.numeric(tax_table[pol, year_index]) / 4
        
        quar_table[pol, 4*(year_index - 1) + 1] = pol_spread
        quar_table[pol, 4*(year_index - 1) + 2] = pol_spread
        quar_table[pol, 4*(year_index - 1) + 3] = pol_spread
        quar_table[pol, 4*(year_index - 1) + 4] = pol_spread
      }
      else if ( quar_year_map[pol,year_index] == 2 ){
        pol_spread = as.numeric(tax_table[pol, year_index]) / 3
        
        quar_table[pol, 4*(year_index - 1) + 1] = NA
        quar_table[pol, 4*(year_index - 1) + 2] = pol_spread
        quar_table[pol, 4*(year_index - 1) + 3] = pol_spread
        quar_table[pol, 4*(year_index - 1) + 4] = pol_spread
      }
      else if ( quar_year_map[pol,year_index] == 3 ){
        pol_spread = as.numeric(tax_table[pol, year_index]) / 2
        
        quar_table[pol, 4*(year_index - 1) + 1] = NA
        quar_table[pol, 4*(year_index - 1) + 2] = NA
        quar_table[pol, 4*(year_index - 1) + 3] = pol_spread
        quar_table[pol, 4*(year_index - 1) + 4] = pol_spread
      }
      else if ( quar_year_map[pol,year_index] == 4 ){
        pol_spread = as.numeric(tax_table[pol, year_index])
        
        quar_table[pol, 4*(year_index - 1) + 1] = NA
        quar_table[pol, 4*(year_index - 1) + 2] = NA
        quar_table[pol, 4*(year_index - 1) + 3] = NA
        quar_table[pol, 4*(year_index - 1) + 4] = pol_spread
      }
    }
  }
  
  colnames(quar_table) = quarters
  return(quar_table)
}
#---

# Filtering policies by group or type
FilterPols = function(tax_filter_vector, taxes_table, filter) {
  
  table_list = list()
  sum_table = c()
  
  # By group or type
  for (pol_filter in tax_filter_vector) {
    # get indexes of polices by group (don't understand the .. in ..filter, but it works)
    pol_index = which(data[, ..filter] == pol_filter)
    
    # Check in case this pol_filter is not found
    if(length(pol_index) == 0) {
      print(c("ERROR - no rows in ", filter, " with type ", pol_filter))
      stop()
    }
    
    # make table for this policy group
    table = taxes_table[c(pol_index), ]
    
    # add the table to the list of tables that will be returned    
    table_list[[length(table_list)+1]] = table
    
    # calculate sum for each year of each pol group
    # can't sum if 1 row (need 2-dimensional array for colSums)
    if(length(pol_index) == 1) {
      sum = table
    }
    else {
      sum = colSums(table, na.rm=TRUE)
    }
    
    # Append the new row of pol_filter sums to the sum_table, and set the row name to the pol_filter    
    sum_table = rbind(sum_table, sum)
    last_row_index = nrow(sum_table)                    # find the index of the new row added
    row.names(sum_table)[last_row_index] = pol_filter   # set the name of the new row
    
    print(c("--------TAX GROUP ", pol_filter, " DONE--------"))
  }
  
  return(list(table_list, sum_table))
}
#---

#---------------------------------------------------

#----QUARTER CALCULATION------------------------------------------------------------------------------------

# Announcement quarters
for( i in 1:nrow(allAnnMonths) ) {
  theYear = allAnnYears[i,]
  theMonth = allAnnMonths[i,]
  theDay = allAnnDays[i,]
  theQuarterAndYear = findQuarter_cal(theYear, theMonth, theDay)
  data[i, ann_Q_cal:= theQuarterAndYear[2]]
  data[i, ann_year_cal:= theQuarterAndYear[1]]
}
#---

# Implementation quarters according to CALENDAR year
for( i in 1:nrow(allImpMonths) ) {
  theYear = allImpYears[i,]
  theMonth = allImpMonths[i,]
  theDay = allImpDays[i,]
  theQuarterAndYear = findQuarter_cal(theYear, theMonth, theDay)
  data[i, imp_Q_cal:= theQuarterAndYear[2]]
  data[i, imp_year:= theQuarterAndYear[1]]
}
#---

# Implementation quarters according to FISCAL year
for( i in 1:nrow(allImpMonths) ) {
  theYear = allImpYears[i,]
  theMonth = allImpMonths[i,]
  theDay = allImpDays[i,]
  theQuarterAndYear = findQuarter_fis(theYear, theMonth, theDay)
  data[i, imp_Q_fis:= theQuarterAndYear[2]]
#  data[i, imp_year:= theQuarterAndYear[1]]
}
#---

#---------------------------------------------------

#---CALCULATING TAX DATA----------------------------------------------------------------------------------

#======
#= 0a == CALENDAR Year version: full-year single shock given imp quarter relative to year
#======

# If the implementation quarter is not Q1, then the shock amount is taken from the following year

for( i in 1:nrow(data) ) {
  year    = (data[i, imp_year])
  
  if (is.na(year)) {
    data[i, tax_data_cal := NA]
    next
  }
#  yearCh    <- as.character(year)   # done to call the year column in tax_df_propGDP by name
  yearCh    <- as.character(paste0("X", year))
  if ( data[i, imp_Q_cal] == 1 ) {
    tax_impact = as.numeric(tax_df_propGDP[i, yearCh])
    
    data[i, tax_data_cal := tax_impact]
  }
  
  else {
#    next_yearCh = as.character(year + 1)
    next_yearCh = as.character(paste0("X", year + 1))
    next_impact = as.numeric(tax_df_propGDP[i, next_yearCh]) ########## ISSUE because column is 'XYEAR' not 'YEAR'
    data[i, tax_data_cal := next_impact]
  }
}
#---

#======
#= 0b == FISCAL Year version: full-year single shock given imp quarter relative to year
#======

# If the implementation quarter is not Q1, then the shock amount is taken from the following year

for( i in 1:nrow(data) ) {
  year    = (data[i, imp_year])
  
  if (is.na(year)) {
    data[i, tax_data_fis := NA]
    next
  }
#  yearCh    <- as.character(year)   # done to call the year column in tax_df_propGDP by name
  yearCh    <- as.character(paste0("X", year))
  
  if ( data[i, imp_Q_fis] == 1 ) {
    tax_impact = as.numeric(tax_df_propGDP[i, yearCh])
    
    data[i, tax_data_fis := tax_impact]
  }
  
  else {
#    next_yearCh = as.character(year + 1)
    next_yearCh = as.character(paste0("X", year + 1))
    next_impact = as.numeric(tax_df_propGDP[i, next_yearCh])
    
    data[i, tax_data_fis := next_impact]
  }
}
#---



#======
#= 1 == FISCAL Year OBR version: full-year single shock taking OBR value for imp year
#======

# store implementation year, take that value

for( i in 1:nrow(data) ) {
  year    = (data[i, imp_year])
  
  if (is.na(year)) {
    data[i, tax_data_1 := NA]
    next
  }
  
  else {
    yearCh = as.character(paste0("X", year))
    tax_impact = as.numeric(tax_df_propGDP[i, yearCh])
    
    if (is.na(tax_impact)) {
      next
    }
    
    else if(tax_impact == 0){
      yearChNext = as.character(paste0("X", year+1))
      tax_impact_next = as.numeric(tax_df_propGDP[i, yearChNext])
      data[i, tax_data_1 := tax_impact_next]
    }
    else{
      data[i, tax_data_1 := tax_impact]
    }
  }

}
#---




##########################################################################################################################################
##########################################################################################################################################


######## CHECK
for( row in 1:nrow(data) ){
  if(is.na(data[row, tax_data_1]) == FALSE ){
    
    if(data[row, tax_data_1] == 0){
      print(c("row: ", row, "imp year", data[row, imp_year]))
    }
    
  }
}

##########################################################################################################################################
##########################################################################################################################################


#======
#= 2 == 3-year tax impact: take the costing from year of implementation as well as the two following fiscal years'
#======

# copy dataframe
tax3_FV = tax_df_propGDP

# Make NA all values before and after 3-yr window
for( row in 1:nrow(tax3_FV) ){
  
  start_index = numeric()
  
  # this is just for now to make su
  if(is.na(data[row, tax_data_1])){
    print(c("IMPLEMENTATION DATE NOT FOUND AT ROW ", row))
    print("+++++======+++++=====+++++====")
    tax3_FV[row,c(1:length(tax3_FV))] = NA
  }
  
  else{
    pol_impact = data[row, tax_data_1]
    print(c("+++ROW ", row, "Pol_impact = ", pol_impact))
    
    for( col in 1:ncol(tax3_FV) ){
      
      if(is.na(tax3_FV[row,col])){
#        print(c(col, " IS NA"))
        next
      }
      else if(tax3_FV[row,col] == pol_impact){
        start_index = col
        #      print(c(col, " IS NOT NA", start_index))
        end_index = col + 2
        tax3_FV[row,-c(start_index:end_index)] = NA
        break
      }
      
    }
  }
}

#======
#= 3 == 10-year tax impact: take the costing from year of implementation as well as the nine following fiscal years'
#======

# copy dataframe
tax10_FV = tax_df_propGDP

# Make NA all values before and after 3-yr window
for( row in 1:nrow(tax10_FV) ){
  
  start_index = numeric()
  
  # this is just for now to make su
  if(is.na(data[row, tax_data_1])){
    print(c("IMPLEMENTATION DATE NOT FOUND AT ROW ", row))
    print("+++++======+++++=====+++++====")
    tax10_FV[row,c(1:length(tax10_FV))] = NA
  }
  
  else{
    pol_impact = data[row, tax_data_1]
    print(c("+++ROW ", row, "Pol_impact = ", pol_impact))
    
    for( col in 1:ncol(tax10_FV) ){
      
      if(is.na(tax10_FV[row,col])){
        #        print(c(col, " IS NA"))
        next
      }
      else if(tax10_FV[row,col] == pol_impact){
        start_index = col
        #      print(c(col, " IS NOT NA", start_index))
        end_index = col + 9
        tax10_FV[row,-c(start_index:end_index)] = NA
        break
      }
      
    }
  }
}



#---------------------------------------------------

#----PRESENT VALUE------------------------------------------------------------------------------------

R = as.numeric(GDP_growth)

year_quart = rep(years, times = 1, each = 4)

tax3_Y = PVfunc(tax3_FV, R)
tax10_Y = PVfunc(tax10_FV, R)

colnames(tax3_Y) = years
colnames(tax10_Y) = years

#---------------------------------------------------

#----QUARTER SPREAD------------------------------------------------------------------------------------

quar = rep(1:4, times = length(years))
quarters = paste(year_quart, quar, sep = '_q')

# Create a map to go from yearly table to quarter table

quar_year_map = copy(tax_df_propGDP)
quar_year_map[,] = NA
colnames(quar_year_map) = as.character(c(2004:2023))

# quarter year map
for ( pol in 1:nrow(quar_year_map) ){
  year = grep( as.character(data[pol, imp_year]), colnames(quar_year_map) )
  year_next = year + 1
  year_last = grep( as.character(2023), colnames(quar_year_map) )
  quar = data[pol, imp_Q_fis]
  
  if (is.na(year) || is.na(year_next) || is.na(quar)){
    next
  }
  else{
    quar_year_map[pol, year] = quar
    quar_year_map[pol, c(year_next:year_last)] = 1
  }
  
}
#---

tax3 = Qspread(tax3_Y, quarter_year_map, quarters)
tax10 = Qspread(tax10_Y, quarter_year_map, quarters)
#---

#---------------------------------------------------

#----TIME SERIES PREPARATION-------------------------------------------------------------------------------------------------------------------

tax_groups = unique( na.omit(data[,group]) )
tax_types = unique( na.omit(data[,tax_type]) )

#---------------------------------------------------


#----CLOYNE EQUIVALENT-------------------------------------------------------------------------------------------------------------------

#Cloyne by group
Cloyne_groupSums = c()
for(group in tax_groups){
  pol_indices = which(data[,group] == as.character(group))
  
  tableName = paste0("Cloyne_group_", group)
  table = matrix(nrow = length(pol_indices), ncol = length(years), dimnames = list(pol_indices, years))
  # print(table)
  
  for (pol_index in pol_indices){
    counter = match(pol_index, pol_indices)
    
    year = data[pol_index, imp_year]
    impact = data[pol_index, tax_data_1]
    
    #print(paste(pol_index, counter, sep = " ~ "))
    table[counter, as.character(year)] = impact
    
    assign( tableName, table)
    
  }
  sumVector = colSums(table, na.rm = TRUE)
  Cloyne_groupSums = rbind(Cloyne_groupSums, sumVector)
  print(sumVector)
  
}
rownames(Cloyne_groupSums) = tax_groups


#Cloyne by type
Cloyne_typeSums = c()
for(type in tax_types){
  pol_indices = which(data[,tax_type] == as.character(type))
  
  tableName = paste0("Cloyne_type_", type)
  table = matrix(nrow = length(pol_indices), ncol = length(years), dimnames = list(pol_indices, years))
  # print(table)
  
  for (pol_index in pol_indices){
    counter = match(pol_index, pol_indices)
    
    year = data[pol_index, imp_year]
    impact = data[pol_index, tax_data_1]
    
    #print(paste(pol_index, counter, sep = " ~ "))
    table[counter, as.character(year)] = impact
    
    assign( tableName, table)
    
  }
  sumVector = colSums(table, na.rm = TRUE)
  Cloyne_typeSums = rbind(Cloyne_typeSums, sumVector)
  print(sumVector)
  
}
rownames(Cloyne_typeSums) = tax_types

#---------------------------------------------------


#---- 3-year TIME SERIES-----------------------------------------------------------------------------------------------------------------------

# total
tax3_sumTotal = colSums(tax3, na.rm = TRUE)
#---

# By Group
return_list_group3 = FilterPols(tax_groups, tax3, "group")
tax3_groups_list = return_list_group3[[1]]
tax3_groupSums = return_list_group3[[2]]
rm(return_list_group3)
#---

# making individual group tables
pol_index = 1
for (pol_filter in tax_groups) {
  
  table_name = paste0("tax3_group_", pol_filter)
  table = tax3_groups_list[[pol_index]]
  
  assign( table_name, table )
  # Now have the name of the policy in pol_filter, and the associated table in this_pol_table
  # Note that pol_index also corresponds to the row in group_sum3_table

  # Do stuff here
  print(c("Processing Policy ", pol_filter))
  
  # end of loop, increment the pol_index for the next pol_filter and associated table
  pol_index = pol_index + 1
}
#---

# By Type 
return_list_type3 = FilterPols(tax_types, tax3, "tax_type")
tax3_types_list = return_list_type3[[1]]
tax3_typeSums = return_list_type3[[2]]
rm(return_list_type3)
#---

# making individual type tables
pol_index = 1
for (pol_filter in tax_types) {
  
  table_name = paste0("tax3_type_", pol_filter)
  table = tax3_types_list[[pol_index]]
  
  assign( table_name, table )
  # Now have the name of the policy in pol_filter, and the associated table in this_pol_table
  # Note that pol_index also corresponds to the row in group_sum3_table
  
  # Do stuff here
  print(c("Processing Policy ", pol_filter))
  
  # end of loop, increment the pol_index for the next pol_filter and associated table
  pol_index = pol_index + 1
}
#---

#---------------------------------------------------

#---- 10-year TIME SERIES-----------------------------------------------------------------------------------------------------------------------

# total
tax10_sumTotal = colSums(tax10, na.rm = TRUE)
#---

# By Group
return_list_group10 = FilterPols(tax_groups, tax10, "group")
tax10_groups_list = return_list_group10[[1]]
tax10_groupSums = return_list_group10[[2]]
rm(return_list_group10)
# making individual group tables
pol_index = 1
for (pol_filter in tax_groups) {
  
  table_name = paste0("tax10_group_", pol_filter)
  table = tax10_groups_list[[pol_index]]
  
  assign( table_name, table )
  # Now have the name of the policy in pol_filter, and the associated table in this_pol_table
  # Note that pol_index also corresponds to the row in group_sum10_table
  
  # Do stuff here
  print(c("Processing Policy ", pol_filter))
  
  # end of loop, increment the pol_index for the next pol_filter and associated table
  pol_index = pol_index + 1
}
#---

# By Type
return_list_type10 = FilterPols(tax_types, tax10, "tax_type")
tax10_types_list = return_list_type10[[1]]
tax10_typeSums = return_list_type10[[2]]
rm(return_list_type10)
# making individual type tables
pol_index = 1
for (pol_filter in tax_types) {
  
  table_name = paste0("tax10_type_", pol_filter)
  table = tax10_types_list[[pol_index]]
  
  assign( table_name, table )
  # Now have the name of the policy in pol_filter, and the associated table in this_pol_table
  # Note that pol_index also corresponds to the row in group_sum10_table
  
  # Do stuff here
  print(c("Processing Policy ", pol_filter))
  
  # end of loop, increment the pol_index for the next pol_filter and associated table
  pol_index = pol_index + 1
}
#---

#---------------------------------------------------



# Adapt group table sizes
tax3_groupSums = tax3_groupSums[,c(1:match("2020_q4", colnames(tax3_groupSums)))]
tax3_typeSums = tax3_typeSums[,c(1:match("2020_q4", colnames(tax3_typeSums)))]
tax10_groupSums = tax10_groupSums[,c(1:match("2020_q4", colnames(tax10_groupSums)))]
tax10_typeSums = tax10_typeSums[,c(1:match("2020_q4", colnames(tax10_typeSums)))]
Cloyne_groupSums = Cloyne_groupSums[,c(1:match("2020", colnames(Cloyne_groupSums)))]
Cloyne_typeSums = Cloyne_typeSums[,c(1:match("2020", colnames(Cloyne_typeSums)))]
#---



#---------------------------------------------------

#---- TIME SERIES PLOTTING-----------------------------------------------------------------------------------------------------------------------


# 3 year
plot(x = 1:length(tax3_sumTotal), y = tax3_sumTotal, type = 'l', lwd = 1.5, col = 'red', xaxt = 'n',
     main = "3yr Series by Group", xlab = "", ylab = "Scorecard effect (% Nominal GDP)",
     ylim = c(min(c(tax3_groupSums, tax3_sumTotal), na.rm = TRUE), max(c(tax3_groupSums, tax3_sumTotal), na.rm = TRUE)) 
)
legend("topleft", legend = c("Tot", "Inc", "Cons", "Cap", "Sec", "Oth"), lwd = 1, col = c("red", "green", "blue", "orange", "cyan", "magenta", "green"))
axis(1, at = c(seq(from = 1, to = 80, by = 4)), labels = c(2004:2023))
lines(1:length(tax3_sumTotal), tax3_groupSums[1,], col = alpha('green', alpha = 0.8))
lines(1:length(tax3_sumTotal), tax3_groupSums[2,], col = alpha('blue', alpha = 0.8))
lines(1:length(tax3_sumTotal), tax3_groupSums[3,], col = alpha('orange', alpha = 0.8))
lines(1:length(tax3_sumTotal), tax3_groupSums[4,], col = alpha('cyan', alpha = 0.8))
lines(1:length(tax3_sumTotal), tax3_groupSums[5,], col = alpha('magenta', alpha = 0.8))
#--- 


# 10 year
plot(x = 1:length(tax10_sumTotal), y = tax10_sumTotal, type = 'l', lwd = 1.5, col = 'red', xaxt = "n",
     main = "10yr Series by Group", xlab = "", ylab = "Scorecard effect (% Nominal GDP)",
     ylim = c(min(c(tax10_groupSums, tax10_sumTotal), na.rm = TRUE), max(c(tax10_groupSums, tax10_sumTotal), na.rm = TRUE)) 
)
legend("topleft", legend = c("Tot", "Inc", "Cons", "Cap", "Sec", "Oth"), lwd = 1, col = c("red", "green", "blue", "orange", "cyan", "magenta", "green"))
axis(1, at = c(seq(from = 1, to = 80, by = 4)), labels = c(2004:2023))
lines(1:length(tax3_sumTotal), tax10_groupSums[1,], col = alpha('green', alpha = 0.8))
lines(1:length(tax3_sumTotal), tax10_groupSums[2,], col = alpha('blue', alpha = 0.8))
lines(1:length(tax3_sumTotal), tax10_groupSums[3,], col = alpha('orange', alpha = 0.8))
lines(1:length(tax3_sumTotal), tax10_groupSums[4,], col = alpha('cyan', alpha = 0.8))
lines(1:length(tax3_sumTotal), tax10_groupSums[5,], col = alpha('magenta', alpha = 0.8))
#--- 



barplot(tax10_groupSums[4,], main = "Capital 3-yr", ylab = "Scorecard effect (% Nominal GDP)")












#---------------------------------------------------

#----NORMALISATION-------------------------------------------------------------------------------

#--------- DATA MANIPULATION
# creating 2 new variables to store the policy impulse shape information, one with the shape and one with the direction

# Aligning all policies to remove NAs
#   tax_align = as.data.frame(t(apply(tax_n,1, function(x) { return(c(x[!is.na(x)],x[is.na(x)]) )} )))
tax3_align <- t(apply(tax3_Y,1, function(x) { return(c(x[!is.na(x)],x[is.na(x)]) )} ))
tax3_align <- tax3_align[,c(1:3)]

tax10_align <- t(apply(tax10_Y,1, function(x) { return(c(x[!is.na(x)],x[is.na(x)]) )} ))
tax10_align <- tax10_align[,c(1:10)]


# Setting up table
tax3_align_norm = tax3_align
tax10_align_norm = tax10_align

# Normaliser is the year with the greatest effect of the first 3 tax costing entries (scorecard values), which are considered definite
norms = numeric(length = nrow(tax3_align_norm))

for( row in 1:nrow(tax3_align_norm) ) {
  
  print(c("ROW: ", row))
  
  max_index = match( max(abs(tax3_align[row, ]), na.rm = TRUE), abs(tax3_align[row, ]) )
  normalizer = tax3_align[row, max_index]

  print(c("max index: ", max_index))
  print(c("normalizer: ", normalizer))
  
  if (is.na(normalizer) == TRUE){
    tax3_align_norm[row, ] = NA
    tax10_align_norm[row, ] = NA
    print("!!!!!! Normalizer is NA, something's wrong !!!!!!")
    
    norms[row] = NA
    
  } 
  
  else if (normalizer == 0){
    tax3_align_norm[row, ] = NA
    tax10_align_norm[row, ] = NA
    print("!!!!!! Normalizer is 0, something's wrong !!!!!!")
    
    norms[row] = NA
    
  }  

  
  else{
    tax3_align_norm[row, ] = tax3_align[row, ] / normalizer
    tax10_align_norm[row, ] = tax10_align[row, ] / normalizer
    
    norms[row] = normalizer
  }
  
  print(tax3_align_norm[row, ])
  print("----------END ROW----------")
  
}
#---

# CORRECTION TO ABOVE
# find max of each policy normalization. If greater than 4.0, then find the point where diff<=10% and use that as normalizer

# check for and fix issues
for (row in 1:nrow(tax10_align_norm) ){
  if (max(tax10_align_norm[row, ], na.rm = TRUE) > 4.0 || min(tax10_align_norm[row, ], na.rm = TRUE) < -4.0){
  print(row)

  if (row == 280) {
    # choose new normalizer
    new_normalizer = tax10_align[row, 5]
    print(new_normalizer)
    
    # run using the original tax#_align table (not normed)
    tax3_align_norm[row, ] = tax3_align[row, ] / new_normalizer
    tax10_align_norm[row, ] = tax10_align[row, ] / new_normalizer
    
    # update norm vector for describing policy shapes
    norms[row] = new_normalizer
  }   
    else if (row == 308) {
      # choose new normalizer
      new_normalizer = tax10_align[row, 5]
      print(new_normalizer)
      
      # run using the original tax#_align table (not normed)
      tax3_align_norm[row, ] = tax3_align[row, ] / new_normalizer
      tax10_align_norm[row, ] = tax10_align[row, ] / new_normalizer
      
      # update norm vector for describing policy shapes
      norms[row] = new_normalizer
    }  
    else if (row == 309) {
      # choose new normalizer
      new_normalizer = tax10_align[row, 5]
      print(new_normalizer)
      
      # run using the original tax#_align table (not normed)
      tax3_align_norm[row, ] = tax3_align[row, ] / new_normalizer
      tax10_align_norm[row, ] = tax10_align[row, ] / new_normalizer
      
      # update norm vector for describing policy shapes
      norms[row] = new_normalizer
    } 
    else if (row == 383) {
      # choose new normalizer
      new_normalizer = tax10_align[row, 4]
      print(new_normalizer)
      
      # run using the original tax#_align table (not normed)
      tax3_align_norm[row, ] = tax3_align[row, ] / new_normalizer
      tax10_align_norm[row, ] = tax10_align[row, ] / new_normalizer
      
      # update norm vector for describing policy shapes
      norms[row] = new_normalizer
    }
    else if (row == 384) {
      # choose new normalizer
      new_normalizer = tax10_align[row, 5]
      print(new_normalizer)
      
      # run using the original tax#_align table (not normed)
      tax3_align_norm[row, ] = tax3_align[row, ] / new_normalizer
      tax10_align_norm[row, ] = tax10_align[row, ] / new_normalizer
      
      # update norm vector for describing policy shapes
      norms[row] = new_normalizer
    } 
    else if (row == 420) {
      # choose new normalizer
      new_normalizer = tax10_align[row, 4]
      print(new_normalizer)
      
      # run using the original tax#_align table (not normed)
      tax3_align_norm[row, ] = tax3_align[row, ] / new_normalizer
      tax10_align_norm[row, ] = tax10_align[row, ] / new_normalizer
      
      # update norm vector for describing policy shapes
      norms[row] = new_normalizer
    } 
    else if (row == 448) {
      # choose new normalizer
      new_normalizer = tax10_align[row, 5]
      print(new_normalizer)
      
      # run using the original tax#_align table (not normed)
      tax3_align_norm[row, ] = tax3_align[row, ] / new_normalizer
      tax10_align_norm[row, ] = tax10_align[row, ] / new_normalizer
      
      # update norm vector for describing policy shapes
      norms[row] = new_normalizer
    }
    else if (row == 449) {
      # choose new normalizer
      new_normalizer = tax10_align[row, 5]
      print(new_normalizer)
      
      # run using the original tax#_align table (not normed)
      tax3_align_norm[row, ] = tax3_align[row, ] / new_normalizer
      tax10_align_norm[row, ] = tax10_align[row, ] / new_normalizer
      
      # update norm vector for describing policy shapes
      norms[row] = new_normalizer
    } 
    else if (row == 536) {
      # choose new normalizer
      new_normalizer = tax10_align[row, 5]
      print(new_normalizer)
      
      # run using the original tax#_align table (not normed)
      tax3_align_norm[row, ] = tax3_align[row, ] / new_normalizer
      tax10_align_norm[row, ] = tax10_align[row, ] / new_normalizer
      
      # update norm vector for describing policy shapes
      norms[row] = new_normalizer
    } 
    else if (row == 537) {
      # choose new normalizer
      new_normalizer = tax10_align[row, 5]
      print(new_normalizer)
      
      # run using the original tax#_align table (not normed)
      tax3_align_norm[row, ] = tax3_align[row, ] / new_normalizer
      tax10_align_norm[row, ] = tax10_align[row, ] / new_normalizer
      
      # update norm vector for describing policy shapes
      norms[row] = new_normalizer
    } 
    else if (row == 542) {
      # choose new normalizer
      new_normalizer = tax10_align[row, 4]
      print(new_normalizer)
      
      # run using the original tax#_align table (not normed)
      tax3_align_norm[row, ] = tax3_align[row, ] / new_normalizer
      tax10_align_norm[row, ] = tax10_align[row, ] / new_normalizer
      
      # update norm vector for describing policy shapes
      norms[row] = new_normalizer
    } 
    else if (row == 572) {
      # choose new normalizer
      new_normalizer = tax10_align[row, 6]
      print(new_normalizer)
      
      # run using the original tax#_align table (not normed)
      tax3_align_norm[row, ] = tax3_align[row, ] / new_normalizer
      tax10_align_norm[row, ] = tax10_align[row, ] / new_normalizer
      
      # update norm vector for describing policy shapes
      norms[row] = new_normalizer
    } 
  
  }
}


#--------- NORMALISED TABLES BASED ON TAX TYPE

for (type in tax_types) {
  # get indexes of polices by type
  pol_index = which(data[,tax_type] == type) 
  print(type)
  
  # make table for each policy type
  table_name = paste0("norm_", type)
  table = tax10_align_norm[c(pol_index), ]
  
  assign( table_name, table)
  
  # calculate average for each year of each pol type
  avg_name = paste0("avg_", type)
  
  if (is.null(nrow(table)) ){
    means = table
    print("1 row")
  }
  else{
    means = colMeans(table, na.rm=TRUE)
    print("more than 1 row")
  }
  
  assign( avg_name, means )
  
  print("--------END TAX TYPE--------")
}
#---

#---------------------------------------------------

#----SHAPE OF POLICIES-------------------------------------------------------------------------------

data <- data %>% 
  add_column(pol_shape = character(length = nrow(data))) %>%
  relocate(pol_shape, .after = group)

data <- data %>% 
  add_column(pol_direction = character(length = nrow(data))) %>%
  relocate(pol_direction, .after = pol_shape)

# Study the time-series to classify shapes
for( row in 1:nrow(data) ){
  
  print(c("ROW NUMBER: ", row))
  
  if ( is.na(tax10_align_norm[row, 1])) {
    next
  }
  
  else{
    
    row_end = numeric()
    row_end_minus1 = numeric()
    
    height = norms[row]
    threshold = ( mean(tax10_align_norm[row, ]) * 0.05 ) * (-1)  # so as to include any small momentary dip slightly below 1
    
    # get the bounds of for the time-series classifications
    for (col in 1:ncol(tax10_align) ){
      if (is.na(tax10_align_norm[row, col]) == TRUE){
        row_end = col
        row_end_minus1 = col -1
      }
      else{
        row_end = 10
        row_end_minus1 = row_end -1
      }
    }
 
    
    #1 - Growing
    if ( all(diff(tax10_align_norm[row, ]) >= threshold, na.rm=TRUE ) == TRUE ) {
      if( height > 0 ){
        data[row, pol_shape := "growing"] 
        data[row, pol_direction := "receipt"]
        print("case 1a-- growing receipt")
      }
      else{
        data[row, pol_shape := "growing"]
        data[row, pol_direction := "cost"]
        print("case 1b-- growing cost")
      }
    }
    
    #2 - Peaks
    else if ( all(diff(tax10_align_norm[row, ]) >= threshold, na.rm=TRUE ) == FALSE && max(abs(tax10_align[row, ])) == abs(height) && tax10_align_norm[row, row_end] <= tax10_align_norm[row, row_end_minus1] ) {
      if( height > 0 ){
        data[row, pol_shape := "peak"]
        data[row, pol_direction := "receipt"]
        print("case 2a-- receipt peak")
      }
      else{
        data[row, pol_shape := "peak"]
        data[row, pol_direction := "cost"]
        print("case 2b-- cost peak")
      }
    }
    
    #3 - Peak and recovery
    else if ( all(diff(tax10_align_norm[row, ]) >= threshold, na.rm=TRUE ) == FALSE && max(abs(tax10_align[row, ])) == abs(height) && tax10_align_norm[row, row_end] > tax10_align_norm[row, row_end_minus1] ) {
      if( height > 0 ){       
        data[row, pol_shape := "peak and recovery"]
        data[row, pol_direction := "receipt"]
        print("case 3a-- receipt peak and recovery")
      }
      else{
        data[row, pol_shape := "peak and recovery"]
        data[row, pol_direction := "cost"]
        print("case 3a-- cost peak and recovery")
        
      }
    }
    
    #5
    else{
      data[row, pol_shape := "other"] 
      print("case 5-- other")
    }
  }

  print(c("normalizer: ", height))
  print(c("end/end-1: ", row_end, row_end_minus1))
  print(diff(tax10_align_norm[row, ]) >= threshold, na.rm=TRUE)
  print("---------------END ROW--------------")
  
}
#---
 
#---------------------------------------------------


#----PLOTTING POLICY IMPULSES-----------------------------------------------------------------------------------

#--------- PLOT AXIES
# Make a new vector for time and ticks t to t+19, for having a uniform X-axis for graphing policy impulse over time
time = 1:(ncol(tax10_align_norm))
time_ticks = character(length = ncol(tax10_align_norm))

for( i in 1:length(time_ticks) ){
  time_tick = i-1
  
  if( time_tick == 0){
    time_ticks[i] = "t"
  }
  else {
    time_ticks[i] = paste0("t+", time_tick)
  }
}
#---


#--------- PLOTTING BY TAX TYPE

# CGT
plot(x = time, y = avg_CGT, type = 'l', lwd = 1.5, col = 'red', 
     main = "CGT", xlab = "Time", ylab = "Norm to full implementation", xaxt = "n",
     ylim = c(min(norm_CGT, na.rm = TRUE), max(norm_CGT, na.rm = TRUE)) 
    )
axis(1, at = seq(from = 1, to = 10, by = 1), labels = time_ticks)
legend("topleft", legend = c("Avg", "Indiv"), lwd = 1, col = c("red", "grey"))
mtext(paste0("Num. pol: ", nrow(norm_CGT) ), side = 3)

for(pol in 1:nrow(norm_CGT)){
  lines(norm_CGT[pol,], col = alpha("black", alpha = 0.2))
}


# DUTY
plot(x = time, y = avg_Duty, type = 'l', lwd = 1.5, col = 'red', 
     main = "Duty", xlab = "Time", ylab = "Norm to full implementation", xaxt = "n",
     ylim = c(min(norm_Duty, na.rm = TRUE), max(norm_Duty, na.rm = TRUE)) 
    )
axis(1, at = seq(from = 1, to = 10, by = 1), labels = time_ticks)
legend("topleft", legend = c("Avg", "Indiv"), lwd = 1, col = c("red", "grey"))
mtext(paste0("Num. pol: ", nrow(norm_Duty) ), side = 3)

for(pol in 1:nrow(norm_Duty)){
  lines(norm_Duty[pol,], col = alpha("black", alpha = .2))
}


# HOUSING
plot(x = time, y = avg_Housing, type = 'l', lwd = 1.5, col = 'red', 
     main = "Housing", xlab = "Time", ylab = "Norm to full implementation", xaxt = "n",
     ylim = c(min(norm_Housing, na.rm = TRUE), max(norm_Housing, na.rm = TRUE)) 
    )
axis(1, at = seq(from = 1, to = 10, by = 1), labels = time_ticks)
legend("topleft", legend = c("Avg", "Indiv"), lwd = 1, col = c("red", "grey"))
mtext(paste0("Num. pol: ", nrow(norm_Housing) ), side = 3)

for(pol in 1:nrow(norm_Housing)){
  lines(norm_Housing[pol,], col = alpha("black", alpha = .2))
}


# INCOME
plot(x = time, y = avg_Income, type = 'l', lwd = 1.5, col = 'red', 
     main = "Income", xlab = "Time", ylab = "Norm to full implementation", xaxt = "n",
     ylim = c(min(norm_Income, na.rm = TRUE), max(norm_Income, na.rm = TRUE)) 
    )
axis(1, at = seq(from = 1, to = 10, by = 1), labels = time_ticks)
legend("topleft", legend = c("Avg", "Indiv"), lwd = 1, col = c("red", "grey"))
mtext(paste0("Num. pol: ", nrow(norm_Income) ), side = 3)


for(pol in 1:nrow(norm_Income)){
  lines(norm_Income[pol,], col = alpha("black", alpha = .2))
}


# INHERITANCE
plot(x = time, y = avg_Inheritance, type = 'l', lwd = 1.5, col = 'red', 
     main = "Inheritance", xlab = "Time", ylab = "Norm to full implementation", xaxt = "n",
     ylim = c(min(norm_Inheritance, na.rm = TRUE), max(norm_Inheritance, na.rm = TRUE)) 
    )
axis(1, at = seq(from = 1, to = 10, by = 1), labels = time_ticks)
legend("topleft", legend = c("Avg", "Indiv"), lwd = 1, col = c("red", "grey"))
mtext(paste0("Num. pol: ", nrow(norm_Inheritance) ), side = 3)

for(pol in 1:nrow(norm_Inheritance)){
  lines(norm_Inheritance[pol,], col = alpha("black", alpha = .2))
}


# INSURANCE
plot(x = time, y = avg_Insurance, type = 'l', lwd = 1.5, col = 'red',
     main = "Insurance", xlab = "Time", ylab = "Norm to full implementation", xaxt = "n",
     ylim = c(min(norm_Insurance, na.rm = TRUE), max(norm_Insurance, na.rm = TRUE)) 
    )
axis(1, at = seq(from = 1, to = 10, by = 1), labels = time_ticks)
legend("topleft", legend = c("Avg", "Indiv"), lwd = 1, col = c("red", "grey"))
mtext(paste0("Num. pol: ", nrow(norm_Insurance) ), side = 3)

for(pol in 1:nrow(norm_Insurance)){
  lines(norm_Insurance[pol,], col = alpha("black", alpha = .2))
}


# NI
plot(x = time, y = avg_NI, type = 'l', lwd = 1.5, col = 'red',
     main = "NI", xlab = "Time", ylab = "Norm to full implementation", xaxt = "n",
     ylim = c(min(norm_NI, na.rm = TRUE), max(norm_NI, na.rm = TRUE)) 
    )
axis(1, at = seq(from = 1, to = 10, by = 1), labels = time_ticks)
legend("topleft", legend = c("Avg", "Indiv"), lwd = 1, col = c("red", "grey"))
mtext(paste0("Num. pol: ", nrow(norm_NI) ), side = 3)

for(pol in 1:nrow(norm_NI)){
  lines(norm_NI[pol,], col = alpha("black", alpha = .2))
}


# PROPERTY
plot(x = time, y = avg_Property, type = 'l', lwd = 1.5, col = 'red',
     main = "Property", xlab = "Time", ylab = "Norm to full implementation", xaxt = "n",
     ylim = c(min(norm_Property, na.rm = TRUE), max(norm_Property, na.rm = TRUE)) 
)
axis(1, at = seq(from = 1, to = 10, by = 1), labels = time_ticks)
legend("topleft", legend = c("Avg", "Indiv"), lwd = 1, col = c("red", "grey"))
mtext(paste0("Num. pol: ", nrow(norm_Property) ), side = 3)

for(pol in 1:nrow(norm_Property)){
  lines(norm_Property[pol,], col = alpha("black", alpha = .2))
}


# SDLT
plot(x = time, y = avg_SDLT, type = 'l', lwd = 1.5, col = 'red',
     main = "SDLT", xlab = "Time", ylab = "Norm to full implementation", xaxt = "n",
     ylim = c(min(norm_SDLT, na.rm = TRUE), max(norm_SDLT, na.rm = TRUE)) 
)
axis(1, at = seq(from = 1, to = 10, by = 1), labels = time_ticks)
legend("topleft", legend = c("Avg", "Indiv"), lwd = 1, col = c("red", "grey"))
mtext(paste0("Num. pol: ", nrow(norm_SDLT) ), side = 3)

for(pol in 1:nrow(norm_SDLT)){
  lines(norm_SDLT[pol,], col = alpha("black", alpha = .2))
}


# VAT
plot(x = time, y = avg_VAT, type = 'l', lwd = 1.5, col = 'red',
     main = "VAT", xlab = "Time", ylab = "Norm to full implementation", xaxt = "n",
     ylim = c(min(norm_VAT, na.rm = TRUE), max(norm_VAT, na.rm = TRUE)) 
)
axis(1, at = seq(from = 1, to = 10, by = 1), labels = time_ticks)
legend("topleft", legend = c("Avg", "Indiv"), lwd = 1, col = c("red", "grey"))
mtext(paste0("Num. pol: ", nrow(norm_VAT) ), side = 3)

for(pol in 1:nrow(norm_VAT)){
  lines(norm_VAT[pol,], col = alpha("black", alpha = .2))
}


# OTHER
plot(x = time, y = avg_Other, type = 'l', lwd = 1.5, col = 'red',
     main = "Other", xlab = "Time", ylab = "Norm to full implementation", xaxt = "n",
     ylim = c(min(norm_Other, na.rm = TRUE), max(norm_Other, na.rm = TRUE)) 
)
axis(1, at = seq(from = 1, to = 10, by = 1), labels = time_ticks)
legend("topleft", legend = c("Avg", "Indiv"), lwd = 1, col = c("red", "grey"))
mtext(paste0("Num. pol: ", nrow(norm_Other) ), side = 3)

for(pol in 1:nrow(norm_Other)){
  lines(norm_Other[pol,], col = alpha("black", alpha = .2))
}

#---


#--------- PLOTTING AGGREGATED TAX TYPE BY GROUP
CAPITAL = rbind(avg_CGT, avg_Inheritance, avg_SDLT)
avg_CAPITAL  = colMeans(CAPITAL, na.rm=TRUE)

plot(x = time, y = avg_CAPITAL, type = 'l', lwd = 1.5, col = 'red',
     main = "Capital group", xlab = "Time", ylab = "Norm to full implementation", xaxt = "n",
     ylim = c(min(CAPITAL, na.rm = TRUE), max(CAPITAL, na.rm = TRUE))
)
axis(1, at = seq(from = 1, to = 10, by = 1), labels = time_ticks)
legend("topleft", legend = c("Avg", "CGT", "Inher", "SDLT"), lwd = 1, col = c("red", "black", "darkgreen", "gold"))
mtext(paste0("CGT: ", nrow(norm_CGT), "  ", "Inher: ", nrow(norm_Inheritance), "  ", "SDLT: ", nrow(norm_SDLT) ), side = 3)

lines(avg_CGT, col = alpha('black', alpha = 0.8) )
lines(avg_Inheritance, col = alpha('darkgreen', alpha = 0.8) )
lines(avg_SDLT, col = alpha('gold', alpha = 0.8) )



CONSUMPTION = rbind(avg_Duty, avg_Insurance, norm_Healthcare, avg_VAT, avg_Housing)
avg_CONSUMPTION = colMeans(CONSUMPTION, na.rm=TRUE)

plot(x = time, y = avg_CONSUMPTION, type = 'l', lwd = 1.5, col = 'red',
     main = "Consumption group", xlab = "Time", ylab = "Norm to full implementation", xaxt = "n",
     ylim = c(min(CONSUMPTION, na.rm = TRUE), max(CONSUMPTION, na.rm = TRUE))
)
axis(1, at = seq(from = 1, to = 10, by = 1), labels = time_ticks)
legend("bottomright", legend = c("Avg", "Duty", "Insur", "Hous", "VAT", "Health"), lwd = 1, col = c("red", "black", "blue", "orange", "grey", "magenta"))
mtext(paste0("Duty: ", nrow(norm_Duty), "  ", "Insur: ", nrow(norm_Insurance), "  ", "Hous: ", nrow(norm_Housing), "  ", "VAT: ", nrow(norm_VAT), "  ", "Health: ", 1 ), side = 3)

lines(avg_Duty, col = alpha('black', alpha = 0.8) )
lines(avg_Insurance, col = alpha('blue', alpha = 0.8) )
lines(avg_Housing, col = alpha('orange', alpha = 0.8) )
lines(avg_VAT, col = alpha('grey', alpha = 0.8) )
lines(norm_Healthcare, col = alpha('magenta', alpha = 0.8) )
#---








#---------------------------------------------------


#----WRITE OUT

#wide
write.csv(tax3_groupSums, "/Users/ali/Desktop/Lavori/UK_Narrative/Data/R_Output/Wide/tax3_groupSums.csv")
write.csv(tax3_typeSums, "/Users/ali/Desktop/Lavori/UK_Narrative/Data/R_Output/Wide/tax3_typeSums.csv")
write.csv(tax10_groupSums, "/Users/ali/Desktop/Lavori/UK_Narrative/Data/R_Output/Wide/tax10_groupSums.csv")
write.csv(tax10_typeSums, "/Users/ali/Desktop/Lavori/UK_Narrative/Data/R_Output/Wide/tax10_typeSums.csv")
write.csv(Cloyne_groupSums, "/Users/ali/Desktop/Lavori/UK_Narrative/Data/R_Output/Wide/Cloyne_groupSums.csv")
write.csv(Cloyne_typeSums, "/Users/ali/Desktop/Lavori/UK_Narrative/Data/R_Output/Wide/Cloyne_typeSums.csv")
#---

#long

tax3_groupSumsL = melt(data.table(tax3_groupSums, keep.rownames = TRUE))
tax3_typeSumsL = melt(data.table(tax3_typeSums, keep.rownames = TRUE))
tax10_groupSumsL = melt(data.table(tax10_groupSums, keep.rownames = TRUE))
tax10_typeSumsL = melt(data.table(tax10_typeSums, keep.rownames = TRUE))
Cloyne_groupSumsL = melt(data.table(Cloyne_groupSums, keep.rownames = TRUE))
Cloyne_typeSumsL = melt(data.table(Cloyne_typeSums, keep.rownames = TRUE))

write.csv(tax3_groupSumsL, "/Users/ali/Desktop/Lavori/UK_Narrative/Data/R_Output/Long/tax3_groupSumsL.csv")
write.csv(tax3_typeSumsL, "/Users/ali/Desktop/Lavori/UK_Narrative/Data/R_Output/Long/tax3_typeSumsL.csv")
write.csv(tax10_groupSumsL, "/Users/ali/Desktop/Lavori/UK_Narrative/Data/R_Output/Long/tax10_groupSumsL.csv")
write.csv(tax10_typeSumsL, "/Users/ali/Desktop/Lavori/UK_Narrative/Data/R_Output/Long/tax10_typeSumsL.csv")
write.csv(Cloyne_groupSumsL, "/Users/ali/Desktop/Lavori/UK_Narrative/Data/R_Output/Long/Cloyne_groupSumsL.csv")
write.csv(Cloyne_typeSumsL, "/Users/ali/Desktop/Lavori/UK_Narrative/Data/R_Output/Long/Cloyne_typeSumsL.csv")
#---


to_write = data.table(tax3_groupSums, keep.rownames = TRUE)
melt(to_write)
write.csv(to_write, "/Users/ali/Desktop/UK_Narrative/Data/R_Output/Narrative2021.csv")
