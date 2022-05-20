%% Housekeeping
clear;
clc;
close all;

data = xlsread('radioisotopes - Sheet1.xls');
data(:,3:3:end) = [];

FeE = data(:,1);
FeE(isnan(FeE)) = [];
FeP = data(:,2);
FeP(isnan(FeP)) = [];

BaE = data(:,3);
BaE(isnan(BaE)) = [];
BaP = data(:,4);
BaP(isnan(BaP)) = [];

ZnE = data(:,5);
ZnE(isnan(ZnE)) = [];
ZnP = data(:,6);
ZnP(isnan(ZnP)) = [];

AmE = data(:,7);
%AmE(isnan(AmE)) = [];
AmP = data(:,8);
% AmP(isnan(AmP)) = [];
idxs = isnan(AmP);
idxs2 = find(idxs == 1);
AmP(idxs2) = [];
AmE(idxs2) = [];

CdE = data(:,9);
CdE(isnan(CdE)) = [];
CdP = data(:,10);
CdP(isnan(CdP)) = [];

idxsBa = find(BaP <= 0.0001);
% if idxsBa >= 1
    for b = idxsBa
        BaP(b) = [];
        BaE(b) = [];
    end
% end

idxsFe = find(FeP <= 0.0001);
    for f = idxsFe
        FeP(f) = [];
        FeE(f) = [];
    end

idxsZn = find(ZnP <= 0.0001);
    for z = idxsZn
        ZnP(z) = [];
        ZnE(z) = [];
    end

idxsAm = find(AmP <= 0.0001);
    for a = idxsAm
        AmP(a) = [];
        AmE(a) = [];
    end
    
idxsCd = find(CdP <= 0.0001);
    for c = idxsCd
        CdP(c) = [];
        CdE(c) = [];
    end

Fe = [FeE FeP];
Ba = [BaE BaP];
Zn = [ZnE ZnP];
Am = [AmE AmP];
Cd = [CdE CdP];

save('Spectral_Lines_Fe','Fe','-ascii','-double','-tabs');
save('Spectral_Lines_Ba','Ba','-ascii','-double','-tabs');
save('Spectral_Lines_Zn','Zn','-ascii','-double','-tabs');
save('Spectral_Lines_Am','Am','-ascii','-double','-tabs');
save('Spectral_Lines_Cd','Cd','-ascii','-double','-tabs');
