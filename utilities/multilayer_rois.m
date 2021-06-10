function multilayer_rois(PROJ, ROI, saveloc)
% multilayer_rois(PROJ, ROI) - visualizes the ROIs on
% multilayer average images. ROI is a struct array from 
% RTMC_mescroi_refinement function (output, pooled together)


% PROJ = multilayer_projections(mescpath, Nlayers, [1:5]);
Nlayers = numel(PROJ);
a = 90;%rotation angle in degrees
b = 180;
sz = size(PROJ(1).mean);

r = [cosd(a) -sind(a); sind(a) cosd(a)]; %rotation matrix
% r_2 = [cosd(b) -sind(b); sind(b) cosd(b)];


for ilayer = 1:Nlayers
    xcorr = 0;
    ycorr = 0;
%     xcorr = abs(floor(ROI(ilayer).R(1).offset(1)/ROI(ilayer).R(1).Xscale));
%     ycorr = abs(floor(ROI(ilayer).R(1).offset(2)/ROI(ilayer).R(1).Yscale));
%     F = figure;
%     set(F,'units', 'normalized', 'position', [0.322 0.159 0.392 0.625]);
    F2 = figure;
    set(F2,'units', 'normalized', 'position', [0.00417 0.503 0.292 0.389])
    I = imshow(flipud(PROJ(ilayer).image)); hold on;
    set(gca, 'YDir','normal')
%     figure(F);
%     imshow(PROJ(ilayer).image); hold on;
    R = ROI(ilayer).R;
    for iR = 1:numel(R)
        x = R(iR).pseudo(1,:)./R(iR).Xscale - sz(1)/2 - xcorr;
        y = R(iR).pseudo(2,:)./R(iR).Yscale - sz(2)/2 - ycorr;
        x_c = R(iR).pseudo_centroid(1)./R(iR).Xscale - sz(1)/2 - xcorr;
        y_c = R(iR).pseudo_centroid(2)./R(iR).Yscale - sz(2)/2 - ycorr;
        x_o = R(iR).original_adjusted(1,:)./R(iR).Xscale - sz(1)/2 - xcorr;
        y_o = R(iR).original_adjusted(2,:)./R(iR).Yscale - sz(2)/2 - ycorr;
        
        interm = [x;y];
        interm_c = [x_c;y_c];
        interm_o = [x_o;y_o];
        
        c = interm'*r;
        cc = interm_c'*r;
        co = interm_o'*r;
%         co = interm_o';
        
        x = c(:,1) + sz(1)/2;
        y = c(:,2) + sz(2)/2;
        
        x_c = cc(1) + sz(1)/2;
        y_c = cc(2) + sz(2)/2;
        
        x_o = co(:,1) + sz(1)/2;
        y_o = co(:,2) + sz(2)/2;
%         figure(F);
%         plot(x, y,'w-','linew',1); hold on
%         plot(x_c, y_c,'ro','MarkerSize',3); hold on
        figure(F2);
        
%         int = [R(iR).adjusted(2,:);R(iR).adjusted(1,:)];
        int = R(iR).adjusted';
        int_c = R(iR).adjusted_centroid;
        int(:, [1 2]) = int(:, [2 1]); 
        int_c([1,2]) = int_c([2,1]);
%         int = int*r;
%         axes(ax2);
        plot(int(:,1), int(:,2),'w-');hold on
        plot(int_c(1),int_c(2),'ro','MarkerSize',3);
        
%         plot(x_o,y_o,'-','Color',[0.94 0.94 0.94]);
    end
    figure(F2);
    axis on;
    set(I,'XData',[-(sz(2)/2 * R(iR).Yscale),sz(2)/2 * R(iR).Yscale],...
        'YData',[-(sz(1)/2 * R(iR).Xscale),(sz(1)/2 * R(iR).Xscale)]);
    ylim([-(sz(1)/2 * R(iR).Xscale),sz(1)/2 * R(iR).Xscale])
    xlim([-(sz(2)/2 * R(iR).Yscale),sz(2)/2 * R(iR).Yscale])
%     set(gca, 'YDir','normal')
    axis on
%     close(F)
    if ~isempty(saveloc)
        saveas(gcf, [saveloc,'\contours_',num2str(ilayer)]);
    end
    close(gcf);
end