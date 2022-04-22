********************************************************************************
* Program for industrial or occupational codes assignation
********************************************************************************

cap program drop assignation_rule
program define assignation_rule
{
syntax, id(varlist) origvar(str) classfrom(str) classto(str) dig(str) seed(int)

// Step 0: Preliminaries

set seed `seed'
sort `id', stable
isid `id', sort
egen id = group(`id')
sort id, stable
isid id, sort

// Step 1: Merge Classes
# d ;
merge_class, 
	id(`id') 
	origvar(`origvar') 
	classfrom(`classfrom') 
	dig(`dig') 
	seed(`seed')
;
# d cr
local corrlist `r(clist)'

// Step 2: Merge Correspondences
foreach c of local corrlist{
	# d ;
	merge_correspondence, 
		id(`id') 
		origvar(`classfrom'_`c'dig) 
		classfrom(`classfrom') 
		classto(`classto') 
		dig(`c') 
		seed(`seed')
	;
	# d cr
}

// Step 3: Clean-Up Stage
drop id
}
end
