function C = bestcorr(OB, iroi)
% C = bestcorr(OB, iroi) - estimates the correlations between ROI
% surrounding boxes by shifting them against each other across all frames 
% and picks out the best correlation. Mathod for experiment object.
% part of HELIOS

Nstages = OB.N_stages;
Npix = 5;

C = [];
if iroi > OB.N_roi
    msgbox('Selected ROI exceeds number of ROIs.');
    C = [];
    return
end
%reference image
% cmask = h5read(OB.file_loc,['/ANALYSIS/ROI_',num2str(iroi),'/STAGE_',num2str(1),'/ROIMASK']);
try
    cframe = h5read(OB.file_loc,['/DATA/STAGE_',num2str(1),'/UNIT_',num2str(1),'/MEANFRAME']);
catch
    msgbox('This experiment has no MEANFRAME');
    C = [];
    return
end
clut = h5read(OB.file_loc,['/DATA/STAGE_',num2str(1),'/UNIT_',num2str(1),'/MEANFRAMELUT']);
% R = roi(cmask,Npix);
R = roi(OB,iroi,1,Npix);

if R.close_to_border
    referenceonborder = 1;
else
    referenceonborder = 0;
end
refframe = cutframe(cframe, clut, R.square_mask);
ref_g = refframe(:,:,2);
refdims = numel(refframe(:,1,1));


for istage = 1:Nstages
    cmask = h5read(OB.file_loc,['/ANALYSIS/ROI_',num2str(iroi),'/STAGE_',num2str(istage),'/ROIMASK']);
%     R = roi(cmask,Npix);
    R = roi(OB,iroi,istage,Npix);
    if ~R.close_to_border & ~referenceonborder
        shiftsize = 5;
    else
        shiftsize = 0;
    end
    shiftwindow = [(-1)*shiftsize:1:shiftsize];
    Nframes = OB.N_stim(istage).*OB.N_reps(istage);
    Nframes_restun = sum(sum(OB.restun{istage}>0));%this eliminates fake frames generated to keep matrix shape in restun
    if Nframes_restun < Nframes
        Nframes = Nframes_restun;
        disp('Number of frames is less than expected');
    end
    for iframe = 1:Nframes;
        cframe = h5read(OB.file_loc,['/DATA/STAGE_',num2str(istage),'/UNIT_',num2str(iframe),'/MEANFRAME']);
        clut = h5read(OB.file_loc,['/DATA/STAGE_',num2str(istage),'/UNIT_',num2str(iframe),'/MEANFRAMELUT']);
        frame = cutframe(cframe, clut, R.square_mask);
        cPOLY_g = frame(:,:,2);
        if numel(frame(:,1,1)) < refdims %this is a bit different from VISC method (see visc_ROIevolution)
            POLYdims = numel(frame(:,1,1));
        else
            POLYdims = refdims;
        end
        for xshift = 1:numel(shiftwindow)
            for yshift = 1:numel(shiftwindow)
                CorrData(xshift,yshift,iframe) = corr2((ref_g([1+shiftsize:POLYdims-shiftsize],[1+shiftsize:POLYdims-shiftsize])),...
                    cPOLY_g([xshift:POLYdims-numel(shiftwindow)+xshift],[yshift:POLYdims-numel(shiftwindow)+yshift]));
            end
        end
    end
    for iframe = 1:Nframes
        cCorrData = CorrData(:,:,iframe);
        MaxCorr(iframe) = max(max(cCorrData));
    end
    C = [C, MaxCorr];
    clear MaxCorr
end
C(1) = 1;

function frame = cutframe(cframe, clut, cmask)
cimag = ind2rgb(cframe,clut);
tempg = cimag(:,:,2);
mintempg = min(min(tempg(tempg~=0)));
tempg(tempg == 0) = mintempg;
cimag(:,:,2) = tempg;
%%%%%%
r = cimag(:,:,1).*cmask;
g = cimag(:,:,2).*cmask;
b = cimag(:,:,3).*cmask;
G = g;
r( ~any(G,2), : ) = [];
r( :, ~any(G,1) ) = [];
g( ~any(G,2), : ) = [];
g( :, ~any(G,1) ) = [];
b( ~any(G,2), : ) = [];
b( :, ~any(G,1) ) = [];
c(:,:,1) = r;
c(:,:,2) = g;
c(:,:,3) = b;
frame = imrotate(flip(c,2),90);