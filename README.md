# aero4wrf
=============

This  project contains the scripts to generate aerosol datasets from MERRA2 AOD monthly means, to be used as an input data for the WRF simulations.

The main script to obtain an aerosol input for WRF is **create_aerosol_input.sh**. It is a combination of bash, cdo, nco, python, and ncl programming languges. To be able to run it, it is advisable to create a conda enviroment with the mentioned programming lanugages installed. The script converts the MERRA2 AOD aerosol data downloaded from the download [page](https://b2share.fz-juelich.de/records/?community=a140d3f3-0117-4665-9945-4c7fcb9afb51&sort=mostrecent&page=1&size=10), to the format readable by WRF. The downloaded data needs to be located in the folder **./data**. In the working directory **./** all the scripts need to be placed, together with the wrfinput_[domain] file (e.g. domain="d01").

To run the script:
	                    
    ./create_aerosol_input.sh
	
The main script (**create_aerosol_input.sh**) uses 3 scripts provided within this project:
1. _to_cf.ncl_  - an NCL script that reads wrf/wps netCDF file and output in netcdf CF compliant format (prestep needed for remapping)
2. _read_grid.py_  - python script (shared within the CORDEX comunityu) that provides the correct information on the corners for each grid cell.
3. _set_attributes.ncl_  - an NCL script that sets correct metadata and the time variabels in the AOD file, so it can be read by WRF.

Currentlly the output are montly netcdf files AOD[year][month]_[domain], with the global attributes copied from the wrfinput file


Option to create yearly or multi-monthly files to be added... 
