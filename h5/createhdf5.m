function out = createhdf5(hrfloc, hdf5loc, pars)
% out = createhdf5(hrfloc, hdf5loc, pars) - creates hdf5 file specified in
% hdf5loc, hrfloc - HUB root file location for that experiment.
% pars.stimtype - a string (eg. '8s_gray60Hz')
% pars.dffmethod - a string (e.g. 'median', 'mode', 'percentile')
% pars.tostitch - an integer {0 or 1}
% part of HELIOS
if nargin < 3
    pars = [];
end
if isempty(pars) || strcmp(pars.bgmethod,'skip')
    skipbg = 1;
else
    skipbg = 0;
end
%whether OnAcid
if strcmp(lower(pars.dffmethod),'onacid')
    do_onacid = 1;
else
    do_onacid = 0;
end
if do_onacid
    skipbg = 1;
end

%added 2020-07-08 implementing customAO bg subtraction method
if strcmp(pars.bgcorrmethod, 'customao') %& ~skipbg
    [~,parfig] = collect_customAO_params;
    while ishandle(parfig)
        pause(0.5);
    end
    hub = findobj('Tag','HUB');
    dhub = guidata(hub);
    P = dhub.AOcustominfo; %parameters for custom AO bg correction
end


S = load(hrfloc);
Sfns = fieldnames(S);
hrf = S.(Sfns{:});

ID = hrf.ID;
setup = hrf.setup;

if isempty(pars)
    if strcmp(setup,'ao')
        if str2num(ID(1:2)) > 36
            pars.stimtype = '13.5s_gray60Hz';
        else
            pars.stimtype = '14s_gray60Hz';
        end
    else
        pars.stimtype = '8s_gray60Hz';
    end
    pars.dffmethod = 'median';
    pars.tostitch = 1;
    pars.bgmethod = 'dynamicpixels';
end
if strcmp(pars.bgcorrmethod, 'customao') %& ~skipbg
    pars.customAOpars = P;
end

%STEP 1 - create empty DATA branch to store ID and setup
if ~exist(hdf5loc)
    fid = H5F.create(hdf5loc);
    plist = 'H5P_DEFAULT';
    gid = H5G.create(fid,'DATA',plist,plist,plist);
    H5G.close(gid);
    H5F.close(fid);
end

%STEP 2 store ID and setup
h5writeatt(hdf5loc,'/DATA', 'ANIMALID', ID);
h5writeatt(hdf5loc,'/DATA', 'SETUP', setup);


%STEP 3 store data
if ~do_onacid
    data_locations = hrf.analysis.imaging.data_matrices.file_path;
    for idl = 1:numel(data_locations)
        segments = strsplit(data_locations{idl},'\');
        idsegment = segments{end-1};
        stageids{idl} = upper([idsegment(1),idsegment(end)]);
    end
    disp('Storing data in hdf5 file. Please wait.')
    tic
    embeddata(hdf5loc, data_locations, stageids);
    t = toc;
    disp(['Data stored in hdf5 file. Running time: ', num2str(t)]);
else %OnAcid way
    counter = 1;
    hrf_data_fields = fieldnames(hrf.imaging);
    for ifn = 1:numel(hrf_data_fields)
        cfield = hrf.imaging.(hrf_data_fields{ifn});
        for ifield = 1:numel(cfield)
            data_locations{counter} = cfield(ifield).data.file_path;
            counter = counter+1;
        end
    end
    for idl = 1:numel(data_locations)
        segments = strsplit(data_locations{idl},'\');
        idsegment = segments{end-1};
        stageids{idl} = upper([idsegment(1),idsegment(end)]);
    end
    if ~isempty(hrf.analysis.imaging.onacid.directory_path)
        onacidloc = hrf.analysis.imaging.onacid.directory_path{1};
    else
        onacidloc = [];
    end
    disp('Storing OnAcid data in hdf5 file. Please wait.')
    tic
    embedonacid(hdf5loc, data_locations, onacidloc, stageids);
    t = toc;
    disp(['OnAcid data stored in hdf5 file. Running time: ', num2str(t)]);
end
%STEP 4 store stimtype
for idl = 1:numel(data_locations)
    h5writeatt(hdf5loc,['/DATA/STAGE_',num2str(idl)], 'STIMTYPE', pars.stimtype);
end

%STEP 5 add data, motion corrected file and roi mask file locations
locs = extractlocations(hrf.imaging, 'data');
for idl = 1:numel(data_locations)
    h5writeatt(hdf5loc,['/DATA/STAGE_',num2str(idl)], 'DATAPATH', locs{idl});
end

locs = extractlocations(hrf.imaging, 'motion_corrected_data');
for idl = 1:numel(data_locations)
    if ~do_onacid
        h5writeatt(hdf5loc,['/DATA/STAGE_',num2str(idl)], 'MOTIONCORRECTEDDATAPATH', locs{idl});
    else
        h5writeatt(hdf5loc,['/DATA/STAGE_',num2str(idl)], 'MOTIONCORRECTEDDATAPATH', []);
    end
end
if ~do_onacid
    locs = extractlocations(hrf.imaging, 'roi');
    for idl = 1:numel(data_locations)
        h5writeatt(hdf5loc,['/DATA/STAGE_',num2str(idl)], 'MASKPATH', locs{idl});
    end
else
    locs = hrf.analysis.imaging.onacid.file_path(contains(hrf.analysis.imaging.onacid.file_path,'after'));
    for idl = 1:numel(data_locations)
        h5writeatt(hdf5loc,['/DATA/STAGE_',num2str(idl)], 'MASKPATH', locs{:});
    end
end

%STEP 6 pull out experiment from the file
EXP = experiment(hdf5loc);

%STEP 7 adding dff method
if isempty(pars)
    method = 'median';
    tostitch = 1;
else
    method = pars.dffmethod;
    tostitch = pars.tostitch;
end

%STEP 8 ESTIMATE DFFBASE
if ~strcmp(lower(method), 'onacid')
    disp('Calculating DFFBASE for the data. Please Wait.');
    tic
    EXP = EXP.dff(lower(method), tostitch, 1);%1 - indicator to store in DFFbase
    t = toc;
    disp(['DFFBASE stored in hdf5 file. Running time: ', num2str(t)]);
end

%STEP 9 BG extraction and subtraction
if ~skipbg
%     EXP = experiment(hdf5loc);
    EXP = EXP.extractbg(pars.bgmethod);%dynamic pixels is much much faster than staticpixels
    
    %subtract bg and estimate dff
    disp('Subtracting BG and calculating dff for the data. Please Wait.');
    tic
    EXP = subtractbg(EXP, pars);%if not skipping bg correction
    t = toc;
    disp(['DFF stored in hdf5 file. Running time: ', num2str(t)]);
    
    stitchstr = '';
    if tostitch
        stitchstr = '_stitched';
    end
    root = '/ANALYSIS';
    if strcmp(pars.bgcorrmethod, 'customao')
        h5writeatt(EXP.file_loc,root,'DFFTYPE','percentile');
    else
        h5writeatt(EXP.file_loc,root,'DFFTYPE',[lower(method), stitchstr]);
    end
    h5writeatt(EXP.file_loc,root,'DFFMODDATE',datenum(now));
    h5writeatt(EXP.file_loc,root,'DFFMODUSER',getenv('username'));
    
end

%STEP 8.25
%for AO we add DFFBASE - dff performed only on the raw data
% if strcmp(setup,'ao') %& ~strcmp(pars.bgcorrmethod, 'customao')
%     disp('Calculating DFFBASE for the data. Please Wait.');
%     tic
%     EXP = EXP.dff(lower(method), tostitch, 1);
%     t = toc;
%     disp(['DFFBASE stored in hdf5 file. Running time: ', num2str(t)]);
% end
%STEP 8.5
%if BG was subtracted then dff does not have to be calculated, otherwise it
%is done here
%OnAcid path also visits this part but instead of calculating dff it splits
%estimated dff and stores it

if skipbg
    if ~do_onacid
        if strcmp(pars.bgcorrmethod, 'customao')
            disp('Subtracting BG and calculating dff for the data. Please Wait.');
            tic
            EXP = subtractbg(EXP, pars);
            t = toc;
            disp(['DFF stored in hdf5 file. Running time: ', num2str(t)]);

            root = '/ANALYSIS';
            h5writeatt(EXP.file_loc,root,'DFFTYPE','percentile');
            h5writeatt(EXP.file_loc,root,'DFFMODDATE',datenum(now));
            h5writeatt(EXP.file_loc,root,'DFFMODUSER',getenv('username'));
        end
        
    else
        loc = hrf.analysis.imaging.onacid.file_path{contains(hrf.analysis.imaging.onacid.file_path,'dff')};
        disp('Loading OnAcid stored dff file');
        S = load(loc);
        disp('Loading done');
        fns = fieldnames(S);
        dff = S.(fns{:});
        if numel(dff(:,1)) ~= EXP.N_roi
            ROIseq = onacidroimatch(hrf.analysis.imaging.onacid.file_path{contains(hrf.analysis.imaging.onacid.file_path,'pre')},...
                hrf.analysis.imaging.onacid.file_path{contains(hrf.analysis.imaging.onacid.file_path,'after')});
            dff = dff(ROIseq,:);
        end
        for istage = 1:EXP.N_stages
            Nsamples(istage) = numel(h5read(EXP.file_loc,['/DATA/STAGE_',num2str(istage),'/UNIT_1/XDATA']));
        end
        disp('Reshaping OnAcid dff struct');
        DFF = onaciddffreshape(dff, EXP.N_stages, EXP.N_stim.*EXP.N_reps, Nsamples);
        disp('Reshaping done');
        
        stimsequence = h5readatt(hdf5loc,'/DATA/STAGE_1','STIMLIST');
        
        for idata = 1:EXP.N_stim(1)*EXP.N_reps(1)
            stimlist(idata) = stimsequence(h5readatt(EXP.file_loc,['/DATA/STAGE_1/UNIT_',num2str(idata)],'STIMID'));
        end
        stimlist = stimlist(1:18);%dirty fix, needs a better approach
        
        disp('Storing OnAcid dff information');
        storeonaciddff(EXP, DFF, stimlist, stimsequence);
        disp('Storing done');
        
        stitchstr = '';
        if tostitch
            stitchstr = '_stitched';
        end
        root = '/ANALYSIS';
        h5writeatt(EXP.file_loc,root,'DFFTYPE',[lower(method), stitchstr]);
        h5writeatt(EXP.file_loc,root,'DFFMODDATE',datenum(now));
        h5writeatt(EXP.file_loc,root,'DFFMODUSER',getenv('username'));
    end
end

%STEP 9 Max Corr 
% C = bestcorr(OB, iroi)
h = waitbar(0,'Calculating Max Correlations');
for iroi = 1:EXP.N_roi
    waitbar(iroi/EXP.N_roi);
    C = EXP.bestcorr(iroi);
    try
        allocatespace(EXP.file_loc, {C}, {['/ANALYSIS/ROI_',num2str(iroi),'/MAXCORR']});
    catch
    end
    storedata(EXP.file_loc, {C}, {['/ANALYSIS/ROI_',num2str(iroi),'/MAXCORR']});
end
close(h)

out = 1;



function locs = extractlocations(root, type)
fns = fieldnames(root);
count = 1;
for ifn = 1:numel(fns)
    cfn = fns{ifn};
    for ielem = 1:numel(root.(cfn))
        try
            locs{count} = root.(cfn)(ielem).(type).file_path;
            count = count+1;
        catch
        end
    end
end

function [P,F] = collect_customAO_params
P.BGcrit = 0.3;
P.light_cont_scale = 0.7;
P.perc = 0.08;
P.BG_sub_scale = 0;

F = figure;
set(F,'units', 'normalized', 'position', [0.455 0.394 0.151 0.345],...
    'Color','w','MenuBar','None','numbertitle','off','Name','Paremeter selection',...
    'WindowStyle','modal');

ED(1) = uicontrol(F,'Style',...
    'edit',...
    'String','0.3','units','normalized','BackgroundColor','w',...
    'FontSize',10,'foregroundcolor','k','Position',[0.5 0.8 0.45 0.15],...
    'HandleVisibility','on','Tag','1','Callback',@AOcustomP);

ED(2) = uicontrol(F,'Style','edit',...
    'String','0.7','units','normalized',...
    'Position',[0.5 0.6 0.45 0.15],'BackgroundColor','w',...
    'FontSize',10,'foregroundcolor','k','HandleVisibility','on','Tag','2','Callback',@AOcustomP);

ED(3) = uicontrol(F,'Style','edit',...
    'String','0.08','units','normalized',...
    'Position',[0.5 0.4 0.45 0.15],'BackgroundColor','w',...
    'FontSize',10,'foregroundcolor','k','HandleVisibility','on','Tag','3','Callback',@AOcustomP);

ED(4) = uicontrol(F,'Style','edit',...
    'String','0','units','normalized',...
    'Position',[0.5 0.2 0.45 0.15],'BackgroundColor','w',...
    'FontSize',10,'foregroundcolor','k','HandleVisibility','on','Tag','4','Callback',@AOcustomP);

mTB(1) = uicontrol(F,'style','text','Units','Normalized',...
    'Position',[0.07 0.75 0.4 0.125]);
set(mTB(1),'String',['BG Crit.'],'FontSize',10,'foregroundcolor','k',...
    'backgroundcolor','w','fontweight','bold','Tag','Unique');

mTB(2) = uicontrol(F,'style','text','Units','Normalized',...
    'Position',[0.07 0.55 0.4 0.125]);
set(mTB(2),'String',['light cont scale'],'FontSize',10,'foregroundcolor','k',...
    'backgroundcolor','w','fontweight','bold','Tag','Unique');

mTB(3) = uicontrol(F,'style','text','Units','Normalized',...
    'Position',[0.07 0.35 0.4 0.125]);
set(mTB(3),'String',['percentile'],'FontSize',10,'foregroundcolor','k',...
    'backgroundcolor','w','fontweight','bold','Tag','Unique');

mTB(4) = uicontrol(F,'style','text','Units','Normalized',...
    'Position',[0.07 0.15 0.4 0.125]);
set(mTB(4),'String',['BG sub scale'],'FontSize',10,'foregroundcolor','k',...
    'backgroundcolor','w','fontweight','bold','Tag','Unique');

PB_VISC = uicontrol(F,'Style', 'Pushbutton', 'String', 'CONFIRM',...
    'Units','Normalized','Position', [0.25 0.05 0.5 0.1],...
    'background','k','ForegroundColor','w','FontSize',18,...
    'Callback', @local_confirm,'Tag','BT1','FontWeight','Bold');

d.F = F;
d.P = P;
guidata(F,d);

function AOcustomP(hObject,eventdata)
d = guidata(hObject);
tag = str2num(hObject.Tag);
switch tag
    case 1
        d.P.BGcrit = str2num(hObject.String);
    case 2
        d.P.light_cont_scale = str2num(hObject.String);
    case 3
        d.P.perc = str2num(hObject.String);
    case 4
        d.P.BG_sub_scale = str2num(hObject.String);
end
guidata(d.F,d);

function local_confirm (hObject, eventdata)
d = guidata(hObject);
try
    hub = findobj('Tag','HUB');
    dhub = guidata(hub);
    dhub.AOcustominfo = d.P;
    guidata(dhub.F_HUB, dhub);
    disp('AOcustom Info struct embedded to HUB.');
catch
    disp('HUB was not found in environment. Info struct was not embedded.');
end
AOcustominfo = d.P;
assignin('base','AOcustominfo',AOcustominfo);
close(d.F);
