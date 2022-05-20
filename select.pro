pro select, ut=ut, multi=multi, points=points, outlen=outlen

; Use the mouse to select specific points in a plot procedure window
; CLICK to define individual points
; CLICK AND DRAG to define line segments (to measure length)
; 
; INPUTS:
;   UT -- set to 1 if x-axis is time units (***NOT SUPPORTED YET***)
;   MULTI -- set to the number of desired points/segments [default: 1]
;
; OUTPUTS:
;   POINTS -- struct w/ coords of selected points, lengths of segments
;   OUTLEN -- the total length (in plot units) of line segments, if defined
;   (NOTE: this is only well-defined if the x and y axes are compatible!)

;checkvar,multi,0
multi = (n_elements(multi) eq 0) ? 0 : multi
totlen = 0.

for i=0,(multi-1)>0 do begin
  cursor,x1,y1,/down
  cursor,x2,y2,/up
  len = 0.

  if keyword_set(ut) then begin
print, "UT not supported."
;    common utcommon,utbase,utstart,utend
;    x1 = anytim(x1+utbase,/yoh)+' (+'+num2str(x1)+'s)'
;    x2 = anytim(x2+utbase,/yoh)+' (+'+num2str(x2)+'s)'
  endif

  print,'(x,y) = ('+strtrim(x1,2)+', '+strtrim(y1,2)+')'
  if (x1 NE x2 or y1 ne y2) then begin
    print,'('+strtrim(x2,2)+', '+strtrim(y2,2)+')'
    len = sqrt((x2-x1)^2+(y2-y1)^2)
    totlen = totlen + len
    print,'length: '+strtrim(len,2)
  endif
  
  xstart  = [temporary(xstart),  x1]
  ystart  = [temporary(ystart),  y1]
  xend    = [temporary(xend),    x2]
  yend    = [temporary(yend),    y2]
  length = [temporary(length), len]
  
endfor
print,'total length: '+strtrim(totlen,2)

points = {xstart: xstart, ystart: ystart, xend: xend, yend: yend, length: length}

outlen=totlen

end
