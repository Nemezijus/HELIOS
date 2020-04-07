function OB = square(OB,Npix)
% OB = square(OB,Npix) - finds a squared mask for a given roi object OB
% based on number of pixels to go up, left, right and down (same number)
% part of HELIOS
if nargin < 2
    borderpix = OB.N_pixels_for_square_mask;
end
cmask = OB.roi_mask;
dims = size(cmask);
W = dims(2);
H = dims(1);
[row, col] = find(cmask);
Nrow = numel(unique(row));
Ncol = numel(unique(col));
maxside = max(Nrow,Ncol);


if max(row)+maxside < H & max(col)+maxside < W
    if min(row) - borderpix > 0 && min(row)+maxside + borderpix < H && min(col) - borderpix > 0 && min(col)+maxside+borderpix < W
        isinner = 1;
    else
        isinner = 0;
    end
else
    if max(row) + borderpix < H && max(col) + borderpix < W
        isinner = 1;%
    else
        isinner = 0;
    end
end

if all(isinner)
    allin = 1;
else
    allin = 0;
end
    

if max(row)+maxside < H & max(col)+maxside < W %anywhere but left and bottom border
    
    %         if min(row) - borderpix > 0 & min(row)+maxside + borderpix < dims & min(col) - borderpix > 0 & min(col)+maxside+borderpix < dims
    if allin
        cmask([min(row) - borderpix:min(row)+maxside+borderpix],[min(col)-borderpix:min(col)+maxside+borderpix]) = 1;
        
    else
        cmask([min(row):min(row)+maxside],[min(col):min(col)+maxside]) = 1;
        
    end
    
else
    %         if max(row) + borderpix < dims & max(col) + borderpix < dims
    if allin
        cmask([max(row)-maxside - borderpix:max(row)+borderpix],[max(col)-maxside-borderpix:max(col)+borderpix]) = 1;
        
    else
        cmask([max(row)-maxside:max(row)],[max(col)-maxside:max(col)]) = 1;
        
    end
    
end

OB.square_mask = cmask;
OB.close_to_border = ~allin;
OB.mask_around_roi = uint16(cmask.*(~OB.roi_mask));

