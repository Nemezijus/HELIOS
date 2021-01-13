function h5creator
%h5creator - an interactive gui for h5 file creation

F = figure;
set(F,'units', 'normalized', 'position', [0.257 0.342 0.49 0.448],'color','w',...
    'MenuBar','None');

PAIRS = struct;
B = 0.8;
current = 1;
PAIRS(current).B = B;
PAIRS(current).motcorr = [];
PAIRS(current).mescroi = [];

mTextBox0 = uicontrol(F,'style','text','Units','Normalized',...
    'Position',[0.15 0.85 0.1 0.05]);
set(mTextBox0,'String','MOT.CORR.','FontSize',10,'foregroundcolor','k',...
    'backgroundcolor','w','fontweight','bold','Tag','Unique');

mTextBox1 = uicontrol(F,'style','text','Units','Normalized',...
    'Position',[0.6 0.85 0.1 0.05]);
set(mTextBox1,'String','MESCROI','FontSize',10,'foregroundcolor','k',...
    'backgroundcolor','w','fontweight','bold','Tag','Unique');

PB_DONE = uicontrol(F,'Style', 'Pushbutton', 'String', 'DONE',...
    'Units','Normalized','Position', [0.85 0.9 0.1 0.1],...
    'background','w','ForegroundColor','k','FontSize',10,...
    'Callback', @local_done,'Tag','DONE','FontWeight','Bold');

RBgroup = uibuttongroup(F,'Visible','off',...
    'Position',[0.005 0.8 0.15 0.2],...
    'BackgroundColor','w',...
    'Units','Normalized','BorderType','None','FontSize',12,...
    'fontweight','bold','TitlePosition','LeftTop',...
    'Title','Select Setup','foregroundcolor','k',...
    'SelectionChangedFcn',@setupselection);
RB(1) = uicontrol(RBgroup,'Style',...
    'radiobutton',...
    'String','RESO','units','normalized','BackgroundColor','w',...
    'FontSize',10,'foregroundcolor','k','Position',[0.1 0.7 0.8 0.3],...
    'HandleVisibility','on');

RB(2) = uicontrol(RBgroup,'Style','radiobutton',...
    'String','AO','units','normalized',...
    'Position',[0.1 0.45 0.8 0.3],'BackgroundColor','w',...
    'FontSize',10,'foregroundcolor','k','HandleVisibility','on');
RBgroup.Visible = 'on';




d.F = F;
d.PAIRS = PAIRS;
d.current = current;
d.editfields = [];
d.PBs = [];
d.setup = 'RESO'; %default
guidata (F, d);
[BTX, B] = add_row(F, B);





function [BTX, B] = add_row(f, B)
d = guidata(f);

ED(1) = uicontrol(f,'Style', 'edit', 'String', 'Add a motion correction file',...
    'tag','editbox1',...
    'Units','Normalized','Position', [0.05, B, 0.3,0.05],'FontSize',12);

ED(2) = uicontrol(f,'Style', 'edit', 'String', 'Add a corresponding mescroi file',...
    'tag','editbox2',...
    'Units','Normalized','Position', [0.5, B, 0.3,0.05],'FontSize',12);

PB_ADD_MOTCORR = uicontrol(f,'Style', 'Pushbutton', 'String', 'Browse',...
    'Units','Normalized','Position', [0.352 B 0.1 0.05],...
    'background','w','ForegroundColor','k','FontSize',10,...
    'Callback', @local_browse,'Tag','MC','FontWeight','Bold');

PB_ADD_MESCROI = uicontrol(f,'Style', 'Pushbutton', 'String', 'Browse',...
    'Units','Normalized','Position', [0.802 B 0.1 0.05],...
    'background','w','ForegroundColor','k','FontSize',10,...
    'Callback', @local_browse,'Tag','ROI','FontWeight','Bold');

PB_ADD = uicontrol(f,'Style', 'Pushbutton', 'String', '+',...
    'Units','Normalized','Position', [0.925 B 0.025 0.05],...
    'background','w','ForegroundColor','k','FontSize',10,...
    'Callback', @local_add,'Tag','add','FontWeight','Bold');

d.PBs(d.current).PB(1) = PB_ADD_MOTCORR;
d.PBs(d.current).PB(2) = PB_ADD_MESCROI;
d.PBs(d.current).PB(3) = PB_ADD;

if d.current > 1
    PB_REMOVE = uicontrol(f,'Style', 'Pushbutton', 'String', '-',...
        'Units','Normalized','Position', [0.955 B 0.025 0.05],...
        'background','w','ForegroundColor','k','FontSize',10,...
        'Callback', @local_remove,'Tag',num2str(d.current),'FontWeight','Bold');
    d.PBs(d.current).PB(4) = PB_REMOVE;
end

d.editfields(d.current).ED = ED;
guidata(d.F, d);
BTX = [];


function local_browse(hO, eventdata)
d = guidata(hO);
switch hO.Tag
    case 'MC'
        ext = '*.mes*';
        field = 'motcorr';
        ed = 1;
        ms = 'off';
    case 'ROI'
        ext = '*.mescroi';
        field = 'mescroi';
        ed = 2;
        ms = 'on';
end
[fl, path] = uigetfile(ext,'MultiSelect', ms);

if iscell(fl)
    for ifl = 1:numel(fl)
        adding{ifl} = fullfile(path, fl{ifl});
        str = 'multiple mescroi files selected';
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
if isempty(d.PAIRS(d.current).motcorr) | isempty(d.PAIRS(d.current).mescroi)
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
        if ipb > 1 & iipb == 4
            d.PBs(ipb).PB(iipb).Tag = num2str(ipb);
        end
        if ipb == 1 & numel(d.PBs(ipb).PB(iipb)) == 4
            delete(d.PBs(ipb).PB(iipb));
            d.PBs(ipb).PB = d.PBs(ipb).PB(1:3);
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
d.PBs(d.current).PB(3).Visible = 'On';
guidata(d.F, d);

function setupselection(hObject, eventdata)
d = guidata(hObject);
setup = lower(eventdata.NewValue.String);
d.setup = setup;
guidata(d.F,d);

function local_done(hO, ev)
d = guidata(hO);
setup = lower(d.setup);
MC_ROI_PAIRS = d.PAIRS;
assignin('base','MC_ROI_PAIRS',MC_ROI_PAIRS);
assignin('base','setup',setup);
collectdata(setup, MC_ROI_PAIRS);