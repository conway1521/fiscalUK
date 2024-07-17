This repository contains a script for analyzing tax policy data from various sources. The script includes several steps for importing, cleaning, transforming, and analyzing the data to identify unique tax policies, their impacts, and trends over time. Below is a summary of the key functionalities and steps included in the script.

Installation

The following R packages are required:

	•	data.table
	•	readr
	•	tidyverse
	•	readxl
	•	writexl
	•	dplyr
	•	lubridate
	•	foreign
	•	haven
	•	pracma
	•	scales
	•	stringr

Key Functionalities

Data Importing and Cleaning

	•	Reading Excel Files: Custom functions my_read_excel and my_write_excel are used to read and write Excel files.
	•	Column Name Cleaning: The clean_column_names function replaces whitespaces in column names with underscores and removes brackets.
	•	Spelling Correction: The fix_spelling function corrects common spelling mistakes in the data.
	•	Combining Columns: The combine_two_columns function combines the Tax_Type and Sub_Type columns.
	•	Extracting Unique Values: The get_column_unique and get_column_unique_nocase functions return unique values of a column, case-sensitive and case-insensitive respectively.
	•	Date Range Checking: The script checks and prints the date ranges in the data frames.

Data Analysis

	•	Matching Rows: The match_rows function matches rows between different data frames based on tax and description columns.
	•	Finding Keywords: The find_keywords2 and find_keywords3 functions extract keywords from data for further analysis.
	•	Policy Grouping: Policies are grouped by type using the FilterPols function.

Time Series and Present Value Calculations

	•	Quarter Calculation: The findQuarter_cal and findQuarter_fis functions determine the quarter of a given date according to calendar and fiscal years.
	•	Present Value Calculation: The PVfunc function calculates the present value of future tax impacts.
	•	Quarter Spread: The Qspread function spreads annual tax data across quarters.

Normalization and Policy Shape Analysis

	•	Normalization: Tax impacts are normalized based on the year with the greatest effect.
	•	Policy Shape Classification: Policies are classified based on their time-series shapes (e.g., growing, peak, peak and recovery) using the data data frame.

Plotting

	•	Time Series Plotting: The script generates time series plots for different tax policy groups and types.
	•	Policy Impulse Plotting: Normalized policy impulses are plotted over time for each tax type.
