********************************************************************************
* Creation of Concordance Tables Repository
* 1. Industrial Sections for ISIC Tables
* 2. From local industry codes to ISIC Rev 4
* 3. From local occupation codes to ISCO 08
********************************************************************************

// Setup

*Main Directory: ISCO ISIC Correspondence Tool
if "`c(username)'" == "raimu" global maindir "D:/Dropbox/Trabajos/World Bank/ISCO ISIC Correspondence Tool/"
if "`c(username)'" == "..."   global maindir "..."

*Working Directories
global outpath "${maindir}Data/Intermediate Data/"

// Export Data Program

cap program drop outdata
program define outdata
{
syntax, outname(str)
	save "`outname'", replace
	outsheet using "`outname'.txt", replace delim(";")
}
end

********************************************************************************
* 1. ISCO Occupations
********************************************************************************

*ISCO 08
local isco_08 "https://www.ilo.org/ilostat-files/ISCO/newdocs-08-2021/ISCO-08/ISCO-08%20EN.csv"

*ISCO 88
local isco_88 "https://www.ilo.org/ilostat-files/ISCO/newdocs-08-2021/ISCO-08/ISCO-08%20EN.csv"

** PENDING **

// ISCO 08

*Stable Source
clear 
insheet using "`isco_08'", clear delim(",")
keep if isco_version == "ISCO-08"
destring unit, replace force
ren unit isco_08_4dig
keep isco_08_4dig
keep if mi(isco_08_4dig)
bys isco_08_4dig: keep if _n == 1
sort isco_08_4dig, stable
isid isco_08_4dig, sort
foreach d in 1 2 3{
	local factor_1 1000
	local factor_2 100
	local factor_3 10
	local factor_4 1
	gen isco_08_`d'dig = floor(isco_08_4dig/`factor_`d'')
}
outdata, outname("${outpath}Class Tables/isco_08")

// ISCO 88

*Stable Source
clear 
insheet using "`isco_88'", clear delim(",")
keep if isco_version == "ISCO-88"
destring unit, replace force
ren unit isco_88_4dig
keep isco_88_4dig
keep if mi(isco_88_4dig)
bys isco_88_4dig: keep if _n == 1
sort isco_88_4dig, stable
isid isco_88_4dig, sort
foreach d in 1 2 3{
	local factor_1 1000
	local factor_2 100
	local factor_3 10
	local factor_4 1
	gen isco_88_`d'dig = floor(isco_88_4dig/`factor_`d'')
}
outdata, outname("${outpath}Class Tables/isco_88")

********************************************************************************
* 2. Occupation Concordance Lists 
********************************************************************************

** Step 2.1: Raw data collection from stable links

// ISCO Codes

*From ISCO 88 to ISCO 08
local isco_88_isco_08 "http://web.archive.org/web/20160305071119/http://www.ilo.org/public/english/bureau/stat/isco/docs/corrtab08-88.xls"

// From ISCO 88 to ISCO 08

clear
import excel using "`isco_88_isco_08'", first
keep ISCO08Code ISCO88code
destring *, replace force
ren ISCO08Code isco_08_4dig
ren ISCO88code isco_88_4dig
bys isco_88_4dig isco_08_4dig: keep if _n == 1
outdata, outname("${outpath}Concordance Tables/from_isco_88_to_isco_08_direct")
outdata, outname("${outpath}Concordance Tables/from_isco_08_to_isco_88_reverse")

/*RS: This is an ad-hoc solution, fix issue with source data for ISCO tables
foreach d in 08 88{
	preserve
	keep isco_`d'_4dig
	bys isco_`d'_4dig: keep if _n == 1
	outdata, outname(${outpath}isco_`d')
	restore
}
