********************************************************************************
* Program for industrial or occupational codes assignation
********************************************************************************

cap program drop merge_class
program define merge_class, rclass
{
syntax, origvar(str) classfrom(str) dig(str) id(varlist) seed(int)

// Step 1. Get Sequential Classifications

*Raw Classification File
preserve
local root "https://raw.githubusercontent.com/RaimundoSmithM/GDL-Harmonization-Tool/main/Class%20Tables/"
import delimited using "`root'`classfrom'.txt", clear delim(";")
if "`classfrom'" == "isic_rev2" tostring isic_rev2_secdig, replace

*Sequential Classification File Generation
if regexm("`classfrom'","isic") == 1{
	local flist_4dig `classfrom'_4dig `classfrom'_3dig `classfrom'_2dig `classfrom'_secdig `classfrom'_1dig
	local flist_3dig `classfrom'_3dig `classfrom'_2dig `classfrom'_secdig `classfrom'_1dig
	local flist_2dig `classfrom'_2dig `classfrom'_secdig `classfrom'_1dig
	local flist_secdig `classfrom'_secdig `classfrom'_1dig
	local flist_1dig `classfrom'_1dig
	if "`dig'" == "4" local clist 4 3 2 sec 1
	if "`dig'" == "3" local clist 3 2 sec 1
	if "`dig'" == "2" local clist 2 sec 1
	if "`dig'" == "sec" local clist sec // 1  RS: we should this discuss how to handle this case. For now, just a non-sequential merge
	if "`dig'" == "1" local clist 1	
}

if regexm("`classfrom'","isco") == 1{
	local flist_4dig `classfrom'_4dig `classfrom'_3dig `classfrom'_2dig `classfrom'_1dig
	local flist_3dig `classfrom'_3dig `classfrom'_2dig `classfrom'_1dig
	local flist_2dig `classfrom'_2dig `classfrom'_1dig
	local flist_1dig `classfrom'_1dig
	if "`dig'" == "4" local clist 4 3 2 1
	if "`dig'" == "3" local clist 3 2 1
	if "`dig'" == "2" local clist 2 1
	if "`dig'" == "1" local clist 1
	
}
tempfile tocall
save `tocall', replace
foreach c of local clist{
	use `tocall', clear
	keep `flist_`c'dig'
	bys `flist_`c'dig': keep if _n == 1
	tempfile class_`c'dig
	save `class_`c'dig', replace
}
restore

// Step 2. Recode Original Variable and Sequentially Merge Classifications
di in red " ### ### ### `clist' ### ### ###"
if "`dig'" != "sec" destring `origvar', force gen(origvar)
if "`dig'" == "sec" tostring `origvar', force gen(origvar)

*Sequential Variables
foreach c of local clist{
	local factor_4_4  1
	local factor_3_4  10
	local factor_2_4  100
	local factor_1_4  1000	
	
*	local factor_4_3  1
	local factor_3_3  1
	local factor_2_3  10
	local factor_1_3  100
	
*	local factor_4_2  1
*	local factor_3_2  10
	local factor_2_2  1
	local factor_1_2  10	
	
*	local factor_4_1  1
*	local factor_3_1  10
*	local factor_2_1  100
	local factor_1_1  1	
	if "`c'" != "sec" & "`dig'" != "sec" gen `classfrom'_`c'dig = floor(origvar/`factor_`c'_`dig'') // Section only is imputed through merge with classification
}
drop origvar

*Merge Classes
foreach c of local clist{	
	# d ;
	joinby 
		`classfrom'_`c'dig 
		using `class_`c'dig', 
		unmatched(master)
		update
	;
	# d cr
	drop _merge
	gen z = runiform()
	gsort id -z
	bys id: keep if _n == 1
	drop z
}
return local clist `clist'

}
end


/*
cap program drop merge_class
program define merge_class
{
syntax, origvar(str) classfrom(str) dig(str)

// 1. Produce Master Data Merge Inputs
	foreach d in of local dlist{
		local factor_1 1000
		local factor_2 100
		local factor 3 10
		local factor_4 1
		gen `classfrom'_`dig'dig = floor(`classfrom'_4dig/`factor_`d'')
	}

// 1. Get Complete Table

*Digits of Aggregation
if "`dig'" == "4" local dlist sec 1 2 3 4
if "`dig'" == "3" local dlist sec 1 2 3
if "`dig'" == "2" local dlist sec 1 2
if "`dig'" == "1" local dlist sec 1
if "`dig'" == "sec" local dlist sec

foreach d of local dlist{
	preserve
	local root "https://raw.githubusercontent.com/RaimundoSmithM/GDL-Harmonization-Tool/main/Correspondence%20Tables/"
	import delimited using "`root'`classfrom'", clear delim(";")
	foreach d in 1 2 3{
		local factor_1 1000
		local factor_2 100
		local factor 3 10
		gen `classfrom'_`dig'dig = floor(`classfrom'_4dig/`factor_`d'')
	}
	bys `classfrom'_`dig'dig: keep if _n == 1
	if inlist("`dig'","sec","1",",2","3") drop `classfrom'_4dig
	if inlist("`dig'","sec","1",",2") drop `classfrom'_3dig
	if inlist("`dig'","sec","1") drop  drop `classfrom'_2dig
	if inlist("`dig'","sec") drop `classfrom'_1dig
	tempfile classmerge_`d'dig
	save `classmerge_`d'dig', replace
	restore

// 3. Merge Complete Table
joinby `classfrom'_`dig'dig using `classmerge', nogen keep(master matched)
}

}
end
