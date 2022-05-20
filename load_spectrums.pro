function load_spectrums, element

  if (n_elements(element) eq 0) then begin
    message, /info, 'You need to specify an element [55Fe, 241Am, 109Cd, 133Ba]'
    return, -1
  endif
  
  filename = string(element) + ' CdTe.txt'
  lines = read_ascii(filename, types = ['Double', 'Double'])
  return, {energies:lines.field1}
  
;  ; Select a text file and open for reading
;
;  OPENR, lun, filename, /GET_LUN
; Read one line at a time, saving the result into array
; array = ''
;  line = ''
;  WHILE NOT EOF(lun) DO BEGIN & $
;    READF, lun, line & $
;    array = [array, line] & $
;  ENDWHILE
;  ; Close the file and free the file unit
;  FREE_LUN, lun
  
end