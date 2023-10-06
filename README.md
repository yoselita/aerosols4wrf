# aero4wrf

This  repository contains scripts to generate aerosol files that can be used as an input data for the WRF simulations.These files can be generated from MERRA2 AOD monthly means and GCM historical and scenario multiyear files.
The main script to obtain an aerosol input for WRF is [create_aersol4wrf_input.sh](./create_aersol4wrf_input.sh). It is a combination of bash, cdo, nco, and ncl programming languges. To be able to run it, it is necessary to create a conda enviroment with the mentioned packages installed. 

In the the script the user needs to define the model name. Set the model="MERRA" if the MERRA file will be processed. The script converts the MERRA2 AOD aerosol data downloaded from [link](https://b2share.fz-juelich.de/records/?community=a140d3f3-0117-4665-9945-4c7fcb9afb51&sort=mostrecent&page=1&size=10) (NOTE: the raw data are available at the [NASA Earth Science Data](https://goldsmr4.gesdisc.eosdis.nasa.gov/data/MERRA2_MONTHLY/M2IMNXGAS.5.12.4/), with an account needed to access the data), to the format readable by WRF. 

If a GCM multyear output willl be used for preparing the aerosol input for WRF, then set the model="GCM". Note that path to files and AOD variable name in the file should be adjusted to the user's data (typically the AOD550 variable name is "od550aer")

To run the script:
	                    
    ./create_aersol4wrf_input.sh
	
The main script [create_aersol4wrf_input.sh](./create_aersol4wrf_input.sh) uses 2 ncl scripts:
1. [grid_corners.ncl](./grid_corners.ncl) - the NCL script that converts WRF grid to a SCRIP convention file for an easy interpolation with cdo. 
2. [set_attributes.ncl](./set_attributes.ncl)  - the NCL script that sets correct metadata and the time variabels in the AOD file, so it can be read by WRF.

The output names of the files are:
<br/> a) if model = "MERRA":
	<br/> `AOD_start-date_end-date_domain`
<br/> b) if model = "GCM":
	<br/> `AOD_scenario_start-date_end-date_domain`
