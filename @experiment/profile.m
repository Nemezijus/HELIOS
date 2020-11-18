function F = profile(OB, iroi, flag)
% F = profile(OB, iroi, flag) - experiment class method which produces a
% matlab image - a profile (or overview) of the iroi ROI.
% OB - experiment object.
% part of HELIOS
if nargin < 3
    flag = [];
end
F = figure;
set(F,'units', 'normalized', 'position', [0.103 0.0528 0.817 0.853],'color','w');
C = colors;

%0 - estimate responses
for istage = 1:OB.N_stages
    R(istage) = response(OB, iroi, istage);
end
G = local_stage_grouping([R.stage]);


%1 - traces

%first - get the ylims
Ymin = Inf;
Ymax = -Inf;
for istage = 1:OB.N_stages
    for istim = 1:OB.N_stim(istage)
        W = OB.traces({iroi, istage, istim, 0},'dff');
        m = mean(W.data);
        if strcmp(OB.setup,'ao')
            m = m(1:end-30); %truncate the last part
        end
        if min(m) < Ymin
            Ymin = min(m);
        end
        if max(m) > Ymax
            Ymax = max(m);
        end
    end
end
AX_traces = autoaxes(F,OB.N_stages, 1,[0.105, 0.5, 0.005, 0.02],[0.025 0.025]);

%now plot the averages
for istage = 1:OB.N_stages
    axes(AX_traces(istage));
    stageID{istage} = h5readatt(OB.file_loc,['/DATA/STAGE_',num2str(istage)],'STAGEID');
    for istim = 1:OB.N_stim(istage)
        W = OB.traces({iroi, istage, istim, 0},'dff');
        plot(W.time(1,:).*1e-3, mean(W.data), 'Color',C.stim(istim,:),'Linest','-','Linew',1.5); hold on
        stimtype = h5readatt(OB.file_loc,['/DATA/STAGE_',num2str(istage)],'STIMTYPE');
        S = stimlist(stimtype);
        plot([S.static1,S.static1].*1e-3,[Ymin, Ymax], 'k-','linew',2);
        plot([S.blank2, S.blank2].*1e-3,[Ymin, Ymax], 'k-','linew',2);
    end
    ylim([Ymin, Ymax]);
    if istage ~= OB.N_stages
        set(gca,'XTickLabel',[]);
    end
    if istage == OB.N_stages
        xlabel('time, s');
    end
    ylabel('dff');
end

%2 - images
AX_images = autoaxes(F, OB.N_stages, 1, [0 0.875 0.005 0.02],[0.025 0.025]);
for istage = 1:OB.N_stages
    [IM, ROI] = local_image(OB, iroi, istage,AX_images(istage));
    axes(AX_images(istage));
    imagesc(IM);hold on
    set(gca,'XTickLabel',[]);
    set(gca,'YTickLabel',[]);
    sqmaskdouble = double(ROI.square_mask);
    roimasksquare = ROI.roi_mask(any(sqmaskdouble,2),any(sqmaskdouble,1));
    BW2 = bwboundaries(roimasksquare);
    if numel(BW2) == 2 %whether there is a hole
        bwperim1 = BW2{1};
        bwperim2 = BW2{2};
        if strcmp(OB.setup,'ao')
            plot(bwperim1(:,2),bwperim1(:,1),'Linestyle','-','Color','w');hold on
            plot(bwperim2(:,2),bwperim2(:,1),'Linestyle','-','Color','w');
        else
            plot(bwperim1(:,1),bwperim1(:,2),'Linestyle','-','Color','w');hold on;
            plot(bwperim2(:,1),bwperim2(:,2),'Linestyle','-','Color','w');
        end
        
    else
        bwperim = BW2{:};
        if strcmp(OB.setup,'ao')
            plot(bwperim(:,2),bwperim(:,1),'Linestyle','-','Color','w');
        else
            plot(bwperim(:,1),bwperim(:,2),'Linestyle','-','Color','w');
        end
    end
end

%3 - polar plot
AX_ppl = autoaxes(F, 1,1,[0.8 0, 0, 0.6]);


for istage = 1:OB.N_stages
    axes(AX_images(istage));
    for ig = 1:numel(G)
        if G(ig).logical(istage)
            Col = C.group(ig,:);
        end
    end
    ylabel(R(istage).stage{:},'Color',Col);
end

axes(AX_ppl)
for istage = 1:OB.N_stages
    goodstim = deg2rad(R(istage).stimulus(R(istage).stimulus <= 360));
    goodstr = R(istage).strength(R(istage).stimulus <= 360);
%     ppl = polarplot ([goodstim, goodstim(1)],[goodstr,goodstr(1)],...
%         'Color','k','Linew',1.5,'Linest','-'); hold on
end

for ig = 1:numel(G)
    m = mean(vertcat(R(G(ig).logical).strength));
    m = m(R(1).stimulus <= 360);
        ppl = polarplot ([goodstim, goodstim(1)],[m,m(1)],...
        'Color',C.group(ig,:),'Linew',2,'Linest','-'); hold on
end
ppl = gca;
ppl.ThetaTick = [0:45:315,337.5];
ppl.ThetaTickLabel = [num2cell([0:45:315]),'cb'];
ppl.LineWidth = 1.5;
ppl.RColor = [0 0 0];
ppl.ThetaDir = 'clockwise';

%4 histogram - number of peaks
AX_hist = autoaxes(F,OB.N_stages, 1,[0.475, 0.4, 0.005, 0.02],[0.025 0.025]);

for istage = 1:OB.N_stages
    Nrepswithpeaks = sum(squeeze(R(istage).peaksinstimwin)>0,2);
    axes(AX_hist(istage));
    if verLessThan('matlab', '9.3')
        aHand = gca;
        bplotdata = sum(squeeze(R(istage).peaksinstimwin)>0,2)./OB.N_reps(istage);
        for ii = 1:numel(bplotdata)
            bar(ii, bplotdata(ii), 'parent', aHand, 'facecolor', C.stim(ii,:));
            hold on
        end
        if istage ~= OB.N_stages
            set(gca,'XTickLabel',[]);
        else
            cellstr(num2str(R(1).stimulus));
            set(gca, 'XTick', 1:numel(bplotdata),...
                'XTickLabel', arrayfun(@num2str, R(1).stimulus, 'UniformOutput', 0),'FontSize',8)
            xtickangle(90)
        end
    else
        bplot = bar(sum(squeeze(R(istage).peaksinstimwin)>0,2)./OB.N_reps(istage));
        bplot.FaceColor = 'Flat';
        bplot.CData = C.stim;
        if istage ~= OB.N_stages
            set(gca,'XTickLabel',[]);
        else
            set(gca, 'XtickLabels',R(1).stimulus,'FontSize',8);
            xtickangle(90)
        end
    end
    ylim([0, 1]);
    box off
    
    if istage == 1
        title('Peaks in stimwin');
    end
end

%5 Dominant stimulus evolution & OSI

AX_domstim = autoaxes(F, 1,1,[0.58 , 0.19, 0, 0.75]);
set(F,'defaultAxesColorOrder',[0.15, 0.15, 0.15; 0.851 0.329 0.102]);
axes(AX_domstim);
yyaxis left
plot([R.dominantstimulus],'ko-');
stimuli = R(1).stimulus;
hold on
for istage = 1:OB.N_stages
    try
        mfc = C.stim(stimuli==R(istage).dominantstimulus,:);
        mec = C.stim(stimuli==R(istage).dominantstimulus,:);
    catch
        mfc = 'k';
        mec = 'k';
    end
    if isempty(mfc)
        mfc = 'k';
    end
    if isempty(mec)
        mec = 'k';
    end
    plot(istage, R(istage).dominantstimulus, 'o',...
        'MarkerFaceColor',mfc,...
        'MarkerEdgeColor',mec);
end
set(AX_domstim,'XTick',[1:numel([R.dominantstimulus])]);
set(AX_domstim, 'XtickLabels',[R.stage]);
set(AX_domstim,'YTick',stimuli(2:end));
xlim([0.9,numel([R.dominantstimulus])+0.1])
ylim([0 315]);
box off;
ylabel('Stimulus, deg')
yyaxis right
plot([R.osi],'*-');
ylim([0 1]);
ylabel('OSI');

title('Dominant stimulus and OSI');


%6 MaxCorr
try
    MC = h5read(OB.file_loc,['/ANALYSIS/ROI_',num2str(iroi),'/MAXCORR']);
    AX_MC = autoaxes(F, 1,1,[0.58 , 0.19, 0.25, 0.5]);
    axes(AX_MC);
    
    plot([1:numel(MC)],MC,'-','Color',[0.5 0.5 0.5]);
    hold on
    xlim([1, numel(MC)]);
    ylim([0 1]);
    
    stops = cumsum(OB.N_stim.*OB.N_reps);
    % midstages = stops - stops(1)./2;
    for istage = 1:OB.N_stages
        %     midstages(istage) =
        cumsamples = cumsum(OB.N_stim(1:istage).*OB.N_reps(1:istage));
        nsamplestillnow = cumsamples(end) - OB.N_stim(1).*OB.N_reps(1);
        cwindowsize = OB.N_stim(istage).*OB.N_reps(istage);
        midstages(istage) = nsamplestillnow + round(cwindowsize./2);
        meanCC(istage) = mean(MC(nsamplestillnow+1:nsamplestillnow+cwindowsize));
        if istage == 1
            maxCC(istage) = max(MC(2:nsamplestillnow+cwindowsize));
        else
            maxCC(istage) = max(MC(nsamplestillnow+1:nsamplestillnow+cwindowsize));
        end
        minCC(istage) = min(MC(nsamplestillnow+1:nsamplestillnow+cwindowsize));
        plot([stops(istage), stops(istage)], [0, 1], ':', 'color',[0.4 0.4 0.4]);
    end
    plot(midstages, meanCC, 'ko-');
    plot(midstages, maxCC, 'b*-');
    plot(midstages, minCC, 'r*-');
    set(AX_MC, 'XTick', midstages);
    set(AX_MC, 'XTickLabels', [R.stage]);
    ylabel('Correlation');
    title('Max corr. evolution');
catch
end

% 7 Textboxes
frombottom = 0.6;
fromleft = 0.825;
mTextBox(1) = uicontrol(F,'style','text','Units','Normalized',...
    'Position',[fromleft frombottom-0 0.15 0.025]);
set(mTextBox(1),'String',['Experiment: ',OB.id],'FontSize',12,'foregroundcolor','k',...
    'backgroundcolor','w','fontweight','bold','Tag','Unique');

mTextBox(2) = uicontrol(F,'style','text','Units','Normalized',...
    'Position',[fromleft frombottom-0.05 0.15 0.05]);
set(mTextBox(2),'String',['ROI: ',num2str(iroi),' (',num2str(OB.N_roi),')'],'FontSize',18,'foregroundcolor','k',...
    'backgroundcolor','w','fontweight','bold','Tag','Unique');

if ~isempty(OB.bg_corrected)
    bgmethod = h5readatt(OB.file_loc, '/ANALYSIS','BGCORRMETHOD');
else
    bgmethod = 'None';
end
mTextBox(3) = uicontrol(F,'style','text','Units','Normalized',...
    'Position',[fromleft-0.005 frombottom-0.1 0.175 0.025]);
set(mTextBox(3),'String',['BG correction method: ',bgmethod],'FontSize',12,'foregroundcolor',[0.3 0.3 0.3],...
    'backgroundcolor','w','fontweight','normal','Tag','Unique');

stitch = 'No';
dfftypecell = strsplit(OB.dff_type,'_');
if numel(dfftypecell) == 2
    dfftype = dfftypecell{1};
    if strcmp(dfftypecell{2},'stitched')
        stitch = 'Yes';
    end
else
    dfftype = dfftypecell{:};
end
mTextBox(4) = uicontrol(F,'style','text','Units','Normalized',...
    'Position',[fromleft frombottom-0.13 0.15 0.025]);
set(mTextBox(4),'String',['DFF method: ',dfftype],'FontSize',12,'foregroundcolor',[0.3 0.3 0.3],...
    'backgroundcolor','w','fontweight','normal','Tag','Unique');

mTextBox(5) = uicontrol(F,'style','text','Units','Normalized',...
    'Position',[fromleft frombottom-0.155 0.15 0.025]);
set(mTextBox(5),'String',['Stitched? ',stitch],'FontSize',12,'foregroundcolor',[0.3 0.3 0.3],...
    'backgroundcolor','w','fontweight','normal','Tag','Unique');

mTextBox(6) = uicontrol(F,'style','text','Units','Normalized',...
    'Position',[fromleft frombottom-0.2 0.15 0.025]);
set(mTextBox(6),'String',['Stimuli color code: '],'FontSize',12,'foregroundcolor',[0 0 0],...
    'backgroundcolor','w','fontweight','normal','Tag','Unique');

colorleft = fromleft+0.05;
mcol(1) = uicontrol(F,'style','text','Units','Normalized',...
    'Position',[colorleft frombottom-0.22 0.025 0.025]);
set(mcol(1),'String',[num2str(stimuli(2))],'FontSize',12,'foregroundcolor',C.stim(2,:),...
    'backgroundcolor','w','fontweight','bold','Tag','Unique');

mcol(2) = uicontrol(F,'style','text','Units','Normalized',...
    'Position',[colorleft+0.025 frombottom-0.22 0.025 0.025]);
set(mcol(2),'String',[num2str(stimuli(6))],'FontSize',12,'foregroundcolor',C.stim(6,:),...
    'backgroundcolor','w','fontweight','bold','Tag','Unique');

mcol(3) = uicontrol(F,'style','text','Units','Normalized',...
    'Position',[colorleft frombottom-0.25 0.025 0.025]);
set(mcol(3),'String',[num2str(stimuli(3))],'FontSize',12,'foregroundcolor',C.stim(3,:),...
    'backgroundcolor','w','fontweight','bold','Tag','Unique');

mcol(4) = uicontrol(F,'style','text','Units','Normalized',...
    'Position',[colorleft+0.025 frombottom-0.25 0.025 0.025]);
set(mcol(4),'String',[num2str(stimuli(7))],'FontSize',12,'foregroundcolor',C.stim(7,:),...
    'backgroundcolor','w','fontweight','bold','Tag','Unique');

mcol(5) = uicontrol(F,'style','text','Units','Normalized',...
    'Position',[colorleft frombottom-0.28 0.025 0.025]);
set(mcol(5),'String',[num2str(stimuli(4))],'FontSize',12,'foregroundcolor',C.stim(4,:),...
    'backgroundcolor','w','fontweight','bold','Tag','Unique');

mcol(6) = uicontrol(F,'style','text','Units','Normalized',...
    'Position',[colorleft+0.025 frombottom-0.28 0.025 0.025]);
set(mcol(6),'String',[num2str(stimuli(8))],'FontSize',12,'foregroundcolor',C.stim(8,:),...
    'backgroundcolor','w','fontweight','bold','Tag','Unique');

mcol(7) = uicontrol(F,'style','text','Units','Normalized',...
    'Position',[colorleft frombottom-0.31 0.025 0.025]);
set(mcol(7),'String',[num2str(stimuli(5))],'FontSize',12,'foregroundcolor',C.stim(5,:),...
    'backgroundcolor','w','fontweight','bold','Tag','Unique');

mcol(8) = uicontrol(F,'style','text','Units','Normalized',...
    'Position',[colorleft+0.025 frombottom-0.31 0.025 0.025]);
set(mcol(8),'String',[num2str(stimuli(9))],'FontSize',12,'foregroundcolor',C.stim(9,:),...
    'backgroundcolor','w','fontweight','bold','Tag','Unique');
d.F = F;
guidata(F,d);




% function local_playframe(hObject, eventdata)
% d = guidata(hObject);

function [IM, R] = local_image(OB, iroi, istage, AX);
Npix = 5;
method = 1;
cframe = h5read(OB.file_loc,['/DATA/STAGE_',num2str(istage),'/MAXPROJ']);
clut = h5read(OB.file_loc,['/DATA/STAGE_',num2str(istage),'/MAXPROJLUT']);

cmask = h5read(OB.file_loc,['/ANALYSIS/ROI_',num2str(iroi),'/STAGE_',num2str(istage),'/ROIMASK']);
% R = roi(cmask,Npix);
R = roi(OB,iroi,istage,Npix);
cmask = R.square_mask;

axdims = getpixelposition(AX);
axw = axdims(3);
axh = axdims(4);
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

if ~strcmp(OB.setup, 'ao')
    frame = imrotate(flip(c,2),90);
else
    frame = c;
end

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
        IM(:,:,:,1) = frame;
        resized = imresize(frame,resizefactor,'method','nearest');
    case 2
        resized = imresize(frame,resizefactor,'method','nearest');
        resized = imresize(frame,[max(size(resized)),max(size(resized))],'method','nearest');
        IM(:,:,:,1) = resized;
end

function G = local_stage_grouping(keys,rule);
if nargin< 2
    rule = 'first_letter';
end

switch rule
    case 'first_letter'
        subkeys = cellfun(@(v)v(1),keys);
        unique_keys = unique(subkeys);
        for iuk = 1:numel(unique_keys)
            G(iuk).logical = subkeys==unique_keys(iuk);
        end
        
end


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