********************************************************************************
* Program for industrial or occupational codes assignation
********************************************************************************

cap program drop merge_correspondence
program define merge_correspondence
{
syntax, id(varlist) origvar(str) classfrom(str) classto(str) dig(str) seed(int)

// 1. Build Correspondence Table
preserve

*ISIC
local tab_isic_rev2_isic_rev3_type direct  
local tab_isic_rev2_isic_rev31_type direct
local tab_isic_rev2_isic_rev4_type indirect

local tab_isic_rev3_isic_rev2_type reverse
local tab_isic_rev3_isic_rev31_type direct
local tab_isic_rev3_isic_rev4_type indirect

local tab_isic_rev31_isic_rev2_type reverse
local tab_isic_rev31_isic_rev3_type direct
local tab_isic_rev31_isic_rev4_type direct

local tab_isic_rev4_isic_rev2_type indirect
local tab_isic_rev4_isic_rev3_type indirect
local tab_isic_rev4_isic_ev31_type direct

*ISCO
local tab_isco_88_isco_08_type direct  
local tab_isco_08_isco_88_type reverse

*Repository
local root "https://raw.githubusercontent.com/RaimundoSmithM/GDL-Harmonization-Tool/main/Correspondence%20Tables/"
local from_isic_rev2_to_isic_rev31 "from_isic_rev2_to_isic_rev31_direct.txt"
local from_isic_rev2_to_isic_rev3 "from_isic_rev2_to_isic_rev3_direct.txt"
local from_isic_rev2_to_isic_rev4 "from_isic_rev2_to_isic_rev4_indirect.txt"
local from_isic_rev31_to_isic_rev2 "from_isic_rev31_to_isic_rev2_reverse.txt"
local from_isic_rev31_to_isic_rev3 "from_isic_rev31_to_isic_rev3_direct.txt"
local from_isic_rev31_to_isic_rev4 "from_isic_rev31_to_isic_rev4_direct.txt"
local from_isic_rev3_to_isic_rev2 "from_isic_rev3_to_isic_rev2_reverse.txt"
local from_isic_rev3_to_isic_rev31 "from_isic_rev3_to_isic_rev31_direct.txt"
local from_isic_rev3_to_isic_rev4 "from_isic_rev3_to_isic_rev4_indirect.txt"
local from_isic_rev4_to_isic_rev2 "from_isic_rev4_to_isic_rev2_indirect.txt"
local from_isic_rev4_to_isic_rev31 "from_isic_rev4_to_isic_rev31_direct.txt"
local from_isic_rev4_to_isic_rev3 "from_isic_rev4_to_isic_rev3_indirect.txt"
local from_isco_08_to_isco_88 "from_isco_08_to_isco_88_reverse.txt"
local from_isco_88_to_isco_08 "from_isco_88_to_isco_08_direct.txt"
di in red "### `root'`from_`classfrom'_to_`classto'' ###"

*Import
import delimited using "`root'`from_`classfrom'_to_`classto''", clear delim(";")
if "`classfrom'" == "isic_rev2" tostring isic_rev2_secdig, replace
if "`classto'" == "isic_rev2" tostring isic_rev2_secdig, replace

*Relevant Variables
local factor_1 1000
local factor_2 100
local factor_3 10
local factor_4 1
if "`dig'" != "sec" {
	gen from = floor(`classfrom'_4dig/`factor_`dig'')
	gen to = floor(`classto'_4dig/`factor_`dig'')
}
if "`dig'" == "sec"{
	gen from = `classfrom'_secdig 
	gen to = `classto'_secdig
	}
*keep from to
drop if mi(to) | mi(from)
bys from to: keep if _n == 1
tempfile corrmerge
save `corrmerge', replace
restore

// 2. Merge Correspondence Table

*Relevant Dataset
preserve
keep id `origvar'
ren `origvar' from
if "`dig'" != "sec" destring from, replace force
if "`dig'" == "sec" tostring from, replace force

*Joinby
joinby from using `corrmerge', unmatched(both) _merge(_merge) update
*keep if !mi(form) & !mi(to)

// 3. Assign Final Codes

gen z = runiform()
sort id z, stable
bys id: keep if _n == 1
keep id to
tempfile assignmerge
save `assignmerge', replace
restore

// 4. Merge Back to the Dataset
merge 1:1 id using `assignmerge', nogen update
ren to `classto'_`dig'dig 
}
end
