function stimuli
% stimuli - a GUI to choose/create a stimulus protocol
% part of HELIOS

C.bgcol = 'w';
C.bgcol_2 = [0.6, 0.6, 0.6];
C.bgcol_3 = [0.9, 0.9, 0.9];
C.fgcol_1 = 'k';
F = figure;
set(F,'units', 'normalized', 'position', [0.376 0.193 0.289 0.612],...
    'color',C.bgcol,'MenuBar','none','NumberTitle','Off', 'Name',...
    'Stimulus Protocol','Resize','Off');

allstim = stimulus_protocol;
allstim_names = fieldnames(allstim);


mTB_1 = uicontrol(F,'style','text','Units','Normalized',...
    'Position',[0.0338 0.956 0.307 0.025],'BackgroundColor',C.bgcol);
set(mTB_1,'String','Select stimulus protocol: ','FontSize',10,'foregroundcolor',C.fgcol_1,...
    'backgroundcolor',C.bgcol,'fontweight','bold','Tag','smalltext','HorizontalAlignment','Left');

mTB_2 = uicontrol(F,'style','text','Units','Normalized',...
    'Position',[0.0338 0.855 0.22 0.025],'BackgroundColor',C.bgcol);
set(mTB_2,'String','Or add a new one: ','FontSize',10,'foregroundcolor',C.fgcol_1,...
    'backgroundcolor',C.bgcol,'fontweight','bold','Tag','smalltext','HorizontalAlignment','Left');

mTB_3 = uicontrol(F,'style','text','Units','Normalized',...
    'Position',[0.05 0.62 0.174 0.0282],'BackgroundColor',C.bgcol);
set(mTB_3,'String','Stimulus type ','FontSize',10,'foregroundcolor',C.fgcol_1,...
    'backgroundcolor',C.bgcol_2,'fontweight','bold','Tag','bgsensitive','HorizontalAlignment','Left');

mTB_4 = uicontrol(F,'style','text','Units','Normalized',...
    'Position',[0.273 0.62 0.22 0.0282],'BackgroundColor',C.bgcol);
set(mTB_4,'String','Stimulus start (ms) ','FontSize',10,'foregroundcolor',C.fgcol_1,...
    'backgroundcolor',C.bgcol_2,'fontweight','bold','Tag','bgsensitive','HorizontalAlignment','Left');
popup(1) = uicontrol(F,'Style', 'popup',...
    'String', allstim_names,'units','normalized',...
    'Position', [0.0991 0.907 0.15 0.0353],'background',C.bgcol,...
    'Value',1,'ForegroundColor',C.fgcol_1,'Callback',@local_pick_stimprot,'Tag','stim');
cb = uicontrol(F,'Style', 'checkbox', 'String', '',...
    'tag','create',...
    'Units','Normalized','Position', [0.2615 0.8557 0.075 0.022],'FontSize',8,...
    'Callback',@local_locking,'Value',0,'BackgroundColor', C.bgcol);

AX = axes(F,'Position', [0.05, 0.1, 0.9, 0.3],'Units', 'Normalized');
set(AX, 'YColor','none');
title('Stimulus Layout');
try
    AX.Toolbar.Visible = 'off';
catch
end
AX2 = axes(F,'Position', [0, 0.45, 1.0, 0.3],'Units', 'Normalized');
set(AX2, 'YColor','none','XColor','None');
patch(AX2,[0 1 1 0],...
    [0, 0, 1, 1],[0.6 0.6 0.6],'EdgeColor','None');
try
    AX2.Toolbar.Visible = 'off';
catch
end


types = {'blank','static','moving'};
pop = uicontrol(F,'Style', 'popup',...
    'String', types,'units','normalized',...
    'Position', [0.0516 0.57 0.2 0.0364],'background',C.bgcol_2,...
    'Value',1,'ForegroundColor',C.fgcol_1,'Tag','type','Enable','off');
ED = uicontrol(F,'Style', 'edit', 'String', 0,...
    'tag','duration',...
    'Units','Normalized','Position', [0.28, 0.57, 0.1975,0.0362],'FontSize',10,...
    'Enable','off');
PB = uicontrol(F,'Style', 'Pushbutton', 'String', 'Add next',...
    'Units','Normalized','Position', [0.5144 0.57 0.15 0.0362],...
    'background',[0.5725 0.6588 0.4039],'ForegroundColor',C.fgcol_1,'FontSize',10,...
    'Callback', @local_add_stim,'Tag','figure','FontWeight','Bold',...
    'Enable', 'Off');

mTB = uicontrol(F,'style','text','Units','Normalized',...
    'Position',[0.6 0.7573 0.39 0.2327],'BackgroundColor',C.bgcol);
mTB2 = uicontrol(F,'style','text','Units','Normalized',...
    'Position',[0.05 0.7 0.174 0.0282],'BackgroundColor',C.bgcol_2);
set(mTB2,'String','Total Duration: ','FontSize',10,'foregroundcolor',C.fgcol_1,...
    'backgroundcolor',C.bgcol_2,'fontweight','bold','Tag','bgsensitive','HorizontalAlignment','Left');

ED2 = uicontrol(F,'Style', 'edit', 'String', 0,...
    'tag','total_duration',...
    'Units','Normalized','Position', [0.28, 0.7, 0.1975,0.0362],'FontSize',10,...
    'Enable','off','Callback',@local_total_dur);

PB2 = uicontrol(F,'Style', 'Pushbutton', 'String', 'SAVE',...
    'Units','Normalized','Position', [0.17 0.477 0.2 0.05],...
    'background',[0.98 0.7412 0.7255],'ForegroundColor',C.fgcol_1,'FontSize',10,...
    'Callback', @local_save,'Tag','figure','FontWeight','Bold','Enable', 'Off');

PB3 = uicontrol(F,'Style', 'Pushbutton', 'String', 'SELECT',...
    'Units','Normalized','Position', [0.3757 0.9011 0.2 0.05],...
    'background',[0.98 0.7412 0.7255],'ForegroundColor',C.fgcol_1,'FontSize',10,...
    'Callback', @local_select,'Tag','figure','FontWeight','Bold','Enable', 'On');
d.F = F;
d.C = C;
d.AX = AX;
d.AX2 = AX2;
d.popup = popup;
d.pop = pop;
d.ED = ED;
d.ED2 = ED2;
d.PB = PB;
d.PB2 = PB2;
d.mTB = mTB;
d.S = allstim;
d.xlim = [];
d.stimbuild.used = {};
d.dtimbuild.S = struct;
guidata(F, d);


function local_pick_stimprot(hO, ed)
d = guidata(hO);
axes(d.AX);
cla reset;
cS = d.S.(hO.String{hO.Value});
show_info(d, cS);
fnames = fieldnames(cS);
for iname = 1:numel(fnames)
    cname = fnames{iname};
    if contains(cname, 'blank')
        col = 'w';
    elseif contains(cname, 'static')
        col = [0.5725 0.6588 0.4039];
    elseif contains(cname, 'moving')
        col = [0.302 0.7451 0.9333];
    else
        col = [0.6 0.6 0.6];
    end
    if iname ~= numel(fnames)
        patch(d.AX,[cS.(cname),cS.(fnames{iname+1}),cS.(fnames{iname+1}),cS.(cname)],...
            [0, 0, 1, 1],col,'EdgeColor','None');hold on
    end
end
if ~isempty(d.xlim)
    set(d.AX, 'XLim', d.xlim);
end
set(d.AX, 'YLim', [-0.001, 1.001]);
title('Stimulus Layout');
xlabel('time, ms');
box off;
set(d.AX, 'YColor','none');
try
    d.AX.Toolbar.Visible = 'off';
catch
end

function local_add_stim(hO, ed)
d = guidata(hO);
type = d.pop.String{d.pop.Value};
time_stamp = str2double(d.ED.String);
d.stimbuild.used{numel(d.stimbuild.used)+1} = type;

count = sum(ismember(d.stimbuild.used, type));
name = [type,num2str(count),'_start'];
d.stimbuild.S.(name) = time_stamp;
plot(d.AX, [time_stamp, time_stamp],[0,1],'k-'); hold on
if ~isempty(d.xlim)
    set(d.AX, 'XLim', d.xlim);
end
title('Stimulus Layout');
try
    d.AX.Toolbar.Visible = 'off';
catch
end
guidata(d.F,d);
show_info(d, d.stimbuild.S);


function show_info(d, stru)
fn = fieldnames(stru);
str = '';
for ifn = 1:numel(fn)
    str = sprintf('%s: %d\n', [str, fn{ifn}], stru.(fn{ifn}));
end
set(d.mTB,'String',str,'FontSize',10,'foregroundcolor',d.C.fgcol_1,...
    'backgroundcolor',d.C.bgcol,'fontweight','bold','Tag','smalltext','HorizontalAlignment','Left');
guidata(d.F, d);

function local_total_dur(hO, ed)
d = guidata(hO);
d.xlim = [0, str2double(d.ED2.String)];
% set(d.AX, 'XLim', [0, str2double(d.ED2.String)]);
guidata(d.F, d);

function local_save(hO, ed)
d = guidata(hO);
S = d.stimbuild.S;
S.total = str2double(d.ED2.String);
answer = inputdlg('Specify the name of this protocol');
stimulus_protocol(answer{:},S);
close(d.F);
stimuli;

function local_locking(hO, ed)
d = guidata(hO);
unlock = hO.Value;
h = findobj('Tag','bgsensitive');
ch = d.AX2.Children;
if unlock
    str = 'On';
    str2 = 'Off';
    fcol = d.C.bgcol_3;
else
    str = 'Off';
    str2 = 'On';
    fcol = d.C.bgcol_2;
end

set(ch, 'FaceColor', fcol);
set(h, 'BackgroundColor',fcol);
set([d.pop, d.ED, d.ED2, d.PB, d.PB2], 'Enable', str);
set(d.popup, 'Enable', str2);
axes(d.AX);
cla reset;
if ~isempty(d.xlim)
    set(d.AX, 'XLim', d.xlim);
end
set(d.AX, 'YLim', [-0.001, 1.001]);
title('Stimulus Layout');
xlabel('time, ms');
box off;
set(d.AX, 'YColor','none');
try
    d.AX.Toolbar.Visible = 'off';
catch
end
guidata(d.F, d);

function local_select(hO, ed)
d = guidata(hO);
S = d.S.(d.popup.String{d.popup.Value});
h5cre = findobj('Tag','h5creator');
if ~isempty(h5cre)
    name = d.popup.String{d.popup.Value};
    name = name(4:end);
    D = guidata(h5cre);
    D.stim_prot = S;
    D.stimtype = name;
    mtb = findobj('Tag', 'stimulus');
    set(mtb, 'String',name);
    guidata(D.F, D);
    msgbox('stimulus protocol accepted!');
else
    assignin('base','S',S);
    msgbox('stimulus exported to workspace as S');
end
close(d.F);