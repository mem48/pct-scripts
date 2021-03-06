clear
clear matrix
cd "C:\Users\Anna Goodman\Dropbox\GitHub"
		
x

	/***********************
	* PREPARE THE INPUT INDIVIDUAL-LEVEL SYNTHETIC POP FROM CENSUS [overlap with metahit work] (INPUT 1)
	***********************
		** RAW INPUTS TO MAKE 'Census2011EW_AllAdults.dta' [all safe-guarded]
			* LSOA-level Age*Sex*T2!: WICID WM12EW[CT0489]_lsoa.csv 
			* Ethnicity, all flows: WICID wu08cew_msoa_v1.csv
			* Ethnicity * T2W, selected flows: WICID CT0600.xls --> use to make CT0600_edit.xls editting top rows
			* Car ownership, all flows: WICID wu09buk_msoa_v1.csv
			* Car ownership * T2W, selected flows: WICID CT0599.xls --> use to make CT0599_edit.xls editting top rows
			* Individual-level data 5% sample, regional level: UKDA, 'isg_regionv2.dta' from https://discover.ukdataservice.ac.uk/catalogue/?sn=7605&type=Data%20catalogue
			* Individual-level data 5% sample, LA level: UKDA, 'recodev12.dta' from https://discover.ukdataservice.ac.uk/catalogue/?sn=7682&type=Data%20catalogue
			* Area-level Index Multiple Deprivation 2015 (Eng)/2014 (Wales)
			* Area-level Rural Urban Classification 2011

		** DO FILES TO MAKE 'Census2011EW_AllAdults.dta':
			* "..\1 - Phys Act_1-PA main\2017_MetaHIT_analysis\2_program\0.1a_CensusCommuteSP_build_180306.do" 
			* "..\1 - Phys Act_1-PA main\2017_MetaHIT_analysis\2_program\0.1b_CensusNonCommuteSP_build_180306.do" 
		
	***********************
	* PREPARE GEOG LOOK UP FILES 
	***********************
		import delimited "pct-inputs\02_intermediate\x_temporary_files\unzip\OA11_LSOA11_MSOA11_LAD11_EW_LUv2.csv", varnames(1) clear 
		drop oa11cd
		duplicates drop
		saveold "pct-inputs\02_intermediate\x_temporary_files\scenario_building\LSOA11_MSOA11_LAD11_EW_LUv2.dta", replace
		
		foreach x in msoa lsoa {
		use "pct-inputs\02_intermediate\x_temporary_files\scenario_building\LSOA11_MSOA11_LAD11_EW_LUv2.dta", clear
		rename lso11anm lsoa11nm
		rename `x'11cd geo_code
		rename `x'11nm geo_name
		rename lad11nm lad_name
		keep geo_code geo_name lad11cd lad_name
		duplicates drop
		saveold "pct-inputs\02_intermediate\x_temporary_files\scenario_building\commute\\`x'\geo_code_lookup.dta", replace		
		}
		
	***************************
	** MORTALITY DATA FOR COMMUTERS (INPUT 2)
	***************************
		import excel "pct-inputs\01_raw\03_health_data\commute_microsim\LA_WeightedMortality16plus_2016.xls", sheet("Commuters_MortRate") clear firstrow
		* FIX GEOGRAPHIES
			gen temp=1
			recode temp 1=2 if geography=="Cornwall,Isles of Scilly"
			recode temp 1=2 if geography=="Westminster,City of London"
			expand temp
			bysort geography: gen littlen=_n
			* FIX PLACES WITH SMALL AREAS MERGED
				replace geographycode="E06000053" if geographycode=="E06000052" & littlen==2 	// ISLES OF SCILLY, NOT CORNWALL
				replace geography="Cornwall" if geographycode=="E06000052"
				replace geography="Isles of Scilly" if geographycode=="E06000053"
				replace geographycode="E09000001" if geographycode=="E09000033" & littlen==2	// CITY OF LONDON, NOT WESTMINSTER
				replace geography="Westminster" if geographycode=="E09000033"
				replace geography="City of London" if geographycode=="E09000001"
			* FIX PLACES WITH 2014 NOT 2011 LA CODES
				replace geographycode="E06000048" if geographycode=="E06000057"
				replace geographycode="E07000100" if geographycode=="E07000240"
				replace geographycode="E07000104" if geographycode=="E07000241"
				replace geographycode="E07000097" if geographycode=="E07000242"
				replace geographycode="E07000101" if geographycode=="E07000243"
				replace geographycode="E08000020" if geographycode=="E08000037"
			drop temp littlen
				
		* RENAME
			rename *16to24* *age1*
			rename *25to34* *age2*
			rename *35to49* *age3*
			rename *50to64* *age4*
			rename *65to74* *age5*
			rename *75plus* *age6*
			rename *fem* *sex2*
			rename *mal* *sex1*
			rename mort* mortrate1*
			rename *_sex* *0*
			rename *_age* *0*
			
		* RESHAPE
			gen littlen=_n
			reshape long mortrate,i(littlen) j(celltype) 
			tostring celltype, gen(typestring)
			gen sex=substr(typestring,3,1)
			gen agecat=substr(typestring,5,1)
			destring sex agecat, replace
			gen female=sex-1
			
			rename geographycode home_lad11cd
			order home_lad11cd female agecat mortrate
			keep home_lad11cd-mortrate
			compress
		saveold "pct-inputs\02_intermediate\x_temporary_files\scenario_building\commute\0temp\mortrate_individual_CommuteSP.dta", replace

	**********************************	
	* PREPARE CYCLE STREETS DATA - SAVE AS STATA (INPUT 3)
	**********************************	
		import delimited "pct-inputs\02_intermediate\02_travel_data\commute\msoa\rfrq_all_data.csv", clear
		saveold "pct-inputs\02_intermediate\x_temporary_files\scenario_building\commute\msoa\rfrq_all_data.dta", replace
		import delimited "pct-inputs\02_intermediate\02_travel_data\commute\lsoa\rfrq_all_data.csv", clear
		saveold "pct-inputs\02_intermediate\x_temporary_files\scenario_building\commute\lsoa\rfrq_all_data.dta", replace
	*/	

	*****************
	** MERGE OD DATA
	*****************
	use "..\1 - Phys Act_1-PA main\2017_MetaHIT_analysis\1b_datacreated\Census2011EW_AllAdults.dta", clear
			drop census_id ecactivity commute_distcat commute_bicycle12- commute_bus12
			
		* DROP WORK FROM HOME OR NON-COMMUTERS
			drop if work_lsoa=="OD0000001" | work_lsoa==""
					
		* MERGE IN MORT RATES
			merge m:1 home_lad11cd agecat female using "pct-inputs\02_intermediate\x_temporary_files\scenario_building\commute\0temp\mortrate_individual_CommuteSP.dta", nogen

		* MERGE IN CYCLE STREETS VARIABLES
			rename home_lsoa geo_code1
			rename work_lsoa geo_code2
			merge m:1 geo_code1 geo_code2 using "pct-inputs\02_intermediate\x_temporary_files\scenario_building\commute\lsoa\rfrq_all_data.dta", keepus(rf_dist_km rf_avslope_perc)
			drop if _merge==2
			drop _merge
			rename geo_code1 geocodetemp
			rename geo_code2 geo_code1
			rename geocodetemp geo_code2
			merge m:1 geo_code1 geo_code2 using "pct-inputs\02_intermediate\x_temporary_files\scenario_building\commute\lsoa\rfrq_all_data.dta", keepus(rf_dist_km rf_avslope_perc) update
			drop if _merge==2
			drop _merge
			rename geo_code1 work_lsoa
			rename geo_code2 home_lsoa
				
	*****************
	** STEP 1: GENERATE FLOW TYPE
	*****************
		gen work_lsoatemp=substr(work_lsoa,1,1)
		replace work_lsoa="OutsideEW" if work_lsoatemp=="S" | work_lsoatemp=="N" | work_lsoa=="OD0000002" | work_lsoa=="OD0000004"
			* Make 'other' if S = scotland, N = northern ireland, OD0000002 = offshore installation, OD0000004 = otherwise overseas

		gen flowtype=.
		recode flowtype .=1 if (work_lsoatemp=="E" | work_lsoatemp=="W") & rf_dist_km!=. & home_lsoa!=work_lsoa
		recode flowtype .=2 if home_lsoa==work_lsoa
		recode flowtype .=3 if work_lsoa=="OD0000003"
		recode flowtype .=4 if (work_lsoatemp=="E" | work_lsoatemp=="W") & rf_dist_km==. 
		recode flowtype .=4 if work_lsoa=="OutsideEW"
		label def flowtypelab 1 "England/Wales between-zone" 2 "Within zone" 3 "No fixed place" 4 "Over max dist or outside England/Wales, offshore installation", modify
		label val flowtype flowtypelab
		drop work_lsoatemp
		
		replace work_lsoa="Other" if flowtype==4
		replace work_msoa="Other" if flowtype==4
			
		/** COUNT NO PEOPLE PER FLOWTYPE - TABLE 1 IN MANUAL C1
			ta flowtype // % commuters
			ta flowtype if commute_mainmode9==1 // % cyclists
		*/
		
	*****************
	** STEP 2: ASSIGN VALUES IF DISTANCE/HILLINESS UNKNOWN
	*****************				
		** ASSIGN ESTIMATED HILLINESS + DISTANCE VALUES IF START AND END IN SAME PLACE
			by home_lsoa work_lsoa, sort: gen littlen1=_n
			by littlen1 home_lsoa (rf_dist_km), sort: gen littlen2=_n
			foreach x in rf_dist_km rf_avslope_perc {
			gen `x'temp=`x'
			replace `x'temp=. if littlen2>3 | littlen1>1
			bysort home_lsoa: egen `x'temp2=mean(`x'temp)
			replace `x'=`x'temp2 if flowtype==2 & `x'==.
			}
			replace rf_dist_km=rf_dist_km/3 if flowtype==2 
				* DISTANCE = A THIRD OF THE MEAN DISTANCE OF SHORTEST 3 FLOWS
				* HILLINESS = MEAN HILLINESS OF SHORTEST 3 FLOWS
			recode rf_dist_km .=0.79 if (home_lsoa=="E02006781" | home_lsoa=="E01019077") & home_lsoa==work_lsoa 		//ISLES OF SCILLY [msoa/lsoa] - ESTIMATED FROM DISTANCE DISTRIBUTION
			recode rf_avslope_perc .=0.2 if (home_lsoa=="E02006781" | home_lsoa=="E01019077") & home_lsoa==work_lsoa //ISLES OF SCILLY [msoa/lsoa] - ESTIMATED FROM CYCLE STREET 
			drop littlen1 littlen2 rf_dist_kmtemp rf_dist_kmtemp2 rf_avslope_perctemp rf_avslope_perctemp2 
			
		** ASSIGN DISTANCE *AMONG CYCLISTS* VALUES IF NO FIXED PLACE : MEAN DIST AMONG CYCLISTS TRAVELLING <15KM
			gen cyc_dist_km=rf_dist_km
			foreach x in 15 30 {
			gen rf_dist_km`x'=rf_dist_km
			replace rf_dist_km`x'=. if rf_dist_km>`x' | flowtype>2
			gen bicycle`x'=(commute_mainmode9==1)
			replace bicycle`x'=. if rf_dist_km`x'==.
			}
			bysort home_lsoa: egen numnrf_dist_km15=sum(rf_dist_km15*bicycle15)
			bysort home_lsoa: egen denrf_dist_km15=sum(bicycle15)
			gen meanrf_dist_km15=numnrf_dist_km15/denrf_dist_km15
			replace cyc_dist_km=meanrf_dist_km15 if flowtype==3 

		** ASSIGN DISTANCE *AMONG CYCLISTS* VALUES IF OUTSIDE ENG/WALES OR >30KM: MEAN DIST AMONG CYCLISTS TRAVELLING <30KM
			egen numnrf_dist_km30=sum(rf_dist_km30*bicycle30)
			egen denrf_dist_km30=sum(bicycle30)
			gen meanrf_dist_km30=numnrf_dist_km30/denrf_dist_km30
			replace cyc_dist_km=meanrf_dist_km30 if flowtype==4 
			replace cyc_dist_km=meanrf_dist_km30 if flowtype==3 & cyc_dist_km==.	// USE 30KM if NO LOCAL CYCLIST GOING <15KM
		
		order home_lsoa- work_msoa flowtype rf_dist_km rf_avslope_perc cyc_dist_km mortrate commute_mainmode9 female agecat nonwhite nocar urbancat5 sparse incomedecile
		keep home_lsoa-incomedecile
		compress
		saveold "pct-inputs\02_intermediate\x_temporary_files\scenario_building\commute\0temp\CommuteSPTemp1.dta", replace
		
	*****************
	** STEP 3A: CALCULATE PROPENSITY TO CYCLE
	*****************
		use "pct-inputs\02_intermediate\x_temporary_files\scenario_building\commute\0temp\CommuteSPTemp1.dta", clear
		** INPUT PARAMETERS FLOW TYPE 1+2
			recode commute_mainmode9 2/max=0,gen(bicycle)
			recode agecat 6=5, gen(agecat5)
			recode agecat 1/3=.,gen(agecat_old)
			recode agecat 1/3=1 4/6=2, gen(femagecat)
			replace femagecat=(femagecat+10) if female==1
			label def femagecatlab 1 "Male 16 to 49" 2 "Male 50+" 11 "Female 16 to 49" 12 "Female 50+" 
			label val femagecat femagecatlab
			recode incomedecile 1/2=1 3/4=2 5/6=3 7/8=4 9/10=5,gen(incomefifth)
			recode urbancat5 1/2=. ,gen(urbancat5_3only)
			
			gen rf_dist_kmsq=rf_dist_km^2
			gen rf_dist_kmsqrt=sqrt(rf_dist_km)
			gen ned_rf_avslope_perc=rf_avslope_perc-0.78 // CENTRE ON 13TH PERCENTILE, AS DUTCH AVERAGE HILLINESS EQUAL TO 13TH PERCENTILE AREAS ENGLAND	
			gen interact=rf_dist_km*ned_rf_avslope_perc
			gen interactsqrt=rf_dist_kmsqrt*ned_rf_avslope_perc
		
		** FIT REGRESSION EQUATION - FLOW TYPE 1+2 - GOV TARGET, DUTCH, EBIKE [model derived from MSOA trips]
			*xi: logit bicycle rf_dist_km rf_dist_kmsqrt rf_dist_kmsq ned_rf_avslope_perc interact interactsqrt if flowtype <=2 
			gen pred_basegt= /*
				*/ -4.018 + (-0.6369 * rf_dist_km) + (1.988 * rf_dist_kmsqrt) + (0.008775 * rf_dist_kmsq) + (-0.2555 * ned_rf_avslope_perc) + (0.02006 * rf_dist_km*ned_rf_avslope_perc) + (-0.1234 * rf_dist_kmsqrt*ned_rf_avslope_perc) 
			gen bdutch = 2.550+(-0.08036*rf_dist_km)					// FROM DUTCH NTS [could in future do this by age/sex? each time comparing total Eng/Wales pop to a specific Dutch pop]
			replace bdutch=. if flowtype==3
			gen bebike= (0.05509*rf_dist_km)+(-0.000295*rf_dist_kmsq)	// PARAMETERISED FROM DUTCH TRAVEL SURVEY, ASSUMING NO DIFFERENCE AT 0 DISTANCE
			replace bebike=bebike+(0.1812 *ned_rf_avslope_perc)			// SWISS TRAVEL SURVEY

			gen pred_dutch= pred_basegt + bdutch
			gen pred_ebike= pred_dutch + bebike
			
		/** NEAR MARKET MODELLING DECISIONS: DIST DECAY BY AGE AND GENDER: FIGURE 2 IN C2 AND ALSO APPENDIX 2 FIGURE/NUM IN TEXT
			gen rf_dist_kmround2=(floor(rf_dist_km/2))*2
			gen rf_avslope_percround2=floor(rf_avslope_perc)
			recode rf_avslope_percround2 6/max=6 // top 1%
			count if flowtype<=2 
			table rf_dist_kmround2 femagecat if flowtype<=2 , c(mean bicycle)
			table rf_avslope_percround2 femagecat if flowtype<=2 , c(mean bicycle)
			table home_gordet nocar , c(mean bicycle)
			*/
			
		/** IDENTIFY REGRESSION EQUATION - FLOW TYPE 1+2 - NEAR MARKET. Paste to 'pct-inputs\02_intermediate\x_temporary_files\scenario_building\commute\1logfiles\NearMarket_flow1+2.xls'
			log using "pct-inputs\02_intermediate\x_temporary_files\scenario_building\commute\1logfiles\NearMarket_flow1+2.smcl", replace
			foreach x in 1 11 {
			forval i=1/9 {
			disp "femagecat `x' in region `i'"
			xi: logit bicycle i.agecat nonwhite nocar i.incomefifth i.urbancat5 sparse rf_dist_km rf_dist_kmsqrt rf_dist_kmsq ned_rf_avslope_perc interact interactsqrt /*
				*/ if femagecat==`x' & home_gordet==`i' & flowtype <=2 
			}
			forval i=10/11 { // SW and Wales = only larger cities
			disp "femagecat `x' in region `i'"
			xi: logit bicycle i.agecat nonwhite nocar i.incomefifth i.urbancat5_3only sparse rf_dist_km rf_dist_kmsqrt rf_dist_kmsq ned_rf_avslope_perc interact interactsqrt /*
				*/ if femagecat==`x' & home_gordet==`i' & flowtype <=2 
			}
			}
			foreach x in 2 12 { // older ages = agecat_old
			forval i=1/9 {
			disp "femagecat `x' in region `i'"
			xi: logit bicycle i.agecat_old nonwhite nocar i.incomefifth i.urbancat5 sparse rf_dist_km rf_dist_kmsqrt rf_dist_kmsq ned_rf_avslope_perc interact interactsqrt /*
				*/ if femagecat==`x' & home_gordet==`i' & flowtype <=2 
			}
			forval i=10/11 { // SW and Wales = only larger cities
			disp "femagecat `x' in region `i'"
			xi: logit bicycle i.agecat_old nonwhite nocar i.incomefifth i.urbancat5_3only sparse rf_dist_km rf_dist_kmsqrt rf_dist_kmsq ned_rf_avslope_perc interact interactsqrt /*
				*/ if femagecat==`x' & home_gordet==`i' & flowtype <=2 
			}
			}
			log close
		*/

		** FIT REGRESSION EQUATION - FLOW TYPE 1+2 - NEAR MARKET
			tab agecat, gen(agecat_)
			tab incomefifth, gen(incomefifth_)
			tab urbancat5, gen(urbancat5_)
			
			gen pred_basenmorig=.
			replace pred_basenmorig = ((.292 * agecat_2) + (.524 * agecat_3) + (-.931 * nonwhite) + (.758 * nocar) + (-.050 * incomefifth_2) + (.035 * incomefifth_3) + (.031 * incomefifth_4) + (.094 * incomefifth_5) + (-.095 * urbancat5_3) + (-.226 * urbancat5_4) + (-.458 * urbancat5_5) + (.386 * sparse) + (-.652 * rf_dist_km) + (2.083 * rf_dist_kmsqrt) + (.009 * rf_dist_kmsq) + (-.224 * ned_rf_avslope_perc) + (.000 * interact) + (-.015 * interactsqrt) + -4.517) if flowtype<=2 & femagecat==1 & home_gordet==1
			replace pred_basenmorig = ((.264 * agecat_2) + (.464 * agecat_3) + (-.918 * nonwhite) + (.788 * nocar) + (.073 * incomefifth_2) + (.048 * incomefifth_3) + (.103 * incomefifth_4) + (.038 * incomefifth_5) + (.281 * urbancat5_3) + (.384 * urbancat5_4) + (.225 * urbancat5_5) + (.140 * sparse) + (-.644 * rf_dist_km) + (2.089 * rf_dist_kmsqrt) + (.008 * rf_dist_kmsq) + (-.197 * ned_rf_avslope_perc) + (.030 * interact) + (-.141 * interactsqrt) + -4.553) if flowtype<=2 & femagecat==1 & home_gordet==2
			replace pred_basenmorig = ((.249 * agecat_2) + (.450 * agecat_3) + (-.984 * nonwhite) + (.801 * nocar) + (.077 * incomefifth_2) + (.125 * incomefifth_3) + (.227 * incomefifth_4) + (.325 * incomefifth_5) + (.104 * urbancat5_2) + (.568 * urbancat5_3) + (.187 * urbancat5_4) + (.212 * urbancat5_5) + (.183 * sparse) + (-.751 * rf_dist_km) + (2.327 * rf_dist_kmsqrt) + (.011 * rf_dist_kmsq) + (-.397 * ned_rf_avslope_perc) + (-.009 * interact) + (.078 * interactsqrt) + -4.705) if flowtype<=2 & femagecat==1 & home_gordet==3
			replace pred_basenmorig = ((.161 * agecat_2) + (.347 * agecat_3) + (-.927 * nonwhite) + (.880 * nocar) + (-.045 * incomefifth_2) + (.050 * incomefifth_3) + (.097 * incomefifth_4) + (.156 * incomefifth_5) + (-.121 * urbancat5_2) + (-.246 * urbancat5_3) + (-.381 * urbancat5_4) + (-.494 * urbancat5_5) + (-.122 * sparse) + (-.708 * rf_dist_km) + (2.192 * rf_dist_kmsqrt) + (.010 * rf_dist_kmsq) + (-.143 * ned_rf_avslope_perc) + (.049 * interact) + (-.231 * interactsqrt) + -3.666) if flowtype<=2 & femagecat==1 & home_gordet==4
			replace pred_basenmorig = ((.245 * agecat_2) + (.433 * agecat_3) + (-1.174 * nonwhite) + (.884 * nocar) + (.031 * incomefifth_2) + (.068 * incomefifth_3) + (.016 * incomefifth_4) + (.017 * incomefifth_5) + (.378 * urbancat5_3) + (.319 * urbancat5_4) + (.304 * urbancat5_5) + (-.171 * sparse) + (-.766 * rf_dist_km) + (2.367 * rf_dist_kmsqrt) + (.011 * rf_dist_kmsq) + (-.101 * ned_rf_avslope_perc) + (.039 * interact) + (-.189 * interactsqrt) + -4.555) if flowtype<=2 & femagecat==1 & home_gordet==5
			replace pred_basenmorig = ((.282 * agecat_2) + (.387 * agecat_3) + (-.567 * nonwhite) + (.934 * nocar) + (.082 * incomefifth_2) + (.255 * incomefifth_3) + (.247 * incomefifth_4) + (.500 * incomefifth_5) + (.665 * urbancat5_3) + (.400 * urbancat5_4) + (.296 * urbancat5_5) + (.181 * sparse) + (-.832 * rf_dist_km) + (2.564 * rf_dist_kmsqrt) + (.012 * rf_dist_kmsq) + (-.322 * ned_rf_avslope_perc) + (.017 * interact) + (-.122 * interactsqrt) + -4.772) if flowtype<=2 & femagecat==1 & home_gordet==6
			replace pred_basenmorig = ((.468 * agecat_2) + (.517 * agecat_3) + (-.931 * nonwhite) + (.014 * nocar) + (.167 * incomefifth_2) + (.121 * incomefifth_3) + (-.107 * incomefifth_4) + (-.242 * incomefifth_5) + (-.612 * rf_dist_km) + (2.510 * rf_dist_kmsqrt) + (.005 * rf_dist_kmsq) + (.210 * ned_rf_avslope_perc) + (.081 * interact) + (-.473 * interactsqrt) + -4.580) if flowtype<=2 & femagecat==1 & home_gordet==7
			replace pred_basenmorig = ((.481 * agecat_2) + (.676 * agecat_3) + (-1.192 * nonwhite) + (.391 * nocar) + (.154 * incomefifth_2) + (.205 * incomefifth_3) + (.302 * incomefifth_4) + (.468 * incomefifth_5) + (-.577 * urbancat5_3) + (-.198 * urbancat5_4) + (-.458 * urbancat5_5) + (-.376 * rf_dist_km) + (1.430 * rf_dist_kmsqrt) + (.003 * rf_dist_kmsq) + (-.286 * ned_rf_avslope_perc) + (.006 * interact) + (-.010 * interactsqrt) + -4.317) if flowtype<=2 & femagecat==1 & home_gordet==8
			replace pred_basenmorig = ((.245 * agecat_2) + (.392 * agecat_3) + (-.644 * nonwhite) + (.753 * nocar) + (.007 * incomefifth_2) + (.107 * incomefifth_3) + (.145 * incomefifth_4) + (.170 * incomefifth_5) + (.283 * urbancat5_3) + (.146 * urbancat5_4) + (.196 * urbancat5_5) + (-.708 * rf_dist_km) + (2.202 * rf_dist_kmsqrt) + (.010 * rf_dist_kmsq) + (-.266 * ned_rf_avslope_perc) + (-.006 * interact) + (-.019 * interactsqrt) + -4.171) if flowtype<=2 & femagecat==1 & home_gordet==9
			replace pred_basenmorig = ((.325 * agecat_2) + (.482 * agecat_3) + (-.435 * nonwhite) + (.564 * nocar) + (.112 * incomefifth_2) + (.101 * incomefifth_3) + (.236 * incomefifth_4) + (.305 * incomefifth_5) + (-.276 * urbancat5_4) + (-.401 * urbancat5_5) + (-.042 * sparse) + (-.767 * rf_dist_km) + (2.400 * rf_dist_kmsqrt) + (.011 * rf_dist_kmsq) + (-.256 * ned_rf_avslope_perc) + (-.003 * interact) + (.053 * interactsqrt) + -4.064) if flowtype<=2 & femagecat==1 & home_gordet==10
			replace pred_basenmorig = ((.400 * agecat_2) + (.626 * agecat_3) + (-.365 * nonwhite) + (.781 * nocar) + (-.026 * incomefifth_2) + (.027 * incomefifth_3) + (.178 * incomefifth_4) + (.164 * incomefifth_5) + (-.021 * urbancat5_4) + (-.261 * urbancat5_5) + (.386 * sparse) + (-.705 * rf_dist_km) + (2.385 * rf_dist_kmsqrt) + (.009 * rf_dist_kmsq) + (-.002 * ned_rf_avslope_perc) + (.044 * interact) + (-.267 * interactsqrt) + -4.945) if flowtype<=2 & femagecat==1 & home_gordet==11
			replace pred_basenmorig = ((.522 * agecat_2) + (.557 * agecat_3) + (-.414 * nonwhite) + (.635 * nocar) + (.054 * incomefifth_2) + (.234 * incomefifth_3) + (.283 * incomefifth_4) + (.476 * incomefifth_5) + (-.213 * urbancat5_3) + (-.280 * urbancat5_4) + (-.489 * urbancat5_5) + (.371 * sparse) + (-.924 * rf_dist_km) + (2.633 * rf_dist_kmsqrt) + (.016 * rf_dist_kmsq) + (-.911 * ned_rf_avslope_perc) + (-.062 * interact) + (.401 * interactsqrt) + -6.601) if flowtype<=2 & femagecat==11 & home_gordet==1
			replace pred_basenmorig = ((.439 * agecat_2) + (.452 * agecat_3) + (-.584 * nonwhite) + (.803 * nocar) + (.144 * incomefifth_2) + (.074 * incomefifth_3) + (.191 * incomefifth_4) + (.142 * incomefifth_5) + (.270 * urbancat5_3) + (.251 * urbancat5_4) + (.305 * urbancat5_5) + (.828 * sparse) + (-.777 * rf_dist_km) + (2.409 * rf_dist_kmsqrt) + (.011 * rf_dist_kmsq) + (-.494 * ned_rf_avslope_perc) + (.045 * interact) + (-.190 * interactsqrt) + -6.411) if flowtype<=2 & femagecat==11 & home_gordet==2
			replace pred_basenmorig = ((.487 * agecat_2) + (.667 * agecat_3) + (-.756 * nonwhite) + (.725 * nocar) + (.090 * incomefifth_2) + (.164 * incomefifth_3) + (.368 * incomefifth_4) + (.537 * incomefifth_5) + (.312 * urbancat5_2) + (1.093 * urbancat5_3) + (.538 * urbancat5_4) + (.439 * urbancat5_5) + (.183 * sparse) + (-.975 * rf_dist_km) + (2.668 * rf_dist_kmsqrt) + (.018 * rf_dist_kmsq) + (-1.048 * ned_rf_avslope_perc) + (-.097 * interact) + (.505 * interactsqrt) + -6.414) if femagecat==11 & home_gordet==3
			replace pred_basenmorig = ((.379 * agecat_2) + (.533 * agecat_3) + (-.972 * nonwhite) + (.725 * nocar) + (.056 * incomefifth_2) + (.151 * incomefifth_3) + (.199 * incomefifth_4) + (.124 * incomefifth_5) + (.040 * urbancat5_2) + (-.090 * urbancat5_3) + (-.266 * urbancat5_4) + (-.243 * urbancat5_5) + (-.199 * sparse) + (-.842 * rf_dist_km) + (2.268 * rf_dist_kmsqrt) + (.014 * rf_dist_kmsq) + (-.590 * ned_rf_avslope_perc) + (.033 * interact) + (-.142 * interactsqrt) + -4.988) if flowtype<=2 & femagecat==11 & home_gordet==4
			replace pred_basenmorig = ((.466 * agecat_2) + (.496 * agecat_3) + (-.970 * nonwhite) + (.775 * nocar) + (.196 * incomefifth_2) + (.333 * incomefifth_3) + (.249 * incomefifth_4) + (.209 * incomefifth_5) + (.604 * urbancat5_3) + (.374 * urbancat5_4) + (.706 * urbancat5_5) + (.215 * sparse) + (-.860 * rf_dist_km) + (2.386 * rf_dist_kmsqrt) + (.014 * rf_dist_kmsq) + (-.418 * ned_rf_avslope_perc) + (.031 * interact) + (-.106 * interactsqrt) + -6.336) if flowtype<=2 & femagecat==11 & home_gordet==5
			replace pred_basenmorig = ((.462 * agecat_2) + (.428 * agecat_3) + (-.501 * nonwhite) + (.927 * nocar) + (.303 * incomefifth_2) + (.551 * incomefifth_3) + (.528 * incomefifth_4) + (.881 * incomefifth_5) + (1.369 * urbancat5_3) + (.964 * urbancat5_4) + (.938 * urbancat5_5) + (.356 * sparse) + (-1.016 * rf_dist_km) + (2.950 * rf_dist_kmsqrt) + (.016 * rf_dist_kmsq) + (-.422 * ned_rf_avslope_perc) + (.053 * interact) + (-.360 * interactsqrt) + -6.755) if flowtype<=2 & femagecat==11 & home_gordet==6
			replace pred_basenmorig = ((.632 * agecat_2) + (.519 * agecat_3) + (-1.036 * nonwhite) + (.011 * nocar) + (.146 * incomefifth_2) + (.085 * incomefifth_3) + (-.070 * incomefifth_4) + (-.220 * incomefifth_5) + (-.891 * rf_dist_km) + (3.395 * rf_dist_kmsqrt) + (.010 * rf_dist_kmsq) + (.148 * ned_rf_avslope_perc) + (.086 * interact) + (-.503 * interactsqrt) + -5.958) if flowtype<=2 & femagecat==11 & home_gordet==7
			replace pred_basenmorig = ((.803 * agecat_2) + (.769 * agecat_3) + (-1.291 * nonwhite) + (.552 * nocar) + (.257 * incomefifth_2) + (.328 * incomefifth_3) + (.392 * incomefifth_4) + (.689 * incomefifth_5) + (-.724 * urbancat5_3) + (-.567 * urbancat5_4) + (-.306 * urbancat5_5) + (-.486 * rf_dist_km) + (1.857 * rf_dist_kmsqrt) + (.003 * rf_dist_kmsq) + (-.321 * ned_rf_avslope_perc) + (.013 * interact) + (-.068 * interactsqrt) + -6.149) if flowtype<=2 & femagecat==11 & home_gordet==8
			replace pred_basenmorig = ((.466 * agecat_2) + (.444 * agecat_3) + (-.611 * nonwhite) + (.815 * nocar) + (.159 * incomefifth_2) + (.380 * incomefifth_3) + (.417 * incomefifth_4) + (.433 * incomefifth_5) + (.557 * urbancat5_3) + (.123 * urbancat5_4) + (.245 * urbancat5_5) + (-.961 * rf_dist_km) + (2.766 * rf_dist_kmsqrt) + (.016 * rf_dist_kmsq) + (-.333 * ned_rf_avslope_perc) + (.005 * interact) + (-.100 * interactsqrt) + -6.076) if flowtype<=2 & femagecat==11 & home_gordet==9
			replace pred_basenmorig = ((.545 * agecat_2) + (.490 * agecat_3) + (-.338 * nonwhite) + (.555 * nocar) + (.141 * incomefifth_2) + (-.012 * incomefifth_3) + (.211 * incomefifth_4) + (.271 * incomefifth_5) + (-.504 * urbancat5_4) + (-.390 * urbancat5_5) + (.207 * sparse) + (-1.044 * rf_dist_km) + (2.975 * rf_dist_kmsqrt) + (.018 * rf_dist_kmsq) + (-.439 * ned_rf_avslope_perc) + (-.023 * interact) + (.164 * interactsqrt) + -5.516) if flowtype<=2 & femagecat==11 & home_gordet==10
			replace pred_basenmorig = ((.554 * agecat_2) + (.365 * agecat_3) + (-.176 * nonwhite) + (.732 * nocar) + (.041 * incomefifth_2) + (.054 * incomefifth_3) + (.730 * incomefifth_4) + (.499 * incomefifth_5) + (-.266 * urbancat5_4) + (-.324 * urbancat5_5) + (.606 * sparse) + (-1.151 * rf_dist_km) + (3.694 * rf_dist_kmsqrt) + (.016 * rf_dist_kmsq) + (-.236 * ned_rf_avslope_perc) + (.088 * interact) + (-.378 * interactsqrt) + -7.285) if flowtype<=2 & femagecat==11 & home_gordet==11
			replace pred_basenmorig = ((-.625 * agecat_5) + (-.336 * agecat_6) + (-1.234 * nonwhite) + (1.084 * nocar) + (.027 * incomefifth_2) + (.074 * incomefifth_3) + (.084 * incomefifth_4) + (.215 * incomefifth_5) + (-.059 * urbancat5_3) + (-.131 * urbancat5_4) + (-.271 * urbancat5_5) + (.406 * sparse) + (-.595 * rf_dist_km) + (1.851 * rf_dist_kmsqrt) + (.008 * rf_dist_kmsq) + (-.310 * ned_rf_avslope_perc) + (.024 * interact) + (-.079 * interactsqrt) + -4.273) if flowtype<=2 & femagecat==2 & home_gordet==1
			replace pred_basenmorig = ((-.609 * agecat_5) + (-.376 * agecat_6) + (-1.071 * nonwhite) + (1.085 * nocar) + (.122 * incomefifth_2) + (.113 * incomefifth_3) + (.165 * incomefifth_4) + (.178 * incomefifth_5) + (.397 * urbancat5_3) + (.557 * urbancat5_4) + (.373 * urbancat5_5) + (.257 * sparse) + (-.593 * rf_dist_km) + (1.739 * rf_dist_kmsqrt) + (.008 * rf_dist_kmsq) + (-.301 * ned_rf_avslope_perc) + (.022 * interact) + (-.080 * interactsqrt) + -4.164) if flowtype<=2 & femagecat==2 & home_gordet==2
			replace pred_basenmorig = ((-.600 * agecat_5) + (-.445 * agecat_6) + (-.871 * nonwhite) + (1.099 * nocar) + (.031 * incomefifth_2) + (.127 * incomefifth_3) + (.187 * incomefifth_4) + (.407 * incomefifth_5) + (.234 * urbancat5_2) + (.846 * urbancat5_3) + (.490 * urbancat5_4) + (.262 * urbancat5_5) + (.129 * sparse) + (-.752 * rf_dist_km) + (2.052 * rf_dist_kmsqrt) + (.013 * rf_dist_kmsq) + (-.617 * ned_rf_avslope_perc) + (-.034 * interact) + (.204 * interactsqrt) + -4.321) if flowtype<=2 & femagecat==2 & home_gordet==3
			replace pred_basenmorig = ((-.592 * agecat_5) + (-.176 * agecat_6) + (-1.063 * nonwhite) + (1.185 * nocar) + (.110 * incomefifth_2) + (.127 * incomefifth_3) + (.239 * incomefifth_4) + (.277 * incomefifth_5) + (.215 * urbancat5_2) + (.133 * urbancat5_3) + (-.108 * urbancat5_4) + (-.314 * urbancat5_5) + (.196 * sparse) + (-.628 * rf_dist_km) + (1.645 * rf_dist_kmsqrt) + (.009 * rf_dist_kmsq) + (-.355 * ned_rf_avslope_perc) + (.030 * interact) + (-.106 * interactsqrt) + -3.380) if flowtype<=2 & femagecat==2 & home_gordet==4
			replace pred_basenmorig = ((-.627 * agecat_5) + (-.374 * agecat_6) + (-1.212 * nonwhite) + (1.210 * nocar) + (.062 * incomefifth_2) + (.144 * incomefifth_3) + (.131 * incomefifth_4) + (.205 * incomefifth_5) + (.486 * urbancat5_3) + (.453 * urbancat5_4) + (.257 * urbancat5_5) + (.156 * sparse) + (-.763 * rf_dist_km) + (2.101 * rf_dist_kmsqrt) + (.011 * rf_dist_kmsq) + (-.254 * ned_rf_avslope_perc) + (.038 * interact) + (-.132 * interactsqrt) + -4.181) if flowtype<=2 & femagecat==2 & home_gordet==5
			replace pred_basenmorig = ((-.487 * agecat_5) + (-.482 * agecat_6) + (-.612 * nonwhite) + (1.291 * nocar) + (.147 * incomefifth_2) + (.224 * incomefifth_3) + (.226 * incomefifth_4) + (.467 * incomefifth_5) + (.684 * urbancat5_3) + (.440 * urbancat5_4) + (.315 * urbancat5_5) + (.488 * sparse) + (-.766 * rf_dist_km) + (2.115 * rf_dist_kmsqrt) + (.012 * rf_dist_kmsq) + (-.365 * ned_rf_avslope_perc) + (-.009 * interact) + (-.040 * interactsqrt) + -4.151) if flowtype<=2 & femagecat==2 & home_gordet==6
			replace pred_basenmorig = ((-.751 * agecat_5) + (-.457 * agecat_6) + (-1.089 * nonwhite) + (.126 * nocar) + (.256 * incomefifth_2) + (.324 * incomefifth_3) + (.242 * incomefifth_4) + (.053 * incomefifth_5) + (-.561 * rf_dist_km) + (2.228 * rf_dist_kmsqrt) + (.005 * rf_dist_kmsq) + (.133 * ned_rf_avslope_perc) + (.023 * interact) + (-.296 * interactsqrt) + -4.342) if flowtype<=2 & femagecat==2 & home_gordet==7
			replace pred_basenmorig = ((-.776 * agecat_5) + (-.393 * agecat_6) + (-1.312 * nonwhite) + (.682 * nocar) + (.071 * incomefifth_2) + (.247 * incomefifth_3) + (.329 * incomefifth_4) + (.488 * incomefifth_5) + (-.456 * urbancat5_3) + (-.265 * urbancat5_4) + (.031 * urbancat5_5) + (-.449 * rf_dist_km) + (1.421 * rf_dist_kmsqrt) + (.005 * rf_dist_kmsq) + (-.402 * ned_rf_avslope_perc) + (.000 * interact) + (.014 * interactsqrt) + -3.852) if flowtype<=2 & femagecat==2 & home_gordet==8
			replace pred_basenmorig = ((-.549 * agecat_5) + (-.402 * agecat_6) + (-.626 * nonwhite) + (1.083 * nocar) + (.042 * incomefifth_2) + (.157 * incomefifth_3) + (.234 * incomefifth_4) + (.213 * incomefifth_5) + (.308 * urbancat5_3) + (.062 * urbancat5_4) + (-.069 * urbancat5_5) + (-.643 * rf_dist_km) + (1.792 * rf_dist_kmsqrt) + (.010 * rf_dist_kmsq) + (-.327 * ned_rf_avslope_perc) + (.009 * interact) + (-.054 * interactsqrt) + -3.661) if flowtype<=2 & femagecat==2 & home_gordet==9
			replace pred_basenmorig = ((-.708 * agecat_5) + (-.481 * agecat_6) + (-.456 * nonwhite) + (.865 * nocar) + (.083 * incomefifth_2) + (.168 * incomefifth_3) + (.223 * incomefifth_4) + (.293 * incomefifth_5) + (-.199 * urbancat5_4) + (-.386 * urbancat5_5) + (-.215 * sparse) + (-.713 * rf_dist_km) + (1.950 * rf_dist_kmsqrt) + (.011 * rf_dist_kmsq) + (-.273 * ned_rf_avslope_perc) + (.008 * interact) + (.004 * interactsqrt) + -3.344) if flowtype<=2 & femagecat==2 & home_gordet==10
			replace pred_basenmorig = ((-.612 * agecat_5) + (-.249 * agecat_6) + (-.360 * nonwhite) + (1.059 * nocar) + (-.105 * incomefifth_2) + (.013 * incomefifth_3) + (.189 * incomefifth_4) + (.258 * incomefifth_5) + (-.003 * urbancat5_4) + (-.296 * urbancat5_5) + (.351 * sparse) + (-.537 * rf_dist_km) + (1.520 * rf_dist_kmsqrt) + (.008 * rf_dist_kmsq) + (-.278 * ned_rf_avslope_perc) + (.014 * interact) + (-.064 * interactsqrt) + -3.878) if flowtype<=2 & femagecat==2 & home_gordet==11
			replace pred_basenmorig = ((-.279 * agecat_5) + (.510 * agecat_6) + (-1.170 * nonwhite) + (.496 * nocar) + (.071 * incomefifth_2) + (.004 * incomefifth_3) + (.044 * incomefifth_4) + (.220 * incomefifth_5) + (.008 * urbancat5_3) + (-.008 * urbancat5_4) + (-.023 * urbancat5_5) + (.615 * sparse) + (-.882 * rf_dist_km) + (2.497 * rf_dist_kmsqrt) + (.015 * rf_dist_kmsq) + (-.781 * ned_rf_avslope_perc) + (.007 * interact) + (.023 * interactsqrt) + -6.004) if flowtype<=2 & femagecat==12 & home_gordet==1
			replace pred_basenmorig = ((.014 * agecat_5) + (.496 * agecat_6) + (-.556 * nonwhite) + (.717 * nocar) + (.098 * incomefifth_2) + (.077 * incomefifth_3) + (.192 * incomefifth_4) + (.214 * incomefifth_5) + (.755 * urbancat5_3) + (.695 * urbancat5_4) + (1.119 * urbancat5_5) + (.511 * sparse) + (-.602 * rf_dist_km) + (1.442 * rf_dist_kmsqrt) + (.011 * rf_dist_kmsq) + (-.792 * ned_rf_avslope_perc) + (-.006 * interact) + (.056 * interactsqrt) + -5.288) if flowtype<=2 & femagecat==12 & home_gordet==2
			replace pred_basenmorig = ((-.228 * agecat_5) + (.379 * agecat_6) + (-.914 * nonwhite) + (.550 * nocar) + (.052 * incomefifth_2) + (.000 * incomefifth_3) + (.115 * incomefifth_4) + (.215 * incomefifth_5) + (.614 * urbancat5_2) + (1.550 * urbancat5_3) + (1.221 * urbancat5_4) + (.955 * urbancat5_5) + (.194 * sparse) + (-.857 * rf_dist_km) + (1.969 * rf_dist_kmsqrt) + (.018 * rf_dist_kmsq) + (-1.291 * ned_rf_avslope_perc) + (-.096 * interact) + (.543 * interactsqrt) + -5.191) if flowtype<=2 & femagecat==12 & home_gordet==3
			replace pred_basenmorig = ((-.149 * agecat_5) + (.421 * agecat_6) + (-1.332 * nonwhite) + (.668 * nocar) + (.098 * incomefifth_2) + (.148 * incomefifth_3) + (.242 * incomefifth_4) + (.181 * incomefifth_5) + (1.082 * urbancat5_2) + (1.249 * urbancat5_3) + (1.271 * urbancat5_4) + (1.109 * urbancat5_5) + (.146 * sparse) + (-.778 * rf_dist_km) + (1.723 * rf_dist_kmsqrt) + (.015 * rf_dist_kmsq) + (-.910 * ned_rf_avslope_perc) + (.011 * interact) + (.000 * interactsqrt) + -5.054) if flowtype<=2 & femagecat==12 & home_gordet==4
			replace pred_basenmorig = ((-.036 * agecat_5) + (.768 * agecat_6) + (-.963 * nonwhite) + (.576 * nocar) + (.092 * incomefifth_2) + (.266 * incomefifth_3) + (.232 * incomefifth_4) + (.282 * incomefifth_5) + (.932 * urbancat5_3) + (1.074 * urbancat5_4) + (1.075 * urbancat5_5) + (.198 * sparse) + (-.765 * rf_dist_km) + (1.666 * rf_dist_kmsqrt) + (.014 * rf_dist_kmsq) + (-.680 * ned_rf_avslope_perc) + (.032 * interact) + (-.051 * interactsqrt) + -5.112) if flowtype<=2 & femagecat==12 & home_gordet==5
			replace pred_basenmorig = ((-.136 * agecat_5) + (.291 * agecat_6) + (-.704 * nonwhite) + (.736 * nocar) + (.144 * incomefifth_2) + (.316 * incomefifth_3) + (.211 * incomefifth_4) + (.465 * incomefifth_5) + (1.355 * urbancat5_3) + (1.356 * urbancat5_4) + (1.228 * urbancat5_5) + (.698 * sparse) + (-.809 * rf_dist_km) + (1.852 * rf_dist_kmsqrt) + (.016 * rf_dist_kmsq) + (-.579 * ned_rf_avslope_perc) + (.021 * interact) + (-.185 * interactsqrt) + -4.928) if flowtype<=2 & femagecat==12 & home_gordet==6
			replace pred_basenmorig = ((-.629 * agecat_5) + (-.296 * agecat_6) + (-1.178 * nonwhite) + (.080 * nocar) + (.444 * incomefifth_2) + (.571 * incomefifth_3) + (.534 * incomefifth_4) + (.379 * incomefifth_5) + (-.746 * rf_dist_km) + (2.764 * rf_dist_kmsqrt) + (.009 * rf_dist_kmsq) + (-.487 * ned_rf_avslope_perc) + (-.150 * interact) + (.377 * interactsqrt) + -5.662) if flowtype<=2 & femagecat==12 & home_gordet==7
			replace pred_basenmorig = ((-.638 * agecat_5) + (-.045 * agecat_6) + (-1.433 * nonwhite) + (.642 * nocar) + (.381 * incomefifth_2) + (.439 * incomefifth_3) + (.613 * incomefifth_4) + (1.062 * incomefifth_5) + (-.293 * urbancat5_3) + (-.028 * urbancat5_4) + (-1.017 * urbancat5_5) + (-.626 * rf_dist_km) + (1.778 * rf_dist_kmsqrt) + (.009 * rf_dist_kmsq) + (-.615 * ned_rf_avslope_perc) + (.024 * interact) + (-.071 * interactsqrt) + -5.300) if flowtype<=2 & femagecat==12 & home_gordet==8
			replace pred_basenmorig = ((-.130 * agecat_5) + (.518 * agecat_6) + (-.659 * nonwhite) + (.770 * nocar) + (.125 * incomefifth_2) + (.254 * incomefifth_3) + (.330 * incomefifth_4) + (.352 * incomefifth_5) + (.500 * urbancat5_3) + (.352 * urbancat5_4) + (.421 * urbancat5_5) + (-.759 * rf_dist_km) + (1.733 * rf_dist_kmsqrt) + (.014 * rf_dist_kmsq) + (-.610 * ned_rf_avslope_perc) + (.013 * interact) + (-.048 * interactsqrt) + -4.441) if flowtype<=2 & femagecat==12 & home_gordet==9
			replace pred_basenmorig = ((-.253 * agecat_5) + (.525 * agecat_6) + (-.490 * nonwhite) + (.431 * nocar) + (.167 * incomefifth_2) + (.050 * incomefifth_3) + (.248 * incomefifth_4) + (.342 * incomefifth_5) + (-.116 * urbancat5_4) + (-.070 * urbancat5_5) + (-.159 * sparse) + (-.815 * rf_dist_km) + (1.746 * rf_dist_kmsqrt) + (.016 * rf_dist_kmsq) + (-.768 * ned_rf_avslope_perc) + (-.034 * interact) + (.271 * interactsqrt) + -3.705) if flowtype<=2 & femagecat==12 & home_gordet==10
			replace pred_basenmorig = ((-.478 * agecat_5) + (.705 * agecat_6) + (-.364 * nonwhite) + (.711 * nocar) + (-.063 * incomefifth_2) + (-.119 * incomefifth_3) + (.318 * incomefifth_4) + (.323 * incomefifth_5) + (.261 * urbancat5_4) + (-.270 * urbancat5_5) + (.736 * sparse) + (-.780 * rf_dist_km) + (2.043 * rf_dist_kmsqrt) + (.012 * rf_dist_kmsq) + (-.717 * ned_rf_avslope_perc) + (.030 * interact) + (.002 * interactsqrt) + -5.426) if flowtype<=2 & femagecat==12 & home_gordet==11
	
		**CONVERT LOG-ODDS TO PROBABILITIES		
			foreach x in basegt dutch ebike basenmorig {
			replace pred_`x'=exp(pred_`x')/(1+exp(pred_`x'))
			}
			
		/** UPDATED DUTCH AND EBIKES - FIG 2 + FIG 3 IN USER MANUAL C
			gen rf_dist_kmround=(floor(rf_dist_km))
			gen rf_avslope_percround=floor(rf_avslope_perc*10)/10
			recode rf_avslope_percround 4/max=4 
			table rf_dist_kmround if flowtype<=2 , c(mean bicycle mean pred_basegt)
			table rf_avslope_percround if flowtype<=2 , c(mean bicycle mean pred_basegt)
			table rf_dist_kmround if flowtype<=2 , c(mean bicycle mean pred_dutch mean pred_ebike)
			table rf_avslope_percround if flowtype<=2 , c(mean bicycle mean pred_dutch mean pred_ebike)
		*/

		** INPUT PARAMETERS FLOW 3 (NO FIXED PLACE)
			foreach x in pred_basegt pred_basenmorig bdutch bebike { // WEIGHTED AVERAGE OF COMMUTERS IN FLOWTYPE 1 & "
			gen `x'temp=`x'
			replace `x'temp=. if flowtype!=1 & flowtype!=2	// WEIGHTED AVERAGE OF COMMUTERS IN FLOWTYPE 1 & "
			gen alltemp=1
			replace alltemp=. if `x'temp==.
			bysort home_lsoa: egen nummean`x'=sum(`x'temp*alltemp)
			bysort home_lsoa: egen denmean`x'=sum(alltemp)
			gen mean`x'=nummean`x'/denmean`x'
			drop `x'temp alltemp nummean`x' denmean`x'
			}
			gen meanpred_basegtsq=meanpred_basegt^2
			gen meanpred_basegtsqrt=meanpred_basegt^0.5
			gen meanpred_basenmorigsq=meanpred_basenmorig^2
			gen meanpred_basenmorigsqrt=meanpred_basenmorig^0.5

		** FIT REGRESSION EQUATION - FLOW 3 - GOV TARGET, DUTCH, EBIKE
			*xi: logit bicycle meanpred_basegtsq meanpred_basegtsqrt if flowtype==3 		
			gen pred2_basegt= -6.530 + (132.2 * meanpred_basegtsq) + (11.47 * meanpred_basegtsqrt) 
			gen pred2_dutch= pred2_basegt + meanbdutch
			gen pred2_ebike= pred2_dutch + meanbebike

		/* IDENTIFY REGRESSION EQUATION - FLOW TYPE 1+2 - NEAR MARKET. Paste to 'pct-inputs\02_intermediate\x_temporary_files\scenario_building\commute\1logfiles\NearMarket_flow3.xls'
			log using "pct-inputs\02_intermediate\x_temporary_files\scenario_building\commute\1logfiles\NearMarket_flow3.smcl", replace
			forval i=1/11 {
			disp "region `i'"
			xi: logit bicycle meanpred_basenmorigsq meanpred_basenmorigsqrt if flowtype==3 & home_gordet==`i' 
			}
			log close	
			*/

		** FIT REGRESSION EQUATION - FLOW 3 - NEAR MARKET
			gen pred2_basenmorig=.
			replace pred2_basenmorig = ((351.2 * meanpred_basenmorigsq) + (18.33 * meanpred_basenmorigsqrt) + -7.35) if flowtype==3 & home_gordet==1
			replace pred2_basenmorig = ((-509.1 * meanpred_basenmorigsq) + (26.06 * meanpred_basenmorigsqrt) + -8.13) if flowtype==3 & home_gordet==2
			replace pred2_basenmorig = ((7.3 * meanpred_basenmorigsq) + (10.74 * meanpred_basenmorigsqrt) + -6.32) if flowtype==3 & home_gordet==3
			replace pred2_basenmorig = ((-178.9 * meanpred_basenmorigsq) + (19.14 * meanpred_basenmorigsqrt) + -7.61) if flowtype==3 & home_gordet==4
			replace pred2_basenmorig = ((182.5 * meanpred_basenmorigsq) + (8.37 * meanpred_basenmorigsqrt) + -5.98) if flowtype==3 & home_gordet==5
			replace pred2_basenmorig = ((66.5 * meanpred_basenmorigsq) + (5.79 * meanpred_basenmorigsqrt) + -5.71) if flowtype==3 & home_gordet==6
			replace pred2_basenmorig = ((-178.4 * meanpred_basenmorigsq) + (28.68 * meanpred_basenmorigsqrt) + -9.64) if flowtype==3 & home_gordet==7
			replace pred2_basenmorig = ((83.5 * meanpred_basenmorigsq) + (19.06 * meanpred_basenmorigsqrt) + -7.45) if flowtype==3 & home_gordet==8
			replace pred2_basenmorig = ((118.2 * meanpred_basenmorigsq) + (7.65 * meanpred_basenmorigsqrt) + -5.98) if flowtype==3 & home_gordet==9
			replace pred2_basenmorig = ((-93.0 * meanpred_basenmorigsq) + (15.50 * meanpred_basenmorigsqrt) + -7.14) if flowtype==3 & home_gordet==10
			replace pred2_basenmorig = ((114.6 * meanpred_basenmorigsq) + (14.82 * meanpred_basenmorigsqrt) + -6.88) if flowtype==3 & home_gordet==11
						
		** COMBINE FLOW 3+4 WITH 1+2
			foreach x in basegt dutch ebike basenmorig {
			replace pred2_`x'=exp(pred2_`x')/(1+exp(pred2_`x'))
			replace pred_`x'=pred2_`x' if flowtype==3
			drop pred2_`x'
			replace pred_`x'=0 if flowtype==4
			}
			
		** SCALE BY REGION TO BE EQIVALENT TO GOV TARGET. Paste to 'pct-inputs\02_intermediate\x_temporary_files\scenario_building\commute\1logfiles\NearMarket_gtscale.xls'
			table home_gordet , c(mean bicycle mean pred_basegt mean pred_basenmorig)
			gen gtscaling=. // pred_basegt divided by pred_basenmorig
			recode gtscaling .=1.731 if home_gordet==1
			recode gtscaling .=1.550 if home_gordet==2
			recode gtscaling .=1.032 if home_gordet==3
			recode gtscaling .=1.040 if home_gordet==4
			recode gtscaling .=1.382 if home_gordet==5
			recode gtscaling .=0.824 if home_gordet==6
			recode gtscaling .=0.592 if home_gordet==7
			recode gtscaling .=1.406 if home_gordet==8
			recode gtscaling .=0.906 if home_gordet==9
			recode gtscaling .=0.665 if home_gordet==10
			recode gtscaling .=1.422 if home_gordet==11
			gen pred_basenm=pred_basenmorig*gtscaling
			*table home_gordet , c(mean bicycle mean pred_basegt mean pred_basenmorig mean pred_basenm)
			
		** SAVE
			keep home_lsoa- incomedecile bicycle pred_basegt pred_basenmorig pred_basenm pred_dutch pred_ebike 
			compress
		save "pct-inputs\02_intermediate\x_temporary_files\scenario_building\commute\0temp\CommuteSPTemp2.dta", replace
				
	*****************
	** PART 3B: APPLY SCENARIOS TO DATA: SLC AND SIC
	*****************
		use "pct-inputs\02_intermediate\x_temporary_files\scenario_building\commute\0temp\CommuteSPTemp2.dta", clear
		* NO CYCLISTS	
			gen nocyclists_slc=0
			gen nocyclists_sic=nocyclists_slc-bicycle
		
		* GOV TARGET, NEAR MARKET - CALC SIC THEN ADD TO BASELINE FOR SLC
			foreach x in basegt basenm {
			bysort home_lsoa work_lsoa: egen odcyclist_all`x'=sum(pred_`x') // NO. PREDICTED NEW CYCLISTS IN FLOW IN SCENARIO IN TOTAL
			bysort home_lsoa work_lsoa: egen odcyclist_noncyclist`x'=sum((1-bicycle)*pred_`x') // NO. PREDICTED NEW CYCLISTS IN FLOW IN SCENARIO IF RESTRICTED TO CURRENT NONCYCLISTS	
			gen `x'_sic=pred_`x'*(odcyclist_all`x'/odcyclist_noncyclist`x') // SCALING FACTOR - INCREASE THE SIC AMONG NON-CYCLISTS SO THAT CAN BE ZERO IN CURRENT CYCLISTS
			replace `x'_sic=0 if bicycle==1	// NO SIC IN CYCLISTS
			recode `x'_sic 1/max=1 		// A SMALL NUMBER OF FLOWS WHICH ARE ALMOST ALL CYCLISTS OTHERWISE HAVE THIS >1
			gen `x'_slc=`x'_sic+bicycle
			drop odcyclist_all`x' odcyclist_noncyclist`x'
			}
			rename basegt* govtarget*
			rename basenm* govnearmkt*			
			
		* GENDER EQ	
			bysort home_lsoa work_lsoa: egen bicycle_all=sum(bicycle)
			bysort home_lsoa work_lsoa: egen bicycle_male=sum((1-female)*bicycle)
			bysort home_lsoa work_lsoa: egen bicycle_female=sum((female)*bicycle)
			bysort home_lsoa work_lsoa: egen female_all=sum((female))
			bysort home_lsoa work_lsoa: egen male_all=sum((1-female))
			gen gendereq_totalslc=(bicycle_male*(1 + (female_all/male_all))) // SLC IN FLOW AS WHOLE
			gen gendereq_sic=(gendereq_totalslc-bicycle_all)/(female_all-bicycle_female)	// SIC PER FEMALE NON-CYCLIST
			replace gendereq_sic = 0 if female_all==bicycle_female // NO CHANGE IF ALL WOMEN ALREADY CYCLE			
			replace gendereq_sic = 0 if gendereq_totalslc<=bicycle_all // NO CHANGE IF SLC<=BASELINE
			replace gendereq_sic = 0 if bicycle_male==0	// NO CHANGE IF NO MALE CYCLISTS IN FLOW
			replace	gendereq_sic = 0 if female==0 | bicycle==1 // NO CHANGE AMONG MALES OR AMONG FEMALE CYCLISTS
			gen gendereq_slc=gendereq_sic+bicycle
			drop bicycle_all- male_all gendereq_totalslc
	
		* DUTCH + EBIKE - CALC SLC, THEN MINUS BASELINE TO GET SIC
			foreach x in dutch ebike {
			bysort home_lsoa work_lsoa: egen odcyclist_all`x'=sum(pred_`x') // NO. PREDICTED NEW CYCLISTS IN FLOW IN SCENARIO IN TOTAL
			bysort home_lsoa work_lsoa: egen odcyclist_cyclist`x'=sum(bicycle*(bicycle-pred_`x')) // NO. CYCLISTS ALREADY HAVE AMONG EXISTING OVER AND ABOVE THEIR PREDICTIONS
			gen `x'_slc=pred_`x'*((odcyclist_all`x'-odcyclist_cyclist`x')/odcyclist_all`x') // SCALING FACTOR - DECREASE THE SLC AMONG NON-CYCLISTS SO THAT CAN BE 1 IN CURRENT CYCLISTS
			replace `x'_slc=1 if bicycle==1	// SLC = BASELINE CYCLING IN CYCLISTS
			replace `x'_slc=bicycle if `x'_slc<=bicycle 	// NO CHANGE IF SLC < BASELINE
			gen `x'_sic=`x'_slc-bicycle
			drop odcyclist_all`x' odcyclist_cyclist`x'
			}
			
		* NO INCREASE IN FLOW TYPE 4 (TOO LONG/OUTSIDE EW)
			foreach x in govtarget govnearmkt gendereq dutch ebike {
			replace `x'_slc=bicycle if flowtype==4	
			replace `x'_sic=0 if flowtype==4
			}

	*****************
	** PART 3C: MODE SHIFT
	*****************			
			recode commute_mainmode9 1=0 2=1 3/max=0,gen(foot)
			recode commute_mainmode9 1/2=0 3=1 4/max=0,gen(car_driver)
			bysort home_lsoa work_lsoa: gen od_all=_N
			bysort home_lsoa work_lsoa: egen od_bicycle=sum(bicycle)
			bysort home_lsoa work_lsoa: egen od_foot=sum(foot)
			bysort home_lsoa work_lsoa: egen od_car_driver=sum(car_driver)

		* NO CYCLISTS
			gen nocyclists_slw=foot
			replace nocyclists_slw=od_foot/(od_all-od_bicycle) if bicycle==1	// Cyclists get walk mode share equal to flow mode share among non-cyclists
			replace nocyclists_slw=0.31 if od_bicycle==od_all	// Flows with pure bicycles at baseline - make walking 31% of new flows [from Lovelae 2017, based on MSOA mode pairs with 50%-99% cycling]
			gen nocyclists_siw=nocyclists_slw-foot
			
			gen nocyclists_sld=car_driver
			replace nocyclists_sld=od_car_driver/(od_all-od_bicycle) if bicycle==1	// Cyclists get walk mode share equal to flow mode share among non-cyclists
			replace nocyclists_sld=0.35 if od_bicycle==od_all	// Flows with pure bicycles at baseline - make driving 35% of new flows [from Lovelae 2017, based on MSOA mode pairs with 50%-99% cycling]
			gen nocyclists_sid=nocyclists_sld-car_driver
			
		* BY SCENARIO
			foreach x in govtarget govnearmkt gendereq dutch ebike {
			gen `x'_siw=foot*`x'_sic*-1
			gen `x'_slw=foot+`x'_siw
			gen `x'_sid=car_driver*`x'_sic*-1
			gen `x'_sld=car_driver+`x'_sid
			}
		* ORDER + DROP EXCESS VARIABLES
			drop pred_basegt pred_dutch pred_ebike pred_basenmorig pred_basenm
			drop bicycle foot- od_car_driver
			foreach x in ebike dutch gendereq govnearmkt govtarget nocyclists {
			order `x'_slc `x'_sic `x'_slw `x'_siw `x'_sld `x'_sid, after(incomedecile)
			}
			
	*****************
	** STEP 4: DO HEAT AND CARBON
	*****************
		** INPUT PARAMETERS HEAT + CARBON [APPENDIX TABLE]
			gen cyclecommute_tripspertypicalweek = .
				replace cyclecommute_tripspertypicalweek = 7.24 if female==0 & agecat<=3
				replace cyclecommute_tripspertypicalweek = 7.32 if female==0 & agecat>=4
				replace cyclecommute_tripspertypicalweek = 6.31 if female==1 & agecat<=3
				replace cyclecommute_tripspertypicalweek = 7.23 if female==1 & agecat>=4
			gen cspeed = 14	
			gen wspeed = 4.8
			gen ebikespeed = 16.4
			gen ebikemetreduction = 0.648
			recode cyc_dist_km min/4.9999999=.07 5/9.9999999=.13 10/19.999999=.23 20/max=.23, gen(percentebike_dutch)
			recode cyc_dist_km min/4.9999999=.71 5/9.9999999=.91 10/19.999999=.93 20/max=1, gen(percentebike_ebike)	
			gen crr_heat=0.9 
			gen cdur_ref_heat=100	
			gen wrr_heat=0.89 
			gen wdur_ref_heat=168
			gen vsl= 1888675		// VALUE IN POUNDS [TAB 'A4.1.1', AFTER SETTING YEAR AS 2017 IN 'USER PARAMETERS' IN WEBTAG BOOK]

			gen cyclecommute_tripsperweek = .
				replace cyclecommute_tripsperweek = 5.46 if female==0 & agecat<=3
				replace cyclecommute_tripsperweek = 5.23 if female==0 & agecat>=4
				replace cyclecommute_tripsperweek = 4.13 if female==1 & agecat<=3
				replace cyclecommute_tripsperweek = 4.88 if female==1 & agecat>=4
			gen co2kg_km=0.182
	
		** DURATION OF CYCLING/WALKING [THE DUTCH/EBIKE DURATION INCORPORATES LOWER INTENSITY]
			gen cdur_obs = 60*((cyc_dist_km*cyclecommute_tripspertypicalweek)/cspeed) // TIME CYCLING PER WEEK IN MINUTES AMONG NEW CYCLISTS
			gen cdur_obs_dutch=((1-percentebike_dutch)*cdur_obs)+(percentebike_dutch*cdur_obs*ebikemetreduction*(cspeed/ebikespeed))
			gen cdur_obs_ebike=((1-percentebike_ebike)*cdur_obs)+(percentebike_ebike*cdur_obs*ebikemetreduction*(cspeed/ebikespeed))
			gen wdur_obs = 60*((cyc_dist_km*cyclecommute_tripspertypicalweek)/wspeed) // TIME WALKING PER WEEK IN MINUTES AMONG THOSE NOW SWITCHING TO CYCLING

		** MORTALITY PROTECTION
			gen cprotection_govtarget= (1-crr_heat)*(cdur_obs/cdur_ref_heat)	// SCALE RR DEPENDING ON HOW DURATION IN THIS POP COMPARES TO REF
			gen cprotection_nocyclists=cprotection_govtarget
			gen cprotection_govnearmkt=cprotection_govtarget
			gen cprotection_gendereq=cprotection_govtarget
			gen cprotection_dutch= (1-crr_heat)*(cdur_obs_dutch/cdur_ref_heat) // GO DUTCH AND EBIKE USE SCALING INCORPORATING FACT SOME EBIKES
			gen cprotection_ebike= (1-crr_heat)*(cdur_obs_ebike/cdur_ref_heat)
			foreach x in nocyclists govtarget govnearmkt gendereq dutch ebike {			
			recode cprotection_`x' 0.45/max=0.45			
			}
			gen wprotection_heat= (1-wrr_heat)*(wdur_obs/wdur_ref_heat)
			recode wprotection_heat 0.30/max=0.30		

		** DEATHS AND VALUES
			foreach x in nocyclists govtarget govnearmkt gendereq dutch ebike {			
			gen `x'_sic_death=`x'_sic*mortrate*cprotection_`x'*-1
			gen `x'_siw_death=`x'_siw*mortrate*wprotection*-1
			gen `x'_sideath_heat=`x'_sic_death+`x'_siw_death
			gen `x'_sivalue_heat=`x'_sideath_heat*vsl*-1 // here and for CO2, not 'gen long' as individual
			drop `x'_sic_death `x'_siw_death
			}
			gen base_sldeath_heat=-1*nocyclists_sideath_heat	// BASELINE LEVEL IS INVERSE OF 'NO CYCLISTS' SCENARIO INCREASE
			gen base_slvalue_heat=-1*nocyclists_sivalue_heat			
			foreach x in govtarget govnearmkt gendereq dutch ebike {			
			gen `x'_sldeath_heat=`x'_sideath_heat+base_sldeath_heat
			gen `x'_slvalue_heat=`x'_sivalue_heat+base_slvalue_heat
			order `x'_sideath_heat `x'_sivalue_heat, after(`x'_slvalue_heat)
			}
			
		** CO2
			foreach x in nocyclists govtarget govnearmkt gendereq dutch ebike {
			gen `x'_sicartrips	=`x'_sid * cyclecommute_tripsperweek * 52.2 	// NO. CYCLISTS * COMMUTE PER DAY 
			gen `x'_sico2		=`x'_sid * cyclecommute_tripsperweek * 52.2 * cyc_dist_km * co2kg_km 	// NO. CAR TRIPS * DIST * CO2 EMISSIONS FACTOR
			}
			gen base_slco2=-1*nocyclists_sico2	// BASELINE LEVEL IS INVERSE OF 'NO CYCLISTS' SCENARIO INCREASE
			order base_slco2, before(govtarget_sicartrips)
			foreach x in govtarget govnearmkt gendereq dutch ebike {
			gen `x'_slco2=`x'_sico2+base_slco2
			order `x'_sicartrips `x'_slco2 , before(`x'_sico2)
			}
			drop mortrate nocyclists* cyclecommute_tripspertypicalweek- wprotection_heat
			
		** SAVE
			compress
		save "pct-inputs\02_intermediate\x_temporary_files\scenario_building\commute\CommuteSP_individual.dta", replace

		
	***********************************
	** SET GEOGRAPHY [ONCE FOR EACH]
	***********************************
		global geography = "lsoa" // "msoa" or "lsoa"
	
	*****************
	** PART pre5: PREPARE INDIVID FOR AGGREGATION [LSOA AND MSOA]
	*****************			
		use "pct-inputs\02_intermediate\x_temporary_files\scenario_building\commute\CommuteSP_individual.dta", clear	
		* PREPARE FOR AGGREGATION
			rename home_$geography geo_code_o 
			rename work_$geography geo_code_d
			gen all=1
			gen bicycle=(commute_mainmode9==1)
			gen foot=(commute_mainmode9==2)
			gen car_driver=(commute_mainmode9==3)
			gen car_passenger=(commute_mainmode9==4)
			gen motorbike=(commute_mainmode9==5)
			gen train_tube=(commute_mainmode9==6)
			gen bus=(commute_mainmode9==7)
			gen taxi_other=(commute_mainmode9==8)
			
			drop home*soa work*soa home_lad11cd home_laname home_gor // home_gordet
			drop flowtype commute_mainmode9- incomedecile
		* MAKE BIDIRECTIONAL OD AND SAVE TEMPORARY DATASET, PRE-AGGREGATION
			gen osub1=substr(geo_code_o,1,1)
			gen dsub1=substr(geo_code_d,1,1)
			gen osub2=substr(geo_code_o,2,.)
			gen dsub2=substr(geo_code_d,2,.)
			destring osub2 dsub2, replace force
			gen homefirst=.
			recode homefirst .=1 if (osub1=="E" & dsub1!="E")
			recode homefirst .=1 if (osub1=="W" & dsub1!="E" & dsub1!="W")
			recode homefirst .=0 if (osub1=="W" & dsub1=="E")
			recode homefirst .=1 if (osub1=="E" & dsub1=="E" & osub2<= dsub2)
			recode homefirst .=1 if (osub1=="W" & dsub1=="W" & osub2<= dsub2)
			recode homefirst .=0 if (osub1=="E" & dsub1=="E" & osub2>dsub2)
			recode homefirst .=0 if (osub1=="W" & dsub1=="W" & osub2>dsub2)
			gen geo_code1=geo_code_o
			replace geo_code1=geo_code_d if homefirst==0
			gen geo_code2=geo_code_d
			replace geo_code2=geo_code_o if homefirst==0
			drop osub1 dsub1 osub2 dsub2 homefirst
		* MAKE DATASET OF GORDET
			preserve
			keep geo_code_o home_gordet
			rename geo_code_o geo_code
			rename home_gordet gordet
			duplicates drop
			save "pct-inputs\02_intermediate\x_temporary_files\scenario_building\commute\\$geography\geo_code_gordet.dta", replace
			restore
			drop home_gordet
		
		order geo_code1 geo_code2 geo_code_o geo_code_d all- taxi_other
		save "pct-inputs\02_intermediate\x_temporary_files\scenario_building\commute\\$geography\CommuteSP_preaggregate_temp.dta", replace

	*****************
	** PART 5A: AGGREGATE TO ZONE LEVEL [LSOA AND MSOA]
	*****************	
		forval reg=1/11 {
		use "pct-inputs\02_intermediate\x_temporary_files\scenario_building\commute\\$geography\CommuteSP_preaggregate_temp.dta", clear
		* RESTRICT TO HOME REGION
			rename geo_code_o geo_code
			merge m:1 geo_code using "pct-inputs\02_intermediate\x_temporary_files\scenario_building\commute\\$geography\geo_code_gordet.dta", nogen
			rename geo_code geo_code_o
			keep if gordet==`reg'
		* AGGREGATE UP AREA FIGURES
			foreach var of varlist all- taxi_other govtarget_slc- ebike_sico2 {
			bysort geo_code_o: egen a_`var'=sum(`var')
			}
		* PERCENT TRIPS AND TRIP HILLINESS
			recode rf_dist_km min/9.9999=1 10/max=0, gen(rf_u10km_dist)
			recode rf_u10km_dist .=0 if geo_code_d=="Other"
				* NB keep as missing if no fixed work place - implicitly assume they have same distribution as everyone else. This exclusion is comparable to what ONS do
			bysort geo_code_o: egen a_perc_rf_dist_u10km=mean(rf_u10km_dist*100)
			gen rf_u10km_avslope_perc=rf_avslope_perc
			replace rf_u10km_avslope_perc=. if rf_u10km_dist!=1
			bysort geo_code_o: egen a_avslope_perc_u10km=mean(rf_u10km_avslope_perc)
		* AREA FILE KEEP/RENAME + MERGE IN NAMES/LA + ORDER
			keep geo_code_o a_*
			rename geo_code_o geo_code
			rename a_* *
			duplicates drop
			merge 1:1 geo_code using "pct-inputs\02_intermediate\x_temporary_files\scenario_building\commute\\$geography\geo_code_lookup.dta"
			drop if _m==2
			drop _m
			order geo_code geo_name lad11cd lad_name all bicycle- taxi_other
		* SAVE + APPEND
			save "pct-inputs\02_intermediate\x_temporary_files\scenario_building\commute\\$geography\z_all_reg`reg'.dta", replace
		}
			use "pct-inputs\02_intermediate\x_temporary_files\scenario_building\commute\\$geography\z_all_reg1.dta", replace
			forval reg=2/11 {
			append using "pct-inputs\02_intermediate\x_temporary_files\scenario_building\commute\\$geography\z_all_reg`reg'.dta"
			}
			export delimited using "pct-inputs\02_intermediate\x_temporary_files\scenario_building\commute\\$geography\z_all_attributes_unrounded.csv", replace
			forval reg=1/11 {
			erase "pct-inputs\02_intermediate\x_temporary_files\scenario_building\commute\\$geography\z_all_reg`reg'.dta"
			}		
	
	*****************
	** PART 5B: AGGREGATE TO FLOW LEVEL [LSOA AND MSOA]
	*****************
		forval reg=1/11 {
		use "pct-inputs\02_intermediate\x_temporary_files\scenario_building\commute\\$geography\CommuteSP_preaggregate_temp.dta", clear
			drop *cartrips	
		* RESTRICT TO STARTING ZONE REGION
			rename geo_code1 geo_code
			merge m:1 geo_code using "pct-inputs\02_intermediate\x_temporary_files\scenario_building\commute\\$geography\geo_code_gordet.dta", nogen
			rename geo_code geo_code1
			keep if gordet==`reg'
		* IDENTIFY VARIABLES WHERE 'ALL' IS TOO SMALL (for lsoa combine <3 flows to 'under 3')
			bysort geo_code1 geo_code2: gen f_all_temp=_N
			replace geo_code_d="Under 3" if f_all_temp<3 & "$geography"=="lsoa"
			replace geo_code1=geo_code_o if geo_code_d=="Under 3"
			replace geo_code2=geo_code_d if geo_code_d=="Under 3"
			foreach var of varlist rf_dist_km rf_avslope_perc {
			replace `var'=. if geo_code_d=="Under 3"
			}
			gen id = geo_code1+" "+geo_code2
			drop f_all_temp
		* AGGREGATE UP FLOW FIGURES
			foreach var of varlist all- taxi_other govtarget_slc- ebike_sico2 {
			bysort id: egen f_`var'=sum(`var')
			}
			foreach var of varlist rf_dist_km rf_avslope_perc {
			bysort id: egen f_`var'=mean(`var') // redundant for lsoa, useful for msoa
			}
		* FLOW FILE KEEP/RENAME + MERGE IN NAMES/LA + ORDER
			keep id geo_code1 geo_code2 f_* 
			rename f_* *
			duplicates drop
			forval i=1/2 {
			rename geo_code`i' geo_code
			merge m:1 geo_code using "pct-inputs\02_intermediate\x_temporary_files\scenario_building\commute\\$geography\geo_code_lookup.dta"
			drop if _m==2
			drop _m
			foreach x in geo_code geo_name lad11cd lad_name {
			rename `x' `x'`i'
			}
			}
			foreach x in geo_name2 lad11cd2 lad_name2 {
			replace `x'="No fixed place" if geo_code2=="OD0000003"
			replace `x'="Other" if geo_code2=="Other"
			replace `x'="Under 3" if geo_code2=="Under 3"
			}
			order id geo_code1 geo_code2 geo_name1 geo_name2 lad11cd1 lad11cd2 lad_name1 lad_name2 all bicycle- taxi_other govtarget_slc- ebike_sico2
		* MERGE IN OTHER CS DATA (BETWEEN-LINES ONLY)
			merge 1:1 id using "pct-inputs\02_intermediate\x_temporary_files\scenario_building\commute\\$geography\rfrq_all_data.dta"
			recode e_dist_km .=0 if geo_code1==geo_code2 // within-zone
			order e_dist_km, before(rf_dist_km)
			drop if _m==2
			count if _m!=3 & geo_code1!=geo_code2 & geo_code2!="Other" & geo_code2!="OD0000003" & geo_code2!="Under 3" // should be none
			drop _m		
		* SAVE + APPEND
			save "pct-inputs\02_intermediate\x_temporary_files\scenario_building\commute\\$geography\od_all_reg`reg'.dta", replace
		}
			use "pct-inputs\02_intermediate\x_temporary_files\scenario_building\commute\\$geography\od_all_reg1.dta", replace
			forval reg=2/11 {
			append using "pct-inputs\02_intermediate\x_temporary_files\scenario_building\commute\\$geography\od_all_reg`reg'.dta"
			}
			export delimited using "pct-inputs\02_intermediate\x_temporary_files\scenario_building\commute\\$geography\od_all_attributes_unrounded.csv", replace
			forval reg=1/11 {
			erase "pct-inputs\02_intermediate\x_temporary_files\scenario_building\commute\\$geography\od_all_reg`reg'.dta"
			}
	
	*****************
	** PART 5C: AGGREGATE TO LA & PCT REGION LEVEL [LSOA ONLY]
	*****************
	** LA
		import delimited using "pct-inputs\02_intermediate\x_temporary_files\scenario_building\commute\lsoa\z_all_attributes_unrounded.csv", clear
		drop *cartrips
		* AGGREGATE
			foreach var of varlist all- taxi_other govtarget_slc- ebike_sico2 {
			bysort lad11cd: egen a_`var'=sum(`var')
			}
			foreach var of varlist perc_rf_dist_u10km avslope_perc_u10km {
			bysort lad11cd: egen temp_`var'=sum(`var'*all)
			gen a_`var'=temp_`var'/a_all
			}
			keep lad11cd lad_name a_*
			rename a_* *
			duplicates drop
		* CHANGE UNITS
			foreach x in base_sl govtarget_sl govtarget_si govnearmkt_sl govnearmkt_si gendereq_sl gendereq_si dutch_sl dutch_si ebike_sl ebike_si{
			replace `x'value_heat=`x'value_heat/1000000 // convert to millions of pounds
			replace `x'co2=`x'co2/1000	// convert to tonnes
			}
		export delimited using "pct-inputs\02_intermediate\x_temporary_files\scenario_building\commute\lad_all_attributes_unrounded.csv", replace
	** REGION
		import delimited "pct-inputs\01_raw\01_geographies\pct_regions\pct_regions_lad_lookup.csv", varnames(1) clear 
		save "pct-inputs\02_intermediate\x_temporary_files\scenario_building\pct_regions_lad_lookup.dta", replace
		import delimited using "pct-inputs\02_intermediate\x_temporary_files\scenario_building\commute\lad_all_attributes_unrounded.csv", clear
		merge 1:1 lad11cd using "pct-inputs\02_intermediate\x_temporary_files\scenario_building\pct_regions_lad_lookup.dta", keepus(region_name) nogen
		* AGGREGATE
			foreach var of varlist all- taxi_other govtarget_slc- ebike_sico2 {
			bysort region_name: egen a_`var'=sum(`var')
			}
			keep region_name a_*
			rename a_* *
			duplicates drop
		* PERCENTAGES FOR INTERFACE
			foreach var of varlist bicycle govtarget_slc govnearmkt_slc gendereq_slc dutch_slc ebike_slc {
			gen `var'_perc=round(`var'*100/all, 1)
			order `var'_perc, after(`var')
			}
			keep region_name *perc
			list if bicycle_perc==. 
			drop if bicycle_perc==. // should be nothing
		export delimited using "pct-inputs\02_intermediate\x_temporary_files\scenario_building\commute\pct_regions_all_attributes.csv", replace

	*****************
	** PART 5D: FILE FOR RASTER WITH NUMBERS ROUNDED (BUT CORRECT TOTALS MAINTAINED), AND NO FILTERING OF LINES <3 [LSOA ONLY]
	*****************			
		use "pct-inputs\02_intermediate\x_temporary_files\scenario_building\commute\lsoa\CommuteSP_preaggregate_temp.dta", clear
		* SUBSET BY DISTANCE AND TO SCENARIO VARIABLES
			keep if rf_dist_km<20 & geo_code1!=geo_code2
			gen id = geo_code1+" "+geo_code2
			keep id bicycle *_slc	
		* AGGREGATE UP FLOW FIGURES
			foreach var of varlist bicycle- ebike_slc {
			bysort id: egen f_`var'=sum(`var')
			}
			keep id f_*
			rename f_* *
			duplicates drop
		* ROUND + MOVE SOME CYCLISTS 0 TO 1, TO GET TOTAL CORRECT NUMBER	
			set seed 20170121
			gen random=uniform()
			foreach var of varlist govtarget_slc govnearmkt_slc gendereq_slc dutch_slc ebike_slc {
			rename `var' `var'_orig 
			gen `var'=round(`var'_orig)
			total `var'_orig `var'
			matrix A=r(table)
			di "`var': " round((100*(1-A[1,2]/A[1,1])),0.01) "%"
			}
			foreach var of varlist govtarget_slc govnearmkt_slc dutch_slc ebike_slc {	// not needed gendereq, as similar with/without rounding
			total `var'_orig `var' if `var'_orig<1.5
			matrix A=r(table)
			gen `var'_diff = round(A[1,1]-A[1,2]) // COUNT THE DIFFERENCE BETWEEN NO CYCLISTS ROUNDED VS NOT ROUNDED AMONG THOSE WHERE NOT ROUNDED IS <1.5	
			sort `var' random
			gen littlen=_n
			recode `var' 0=1 if littlen <=`var'_diff // ROUND SOME 0 TO 1 SO THAT TOTAL NO. <1.5 IS CORRECT
			drop littlen
			}
			foreach var of varlist govtarget_slc govnearmkt_slc gendereq_slc dutch_slc ebike_slc {			
			total `var'_orig `var' 
			matrix A=r(table)
			di "`var': " round((100*(1-A[1,2]/A[1,1])),0.01) "%"
			}
		* LIMIT TO THOSE WITH ANY CYCLING, AND SAVE
			egen sumcycle=rowtotal(bicycle govtarget_slc govnearmkt_slc gendereq_slc dutch_slc ebike_slc)
			drop if sumcycle==0
			keep id bicycle govtarget_slc govnearmkt_slc gendereq_slc dutch_slc ebike_slc
			sort id
			export delimited using "pct-inputs\02_intermediate\02_travel_data\commute\lsoa\od_raster_attributes.csv", replace

	erase "pct-inputs\02_intermediate\x_temporary_files\scenario_building\commute\\$geography\CommuteSP_preaggregate_temp.dta"

x

		* GM DESCRIPTIVES, TABLE 2 IN APPENDIX 1
			use "..\1 - Phys Act_1-PA main\2017_MetaHIT_analysis\1b_datacreated\Census2011EW_AllAdults.dta", clear
			keep if commute_mainmode9<9 // exclude non-commuters or work from home
			rename home_lad11cd lad11cd
			merge m:1 lad11cd using "pct-inputs\02_intermediate\x_temporary_files\scenario_building\pct_regions_lad_lookup.dta", keepus(region_name) nogen
			keep if region_name=="greater-manchester"
			tab commute_mainmode9 nocar, col
			tab commute_mainmode9 nonwhite, col
			recode commute_mainmode9 2/max=0, gen(cycle)
			table agecat female if nonwhite==0, c(mean cycle)
			table agecat female if nonwhite==1, c(mean cycle)			

