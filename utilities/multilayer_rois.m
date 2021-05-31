function multilayer_rois(PROJ, ROI, saveloc)
% multilayer_rois(PROJ, ROI) - visualizes the ROIs on
% multilayer average images. ROI is a struct array from 
% RTMC_mescroi_refinement function (output, pooled together)


% PROJ = multilayer_projections(mescpath, Nlayers, [1:5]);
Nlayers = numel(PROJ);
a = 90;
sz = size(PROJ(1).mean);
r = [cosd(90) -sind(90); sind(90) cosd(90)]; %rotation matrix
for ilayer = 1:Nlayers
    figure;
    set(gcf,'units', 'normalized', 'position', [0.322 0.159 0.392 0.625]);
    imshow(PROJ(ilayer).image); hold on;
    R = ROI(ilayer).R;
    for iR = 1:numel(R)
        x = R(iR).pseudo(1,:) - sz(1)/2;
        y = R(iR).pseudo(2,:) - sz(2)/2;
        interm = [x;y];
        c = interm'*r;
        x = c(:,1) + sz(1)/2;
        y = c(:,2) + sz(2)/2;
        plot(x, y,'w-'); hold on
    end
    saveas(gcf, [saveloc,'\contours_',num2str(ilayer)]);
    close(gcf);
end