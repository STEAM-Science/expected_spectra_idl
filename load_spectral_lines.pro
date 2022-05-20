function load_spectral_lines, element

  if (n_elements(element) eq 0) then begin
    message, /info, 'You need to specify an element [Fe, Am, Cd, Ba, Zn]'
    return, -1
  endif

  filename = 'Spectral_Lines_' + string(element) + '.csv'
  lines = read_csv(filename, types = ['Double', 'Double'])
  return, {energies:lines.field1, intensities:lines.field2}
end