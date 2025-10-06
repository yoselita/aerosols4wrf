#!/bin/bash
#-------------------------------------------------------------------------------------------------------------------------------------------------
# Author: Josipa Milovac (contact: milovacj@unican.es)
#
# This script creates aerosol input files for the WRF run from GCM montlhy mean data aggegated in multoyear files or MERRA monthly mean data.
# The created files can be used as auxinput15.
#
# MERRA download sites: 1) NASA: https://goldsmr4.gesdisc.eosdis.nasa.gov/data/MERRA2_MONTHLY/M2IMNXGAS.5.12.4/
#						2) JUELICH (processed version): https://b2share.fz-juelich.de/records/?community=a140d3f3-0117-4665-9945-4c7fcb9afb51&sort=-&page=1&size=10
#
# The outputname of the file is:
# 	if model=="MERRA":
# 				"AOD_${start_year}${start_month}${start_day}_${end_year}${end_month}${end_days_of_end_month}_${domain}"
#	if mode=="GCM":
# 				"AOD_${scenario}_${start_year}${start_month}01_${end_year}${end_month}${end_days_of_end_month}_${domain}"
#-------------------------------------------------------------------------------------------------------------------------------------------------
#
# Define functions for the main code:
#
# Sets start time when time variable is missing
function set_start_time(){
  ifile=$1
  cdo -s setdate,${start_date//_*/} ${ifile} fout
  cdo -s settime,${start_date//*_/} fout ${ifile}
  rm fout
}

# Function to interpolate monthly to diurnal
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

function delete_atts(){
  file_out=$1  
  varname=$2  
	ncatted -O -h -a "corner_*",global,d,, ${file_out}
	ncatted -O -h -a "FLAG_*",global,d,, ${file_out}
	ncatted -O -h -a "SIMULATION_START_DATE",global,d,, ${file_out}
	ncatted -O -h -a "GRIDTYPE",global,d,, ${file_out}
	ncatted -O -h -a "sr_*",global,d,, ${file_out}
	ncatted -O -h -a "sr_*",AOD5502D,d,, ${file_out}
	ncatted -O -h -a "stagger",AOD5502D,m,c,"" ${file_out}
	ncatted -O -h -a "_FillValue",AOD5502D,m,f,"NaN" ${file_out}
	ncatted -O -h -a "coordinates",AOD5502D,a,c,"XLONG XLAT XTIME" ${file_out}
	ncks -O -h --mk_rec_dmn Time ${file_out} -o tmp.nc; mv tmp.nc ${file_out}
}
####################################################################################################################################################
#
# Define paths and variables
#---------------------------------------------------------------------------------------------------------------------------------------------------
#
# Activate your eviroment with cdo, nco, and ncl packages installed
# source activate <your conda enviroment>

domain=$1	# Define domain ("d01" or "d02")
model=$2	# Define model ("GCM" or "MERRA")
if [[ "${model}" == "MERRA" && -z "$3" ]]; then # If MERRA, define a download site: processed JUELICH or original MERRA
    echo "Please provide the download site of your raw data are coming as an argument: JUELICH or NASA"
    echo "Usage: $0 <domain> <model> <download site>"
    exit 1
else
    downsite=$3
fi

if [[ "${model}" == "MERRA" ]]; then
    if [[ "${downsite}" == "NASA" ]]; then
        aod_varname="AODANA"
    else
        aod_varname="AOD"
    fi    
	start_year=2018
	start_month=01
	start_day=01
	end_year=2018
	end_month=01
	end_day=31
	merge="True"  # Set to True if you want to produce multimonthly data, otherwise "False"
	
	# Creating sequences over years and months
	years=$(seq $start_year $end_year)
	months=$(seq -w $start_month $end_month)
	
	# Define working directory
	path2data="./data/"
	wrkdir=`pwd`	
	output="${wrkdir}/output/"
	mkdir -p ${output}
	
elif [ ${model} == "GCM" ]; then		
	aod_varname="od550aer"
	scenario="historical" # or "ssp126" "ssp370" "ssp585"
	
	# Create working and output directories
	wrkdir=`pwd`
	output="${wrkdir}/output/${scenario}"
	splitdir="${wrkdir}/split"
	mkdir -p ${splitdir}
	mkdir -p ${output}	
	
	# Define working directory
	if [ "${scenario}" -eq "historical" ]; then
		path2data="path/CMIP6/CMIP/institution/GCM/${scenario}/realization/AERmon/od550aer/..."
	else
		path2data="path/CMIP6/ScenarioMIP/institution/GCM/${scenario}/realization/AERmon/od550aer/..."
	fi
fi
####################################################################################################################################################
#
# Main program
#
#-------------------------------------------------------------------------------------------------------------------------------------------------

if [ ${model} == "GCM" ]; then		
	for filename in ${path2data}/${aod_varname}_*.nc; do
		# Split multi year file into a yearly file due to oversized outcome
		cdo -s splityear $filename ${splitdir}/${aod_varname}_${scenario}_
		
		for file in ${splitdir}/${aod_varname}_${scenario}*; do
			fname=$(basename ${file})
			echo "Working on the file ${fname}"

			# Check number of years and months in the file
			years=(`cdo -s showyear ${file}`)
			months=(`cdo -s showmon ${file}`)
			dates=(`cdo -s showdate ${file}`)
			ndates=`cdo -s ntime ${file}`
			
			# Remove time_bnds variables
			ncks -C -h -x -v time_bnds ${file} temp.nc

			# Inteprolate monthly to daily files
			for i in "${!dates[@]}"; do
				date="${dates[i]}"
				year=$(echo ${date} | awk -F"-" '{print $1}');
				month=$(echo ${date} | awk -F"-" '{print $2}');
				ndays_per_month=`cal $month $year | awk 'NF {DAYS = $NF}; END {print DAYS}'`;
				
				sday="01"
				eday=${ndays_per_month}	
				
				cdo -s -w seltimestep,$((i + 1)) temp.nc fcut.nc
				ncatted -a coordinates,,d,, fcut.nc fint.nc
				cdo -s -selname,${aod_varname} fint.nc out.nc
				
				start_date=${year}-${month}-${sday}_00:00:00
				end_date=${year}-${month}-${eday}_00:00:00
				
				set_start_time out.nc			
				timeRange2Interval out.nc AOD_${year}${month} ${start_date/_/T} ${end_date/_/T} 1day	
				rm fcut.nc fint.nc out.nc
			done

			# Merge monhtly to yearly files and interpolate to the WRF grid
			cdo -s mergetime AOD_* AODmerged.nc; rm AOD_*
			ncl 'srcFile="geo_em.'${domain}'.nc"' grid_corners.ncl
			cdo -s remapbil,out_grid.nc AODmerged.nc out.nc
			cdo -s chname,${aod_varname},AOD5502D out.nc AODremapped.nc; rm out.nc

			# Set attributes from the geo_em file and create Times variable as it is in wrflowinp_d0x
			file_out="AOD_${scenario}_${years[0]}${months[0]}01_${year}${month}${ndays_per_month}_${domain}"
			ncl 'file_input="AODremapped.nc"' 'domain="'${domain}'"' 'file_out="'${file_out}'"'  'model="GCM"' set_attributes.ncl
			mv ${file_out}.nc ${file_out}

			# Fix all the global attributes
			delete_atts ${file_out} "AOD5502D"
			
			rm AODmerged.nc AODremapped.nc out_grid.nc temp.nc
			mv ${file_out} ${output}/
		done
		rm ${splitdir}/*
	done
	
elif [ ${model} == "MERRA" ]; then	
	for year in ${years}; do
		# loop per month
		for month in ${months}; do
		 	filename=`ls ${path2data}/MERRA2_*${year}${month}.nc`
		 	fname=$(basename ${filename})
		 	
		 	# Extracting AOD from the file
			echo "Working onf the file: $filename"
		 	ncatted -h -a coordinates,,d,, ${filename} fint.nc
		 	if [ ${downsite} == "NASA" ]; then
		 	  ncwa -a time fint.nc tmp.nc; rm fint.nc
		 	  ncks -x -v time tmp.nc -o fint.nc; rm tmp.nc
		 	fi
		 	cdo -s -selname,${aod_varname} fint.nc out.nc ;rm fint.nc

			# Defining the starting and the ending day, and setting the starting time
			ndays_per_month=`cal $month $year | awk 'NF {DAYS = $NF}; END {print DAYS}'`
			if [[ ${month} == ${start_month} ]] && [[ ${month} != ${end_month} ]]; then
			        sday=${start_day}
			        eday=${ndays_per_month}
			elif [[ ${month} == ${end_month} ]]; then
			        sday="01"
			        eday=${end_day}
			else
			        sday="01"
			        eday=${ndays_per_month}
			fi
			if [[ ${sday} == ${eday} ]]; then
				eday=$(printf %02d `expr $sday + 1`)
			fi			
			start_date=${year}-${month}-${sday}_00:00:00
			end_date=${year}-${month}-${eday}_00:00:00
		 	set_start_time out.nc

			# Defining the starting and the ending day, and setting the starting time
		  	timeRange2Interval out.nc AOD_$fname ${start_date/_/T} ${end_date/_/T} 1day
		  	rm out.nc
			coordinates="XLONG XLAT XTIME"
			
			# Remapping
			ncl 'srcFile="geo_em.'${domain}'.nc"' grid_corners.ncl
			cdo -s remapbil,out_grid.nc AOD_$fname out.nc; rm AOD_$fname
			cdo -s chname,${aod_varname},AOD5502D out.nc AODremapped_${year}${month}.nc
			rm out.nc out_grid.nc

			# if merging is not set to True, setting the attributes and creaeting the Time variable
			if [[ ${merge} == "False" ]]; then
				file_out="AOD_${year}${month}${sday}_${year}${month}${eday}_${domain}"
				ncl 'file_input="AODremapped_'${year}${month}'.nc"' 'domain="'${domain}'"' 'file_out="'${file_out}'"' 'model="'${model}'"' set_attributes.ncl
				delete_atts ${file_out}.nc "AOD5502D"
				mv ${file_out} ${output}/${file_out}
				rm AODremapped_*.nc
			fi
		done
	done		

	# Merge files if set to yeas
	if [[ ${merge} == "True" ]]; then
		echo "Merging AOD files and setting the attributes..."
		cdo mergetime AODremapped_* AOD_merged.nc
		file_out="AOD_${start_year}${start_month}${start_day}_${end_year}${end_month}${end_day}_${domain}"
		ncl 'file_input="AOD_merged.nc"' 'domain="'${domain}'"' 'file_out="'${file_out}'"' 'model="'${model}'"' set_attributes.ncl
		rm AODremapped_*.nc AOD_merged.nc
		delete_atts ${file_out}.nc "AOD5502D"
		mv ${file_out} ${output}/${file_out}
	fi
fi
