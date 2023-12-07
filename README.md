# aero4wrf

This  repository contains scripts to generate aerosol files that can be used as an input data for the WRF simulations.These files can be generated from MERRA2 AOD monthly means and GCM historical and scenario multiyear files. This version of the script is developed and tested for the NorESM2 GCM runs, but it could be the case that the naming inside of the script will need some adaptation.

The main script to obtain an aerosol input for WRF is [create_aersol4wrf_input.sh](./create_aersol4wrf_input.sh). It is a combination of bash, cdo, nco, and ncl programming languges. To be able to run it, it is necessary to create a conda enviroment with the mentioned packages installed. 

Within the script the user needs to redefine:

1. The model type (evaluation or GCM run):

	* For the evaluation run set the **model="MERRA"** and a MERRA2 files will be processed ([CORDEX protocol](https://cordex.org/wp-content/uploads/2021/05/CORDEX-CMIP6_exp_design_RCM.pdf)). The script converts the MERRA2 AOD aerosol data that you should download from [link](https://b2share.fz-juelich.de/records/?community=a140d3f3-0117-4665-9945-4c7fcb9afb51&sort=mostrecent&page=1&size=10) (NOTE: the raw data are available at the [NASA Earth Science Data](https://goldsmr4.gesdisc.eosdis.nasa.gov/data/MERRA2_MONTHLY/M2IMNXGAS.5.12.4/), with an account needed to access the data), to the format readable by WRF. 

	* If a GCM multyear output will be used for preparing the aerosol input for WRF, then set the **model="GCM"**.

	<br/> **Note:** Paths to the files and AOD variable name in the file should be adjusted to the model that is used (e.g. in NorESM2 the AOD550 variable is named "od550aer")

3. Set the start and end dates 

4. Set the domain (e.g. d01, d02)
	
The main script [create_aersol4wrf_input.sh](./create_aersol4wrf_input.sh) uses 2 ncl scripts:
1. [grid_corners.ncl](./grid_corners.ncl) - the NCL script that converts WRF grid to a SCRIP convention file for an easy interpolation with cdo. 
2. [set_attributes.ncl](./set_attributes.ncl)  - the NCL script that sets correct metadata and the time variabels in the AOD file, so it can be read by WRF.

To run the script:
	                    
    ./create_aersol4wrf_input.sh

The output names of the files are:
	<br/> a) if model = "MERRA":
	<br/> `AOD_start-date_end-date_domain`
	<br/> b) if model = "GCM":
	<br/> `AOD_scenario_start-date_end-date_domain`
	
	
### NOTE: ###
In the running folder geo_em.d0x.nc file should be placed so that the ncl scripts get the necessarty information for the inteprolation and setting the metadata. 

