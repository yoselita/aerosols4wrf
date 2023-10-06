# aero4wrf

This  project contains scripts to generate aerosol datasets from MERRA2 AOD monthly means and GCM historical and scenarion multiyear files that can be used as an input data for the WRF simulations.

The main script to obtain an aerosol input for WRF is [create_aersol4wrf_input.sh](./create_aersol4wrf_input.sh). It is a combination of bash, cdo, nco, and ncl programming languges. To be able to run it, it is advisable to create a conda enviroment with the mentioned programming lanugages installed. 

The used need to define in the the script model="MERRA" if the MERRA file will be processed. The script converts the MERRA2 AOD aerosol data downloaded from [link](https://b2share.fz-juelich.de/records/?community=a140d3f3-0117-4665-9945-4c7fcb9afb51&sort=mostrecent&page=1&size=10) (NOTE: the raw data are available at the [NASA Earth Science Data](https://goldsmr4.gesdisc.eosdis.nasa.gov/data/MERRA2_MONTHLY/M2IMNXGAS.5.12.4/), with an account needed to access the data), to the format readable by WRF. 

To run the script:
	                    
    ./create_aersol4wrf_input.sh
	
The main script [create_aersol4wrf_input.sh](./create_aersol4wrf_input.sh) uses 2 ncl scripts:
1. [grid_corners.ncl](./grid_corners.ncl) - the NCL script that converts WRF grid to a SCRIP convention file for an easy interpolation with cdo. 
2. [set_attributes.ncl](./set_attributes.ncl)  - the NCL script that sets correct metadata and the time variabels in the AOD file, so it can be read by WRF.

The outputname of the file is:
if model == "MERRA":
	if merging is applied:
		"AOD_${start_year}${start_month}${start_day}_${end_year}${end_month}${end_day}_${domain}"
		
	withouth merging a monthly file will be created:
		"AOD_${start_year}${start_month}${start_day}_${start_year}${start_month}${ndays_per_month}_${domain}"
		
	
if model == "GCM":
  "AOD_${scenario}_${start_year}${start_month}01_${start_year}1231_${domain}"
