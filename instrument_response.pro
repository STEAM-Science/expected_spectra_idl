FUNCTION instrument_response, energy_centers, detector_select = detector_select, filter_thick = filter_thick, aluminum=aluminum, polyimide=polyimide

  a2kev = 12.398420
  keV_per_el = 3.64e-3 ; energy per electron/hole pair in Si
  si_thick = 500. ; microns
  cdte_thick = 1000. * 1e-4 ; cm
  ; Get XCOM attenuation factors
  mu_be = read_dat('./be_1_100keV.dat')
  mu_cdte = read_dat('./cdte_1_100keV.dat')
  mu_filt = keyword_set(aluminum) ? read_dat('./al_1_100keV.dat') : mu_be
  mu_energies = reform(mu_be[0,*]) * 1000 ; keV
  polytran = read_dat('./polyimide_1_100Ang.dat') ; wavelength in nm!!
  be_dens = 1.85 ; g/cm^3
  cdte_dens = 5.85 ; g/cm^3
  filt_dens = keyword_set(aluminum) ? 2.70 : be_dens ; g/cm^3
  
  if not keyword_set(detector_select) then detector_select=0

  if keyword_set(aluminum) and keyword_set(polyimide) then begin
    message, /info, "Keyword conflict -- cannot set both /aluminum and /polyimide.  DEFAULTING to aluminum."
    polyimide = 0
  endif

  CASE detector_select of ;detector response


    0: begin ;SDD
      be_thick = 15. ; micron
      filt_thick = keyword_set(filter_thick) ? filter_thick : 0. ; micron
      resolution = 0.15 ; keV FWHM

      if keyword_set(aluminum) then begin
        diode_param, ['Be', 'Al'], [be_thick, filt_thick]*1e4, wv_besi, resp_besi, si=si_thick*1e4, ox=70., /noplot
        resp_poly = 1.
      endif else if keyword_set(polyimide) then begin
        diode_param, ['Be'], [be_thick]*1e4, wv_besi, resp_besi, si=si_thick*1e4, ox=70., /noplot
        resp_poly = interpol(polytran[1,*]^filt_thick, polytran[0,*]*10, wv_besi)
      endif else begin
        diode_param, ['Be'], [be_thick+filt_thick]*1e4, wv_besi, resp_besi, si=si_thick*1e4, ox=70., /noplot
        resp_poly = 1.
      endelse
      ; Convert to cts/ph = (el/ph) / (keV / (keV / el))
      resp_besi /= (a2kev/wv_besi)/keV_per_el
      ; Interpolate response (cts/ph) at eee bins, zero the response below 0.5 keV (LLD)
      resp = interpol(resp_besi*resp_poly, a2kev/wv_besi, energy_centers)
      
      ; i really don't know how to add air to this
      
      resp[where(energy_centers lt 0.5)] = 0.

      RETURN, resp

    end

    1: begin ;CdTe
      be_thick = 100. * 1e-4 ; cm
      filt_thick = (keyword_set(filter_thick) ? filter_thick : 0.) * 1e-4 ; cm
      resolution = 0.3 ; keV FWHM

      ; Calculate response of detector, cts/photon, added air??
      resp_raw = reform(exp(-mu_be[3,*] * be_thick * be_dens) * exp(-mu_filt[3,*] * filt_thick * filt_dens) * (1 - exp(-mu_cdte[3,*] * cdte_thick * cdte_dens)))

      ; Interpolate response (cts/ph) at eee bins, zero the response below 5 keV (LLD)
      resp = interpol(resp_raw, mu_energies, energy_centers)
      resp[where((energy_centers lt 4.5) or (energy_centers ge 100.))] = 0.

      RETURN, resp

    end

  ENDCASE


END

