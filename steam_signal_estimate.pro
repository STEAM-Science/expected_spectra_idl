pro steam_signal_estimate, aperture=aperture, resolution=resolution, detector_select=detector_select, aluminum=aluminum, polyimide=polyimide, filter_thick=filter_thick

  if not keyword_set(detector_select) then detector_select=0
  
  ; Set various conversion factors and physical parameters
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

  setplot
  !x.margin = [6,1]
  !y.margin = [3.15, 1.75]
;  cc = rainbow(7)
  linecolors
  
  if keyword_set(aluminum) and keyword_set(polyimide) then begin
    message, /info, "Keyword conflict -- cannot set both /aluminum and /polyimide.  DEFAULTING to aluminum."
    polyimide = 0
  endif
  
  case detector_select of
  
  0: begin ; SDD, arbitrary Be filter
    be_thick = 15. ; micron
    filt_thick = keyword_set(filter_thick) ? filter_thick : 0. ; micron
    if not keyword_set(aperture) then aperture = 300. ; micron
    area = !dpi*(aperture*1e-4/2.)^2 ; cm^2
    meas_title = 'SDD (Be 15!Mmm), Ap = ' + strtrim(round(aperture),2) + '!Mmm, ' + (keyword_set(aluminum) ? 'Al' : (keyword_set(polyimide) ? 'Poly' : 'Be')) + ' = ' + strtrim(round(filt_thick),2) + '!Mmm'
    if not keyword_set(resolution) then resolution = 0.15 ; keV FWHM
    
    ; Create arbitrary energy array, 0.5-20 keV, ~0.02 keV bins
    wid_ee = (20-0.5)/1024
    junk = get_edges(findgen((20.-0.5)/wid_ee+1)*wid_ee+0.5, edges_2=eee, mean=eee_mean, wid=eee_wid)
;    setenv,'CHIANTI_CONT_FILE=chianti_cont_01_30_v71.geny'
;    chianti_kev_common_load, /NO_ABUND, /reload

    ; Get Henke attenuation factors (el/ph) -- wv in Ang
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
    resp = interpol(resp_besi*resp_poly, a2kev/wv_besi, eee_mean)
    resp[where(eee_mean lt 0.5)] = 0.
  end

  1: begin ; CdTe, arbitrary filter (Be or Al)
    be_thick = 100. * 1e-4 ; cm
    filt_thick = (keyword_set(filter_thick) ? filter_thick : 0.) * 1e-4 ; cm
    if not keyword_set(aperture) then aperture = 2700. ; micron
    area = !dpi*(aperture*1e-4/2.)^2 ; cm^2
    meas_title = 'CdTe (Be 100!Mmm), Ap = ' + strtrim(round(aperture),2) + '!Mmm, ' + (keyword_set(aluminum) ? 'Al' : (keyword_set(polyimide) ? 'Poly' : 'Be')) + ' = ' + strtrim(round(filt_thick*1e4),2) + '!Mmm'
    if not keyword_set(resolution) then resolution = 0.3 ; keV FWHM

    ; Create arbitrary energy array, 1-100 keV, ~0.1 keV bins
    wid_ee = (100.-1.)/1024
    junk = get_edges(findgen((100.-1)/wid_ee+1)*wid_ee+1., edges_2=eee, mean=eee_mean, wid=eee_wid)
;    setenv,'CHIANTI_CONT_FILE=chianti_cont_1_250_v70.sav'
;    chianti_kev_common_load, /NO_ABUND, /reload

    ; Calculate response of detector, cts/photon
    resp_raw = reform(exp(-mu_be[3,*] * be_thick * be_dens) * exp(-mu_filt[3,*] * filt_thick * filt_dens) * (1 - exp(-mu_cdte[3,*] * cdte_thick * cdte_dens)))

    ; Interpolate response (cts/ph) at eee bins, zero the response below 5 keV (LLD)
    resp = interpol(resp_raw, mu_energies, eee_mean)
    resp[where((eee_mean lt 4.5) or (eee_mean ge 52.))] = 0.
  end

  endcase

  ; Calculate various incident photon flux spectra
  ; spec = (phot / cm^2 / s / keV) * keV * cm^2 = phot / s
  ; For 2002 Jul 23, interval 9 (peak HXR) based on Caspi & Lin (2010)
  spec_x5 = (f_vth(eee, [1.27277, 3.63241, 1.0]) + f_vth(eee, [5.40545, 2.02360, 1.0]) + f_vth(eee, [58, 0.52, 1.0]) + f_3pow(eee, [19.9396, 1.50000, 48.1353, 2.65948, 400.000, 2.00000])) * eee_wid * area
  ; With temps based on Caspi, Krucker, & Lin 2014, EMs adjusted to match GOES flux, and PL adjusted arbitrarily
  spec_m5 = (f_vth(eee, [0.175, 2.75755, 1.0]) + f_vth(eee, [0.6, 1.55112, 1.0]) + f_vth(eee, [5.8, 0.52, 1.0]) + f_3pow(eee, [1.99396, 1.50000, 35, 3.5, 400.000, 2.00000])) * eee_wid * area
  spec_m1 = (f_vth(eee, [0.044, 1.80964, 1.0]) + f_vth(eee, [0.135, 1.29260, 1.0]) + f_vth(eee, [1.2, 0.52, 1.0]) + f_3pow(eee, [0.39879, 1.50000, 20, 4, 400.000, 2.00000])) * eee_wid * area
  ; With temps based on Caspi, Krucker, & Lin 2014 for GOES, guesstimate for RHESSI, EMs adjusted to match GOES flux, and PL adjusted arbitrarily
  spec_c1 = (f_vth(eee, [0.01, 1.2, 1.0]) + f_vth(eee, [0.015, 0.896204, 1.0]) + f_vth(eee, [.08, 0.52, 1.0]) + f_vth(eee, [3.5, 0.2, 0.41]) + f_3pow(eee, [0.04, 1.50000, 15, 6, 400.000, 2.00000])) * eee_wid * area
  ; For strong and weak ARs, based on X123 rocket results of Caspi et al. (2015) -- B7 and B1.6 levels
  spec_b7 = (f_vth(eee, [0.031242997, 0.74194414, 0.41]) + f_vth(eee, [3.5, 0.23129428, 0.41])) * eee_wid * area
  spec_b1 = (f_vth(eee, [0.0014166682, 0.75919482, 1.0]) + f_vth(eee, [0.4, 0.25346233, 1.0])) * eee_wid * area
  spec_a1 = (f_vth(eee, [0.0003, 0.6, 1.0]) + f_vth(eee, [0.07, 0.22, 1.0])) * eee_wid * area
  ; For deep minimum, based on Sylwester et al. (2012)
  spec_min = (f_vth(eee, [0.0978000, 0.147357, 1.0])) * eee_wid * area
  ; Add B7 active-region background to the BIG flares, B1 to the small flare
  spec_x5 += spec_b7 & spec_m5 += spec_b7 & spec_m1 += spec_b7 & spec_c1 += spec_b1
  spec_b1 += spec_min & spec_a1 += spec_min
  plot_oo, eee_mean, spec_m1, yr=[1e-4,1e4],xr=[0.5,(detector_select ? 100 : 30)],/xs, xtitle='Energy [keV]', ytitle='phot/sec'
  oplot, eee_mean, spec_c1, color=1
  oplot, eee_mean, spec_b7, color=2
  oplot, eee_mean, spec_b1, color=3
  oplot, eee_mean, spec_a1, color=4
  oplot, eee_mean, spec_min, color=5

  ; Isolate energies important for GOES flux
;  iii = where(a2kev/eee_mean ge 1. and a2kev/eee_mean le 8.)

  ; Make sure X5 flare is 10x M5 flare, M5 flare is 5x M1 flare... obviously just an estimate, assume factor-of-2 uncertainty
  ; Output should be close to: 10, 5, 10, 14.3, 4.3
;  print, total(spec_x5[iii]) / total(spec_m5[iii]), total(spec_m5[iii]) / total(spec_m1[iii]), total(spec_m1[iii]) / total(spec_c1[iii]),  total(spec_m1[iii]) / total(spec_b7[iii]), total(spec_b7[iii]) / total(spec_b1[iii])

  ; Calculate count rate spectra for the incident spectra, based on instrument response and resolution
  predict_x5 = gaussfold(eee_mean, spec_x5 * resp, resolution)
  predict_m5 = gaussfold(eee_mean, spec_m5 * resp, resolution)
  predict_m1 = gaussfold(eee_mean, spec_m1 * resp, resolution)
  predict_c1 = gaussfold(eee_mean, spec_c1 * resp, resolution)
  predict_b7 = gaussfold(eee_mean, spec_b7 * resp, resolution)
  predict_b1 = gaussfold(eee_mean, spec_b1 * resp, resolution)
  predict_a1 = gaussfold(eee_mean, spec_a1 * resp, resolution)
  predict_min = gaussfold(eee_mean, spec_min * resp, resolution)

  ; Plot up the signal estimate
  setplot & !p.charsize=4 & !p.thick=3
  cc = rainbow(8)
;  linecolors
  plot_oo, eee_mean, predict_x5 / eee_wid, xr=[(detector_select ? 5 : 0.5),(detector_select ? 50 : 20)], /xs, yr=[1e-4,(detector_select ? 1e6 : 1e6)], /ys, psym=10, xtitle='Energy [keV]', ytitle='counts s!U-1!N keV!U-1!N', title='STEAM: ' + meas_title
  oplot,   eee_mean, predict_m5 / eee_wid,                           psym=10, color=cc[0];2
  oplot,   eee_mean, predict_m1 / eee_wid,                           psym=10, color=cc[1];10
  oplot,   eee_mean, predict_c1 / eee_wid,                           psym=10, color=cc[2];4
  oplot,   eee_mean, predict_b7 / eee_wid,                           psym=10, color=cc[3];8
  oplot,   eee_mean, predict_b1 / eee_wid,                           psym=10, color=cc[4];12
if not keyword_set(detector_select) then begin
  oplot,   eee_mean, predict_a1 / eee_wid,                           psym=10, color=cc[5];13
  oplot,   eee_mean, predict_min / eee_wid,                           psym=10, color=cc[6];9
endif
  numdets = (detector_select ? 1. : 1.)
  flare_integ_time = 60.
  ar_integ_time = 3600 * 6.
  snr = 10.
;  oplot,   [(detector_select ? 5 : 0.5),(detector_select ? 100 : 30)], ((detector_select ? 5. : 10.) / flare_integ_time / numdets) * [1,1], line = 2
; Plot 1 count per second
  oplot,   [(detector_select ? 5 : 0.5),(detector_select ? 100 : 30)], (snr^2 / flare_integ_time / resolution ) * [1,1], line = 2
;  polyfill, (filter ? [5, 9, 9, 5, 5] : [0.5, 1.2, 1.2, 0.5, 0.5])*1.03, ((filter ? 5. : 10.) / 30. / numdets) * [0.45, 0.45, 0.95, 0.95, 0.45], color=!p.background
  xyouts, (detector_select ? 5 : 0.5)*1.03, ((detector_select ? snr^2 : snr^2) / flare_integ_time / resolution) * .5 * .7, 'SNR > '+strtrim((detector_select ? 5 : 5),2)+' (FL, ' + sigfig(flare_integ_time,2) + ' s)';, charsize=3
  oplot,   [(detector_select ? 5 : 0.5),(detector_select ? 100 : 30)], (snr^2 / ar_integ_time / resolution ) * [1,1], line = 2
;  polyfill, (filter ? [5, 7, 7, 5, 5] : [0.5, 1.5, 1.5, 0.5, 0.5])*1.03, ((filter ? 5. : 10.) / 1200. / numdets) * [0.45, 0.45, 0.95, 0.95, 0.45], color=!p.background
  xyouts, (detector_select ? 5 : 0.5)*1.03, ((detector_select ? snr^2 : snr^2) / ar_integ_time / resolution) * .5 * .7, 'SNR > '+strtrim((detector_select ? 5 : 5),2)+' (AR, ' + sigfig(ar_integ_time / 60.,2) + ' m)';, charsize=3
  dx = 0.79 & dy = .025
  xyouts, dx - 0.01, 0.79+dy, /norm, align=1, 'TOTAL CPS:';, charsize=3
 xyouts, dx, 0.85+dy, /norm, 'X5 = ' + sigfig(total(predict_x5),4);, charsize=3
 xyouts, dx, 0.81+dy+0.005, /norm, 'M5 = ' + sigfig(total(predict_m5),4), color=cc[0];2;, charsize=3
  xyouts, dx, 0.77+dy+0.01, /norm, 'M1 = ' + sigfig(total(predict_m1),4), color=cc[1];10;, charsize=3
  xyouts, dx, 0.73+dy+0.015, /norm, 'C1 = ' + sigfig(total(predict_c1),4), color=cc[2];4;, charsize=3
  xyouts, dx, 0.69+dy+0.02, /norm, 'B7 = ' + sigfig(total(predict_b7),4), color=cc[3];8;, charsize=3
  xyouts, dx, 0.65+dy+0.025, /norm, 'B1 = ' + sigfig(total(predict_b1),4), color=cc[4];12;, charsize=3
if not keyword_set(detector_select) then begin
  xyouts, dx, 0.61+dy+0.03, /norm, 'A1 = ' + sigfig(total(predict_a1),4), color=cc[5];13;, charsize=3
  xyouts, dx, 0.57+dy+0.035, /norm, 'Min = ' + sigfig(total(predict_min),4), color=cc[6];9;, charsize=3
endif

  ; Restore for other purposes...
;  setenv,'CHIANTI_CONT_FILE=chianti_cont_01_30_v71.geny'
;  chianti_kev_common_load, /NO_ABUND, /reload

end
