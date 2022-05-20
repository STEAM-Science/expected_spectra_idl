pro new_isotope_spectrum, distance = distance, element = element, time = time, aperture = aperture, air_dens=air_dens

  if not keyword_set(distance) then distance=1.

  if not keyword_set(time) then time = 1.

  if not keyword_set(element) then begin
    message, /info, 'Please specify element'
  endif
  
  ; All of these are with the CdTe detector so I'm only using the code for that one
  
  if not keyword_set(aperture) then aperture = 2700. ; micron
  area = !dpi*(aperture*1e-4/2.)^2 ; cm^2
  
  if not keyword_set(resolution) then resolution = 0.3 ; keV FWHM
  
  energies = load_spectrums(element)
; wwif finite(energies)
  wid_ee = energies/10240
  junk = get_edges(findgen((energies)/wid_ee+1)*wid_ee+1., edges_2=eee, mean=eee_mean, wid=eee_wid, edges_1 = edges)
  spectrum = area*make_isotope_spectra(edges, element = element, activity = activity, time = time)/(4.*!dpi*distance^2)
  response = instrument_response(eee_mean, detector_select = detector_select, filter_thick = filter_thick, aluminum = aluminum, polyimide = polyimide)
  smooth_spectrum = gaussfold(eee_mean, spectrum*response, resolution, /nointerp)
  
  wid_ee2 = (energies)/1024
  junk = get_edges(findgen((energies)/wid_ee2+1)*wid_ee2+1., edges_2=eee2, mean=eee_mean2, wid=eee_wid2, edges_1=edges2)
  
  ; air attenuation function
  air = air_attenuation(eee_mean, distance=distance, air_dens=air_dens)

  ;ssw_rebinner, specin, edgesin, specout, edgesout

  ssw_rebinner, smooth_spectrum*air, eee, spectrum_rebinned, eee2

  ;pause
  plot,eee_mean2,spectrum_rebinned, xtitle = 'Energy(keV)', ytitle = 'Counts(photons)', _extra = _extra

  output_spectrum = {energy:eee_mean2, spectrum:spectrum_rebinned}
  

end