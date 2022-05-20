FUNCTION make_isotope_spectra, energy_edges, element=element, activity=activity, time=time
  IF n_elements(energy_edges) eq 0 then begin
    MESSAGE, /info, 'Missing energy_edge input...Returning -1'
    RETURN, -1
  ENDIF

  if not keyword_set(element) then element='Fe' ;does if not keywordset(element) then element=Fe55 work? maybe have to define element=__ before.
  if not keyword_set(activity) then activity=1.
  
  ;if not keyword_set(time) then begin
    ;message, /info, 'Please specify exposure time'
;    return, -1
;  endif
  
  ;defining constants
  decaysPerSecond = 37000.0 ;[micro curie]
  
  ;check all elements in gamma rays to see if we missed any
  ;http://nucleardata.nuclear.lu.se/toi/nucSearch.asp
  SWITCH element of
    
    ;'Fe': begin ; Fe55 ;http://nucleardata.nuclear.lu.se/toi/nuclide.asp?iZA=260055
      ;keV = [0.556,0.568,0.637,0.637,0.640,0.648,0.720,0.720,5.888,5.899,6.49,6.49,6.536]
      ;intensity = [.037,.025,.028,.25,.0022,.19,.011,.017,8.5,16.9,1.01,1.98,.00089]/100.0
      ;end
      
    'Fe': 
    
    'Ba': 
    
    'Zn':
    
    'Am': 
    
    'Cd': begin 
      lines = load_spectral_lines(element)
      break
      
    end
    ELSE: begin
      message, /info, 'Element ' + element + ' does not exist'
      return, -1
      end
    endswitch
      
    ;'Ba': begin ; Ba133 ; add gammas
      ;keV = [3.795, 4.142, 4.272, 4.286, 4.620, 4.649, 4.717, 4.781, 4.934, 5.281, 5.542, 5.553, 30.270, 30.625, 30.973, 34.920, 34.987, 35.252, 35.818, 35.907] 
      ;intensity = [0.24, 0.11, 0.66, 6.0, 3.8, 0.56, 0.93, 0.048, 1.19, 0.54, 0.15, 0.22, 0.00401, 34.9, 64.5, 5.99, 11.6, 0.123, 3.58, 0.74]/100.
      ;end
      
    ;'Zn': begin ; Zn65
      ;keV = [0.811, 0.831, 0.929, 0.929, 0.931, 0.949, 1.022, 1.022, 7.883, 8.028, 8.048, 8.905, 8.905, 8.977, 8.979]
      ;intensity = [0.046, 0.027, 0.063, 0.57, 0.00079, 0.37, 0.019, 0.028, 0.0000234, 11.9, 23.4, 1.43, 2.78, 0.00327, 0.00000018]/100d0
      ;end
      
    ;'Am': begin ; Am241 ; take out the really weak lines (smaller than a factor of 100 of largest line (generally) less than .1 and add 26.3448:2.40, 33.1964:0.126, 59.5412:35.9 ;http://nucleardata.nuclear.lu.se/toi/nuclide.asp?iZA=950241
      ;keV = [11.871, 13.761, 13.946, 15.861, 16.109, 16.816, 17.061, 17.505, 17.751, 17.992, 20.784, 21.009, 21.342, 21.491, 96.242, 97.069, 101.059, 113.303, 114.234, 114.912, 117.463, 117.875] 
      ;intensity = [0.66, 1.07, 9.6, 0.153, 0.184, 2.5, 1.5, 0.65, 5.7, 1.37, 1.39, 0.65, 0.59, 0.29, 0.000028, 0.008, 0.012, 0.0015, 0.0028, 0.00011, 0.0011, 0.0004]/100.
      ;end
      
    ;'Cd': begin ; Cd109
      ;keV = [2.634, 2.806, 2.978, 2.984, 3.151, 3.203, 3.234, 3.256, 3.348, 3.520, 3.743, 3.750, 21.708, 21.708, 21.990, 22.163, 24.912, 24.943, 25.144, 25.445, 25.511]
      ;intensity = [0.18, 0.097, 0.50, 4.5, 2.6, 0.14, 0.22, 0.030, 0.58, 0.28, 0.027, 0.045, 0.00122, 29.5, 55.7, 4.76, 9.2, 0.067, 2.3, 0.487]/100.
      ;end
            

  numOfPhotons = lines.intensities/100. * decaysPerSecond * activity * time;CountRate, in photons per second
  ;PRINT, numOfPhotons

  output_spectrum = fltarr(n_elements(energy_edges)-1) ;makes an zero array with length of energy edges array -1
  FOR i = 0, n_elements(lines.energies)-1, 1 do begin
    index = min(WHERE(energy_edges gt lines.energies[i], count))
    IF count gt 0 then output_spectrum[index] += numOfPhotons[i]
  ENDFOR

  RETURN, output_spectrum
END