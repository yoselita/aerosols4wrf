;----------------------------------------------------------------------
; Converts WRF grid to a SCRIP convention file.
;
;	Command syntax:
;  ncl 'srcFile="geo_em.d01.nc"' grid_corners.nc
;
;----------------------------------------------------------------------

load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"
begin
		;---Input file
		srcInFile = addfile(srcFile,"r")

		;---Output file
    srcOutFile = "out_grid.nc"
		
		; Read lat and lon from the source file
    lat_var  = srcInFile->XLAT_M(0,:,:)
    lon_var  = srcInFile->XLONG_M(0,:,:)

    ; Set options
    Opt                = True
    Opt@ForceOverwrite = True
    Opt@PrintTimings   = False
    Opt@Title          = "PISM Grid"
    Opt@Debug          = False

		; Writes the description of a curvilinear grid to a SCRIP file
    curvilinear_to_SCRIP(srcOutFile,lat_var,lon_var,Opt)

;---Clean up
    delete(Opt)
end                                             
