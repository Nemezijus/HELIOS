function h5creator
%h5creator - an interactive gui for h5 file creation
bgcol = [0.4431 0.5608 0.4510];
F = figure;
set(F,'units', 'normalized', 'position', [0.257 0.342 0.49 0.448],...
    'color',bgcol,...
    'MenuBar','None','Name','H5creator','NumberTitle','off','tag','h5creator');

PAIRS = struct;
B = 0.75;
current = 1;
PAIRS(current).B = B;
PAIRS(current).motcorr = [];
PAIRS(current).mescroi = [];
PAIRS(current).onacid = [];

mTextBox(1) = uicontrol(F,'style','text','Units','Normalized',...
    'Position',[0.075 0.8 0.1 0.05]);
set(mTextBox(1),'String','MOT.CORR.','FontSize',10,'foregroundcolor','k',...
    'backgroundcolor',bgcol,'fontweight','bold','Tag','Unique');

mTextBox(2) = uicontrol(F,'style','text','Units','Normalized',...
    'Position',[0.35 0.8 0.1 0.05]);
set(mTextBox(2),'String','ONACID FILES','FontSize',10,'foregroundcolor','k',...
    'backgroundcolor',bgcol,'fontweight','bold','Tag','Unique');

mTextBox(3) = uicontrol(F,'style','text','Units','Normalized',...
    'Position',[0.675 0.8 0.1 0.05]);
set(mTextBox(3),'String','BEHAVIOR','FontSize',10,'foregroundcolor','k',...
    'backgroundcolor',bgcol,'fontweight','bold','Tag','Unique');

mTextBox(4) = uicontrol(F,'style','text','Units','Normalized',...
    'Position',[0.16 0.9334 0.032 0.028]);
set(mTextBox(4),'String','ID: ','FontSize',10,'foregroundcolor','k',...
    'backgroundcolor',bgcol,'fontweight','bold','Tag','Unique');
ed = uicontrol(F,'Style', 'edit', 'String', 'none',...
    'tag','editbox0',...
    'Units','Normalized','Position', [0.2 0.9224 0.1 0.0525],'FontSize',9,...
    'Callback',@local_ID);


mTextBox(5) = uicontrol(F,'style','text','Units','Normalized',...
    'Position',[0.3122 0.9334 0.1104 0.028]);
set(mTextBox(5),'String','Stim. Protocol: ','FontSize',10,'foregroundcolor','k',...
    'backgroundcolor',bgcol,'fontweight','bold','Tag','Unique');

mTextBox(6) = uicontrol(F,'style','text','Units','Normalized',...
    'Position',[0.4222 0.928 0.1104 0.035]);
set(mTextBox(6),'String','No stimulus','FontSize',10,'foregroundcolor',[0 0.447 0.7412],...
    'backgroundcolor',bgcol,'fontweight','bold','Tag','stimulus',...
    'ButtonDownFcn',@local_stimprot,'Enable', 'Inactive');

mTextBox(7) = uicontrol(F,'style','text','Units','Normalized',...
    'Position',[0.5322 0.9334 0.1104 0.028]);
set(mTextBox(7),'String','Stim. Pattern: ','FontSize',10,'foregroundcolor','k',...
    'backgroundcolor',bgcol,'fontweight','bold','Tag','Unique');

mTextBox(8) = uicontrol(F,'style','text','Units','Normalized',...
    'Position',[0.6422 0.928 0.1104 0.035]);
set(mTextBox(8),'String','No pattern','FontSize',10,'foregroundcolor',[0 0.447 0.7412],...
    'backgroundcolor',bgcol,'fontweight','bold','Tag','pattern',...
    'ButtonDownFcn',@local_stimpatt,'Enable', 'Inactive');

PB_DONE = uicontrol(F,'Style', 'Pushbutton', 'String', 'DONE',...
    'Units','Normalized','Position', [0.85 0.89 0.1 0.1],...
    'background','w','ForegroundColor','k','FontSize',10,...
    'Callback', @local_done,'Tag','DONE','FontWeight','Bold');

RBgroup = uibuttongroup(F,'Visible','off',...
    'Position',[0.005 0.9 0.152 0.1],...
    'BackgroundColor',bgcol,...
    'Units','Normalized','BorderType','None','FontSize',12,...
    'fontweight','bold','TitlePosition','LeftTop',...
    'Title','Select Setup','foregroundcolor','k',...
    'SelectionChangedFcn',@setupselection);
RB(1) = uicontrol(RBgroup,'Style',...
    'radiobutton',...
    'String','RESO','units','normalized','BackgroundColor',bgcol,...
    'FontSize',10,'foregroundcolor','k','Position',[0.001 0.01 0.45 0.9],...
    'HandleVisibility','on');

RB(2) = uicontrol(RBgroup,'Style','radiobutton',...
    'String','AO','units','normalized',...
    'Position',[0.5 0.01 0.45 0.9],'BackgroundColor',bgcol,...
    'FontSize',10,'foregroundcolor','k','HandleVisibility','on');
RBgroup.Visible = 'on';




d.F = F;
d.ID = 'None';
d.PAIRS = PAIRS;
d.current = current;
d.editfields = [];
d.PBs = [];
d.mtb = mTextBox;
d.setup = 'RESO'; %default
d.is_onacid = 0;
d.stim_present = 0;
d.stim_pattern = [];
guidata (F, d);
[BTX, B] = add_row(F, B);





function [BTX, B] = add_row(f, B)
d = guidata(f);
enable_mescroi = 'On';
if d.is_onacid
    enable_mescroi = 'off';
end
ED(1) = uicontrol(f,'Style', 'edit', 'String', 'Add a motion correction file',...
    'tag','editbox1',...
    'Units','Normalized','Position', [0.005, B, 0.2,0.05],'FontSize',9);

ED(2) = uicontrol(f,'Style', 'edit', 'String', 'Add mescroi/onacid file(s)',...
    'tag','editbox2',...
    'Units','Normalized','Position', [0.3, B, 0.2,0.05],'FontSize',9);

ED(3) = uicontrol(f,'Style', 'edit', 'String', 'Add behavior file(s)',...
    'tag','editbox2',...
    'Units','Normalized','Position', [0.6, B, 0.2,0.05],'FontSize',9);

PB_ADD_MOTCORR = uicontrol(f,'Style', 'Pushbutton', 'String', 'Browse',...
    'Units','Normalized','Position', [0.206 B 0.075 0.05],...
    'background','w','ForegroundColor','k','FontSize',10,...
    'Callback', @local_browse,'Tag','MC','FontWeight','Bold');

PB_ADD_MESCROI = uicontrol(f,'Style', 'Pushbutton', 'String', 'Browse',...
    'Units','Normalized','Position', [0.501 B 0.075 0.05],...
    'background','w','ForegroundColor','k','FontSize',10,...
    'Callback', @local_browse,'Tag','ROI','FontWeight','Bold','Enable',enable_mescroi);

PB_ADD_BEHAVE = uicontrol(f,'Style', 'Pushbutton', 'String', 'Browse',...
    'Units','Normalized','Position', [0.801 B 0.075 0.05],...
    'background','w','ForegroundColor','k','FontSize',10,...
    'Callback', @local_browse,'Tag','BEH','FontWeight','Bold');

PB_ADD = uicontrol(f,'Style', 'Pushbutton', 'String', '+',...
    'Units','Normalized','Position', [0.905 B 0.025 0.05],...
    'background','w','ForegroundColor','k','FontSize',10,...
    'Callback', @local_add,'Tag','add','FontWeight','Bold');

d.PBs(d.current).PB(1) = PB_ADD_MOTCORR;
d.PBs(d.current).PB(2) = PB_ADD_MESCROI;
d.PBs(d.current).PB(3) = PB_ADD_BEHAVE;
d.PBs(d.current).PB(4) = PB_ADD;

if d.current > 1
    PB_REMOVE = uicontrol(f,'Style', 'Pushbutton', 'String', '-',...
        'Units','Normalized','Position', [0.935 B 0.025 0.05],...
        'background','w','ForegroundColor','k','FontSize',10,...
        'Callback', @local_remove,'Tag',num2str(d.current),'FontWeight','Bold');
    d.PBs(d.current).PB(5) = PB_REMOVE;
end

d.editfields(d.current).ED = ED;
guidata(d.F, d);
BTX = [];


function local_browse(hO, eventdata)
d = guidata(hO);
trigger_on_acid = 0;
switch hO.Tag
    case 'MC'
        ext = '*.mes*';
        field = 'motcorr';
        ed = 1;
        ms = 'off';
    case 'ROI'
        switch lower(d.setup)
            case 'ao'
                ext = '*.mescroi';
                field = 'mescroi';
            case 'reso'
                ext = {'*.mat; *.mescroi'};
                field = 'onacid';
                trigger_on_acid = 1;
        end
        ed = 2;
        ms = 'on';
    case 'BEH'
        ext = '*.csv';
        field = 'behavior';
        ed = 3;
        ms = 'on';
end
[fl, path] = uigetfile(ext,'MultiSelect', ms);
if isequal(fl, 0)
    return
end
if trigger_on_acid
    d.is_onacid = 1;
end

if iscell(fl)
    for ifl = 1:numel(fl)
        adding{ifl} = fullfile(path, fl{ifl});
        str = 'multiple files selected';
    end
else
    adding = fullfile(path, fl);
    str = adding;
end
d.PAIRS(d.current).(field) = adding;

set(d.editfields(d.current).ED(ed), 'String', str);
guidata(d.F, d);

function local_add(hO, eventdata)
d = guidata(hO);
if d.is_onacid
    d.PAIRS(d.current+1).onacid = d.PAIRS(d.current).onacid;
end
if isempty(d.PAIRS(d.current).motcorr) | (isempty(d.PAIRS(d.current).mescroi) & isempty(d.PAIRS(d.current).onacid))
    msgbox('One of the two previous fields is not filled in!');
    return
end

d.current = d.current+1;
d.PAIRS(d.current).B = d.PAIRS(d.current-1).B - 0.1;
B = d.PAIRS(d.current).B;
guidata(d.F, d);
[BTX, B] = add_row(d.F, B);
set(hO,'Visible','Off');

function local_remove(hO, eventdata)
d = guidata(hO);
idx = str2num(hO.Tag);
PB = d.PBs(idx).PB;
for ipb = 1:numel(PB)
    delete(PB(ipb));
end
PBidx = [1:numel(d.PBs)];
newPBidx = setdiff(PBidx, idx);
d.PBs = d.PBs(newPBidx);

ED = d.editfields(idx).ED;
for ied = 1:numel(ED)
    delete(ED(ied));
end

EDidx = [1:numel(d.editfields)];
newEDidx = setdiff(EDidx, idx);
d.editfields = d.editfields(newEDidx);

PAIRSidx = [1:numel(d.PAIRS)];
newPAIRSidx = setdiff(PAIRSidx, idx);
d.PAIRS = d.PAIRS(newPAIRSidx);

%move elements up
start = 0.8;
for ipb = 1:numel(d.PBs)
    for iipb = 1:numel(d.PBs(ipb).PB)
        pos = d.PBs(ipb).PB(iipb).Position;
        pos(2) = start-(ipb-1)*0.1;
        d.PBs(ipb).PB(iipb).Position = pos;
        if ipb > 1 & iipb == 5
            d.PBs(ipb).PB(iipb).Tag = num2str(ipb);
        end
        if ipb == 1 & numel(d.PBs(ipb).PB(iipb)) == 5
            delete(d.PBs(ipb).PB(iipb));
            d.PBs(ipb).PB = d.PBs(ipb).PB(1:4);
        end
    end
end

for ied = 1:numel(d.editfields)
    for iied = 1:numel(d.editfields(ied).ED)
        pos = d.editfields(ied).ED(iied).Position;
        pos(2) = start-(ied-1)*0.1;
        d.editfields(ied).ED(iied).Position = pos;
    end
end
d.current = d.current-1;

for ip = 1:numel(d.PAIRS)
    d.PAIRS(ip).B = start - (ip-1)*0.1;
end
d.PBs(d.current).PB(4).Visible = 'On';
guidata(d.F, d);

function setupselection(hObject, eventdata)
d = guidata(hObject);
setup = lower(eventdata.NewValue.String);
d.setup = setup;
switch setup
    case 'ao'
        str = 'MESCROI';
    case 'reso'
        str = 'ONACID FILES';
end
set(d.mtb(2), 'String', str);
guidata(d.F,d);

function local_ID(hO, ev)
d = guidata(hO);
d.ID = ['m',hO.String];
guidata(d.F,d);

function local_done(hO, ev)
d = guidata(hO);
setup = lower(d.setup);
for ip = 1:numel(d.PAIRS)
    P(ip).motcorr = d.PAIRS(ip).motcorr;
    P(ip).mescroi = d.PAIRS(ip).mescroi;
    P(ip).onacid = d.PAIRS(ip).onacid;
    try
        P(ip).behavior = d.PAIRS(ip).behavior;
    catch
        P(ip).behavior = [];
    end
end
MC_ROI_PAIRS = P;
assignin('base','MC_ROI_PAIRS',MC_ROI_PAIRS);
assignin('base','setup',setup);

F = analysis_info(d);
while ishandle(F)
    pause(0.5);
end
d = guidata(hO);
%%%TEMP COMMENT OUT
if isempty(d.stim_pattern)
    stimlist = [];
else
    stimlist.list = d.stim_pattern;
    stimlist.order = {'999','0','45','90','135','180','225','270','315'};
end
if ~d.is_onacid
    tic;
    disp('Creating data.mat files!');
    collectdata(setup, MC_ROI_PAIRS, stimlist); %creates data.mat files
    t = toc;
    disp(['data.mat files created! Running time: ',num2str(t),' s']);
end

%creating h5
%here we create dummy hrf struct since there is no hrf coming from this gui
hrf.ID = d.ID;
hrf.setup = setup;
for ip = 1:numel(P)
    loc = P(ip).motcorr;
    loc = strsplit(loc,'\');
    loc = loc(1:end-1);
    loc = strjoin(loc,'\');
    if ~d.is_onacid
        dataloc = [loc,'\data.mat'];
    else
        dataloc = [];
    end
    hrf.analysis.imaging.data(ip).file_path = dataloc;
    if d.is_onacid
        hrf.analysis.imaging.onacid.file_path = P(ip).onacid;
    end
    if ~isempty(P(ip).behavior)
        for ib = 1:numel(P(ip).behavior)
            hrf.measurements.session(ip).behavior_data(ib).file_path = P(ip).behavior{ib};
        end
    else
        hrf.measurements.session(ip).behavior_data = [];
    end
end
% pars.dffmethod = 'median';
% pars.tostitch = 0;

if d.is_onacid
    d.info.dffmethod = 'onAcid';%Forceful way imposing onacid
end
loc = P(1).motcorr;
loc = strsplit(loc,'\');
loc = loc(1:end-2);
loc = strjoin(loc,'\');
h5name = ['\',d.ID,'.h5'];
hdf5loc = [loc,h5name];

out = moculus_createhdf5(hrf, hdf5loc, d.info, MC_ROI_PAIRS, stimlist);

function local_stimprot(hO, ed)
stimuli;

function local_stimpatt(hO, ed)
stimuli_pattern;