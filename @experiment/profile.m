function F = profile(OB, iroi, flag)
% F = profile(OB, iroi, flag) - experiment class method which produces a
% matlab image - a profile (or overview) of the iroi ROI.
% OB - experiment object.
% part of HELIOS
if nargin < 3
    flag = [];
end
F = figure;
set(F,'units', 'normalized', 'position', [0.101 0.1 0.821 0.775],'color','w');
C = colors;

%1 - traces

%first - get the ylims
Ymin = Inf;
Ymax = -Inf;
for istage = 1:OB.N_stages
    for istim = 1:OB.N_stim(istage)
        W = OB.traces({iroi, istage, istim, 0},'dff');
        m = mean(W.data);
        if min(m) < Ymin
            Ymin = min(m);
        end
        if max(m) > Ymax
            Ymax = max(m);
        end
    end
end
AX_traces = autoaxes(F,OB.N_stages, 1,[0.105, 0.5, 0.005, 0.005],[0.025 0.025]);

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
AX_images = autoaxes(F, OB.N_stages, 1, [0 0.875 0.005 0.005],[0.025 0.025]);
for istage = 1:OB.N_stages
    IM = local_image(OB, iroi, istage,AX_images(istage));
    axes(AX_images(istage));
    imagesc(IM);
    set(gca,'XTickLabel',[]);
    set(gca,'YTickLabel',[]);
end


%3 - polar plot
AX_ppl = autoaxes(F, 1,1,[0.8 0, 0, 0.6]);
for istage = 1:OB.N_stages
    R(istage) = response(OB, iroi, istage);
end
G = local_stage_grouping([R.stage]);

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
AX_hist = autoaxes(F,OB.N_stages, 1,[0.475, 0.4, 0.005, 0.005],[0.025 0.025]);
for istage = 1:OB.N_stages
    Nrepswithpeaks = sum(squeeze(R(istage).peaksinstimwin)>0,2);
    axes(AX_hist(istage));
    bplot = bar(sum(squeeze(R(istage).peaksinstimwin)>0,2)./OB.N_reps(istage));
    bplot.FaceColor = 'Flat';
    bplot.CData = C.stim;
    ylim([0, 1]);
    box off
end

%5 Dominant stimulus evolution

AX_domstim = autoaxes(F, 1,1,[0.575 , 0.2, 0, 0.75]);
axes(AX_domstim);
plot([R.dominantstimulus],'ko-');
stimuli = R(1).stimulus(2:end);
hold on
for istage = 1:OB.N_stages
    plot(istage, R(istage).dominantstimulus, 'o',...
        'MarkerFaceColor',C.stim(stimuli==R(istage).dominantstimulus,:),...
        'MarkerEdgeColor',C.stim(stimuli==R(istage).dominantstimulus,:));
end
set(AX_domstim,'XTick',[1:numel([R.dominantstimulus])]);
set(AX_domstim, 'XtickLabels',[R.stage]);
set(AX_domstim,'YTick',stimuli);
xlim([1,numel([R.dominantstimulus])])
ylim([0 315]);
box off;

%6 OSI evolution
AX_osi = autoaxes(F, 1,1,[0.575 , 0.2, 0.25, 0.5]);
axes(AX_osi);
plot([R.osi],'ko-','MarkerFaceColor','k');
set(AX_osi,'XTick',[1:numel([R.dominantstimulus])]);
set(AX_osi, 'XtickLabels',[R.stage]);
xlim([1,numel([R.dominantstimulus])])
ylim([0 1]);
box off
d.F = F;
guidata(F,d);



% function local_playframe(hObject, eventdata)
% d = guidata(hObject);

function IM = local_image(OB, iroi, istage, AX);
Npix = 5;
method = 2;
cframe = h5read(OB.file_loc,['/DATA/STAGE_',num2str(istage),'/MAXPROJ']);
clut = h5read(OB.file_loc,['/DATA/STAGE_',num2str(istage),'/MAXPROJLUT']);

cmask = h5read(OB.file_loc,['/ANALYSIS/ROI_',num2str(iroi),'/STAGE_',num2str(istage),'/ROIMASK']);
R = roi(cmask,Npix);
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