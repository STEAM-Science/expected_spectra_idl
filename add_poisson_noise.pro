FUNCTION add_poisson_noise, spectrum

noisy_spectrum = spectrum*0.

for i=0, n_elements(spectrum)-1 do begin

  if spectrum[i] gt 0 then begin
    noisy_spectrum[i] = randomu(seed,POISSON = spectrum[i],/DOUBLE)
  endif else begin
    noisy_spectrum[i] = 0
  endelse
  
endfor

RETURN, noisy_spectrum

end