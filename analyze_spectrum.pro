pro analyze_spectrum, spectrum_file, input_element = input_element, time=time, distance=distance, detector_select=detector_select, aperture=aperture, resolution=resolution

  ; read in spectrum data file
  if TYPENAME(spectrum_file) NE 'STRING' THEN BEGIN
    message, level=-1, 'Please enter mystery spectrum data file as a string'
  endif
  
  ; read data into an array
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
  measured_spectrum_raw = fltarr(n_elements(array)-1)

  FOR i=0,n_elements(array)-2 DO BEGIN
    measured_spectrum_raw[i] = array[i]+array[i+1]
  ENDFOR
  
  ; create element spectra for comparison do i need this section? i confused myself
  el_list = ['Fe', 'Ba', 'Zn', 'Am', 'Cd']
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

    ; add exponential decay to this one
    ssw_rebinner, smooth_spectrum, eee, spectrum_rebinned, eee2

    el_struct[index].energy = eee_mean2
    el_struct[index].counts = spectrum_rebinned

  ENDFOREACH
  
  ; compare spectra
  measured_spectrum = measured_spectrum_raw/max(measured_spectrum_raw)
  
  ; set element
  if input_element eq 'Fe' then el_index = 0.
  if input_element eq 'Ba' then el_index = 1. 
  if input_element eq 'Zn' then el_index = 2. 
  if input_element eq 'Am' then el_index = 3. 
  if input_element eq 'Cd' then el_index = 4. 

  print, input_element
  print, el_index
  
  ; normalize
  comp_spectrum = el_struct[el_index].counts;/max(el_struct[el_index].counts)
  ;error = sqrt(total((measured_spectrum-comp_spectrum)^2))
  
  ; calculate gain and offset
  calc_gain = (max(measured_spectrum)-min(measured_spectrum))/(max(comp_spectrum)-min(comp_spectrum))
  ;calc_offset = ((max(measured_spectrum)-min(measured_spectrum))-(max(comp_spectrum)-min(comp_spectrum)))/2
  ;calc_offset = mean(comp_spectrum)-mean(measured_spectrum)
  calc_offset = comp_spectrum[-1]-measured_spectrum[-1]
  
  calc_two = (measured_spectrum - calc_offset)/calc_gain
  
  print, 'Calculated gain is: ', calc_gain
  print, 'Calculated offset is: ', calc_offset
  
  ;plot, measured_spectrum, xrange = [0,50], yrange = [0,1], COLOR=cgColor("Red")
  plot, calc_two, COLOR=cgColor("Blue")
  oplot, comp_spectrum, color=cgColor('Red')

end