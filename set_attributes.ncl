;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Author: Josipa Milovac (contact: milovacj@unican.es)
;
; NCL script that sets correct metadata to the AOD file, so it can be read by WRF
;
; command syntax:
;   ncl year=${year} month=${month} 'domain="d01"' merged_yearly=${merge_yearly} set_attributes.ncl
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
begin
  if (month.le.9) then
	number_str = "0"+tostring(month)
  else
  	number_str = tostring(month)
  end if 
  delete(month)   
  month=number_str

  ; Define input file and wrflowinput file
  file_input="AOD"+year+month+".nc"
  file_wrfinput="wrfinput_" + domain ; "wrflowinp_d01" or "geo_em.d01.nc"

  ; Loading the files
  f_input   = addfile(file_input,"r")   
  ;wrfinput  = addfile(file_wrfinput+".nc","r")  
  wrfinput  = addfile(file_wrfinput,"r")  
  
  ; Reading variable from the input file
  aod  = tofloat(f_input->AOD5502D)
  time = f_input->time
  ntimes = dimsizes(time)  

  ; Reading global atributes from the wrfinput file
  ;var_default  = wrfinput->SST
  if (file_wrfinput.eq."wrflowinp_"+domain+".nc") then
  	var_default  = wrfinput->SST
  else
  	var_default  = wrfinput->LU_INDEX
  end if
  time_default = wrfinput->Times

  ; Creating Times variable for monthly data
  Times  = new((/ntimes,19/),typeof(time_default)) 
  do i=0,ntimes-1,1
  	if (i.lt.9) then
  		day = "0" + tostring(i+1)
  	else
  		day = tostring(i+1)
  	end if
  	Times(i,:)   = tochar(tostring(year)+"-" + month + "-" + day +"_00:00:00")
  end do
  
  if (merged_yearly.eq."False") then  
 	next_month=toint(month)+1
  	if (next_month.le.9) then
 		next_month_str = "0"+tostring(next_month)
  	else
  		next_month_str = tostring(next_month)
  	end if 
  	
  	if (next_month_str.gt."12") then
  		next_year=year+1
  		next_month_str="01"
  	else
  		next_year=year
 	end if      
  	Times(ntimes-1,:)  = tochar(tostring(next_year)+"-" + next_month_str + "-01_00:00:00")
  end if
  
  ; Deleting all predefined variabel attributes
  delete_VarAtts(Times, -1)
  delete_VarAtts(aod, -1)  
  
  ; Asigning the same atributes as in wrfinput file
  copy_VarMeta(time_default,Times)
  copy_VarMeta(var_default,aod)
  
  ; Changing the attributes that are specific for a variable
  aod@description = "Total AOD MONTHLY AVERAGE"
  aod@units = ""

  ; Opening a netcdf file where to write out the data
  file_out = "AOD"+tostring(year)+month+"_"+domain+".nc"
  if (fileexists(file_out)) then
    system("rm " + file_out)
  end if 
  aod_input = addfile(file_out,"c") 
  
  global_attnames = getvaratts(wrfinput) 
  do i=0,dimsizes(global_attnames)-1
      aod_input@$global_attnames(i)$ = wrfinput@$global_attnames(i)$ 
  end do
  delete(aod_input@JULYR)		
  delete(aod_input@JULDAY)		
  aod_input@START_DATE = tostring(Times(0,:)) 
  ; To avoid use_old_data = True, set this global attribute
  ;aod_input@TITLE = " OUTPUT FROM REAL_EM V4.2.2 PREPROCESSOR"
    
  ; Writing variables in the output
  aod_input->Times=Times  
  aod_input->AOD5502D=aod 

  ; Setting time to unlimited and deleting time variable that is automatically created from the variable Times
  system("ncdump "+ file_out + " | sed -e 's#^.Time = 12#Time = UNLIMITED ; // (currently 12)#'  | ncgen -o out.nc")
  system("ncks -h -C -O -x -v Time out.nc AOD"+tostring(year) + month + "_" + domain)
  system("rm out.nc " + file_out)
  ;system("ncatted -O -h -a ISWATER,global,o,i,17 AOD"+tostring(year)+month+"_"+domain)
end
