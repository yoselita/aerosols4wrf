;----------------------------------------------------------------------------------------------------------------
; Author: Josipa Milovac (contact: milovacj@unican.es)
;
; NCL script that sets correct metadata to the AOD file, so it can be read by WRF:
;
; Command syntax:
;   ncl 'file_input="AODremapped.nc"' 'domain="d01"' 'file_out="'${fout}'"' 'model=="GCM"' set_attributes.ncl
;
;----------------------------------------------------------------------------------------------------------------

begin
  ; Loading the files
  model=model
  f_input   = addfile(file_input,"r")   
  wrfinput  = addfile("geo_em."+domain+".nc", "r")  
  
  ; Reading variable from the input file
  aod  = tofloat(f_input->AOD5502D)
  time_double = f_input->time
  ntimes = dimsizes(time_double)
  time = tochar(tostring(f_input->time)) 
  
  ; Reading data from the wrfinput file
  var_default  = wrfinput->LU_INDEX
  time_default = wrfinput->Times 
  
  if (model .eq. "GCM") then
  	utc_date = cd_calendar(time_double, 0)
		year = toint(utc_date(:,0))
		month = toint(utc_date(:,1))
		day = toint(utc_date(:,2))
		Times = tochar(tostring(year) + "-" + tostring(sprinti("%0.2i", month)) + "-" + tostring(sprinti("%0.2i", day)) +"_00:00:00")
	else
		Times  = new((/ntimes,19/),typeof(time_default)) 
		do i=0,ntimes-1,1
		year = time(i,0:3)
		month = time(i,4:5)
		day = time(i,6:7)
			Times(i,:) = tochar(tostring(year)+"-" + tostring(month) + "-" + tostring(day) +"_00:00:00")
		end do	
  end if  
  
  ; Deleting all predefined variable attributes
  delete_VarAtts(Times, -1)
  delete_VarAtts(aod, -1)  
  
  ; Asigning the same atributes as in geo_em file
  copy_VarMeta(time_default,Times)
  copy_VarMeta(var_default,aod) 
  
  ; Changing the attributes that are specific for a variable
  aod@description = "Total AOD MONTHLY AVERAGE"
  aod@units = "1"

  ; Opening a netcdf file where to write out the data
  if (fileexists(file_out + ".nc")) then
    system("rm " + file_out + ".nc")
  end if 
  aod_input = addfile(file_out+".nc","c")   
  
  global_attnames = getvaratts(wrfinput) 
  do i=0,dimsizes(global_attnames)-1
      aod_input@$global_attnames(i)$ = wrfinput@$global_attnames(i)$ 
  end do
  
  ; Add and update few atributes
	if (model .eq. "GCM") then
		aod_input@JULYR  = toint(tostring(Times(0,0:3)))
		aod_input@JULDAY = toint(systemfunc("date +%j -d " + tostring(Times(0,5:6)) + "/" + \
				tostring(Times(0,8:9)) + "/" + tostring(Times(0,0:3))))
		aod_input@START_DATE = tostring(Times(0,:)) 
	else
		aod_input@JULYR = toint(tostring(time(0,0:3)))
		aod_input@JULDAY = toint(systemfunc("date +%j -d " + (time(0,4:5)) + "/" + \
				(time(0,6:7)) + "/" + (time(0,0:3))))
		aod_input@START_DATE = tostring(Times(0,:)) 
	end if

		; To avoid use_old_data = True, set this global attribute
		aod_input@TITLE = " OUTPUT FROM REAL_EM V4.5.1 PREPROCESSOR"
  
  ; Write variables to the file
  aod_input->AOD5502D=aod 
  aod_input->Times=Times
end
