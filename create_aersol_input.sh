#!/bin/bash
####################################################################################################################################################
# Author: Josipa Milovac (contact: milovacj@unican.es)
#
# Input necessary:
# 	1. Dowloaded MERRA2 data in the folder ./data from 
#	https://b2share.fz-juelich.de/records/?community=a140d3f3-0117-4665-9945-4c7fcb9afb51&sort=mostrecent&page=1&size=10
#	2. wrfinput_<domain> after running ./real.exe
#
# Output can be agregated as montly or yearly files. If yearly files wanted, then set the variabele "merge_yearly=True", otherwise to false
# 
# Output files are montly data (option to create yearly or multi-monthly files to be added, some features added): 
#	1. AOD<year><month>_<domain> 	
#
# The frequency of the output files is diurnal (1440 minutes)
# The global attributes are copied from wrfinput file
# AOD variable is renamed to AOD5502D so that WRF can recognize it
#
# After downloading MERRA2 files in ./data folder, in ./ wrfinput_<domain> file has to be placed together with all the scripts
# To run the script:
# ./create_aerosol_input 
####################################################################################################################################################
# Define start-end year and month - for a user to adapt
start_year=2012
start_month=06
end_year=2012
end_month=07
domain="d01"
merge_yearly="False"  # Set "True" if you want to produce yearly ot multhy month data - to be added!!!
####################################################################################################################################################
start_date=$start_year-$start_month-01_00:00:00
end_date=$end_year-$end_month-01_00:00:00

# Creating sequences over years and months
years=$(seq $start_year $end_year)
months=$(seq -w $start_month $end_month)

# sets start time (useful when time variable is missing)
function set_start_time(){
  ifile=$1
  cdo -s setdate,${start_date//_*/} ${ifile} fout
  cdo -s settime,${start_date//*_/} fout ${ifile}
  rm fout
}

# function to interpolate montly to diurnal
function timeRange2Interval(){
  ifile=$1
  ofile=$2
  sdate=$3
  edate=$4
  interval=$5
  nrec=$(cdo -s ntime ${ifile})
  test ${nrec} -eq 0 && nrec=1
  cdo -s seltimestep,1 ${ifile} fout1
  cdo -s setdate,${sdate} fout1 fout2
  cdo -s settime,$(echo ${sdate} | awk -FT '{print $2}') fout2 fout0
  cdo -s seltimestep,${nrec} ${ifile} fout1
  cdo -s setdate,${edate} fout1 fout2
  cdo -s settime,$(echo ${edate} | awk -FT '{print $2}') fout2 fout1
  cdo -s mergetime fout0 fout1 fout3
  cdo -s inttime,$(cdo -s showdate fout0 | tr -d ' '),00:00:00,${interval} fout3  ${ofile}
  rm fout0 fout1 fout2 fout3
}

# loops per year and per month
for year in ${years}; do
   for month in ${months}; do  
    
        # filename format for MERRA data downloaded from https://b2share.fz-juelich.de/records/059656a3e53d4815ac1ffc0a0201d3e9
	filename="MERRA2_OPPMONTH_wb10.${year}${month}.nc"
	
	# selecting the variable od interest, removing attribute "coorindates" to avoid warning messages
	ncatted -a coordinates,,d,, "./data/$filename" fint.nc
        cdo -selname,AOD fint.nc out.nc ;rm fint.nc
        
        # interpolating diurnal values from monthy values  
        set_start_time out.nc
        sdate=$year-$month-01_00:00:00
        if [ $(expr $month) == 12 ]; then
        	edate=$(expr $year + 1)-01-01_00:00:00 
        else
		edate=$year-$(expr $month + 1)-01_00:00:00 
	fi
        timeRange2Interval out.nc AOD_$filename ${sdate/_/T} ${edate/_/T} 1day
        
        # if to be merged in yearly file, remove the last timestep to avoid repeating timesteps when mearging monthly files
        #if [ ${merge_yearly} == "True" ]; then
        #	cdo delete,timestep=-1 AOD_$filename out.nc
        #	mv out.nc AOD_$filename
        #fi
                
        # setting the time axis 
        cdo settunits,days -settaxis,$year-$month-01,00:00,1day AOD_$filename out.nc
        ncap2 -O -s '@units="days since 1980-01-01 00:00:00 GMT";time=udunits(time,@units);time@units=@units' out.nc AOD_$filename
        rm out.nc
        
	# create cf-conform file to extract correct information on the WRF grid
	ncl 'file_in="wrfinput_'${domain}'.nc"' 'file_out="int_file.nc"' 'domain="'${domain}'"' to_cf.ncl
	
	# define destination.grid
	python3 read_grid.py int_file.nc; rm int_file.nc
	mv info.grid destination.grid
        
        # remapping using bilinear interpolation method
        cdo genbil,destination.grid AOD_$filename weights.nc
        cdo remap,destination.grid,weights.nc AOD_$filename out.nc; 
        rm destination.grid AOD_$filename weights.nc 
        
        # renaming the variable 
        cdo chname,AOD,AOD5502D out.nc AODremapped_${year}${month}.nc; rm out.nc
        mv AODremapped_${year}${month}.nc AOD${year}${month}.nc
        ncl year=${year} month=${month} 'domain="'${domain}'"' merged_yearly=${merge_yearly} set_attributes.ncl
        rm AOD${year}${month}.nc
   done          
done



