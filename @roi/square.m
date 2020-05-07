function OB = square(OB,iroi,istage,exp, borderpix)
% OB = square(OB,iroi,istage,exp) - finds a squared mask for a given roi object OB
% based on number of pixels to go up, left, right and down (same number)
% part of HELIOS
if nargin < 4
    borderpix = OB.N_pixels_for_square_mask;
end
cmask = OB.roi_mask;

switch OB.setup
    case 'ao'
        allin = 1; %be default in AO we consider all folded frames to be in
        dimspath = strjoin({'/ANALYSIS',['ROI_',num2str(iroi)],['STAGE_',num2str(istage)]},'/');
        dims = h5readatt(exp.file_loc, dimspath, 'DIMENSIONS');
        
        FFdims = h5readatt(exp.file_loc, dimspath, 'FFSIZE');
        width = FFdims(1);
        height = FFdims(2);
        
        Nsquares = dims(2)./height;
        preview = h5read(exp.file_loc, ['/DATA/STAGE_',num2str(istage),'/MAXPROJ']);
        previewsize = size(preview);
        
        cmask = local_frameset_descript(previewsize, height, width, Nsquares,istage, iroi,exp);
    otherwise
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
end
OB.square_mask = cmask;
OB.close_to_border = ~allin;
OB.mask_around_roi = uint16(cmask.*(~OB.roi_mask));

function FS = local_frameset_descript(fs, H, W, Nsq, Nstage, iroi, exp);
%Nsq - number of squares
N = exp.N_roi;%number of ROIs
blankframe = zeros(fs);
Nroicols = fs(2)/W;
Nroirows = fs(1)/H;
colcount = 0;

roiselmask = h5read(exp.file_loc,['/ANALYSIS/ROI_',num2str(iroi),'/STAGE_',num2str(Nstage),'/ROIMASK']);
roiselmaskidx = find(roiselmask);

for iN = 1:Nsq
    roisqmask = blankframe;
    if mod(iN,Nroicols) == 0
        rowcount = Nroicols-1;
    else
        rowcount = mod(iN,Nroicols)-1;
    end
    if mod(iN,Nroicols) == 1
        colcount = colcount+1;
    end
    roisqmask((colcount-1)*H + 1:(colcount-1)*H + H,1+W*rowcount : W*rowcount+W) = 1;
    roisqmaskidx = find(roisqmask);
    memberpixelcheck = ismember(roiselmaskidx,roisqmaskidx);
    if sum(memberpixelcheck) > 0.8*numel(roiselmaskidx)
        FS = roisqmask;
        return
    end
end
% for iN = 1:Nsq
%     roisqmask = blankframe;
%     if mod(iN,Nroicols) == 0
%         rowcount = Nroicols-1;
%     else
%         rowcount = mod(iN,Nroicols)-1;
%     end
%     if mod(iN,Nroicols) == 1
%         colcount = colcount+1;
%     end
%     roisqmask((colcount-1)*H + 1:(colcount-1)*H + H,1+W*rowcount : W*rowcount+W) = 1;
% %     emptymat((colcount-1)*height + 1:(colcount-1)*height + height,1+width*rowcount : width*rowcount+width) = 1;
% % end
%     
% %     roisqmask(:,(iN-1)*W+1:W*iN) = 1;%
%     roisqmaskidx = find(roisqmask);
%     roisqmaskidx(roisqmaskidx>0);
%     FS.STAGE(Nstage).ROI(iN).squareframe = roisqmask;
%     %     FS(iN).idxs = roisqmaskidx;
%     count = 1;
%     for iM = 1:N
% %         cR = R(iM).STAGE(Nstage).logicalROI;
% %         roiselmask = cR.roi;
%         roiselmask = h5read(exp.file_loc,['/ANALYSIS/ROI_',num2str(iM),'/STAGE_',num2str(Nstage),'/ROIMASK']);
%         roiselmaskidx = find(roiselmask);
%         
%         memberpixelcheck = ismember(roiselmaskidx,roisqmaskidx);
%         if sum(memberpixelcheck) > 0.8*numel(roiselmaskidx)
%             FS.STAGE(Nstage).ROI(iN).containROI(count) = iM;
%             count = count+1;
%         end
%     end
% end
% 

