pro spectrum_gaussfit, _extra = _extra

  smooth_isotope_spectrum, out = spec, _extra = _extra
  message, /info, 'Select points to zoom in on region of interest'
  select, multi = 2, points = points1
  plot, spec.energy, spec.spectrum, xrange = [min(points1.xstart), max(points1.xstart)]
  message, /info, 'Select points to the left and right of peak to fit gaussian'
  select, multi = 2, points = points
  idxs = where((spec.energy gt min(points.xstart)) and (spec.energy lt max(points.xstart)))
  yfit = gaussfit(spec.energy[idxs], spec.spectrum[idxs], coeff, NTERMS = 3)
  oplot, spec.energy[idxs], yfit, color = 'FF'x
  labels = ['A0 = Amplitude','A1 = Center','A2 = Standard Deviation']
  print, labels, coeff
  
  print, total(yfit), (coeff[0]*coeff[2])/0.3989
  ; total (this is the function) yfit, theres also a formula from the gaussian coefficients (amp*std)((A0*A2)/0.3989), 
  ; tells how many photons are in entire gaussian (min area should be 100 phtns)

end