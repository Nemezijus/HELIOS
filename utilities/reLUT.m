function [newLUT, newIMG] = reLUT(IMGind, oldLUT, toplot)
% newLUT = reLUT(IMG, oldLUT, toplot) - assigns a new LUT for a given
% image so that visibility of structures would improve

%IMG - unsigned 16bit
% IMGind = rgb2ind(IMG,oldLUT);

minIMG = min(min(IMGind(IMGind > 1)));
% maxIMG = max(max(IMGind));

maxIMG = prctile(IMGind(:),99);
maxIMG = prctile(IMGind(IMGind>maxIMG),99);
newLUT = oldLUT;

newLUT(1:minIMG,2) = 0;
try
    newLUT(minIMG+1:maxIMG,2) = linspace(0,1,maxIMG-minIMG);
catch
    disp('error in reLUT encountered');
    newLUT = oldLUT;
end
newLUT(maxIMG+1:numel(oldLUT(:,2)),2) = 1;


newIMG = ind2rgb(IMGind,newLUT);
if toplot
    ff = figure;
    set(ff,'units', 'normalized', 'position', [0.223 0.274 0.608 0.497])
    subplot(1,2,1);
    imagesc(ind2rgb(IMGind,oldLUT));
    subplot(1,2,2);
    imagesc(newIMG);
    %STATS
    
    disp(['min intensity in the frame: ',num2str(minIMG)]);
    disp(['max intensity in the frame: ',num2str(maxIMG)]);
    
    GoldLUT = oldLUT(:,2);
    idxGoldLUT = 1:numel(GoldLUT);
    disp(['OLD LUT range: ',num2str(max(idxGoldLUT(GoldLUT == 0))),' - ',...
        num2str(min(idxGoldLUT(GoldLUT == 1))), ' (range: ',...
        num2str(min(idxGoldLUT(GoldLUT == 1))-max(idxGoldLUT(GoldLUT == 0))),')']);
    max(idxGoldLUT(GoldLUT == 0));
    min(idxGoldLUT(GoldLUT == 1));
    
    GnewLUT = newLUT(:,2);
    idxGnewLUT = 1:numel(GnewLUT);
    disp(['NEW LUT range: ',num2str(max(idxGnewLUT(GnewLUT == 0))),' - ',...
        num2str(min(idxGnewLUT(GnewLUT == 1))),' (range: ',...
        num2str(min(idxGnewLUT(GnewLUT == 1))-max(idxGnewLUT(GnewLUT == 0))),')']);
end

