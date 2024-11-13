clear
import excel "C:\Users\Emma\OneDrive - purdue.edu\Desktop\RA Fall 2023\sorting model practice for buyouts.xlsx", sheet("Data") firstrow

*** Data Generation ***
clear
input TractID_b
101
102
103
104
105
106
107
end
gen price_b = rnormal(500000, 100000) // census data
gen X_itb = rnormal(0, 10) // house attributes
gen Z_bt = rnormal(0, 10) // tract attributes, which vary by w_ik (tract level demographics)
gen Mandatory = (runiform() > 0.5)  // b_jt = 1 if mandatory
gen TractPop_b = rnormal(1000, 200) // census data
gen share_black = rnormal(0.2, 0.05)  // census data
gen share_hispanic = rnormal(0.3, 0.05) // census data
gen share_white = rnormal(0.5, 0.1) // census data
gen share_lowincome = rnormal(0.4, 0.1) // census data
gen share_midincome = rnormal(0.4, 0.1) // census data
gen share_highincome = rnormal(0.2, 0.05) // census data
gen share_spanish = rnormal(0.25, 0.05) // census data
gen near_jt = (runiform() > 0.5)   
* To be estimated *
gen alpha_p = -0.002 // price coeff
gen alpha_mandatory = 9 // mandatory buyout coeff
gen alpha_z = 0.2 // neighb coeff
gen alpha_x = 0.25 // house coeff 

save tracts, replace

*** Cross households with choice set ***
clear
import excel "C:\Users\Emma\OneDrive - purdue.edu\Desktop\RA Fall 2023\sorting model practice for buyouts.xlsx", sheet("Data") firstrow

cross using tracts
sort SaleID TractID_a TractID_b
order SaleID TractID_a TractID_b

egen totalpopb = total(TractPop_b)  // Total population across all tracts
order SaleID TractID_a TractID_b totalpopb

gen actualshare_b = TractPop_b/totalpopb

gen xi = rnormal(0, 2)
gen z_j = rnormal(1, 2)

*** Utility Calculation ***
gen delta_jt = Mandatory*alpha_mandatory + price_b * alpha_p + X_itb * alpha_x + Z_bt * alpha_z
gen epsilon = rnormal(0, 1)
gen V = delta_jt + Z_bt * alpha_z + epsilon

sort SaleID V
bysort SaleID: gen d = _n == 7

gen expV = exp(V)
sort TractID_b
bysort TractID_b: gen sumexpV = sum(expV)
gen Pr_ijt = expV/sumexpV
gen shareNt = 1/TractPop_b
gen s_jt = Pr_ijt * shareNt
sort TractID_b
bysort TractID_b: gen predictedshare_b = sum(s_jt)

*** Likelihood Estimation ***
gen LL = d * log(Pr_ijt) + (1 - d) * log(1 - Pr_ijt)
sum LL


*** Stage 2 ***
replace delta_jt= 0 if TractID_b == 102

gen IV = price_b * 1.2 + rnormal(0, 50000)

ivregress 2sls delta_jt (price_b = IV) X_itb Z_bt Mandatory
reg delta_jt X_itb Z_bt price_b Mandatory
