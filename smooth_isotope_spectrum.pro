pro smooth_isotope_spectrum, time = time, output_spectrum = output_spectrum, air_dens = air_dens, distance = distance, aperture = aperture, element = element, activity = activity, resolution = resolution, detector_select = detector_select, filter_thick = filter_thick, aluminum = aluminum, polyimide = polyimide, _extra = _extra

  if not keyword_set(detector_select) then detector_select=0
  
  if not keyword_set(distance) then distance=1. ;gaps in testing rig are 7mm
  
  if not keyword_set(time) then time = 1.
  
  if not keyword_set(element) then begin
    message, /info, 'Please specify element'
  endif
  
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
      
      ;plot,eee_mean,smooth_spectrum, _extra = _extra ;allows us to pass in any arbitrary keywords and assign appropriately
      
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
  response = instrument_response(eee_mean, detector_select = detector_select, filter_thick = filter_thick, aluminum = aluminum, polyimide = polyimide)
  
  ; air attenuation function
  air = air_attenuation(eee_mean, distance=distance, air_dens=air_dens)
  
  smooth_spectrum = gaussfold(eee_mean, spectrum*response*air, resolution, /nointerp)
  
  ;ssw_rebinner, specin, edgesin, specout, edgesout

  ssw_rebinner, smooth_spectrum, eee, spectrum_rebinned, eee2

  ;pause
  plot,eee_mean2,spectrum_rebinned, xtitle = 'Energy(keV)', ytitle = 'Counts(photons)', _extra = _extra
  
  output_spectrum = {energy:eee_mean2, spectrum:spectrum_rebinned}
  
end