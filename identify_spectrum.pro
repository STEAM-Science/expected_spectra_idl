pro identify_spectrum, spectrum_file, time=time, distance=distance, detector_select=detector_select, aperture=aperture, resolution=resolution

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Read mystery spectrum
  if TYPENAME(spectrum_file) NE 'STRING' THEN BEGIN
    message, level=-1, 'Please enter mystery spectrum data file as a string'
  endif

  ; in the future, we should add logic that reads the calibration data to convert bin #s to energies
  OPENR, lun, spectrum_file, /GET_LUN
  array = ''
  line = ''
  read_data = boolean(0)
  WHILE NOT EOF(lun) DO BEGIN
    readf, lun, line
    if line EQ '<<END>>' THEN BREAK
    if read_data THEN BEGIN
      array = [array,line]
    endif
    if line EQ '<<DATA>>' THEN read_data = boolean(1)
  ENDWHILE
  array = double(array)
  FREE_LUN, lun
  
  ; make spectrum array with 1 less data point, and add together value at neighboring edges to get values
  mystery_spectrum_raw = fltarr(n_elements(array)-1)
  
  FOR i=0,n_elements(array)-2 DO BEGIN
    mystery_spectrum_raw[i] = array[i]+array[i+1]
  ENDFOR
  
  
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Gather element spectra
  
  el_list = ['Fe', 'Ba', 'Zn', 'Am']
  el_struct = REPLICATE({spectrum,element:'Fe',energy:make_array(1024,/double,value=1),$
    counts:make_array(1024,/double,value=0)},n_elements(el_list))
  

  FOREACH element, el_struct, index DO BEGIN
    
    element = el_list[index]
    el_struct[index].element = element
    
    if not keyword_set(detector_select) then detector_select=0
  
    if not keyword_set(distance) then distance=1. ;gaps in testing rig are 7mm
  
    if not keyword_set(time) then time = 1.
  
    CASE detector_select of 

    0: begin ;SDD
      
      if not keyword_set(aperture) then aperture = 300. ; micron
      area = !dpi*(aperture*1e-4/2.)^2 ; cm^2
      
      ;if not keyword_set(filter_thick) then filter_thick = 5.5 ; micron
      
      if not keyword_set(resolution) then resolution = 0.15 ; keV FWHM
      ; Create arbitrary energy array, 0.5-20 keV, ~0.02 keV bins
      wid_ee = (20-0.5)/10240
      junk = get_edges(dindgen((20.-0.5)/wid_ee+1)*wid_ee+0.5, edges_2=eee, mean=eee_mean, wid=eee_wid, edges_1=edges)
      ; added aperture area and distance from source
      
      ; make new edges for fine energy array
      wid_ee2 = (20-0.5)/1024
      junk = get_edges(dindgen((20.-0.5)/wid_ee2+1)*wid_ee2+0.5, edges_2=eee2, mean=eee_mean2, wid=eee_wid2, edges_1=edges2)
    end

    1: begin ;CdTe
      
      if not keyword_set(aperture) then aperture = 2700. ; micron
      area = !dpi*(aperture*1e-4/2.)^2 ; cm^2
      
      ;if not keyword_set(filter_thick) then filter_thick = 50. ; micron
          
      if not keyword_set(resolution) then resolution = 0.3 ; keV FWHM
      wid_ee = (100.-1.)/10240
      junk = get_edges(dindgen((100.-1)/wid_ee+1)*wid_ee+1., edges_2=eee, mean=eee_mean, wid=eee_wid, edges_1 = edges)
 
      ;plot,eee_mean,smooth_spectrum, _extra = _extra
      
      ; make new edges for fine energy array
      wid_ee2 = (100-1.)/1024
      junk = get_edges(dindgen((100.-1)/wid_ee2+1)*wid_ee2+1., edges_2=eee2, mean=eee_mean2, wid=eee_wid2, edges_1=edges2)
    end
    
    ENDCASE
    
    spectrum = area*make_isotope_spectra(edges, element = element, activity = activity, time = time)/(4.*!dpi*distance^2)
    response = instrument_response(eee_mean, detector_select = detector_select, filter_thick = filter_thick,$
      aluminum = aluminum, polyimide = polyimide)
  
    ; air attenuation function
    air = air_attenuation(eee_mean, distance=distance, air_dens=air_dens)
  
    smooth_spectrum = gaussfold(eee_mean, spectrum*response*air, resolution, /nointerp)
  
    ssw_rebinner, smooth_spectrum, eee, spectrum_rebinned, eee2
    
    el_struct[index].energy = eee_mean2
    el_struct[index].counts = spectrum_rebinned

  ENDFOREACH
  
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; Compare spectra
  err = make_array(n_elements(el_list),/double,value=0)
  
  mystery_spectrum = mystery_spectrum_raw/max(mystery_spectrum_raw)
  
  for i=0,n_elements(err)-1 DO BEGIN
    ; scale everything for comparison
    comp_spectrum = el_struct[i].counts/max(el_struct[i].counts)
    err[i] = sqrt(total((mystery_spectrum-comp_spectrum)^2))
  endfor
  
  index = where(err eq min(err))
  
  print, 'Closest element match is: '
  print, el_list[index]
  
end