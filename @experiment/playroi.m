function [IMmovie,frames] = playroi(OB, iroi, istage, Npix)
% [IMmovie, frames] = playroi(OB, iroi, istage, Npix) - method for experiment object. Generates
% movie for a specified ROI and day created from stacked squared frames
% around that ROI
% part of HELIOS
if nargin < 4
    Npix = 5;
end
if nargin < 3
    istage = 1;
end
method = 2;
Nframes = OB.N_stim(istage).*OB.N_reps(istage);
if Nframes == 0
    msgbox('no frames to use for the video. Terminating')
    return
end
F = figure;
set(F,'units', 'normalized', 'position', [0.396 0.331 0.24 0.389],'Color','white',...
    'NumberTitle','off','Name',['ROI ', num2str(iroi),' stage ',num2str(istage)]);
AX = axes;
axdims = getpixelposition(AX);
axw = axdims(3);
axh = axdims(4);


% cmask = h5read(OB.file_loc,['/ANALYSIS/ROI_',num2str(iroi),'/STAGE_',num2str(istage),'/ROIMASK']);
R = roi(OB,iroi,istage,Npix);
cmask = R.square_mask;
for iframe = 1:Nframes
    cframe = h5read(OB.file_loc,['/DATA/STAGE_',num2str(istage),'/UNIT_',num2str(iframe),'/MEANFRAME']);
    clut = h5read(OB.file_loc,['/DATA/STAGE_',num2str(istage),'/UNIT_',num2str(iframe),'/MEANFRAMELUT']);
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
    
    imdims = size(frame);
        imw = imdims(1);
        imh = imdims(2);
        wrat = axw/imw;
        hrat = axh/imh;
        if wrat < hrat
            resizefactor = wrat;
        else
            resizefactor = hrat;
        end
        switch method
            case 1
                IMmovie(:,:,:,iframe) = frame;
                resized = imresize(frame,resizefactor,'method','nearest');
            case 2
                resized = imresize(frame,resizefactor,'method','nearest');                
                resized = imresize(frame,[max(size(resized)),max(size(resized))],'method','nearest');
                IMmovie(:,:,:,iframe) = resized;
        end
        resized(resized>1) = 1;
        resized(resized<0) = 0;
        frames(iframe) = im2frame(resized);
    
end
if nargout == 0
    movie(AX,frames);
    IMmovie =[];
    frames =[];
else
    close (F)
end