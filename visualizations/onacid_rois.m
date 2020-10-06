function onacid_rois(onacidloc, ex, mescloc, R, M)
% onacid_rois(onacidloc, exp, mescloc, ROI) - visualizes Onacid ROI
% contours and their dff

saveloc = 'N:\DATA\andrius.plauska\onacid runs\run15-36A1\IMG';
% saveloc = 'N:\DATA\andrius.plauska\onacid runs\36A1\run1\IMG';
Ndays = ex.N_stages;

X = h5read(ex.file_loc,'/DATA/STAGE_1/UNIT_1/XDATA');

C = colors;
onacfiles = dir(onacidloc);
onacfiles = onacfiles(~[onacfiles.isdir]);
for ifile = 1:numel(onacfiles)
    onacidfiles{ifile} = fullfile(onacfiles(ifile).folder, onacfiles(ifile).name);
end

loc = onacidfiles{contains(onacidfiles,'dff.mat')};
disp('Loading OnAcid stored dff file');
S = load(loc);
disp('Loading done');
fns = fieldnames(S);
dff = S.(fns{:});
DFF = onaciddffreshape(dff, Ndays, 9*12, numel(X), ex.N_reps);
if isempty(M)
    disp('calculating max projections. Takes a lot of time')
    for imesc = 1:numel(mescloc)
        tic
        [M(imesc).MP,M(imesc).maxp] = maxprojection_of_mesc(mescloc{imesc});
        toc
    end
end
mescroi_path = onacidfiles{contains(onacidfiles,'after')};
flag.convX = M(1).MP(1).convX;
flag.convY = M(1).MP(1).convY;
if isempty(R)
    for istage = 1 : Ndays
        tic
        R(istage).R = mescroi2poly(mescroi_path, M(istage).MP(1).geomTrans, ex.setup, flag);
        toc
    end
end
nroi = numel(R(1).R);


onacfiles = dir(onacidloc);
onacfiles = onacfiles(~[onacfiles.isdir]);

for ifile = 1:numel(onacfiles)
    onacidfiles{ifile} = fullfile(onacfiles(ifile).folder, onacfiles(ifile).name);
end

%for ROi contour showcase we show only Baseline 1
ibg = 1;
maxproj = M(ibg).maxp;
im = imrotate(flip(maxproj,2),90);

%%%%%%SURROGATE
surrogateF = figure;
set(surrogateF,'units', 'normalized', 'position', [0.0615 0.0991 0.889 0.786],'Color','white');
    
    AX1 = autoaxes(surrogateF,1,1,[0 0.5 0 0]);
    axes(AX1);
    imshow(im,M(ibg).MP(1).LUT); hold on

    for ir = 1:nroi
        try
            [logicalROI, roi_indexed] = roimask(R(1).R(ir).poly, maxproj);
            RR(ir).logicalROI = uint64(logicalROI);
            BW2 = bwboundaries(RR(ir).logicalROI);
            if numel(BW2) == 2 %whether there is a hole
                bwperim1 = BW2{1};
                bwperim2 = BW2{2};
                
                
                plot(bwperim1(:,1),bwperim1(:,2),'Linestyle','-','Color','w');hold on;
                plot(bwperim2(:,1),bwperim2(:,2),'Linestyle','-','Color','w');
                text(bwperim2(1,1),bwperim2(1,2),num2str(ir),'Color','r');
                
            else
                bwperim = BW2{:};
                
                plot(bwperim(:,1),bwperim(:,2),'Linestyle','-','Color','w');
                text(bwperim(1,1),bwperim(1,2),num2str(ir),'Color','r');
                
            end
        catch
            
        end
    end
h = findobj(surrogateF,'type','axes');
for iroi = 1:nroi
    F = figure;
    set(F,'units', 'normalized', 'position', [0.0615 0.0991 0.889 0.786],'Color','white');
    mTextBox0 = uicontrol(F,'style','text','Units','Normalized',...
        'Position',[0.001 0.955 0.15 0.025]);
    set(mTextBox0,'String',['  ROI = ', num2str(iroi)],'FontSize',10,'foregroundcolor','k',...
        'backgroundcolor','w','fontweight','bold','Tag','Unique');
    
%     AX1 = autoaxes(F,1,1,[0 0.5 0 0]);
%     axes(AX1);
%     imshow(im,M(ibg).MP(1).LUT); hold on
%     tic
%     for ir = 1:nroi
%         try
%             [logicalROI, roi_indexed] = roimask(R(1).R(ir).poly, maxproj);
%             RR(ir).logicalROI = uint64(logicalROI);
%             BW2 = bwboundaries(RR(ir).logicalROI);
%             if numel(BW2) == 2 %whether there is a hole
%                 bwperim1 = BW2{1};
%                 bwperim2 = BW2{2};
%                 
%                 
%                 plot(bwperim1(:,1),bwperim1(:,2),'Linestyle','-','Color','w');hold on;
%                 plot(bwperim2(:,1),bwperim2(:,2),'Linestyle','-','Color','w');
% %                 text(bwperim2(1,1),bwperim2(1,2),num2str(ir),'Color','r');
%                 
%             else
%                 bwperim = BW2{:};
%                 
%                 plot(bwperim(:,1),bwperim(:,2),'Linestyle','-','Color','w');
%                 text(bwperim(1,1),bwperim(1,2),num2str(ir),'Color','r');
%                 
%             end
%         catch
%             
%         end
%     end
%     toc
    s = copyobj(h,F);
    [logicalROI, roi_indexed] = roimask(R(ibg).R(iroi).poly, maxproj);
    BW2 = bwboundaries(uint64(logicalROI));
    if numel(BW2) == 2 %whether there is a hole
        bwperim1 = BW2{1};
        bwperim2 = BW2{2};
        
        
        plot(bwperim1(:,1),bwperim1(:,2),'Linestyle','-','Color','r');hold on;
        plot(bwperim2(:,1),bwperim2(:,2),'Linestyle','-','Color','r');
        text(bwperim2(1,1),bwperim2(1,2),num2str(iroi),'Color','r');
        
    else
        bwperim = BW2{:};
        
        plot(bwperim(:,1),bwperim(:,2),'Linestyle','-','Color','r');
        text(bwperim(1,1),bwperim(1,2),num2str(iroi),'Color','r');
        
    end
    
    
    
    AX3 = autoaxes(F,6,1,[0.46 0.42 0 0]);
    for istage = 1 : Ndays
        RGB = ind2rgb(M(istage).maxp,M(istage).MP(1).LUT);
        [mask, pixelidx] = roimask(R(istage).R(iroi).poly, M(istage).maxp); 
        cmask = square(mask);
        
        
        axes(AX3(istage));
        MAXPRO = local_trim_square(RGB, cmask);
        imagesc(MAXPRO);hold on;
        set(gca,'Yticklabels','');
        set(gca,'Xticklabels','');
        
        im = imrotate(flip(M(istage).maxp,2),90);
        [logicalROI, roi_indexed] = roimask(R(istage).R(iroi).poly, im);
        logicalROI = uint64(logicalROI);
        roisquare = square(logicalROI);
        sqmaskdouble = double(roisquare);
        roimasksquare = logicalROI(any(sqmaskdouble,2),any(sqmaskdouble,1));
        BW2 = bwboundaries(roimasksquare);
        if numel(BW2) == 2 %whether there is a hole
            bwperim1 = BW2{1};
            bwperim2 = BW2{2};
            plot(bwperim1(:,1),bwperim1(:,2),'Linestyle','-','Color','w');hold on;
            plot(bwperim2(:,1),bwperim2(:,2),'Linestyle','-','Color','w');
            
            
        else
            bwperim = BW2{:};
            plot(bwperim(:,1),bwperim(:,2),'Linestyle','-','Color','w');
        end
    end
    
    AX2 = autoaxes(F,6,1,[0.55 0 0 0]);
    gdff = DFF(iroi);
    for istage = 1:Ndays
        cstage = gdff.stage(istage);
        axes(AX2(istage));
        for isignal = 1:ex.N_stim(istage)*ex.N_reps(istage)
            colorpick = mod(isignal,9);
            if colorpick == 0
                colorpick = 9;
            end
            plot(X,cstage.signal(isignal,:),'Color',C.stim(colorpick,:)); hold on
        end
        if istage == 1
            title('OnAcid');
        end
    end
    
    fn = ['\ROI_',num2str(iroi)];
    saveas(gcf,[saveloc,fn],'png');
    close(gcf)
end


%30A1
% mescloc{1} = 'N:\DATA\Betanitas\!Mouse Gramophon\2_Imaging\group30\30A1 (112, Máté)\Measurement data\baseline1\2017_09_04_mouse30A_baseline1_combine_mcorr.mesc';
% mescloc{2} = 'N:\DATA\Betanitas\!Mouse Gramophon\2_Imaging\group30\30A1 (112, Máté)\Measurement data\baseline2\2017_09_05_mouse30A_baseline2_combine_mcorr.mesc';
% mescloc{3} = 'N:\DATA\Betanitas\!Mouse Gramophon\2_Imaging\group30\30A1 (112, Máté)\Measurement data\baseline3\2017_09_06_mouse30A_baseline3_combine_mcorr_tough1.mesc';
% mescloc{4} = 'N:\DATA\Betanitas\!Mouse Gramophon\2_Imaging\group30\30A1 (112, Máté)\Measurement data\effect1\2017_09_20_mouse30A_effect1_combine_mcorr_tough1.mesc';
% mescloc{5} = 'N:\DATA\Betanitas\!Mouse Gramophon\2_Imaging\group30\30A1 (112, Máté)\Measurement data\effect2\2017_09_21_mouse30A_effect2_combine_mcorr_tough1.mesc';
% mescloc{6} = 'N:\DATA\Betanitas\!Mouse Gramophon\2_Imaging\group30\30A1 (112, Máté)\Measurement data\effect3\2017_09_22_mouse30A_effect3_combine_mcorr_tough1.mesc';


% 36A1
% mescloc{1} = 'N:\DATA\Betanitas\!Mouse Gramophon\2_Imaging\group36\36A1 (060, Andy&Blanka)\Measurement data\baseline1\2018_02_21_baseline1_combine_mcorr.mesc';
% mescloc{2} = 'N:\DATA\Betanitas\!Mouse Gramophon\2_Imaging\group36\36A1 (060, Andy&Blanka)\Measurement data\baseline2\2018_02_22_baseline2_combine_mcorr.mesc';
% mescloc{3} = 'N:\DATA\Betanitas\!Mouse Gramophon\2_Imaging\group36\36A1 (060, Andy&Blanka)\Measurement data\baseline3\2018_02_23_baseline3_combine_mcorr.mesc';
% mescloc{4} = 'N:\DATA\Betanitas\!Mouse Gramophon\2_Imaging\group36\36A1 (060, Andy&Blanka)\Measurement data\effect1\2018_03_07_effect1_combine_mcorr.mesc';
% mescloc{5} = 'N:\DATA\Betanitas\!Mouse Gramophon\2_Imaging\group36\36A1 (060, Andy&Blanka)\Measurement data\effect2\2018_03_08_effect2_combine_mcorr.mesc';
% mescloc{6} = 'N:\DATA\Betanitas\!Mouse Gramophon\2_Imaging\group36\36A1 (060, Andy&Blanka)\Measurement data\effect3\2018_03_09_effect3_combine_mcorr.mesc';
















function C = colors
% https://color.adobe.com/create
%1 stimuli
C.stim(2,:) = html2rgb('#33B2FF');
C.stim(3,:) = html2rgb('#FF6032');
C.stim(4,:) = html2rgb('#E8C223');
C.stim(5,:) = html2rgb('#26FF26');
C.stim(6,:) = html2rgb('#9CE8FF');
C.stim(7,:) = html2rgb('#FFAA9C');
C.stim(8,:) = html2rgb('#E8CF82');
C.stim(9,:) = html2rgb('#A5FF8F');
C.stim(1,:) = html2rgb('#595B66');

%2 groups
C.group(1,:) = html2rgb('#54AD85');
C.group(2,:) = html2rgb('#FA2200');
C.group(3,:) = html2rgb('#FFC05C');
C.group(4,:) = html2rgb('#1D69AD');

function cc = html2rgb(code)
cc = sscanf(code(2:end),'%2x%2x%2x',[1 3])/255;

function sq = local_trim_square(cimag, cmask)
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

sq = imrotate(flip(c,2),90);


function cmask = square(cmask)
dims = size(cmask);
W = dims(2);
H = dims(1);
[row, col] = find(cmask);
Nrow = numel(unique(row));
Ncol = numel(unique(col));
maxside = max(Nrow,Ncol);
borderpix = 5;

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
        err = 1;
        maxsidetemp = maxside;
        while err
            try
                cmask([max(row)-maxsidetemp - borderpix:max(row)+borderpix],[max(col)-maxsidetemp-borderpix:max(col)+borderpix]) = 1;
                err = 0;
            catch
                maxsidetemp = maxsidetemp-1;
            end
        end
        
    else
        %code below added 2020 05 15 and needs some refining
        err = 1;
        maxsidetemp = maxside;
        while err
            try
                cmask([max(row)-maxsidetemp:max(row)],[max(col)-maxsidetemp:max(col)]) = 1;%except this line
                err = 0;
            catch
                maxsidetemp = maxsidetemp-1;
            end
        end
        %till here
        
    end
    
end