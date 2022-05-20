FUNCTION air_attenuation, energy_centers, distance=distance, air_dens=air_dens

  if not keyword_set(distance) then distance=1.

  a2kev = 12.398420
  keV_per_el = 3.64e-3 ; energy per electron/hole pair in Si
  air_thick = distance ; in cm
  ; Get XCOM attenuation factors
  mu_air = read_dat('./air_1_100keV.dat')
  mu_energies = reform(mu_air[0,*]) * 1000 ; keV

  if not keyword_set(air_dens) then air_dens=0.001049 ;change to being an input pressure and calculate density from it

  ; Calculate air attenuation
  resp_raw = reform(exp(-mu_air[3,*] * air_thick * air_dens))

  ; Interpolate response (cts/ph) at eee bins, zero the response below 5 keV (LLD)
  resp = interpol(resp_raw, mu_energies, energy_centers)
  resp[where((energy_centers lt 0.5) or (energy_centers ge 100.))] = 0.

  RETURN, resp

END