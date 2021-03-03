function stimuli_pattern(nunits)
% P = stimuli_pattern(nunits) - a GUI to choose/create stimuli pattern used
% in the measurement
if nargin < 1
    nunits = 10;
end
C.bgcol = 'w';
C.bgcol_2 = [0.6, 0.6, 0.6];
C.bgcol_3 = [0.9, 0.9, 0.9];
C.fgcol_1 = 'k';

allpatt = stimulus_pattern;
allpatt_names = fieldnames(allpatt);

sequence = [0:45:315];
seq1 = {'chessboard'};
seq2 = compose('%g', sequence);
clear sequence;
sequence = [seq1,seq2];

str = seq2str(sequence);
F = figure;
set(F,'units', 'normalized', 'position', [0.336 0.286 0.372 0.389],...
    'color',C.bgcol,'MenuBar','Figure','NumberTitle','Off', 'Name',...
    'Stimulus Sequence','Resize','Off');

AX1 = axes(F, 'Position', [0 0 0.2 1],'Units', 'Normalized');
set(AX1, 'YColor','none','XColor','None');
patch(AX1,[0 1 1 0],...
    [0, 0, 1, 1],[0.6 0.6 0.6],'EdgeColor','None');
AX2 = axes(F, 'Position', [0.2 0.8 0.8 0.2],'Units', 'Normalized');
set(AX2, 'YColor','none','XColor','None');
patch(AX2,[0 1 1 0],...
    [0, 0, 1, 1],[0.9 0.9 0.9],'EdgeColor','None');

try
    AX1.Toolbar.Visible = 'off';
    AX2.Toolbar.Visible = 'off';
catch
end

mTB(1) = uicontrol(F,'style','text','Units','Normalized',...
    'Position',[0 0 0.2 0.9],'BackgroundColor',C.bgcol);
set(mTB(1),'String',str,'FontSize',10,'foregroundcolor',C.fgcol_1,...
    'backgroundcolor',C.bgcol_2,'fontweight','bold','Tag','smalltext',...
    'HorizontalAlignment','Center');

PB(1) = uicontrol(F,'Style', 'Pushbutton', 'String', 'Add',...
    'Units','Normalized','Position', [0.05 0.05 0.1 0.05],...
    'background',[0.5725 0.6588 0.4039],'ForegroundColor',C.fgcol_1,'FontSize',10,...
    'Callback', @local_add_stim,'Tag','figure','FontWeight','Bold',...
    'Enable', 'On');

PB(2) = uicontrol(F,'Style', 'Togglebutton', 'String', 'Load',...
    'Units','Normalized','Position', [0.25 0.9 0.1 0.05],...
    'background',[0.5725 0.6588 0.4039],'ForegroundColor',C.fgcol_1,'FontSize',10,...
    'Callback', @local_load_toggle,'Tag','figure','FontWeight','Bold',...
    'Enable', 'On');

PB(3) = uicontrol(F,'Style', 'Togglebutton', 'String', 'Create',...
    'Units','Normalized','Position', [0.45 0.9 0.1 0.05],...
    'background',[0.5725 0.6588 0.4039],'ForegroundColor',C.fgcol_1,'FontSize',10,...
    'Callback', @local_create_toggle,'Tag','figure','FontWeight','Bold',...
    'Enable', 'On');

pop = uicontrol(F,'Style', 'popup',...
    'String', sequence,'units','normalized',...
    'Position', [0.6 0.892 0.125 0.0595],'background',C.bgcol_2,...
    'Value',1,'ForegroundColor',C.fgcol_1,'Tag','type','Enable','on');

PB(4) = uicontrol(F,'Style', 'Pushbutton', 'String', '+',...
    'Units','Normalized','Position', [0.75 0.9 0.03 0.05],...
    'background',[0.5725 0.6588 0.4039],'ForegroundColor',C.fgcol_1,'FontSize',10,...
    'Callback', @local_add_one,'Tag','figure','FontWeight','Bold',...
    'Enable', 'On');

PB(5) = uicontrol(F,'Style', 'Pushbutton', 'String', '-',...
    'Units','Normalized','Position', [0.8 0.9 0.03 0.05],...
    'background',[0.9098 0.3725 0.3725],'ForegroundColor',C.fgcol_1,'FontSize',10,...
    'Callback', @local_delete_last,'Tag','figure','FontWeight','Bold',...
    'Enable', 'On');

PB(6) = uicontrol(F,'Style', 'Pushbutton', 'String', 'DONE',...
    'Units','Normalized','Position', [0.525 0.825 0.1 0.05],...
    'background',[0.9098 0.3725 0.3725],'ForegroundColor',C.fgcol_1,'FontSize',10,...
    'Callback', @local_create_pattern,'Tag','figure','FontWeight','Bold',...
    'Enable', 'On');

PB(7) = uicontrol(F,'Style', 'Pushbutton', 'String', 'SELECT',...
    'Units','Normalized','Position', [0.85 0.85 0.125 0.125],...
    'background',[0.0745 0.6235 1.0],'ForegroundColor',C.fgcol_1,'FontSize',10,...
    'Callback', @local_select,'Tag','figure','FontWeight','Bold',...
    'Enable', 'On');

popup(1) = uicontrol(F,'Style', 'popup',...
    'String', allpatt_names,'units','normalized',...
    'Position', [0.25 0.825 0.1 0.05],'background',C.bgcol,...
    'Value',1,'ForegroundColor',C.fgcol_1,'Callback',@local_pick_stimpatt,...
    'Tag','stim','Enable','Off');
d.F = F;
d.C = C;
d.mTB = mTB;
d.PB = PB;
d.pop = pop;
d.popup = popup;
d.sequence = sequence;
d.str = str;
d.tbs = [];
d.counttxt = [];
d.pattern = {};
d.bottom = 0.75;
d.nunits = nunits;
guidata(F, d);

function str = seq2str(seq)
str = '';
for ise = 1:numel(seq)
    str = sprintf('%s\n', [str, seq{ise}]);
end


function local_add_stim(hO, ed)
d = guidata(hO);
answer = inputdlg('Add new stimulus: ');
d.sequence = [d.sequence, answer];
str = seq2str(d.sequence);
set(d.mTB(1), 'String', str);
set(d.pop, 'String', d.sequence);
d.str = str;
guidata(d.F, d);

function local_add_one(hO, ed)
d = guidata(hO);
choice = d.pop.String{d.pop.Value};

Nchoices = numel(d.pattern);

if mod(Nchoices, 10) == 0
    left = 0.21;
    d.bottom = d.bottom - 0.1;
else
    left = 0.21+mod(Nchoices,10)*0.08;
end
if strcmp(choice,'chessboard')
    choice = 'CB';
end
d.pattern{numel(d.pattern)+1} = choice;
d.tbs(Nchoices+1) = uicontrol(d.F,'style','text','Units','Normalized',...
    'Position',[left d.bottom 0.075 0.05],'BackgroundColor',d.C.bgcol);
set(d.tbs(Nchoices+1),'String',choice,'foregroundcolor',d.C.fgcol_1,...
    'backgroundcolor','w','fontweight','bold','Tag','smalltext',...
    'HorizontalAlignment','Center','Fontsize',10);
d.counttxt(Nchoices+1) = uicontrol(d.F,'style','text','Units','Normalized',...
    'Position',[left d.bottom+0.045 0.075 0.04],'BackgroundColor',d.C.bgcol);
set(d.counttxt(Nchoices+1),'String',num2str(Nchoices+1),'FontSize',9,'foregroundcolor','r',...
    'backgroundcolor','w','fontweight','normal','Tag','smalltext',...
    'HorizontalAlignment','Center');

guidata(d.F, d);

function local_delete_last(hO, ed)
d = guidata(hO);

Nchoices = numel(d.pattern);
if Nchoices == 0
    return
end
if mod(Nchoices-1, 10) == 0
    d.bottom = d.bottom + 0.1;
    if d.bottom > 0.75
        d.bottom = 0.75;
    end
end
d.pattern = d.pattern(1:end-1);
delete(d.counttxt(end));
d.counttxt = d.counttxt(1:end-1);
delete(d.tbs(end));
d.tbs = d.tbs(1:end-1);
guidata(d.F, d);


function local_pick_stimpatt(hO, ed)
d = guidata(hO);
P = stimulus_pattern(d.popup(1).String{d.popup(1).Value});

delete(d.tbs)
delete(d.counttxt);
d.tbs = [];
d.counttxt = [];
d.pattern = [];
Nchoices = numel(P);
d.bottom = 0.75;

for ichoice = 1:Nchoices
    if mod(ichoice-1, 10) == 0
        left = 0.21;
        d.bottom = d.bottom - 0.1;
    else
        left = 0.21+mod(ichoice-1,10)*0.08;
    end
    if strcmp(P{ichoice},'999')
        choice = 'CB';
    else
        choice = P{ichoice};
    end
    
    d.pattern{numel(d.pattern)+1} = P{ichoice};
    d.tbs(ichoice) = uicontrol(d.F,'style','text','Units','Normalized',...
        'Position',[left d.bottom 0.075 0.05],'BackgroundColor',d.C.bgcol);
    set(d.tbs(ichoice),'String',choice,'foregroundcolor',d.C.fgcol_1,...
        'backgroundcolor','w','fontweight','bold','Tag','smalltext',...
        'HorizontalAlignment','Center','Fontsize',10);
    d.counttxt(ichoice) = uicontrol(d.F,'style','text','Units','Normalized',...
        'Position',[left d.bottom+0.045 0.075 0.04],'BackgroundColor',d.C.bgcol);
    set(d.counttxt(ichoice),'String',num2str(ichoice),'FontSize',9,'foregroundcolor','r',...
        'backgroundcolor','w','fontweight','normal','Tag','smalltext',...
        'HorizontalAlignment','Center');
end
guidata(d.F, d);

function local_load_toggle(hO, ed)
d = guidata(hO);
delete(d.tbs)
delete(d.counttxt);
d.tbs = [];
d.counttxt = [];
d.pattern = [];
if hO.Value
    set(d.popup(1), 'Enable', 'on');
    set(d.PB(3), 'Value', 0);
    set(d.PB(4:6), 'Enable', 'Off');
    set(d.pop, 'Enable', 'Off');
else
    set(d.popup(1), 'Enable', 'off');
    set(d.PB(3), 'Value', 1);
    set(d.PB(4:6), 'Enable', 'On');
    set(d.pop, 'Enable', 'On');
end

guidata(d.F, d);

function local_create_toggle(hO, ed)
d = guidata(hO);
delete(d.tbs)
delete(d.counttxt);
d.tbs = [];
d.counttxt = [];
d.pattern = [];
if hO.Value
    set(d.popup(1), 'Enable', 'off');
    set(d.PB(2), 'Value', 0);
    set(d.PB(4:6), 'Enable', 'On');
    set(d.pop, 'Enable', 'On');
    
else
    set(d.popup(1), 'Enable', 'on');
    set(d.PB(2), 'Value', 1);
    set(d.PB(4:6), 'Enable', 'Off');
    set(d.pop, 'Enable', 'Off');
end

guidata(d.F, d);

function local_create_pattern(hO, ed)
d = guidata(hO);
if isempty(d.pattern)
    msgbox('No pattern created!')
    return
end
answer = inputdlg('Specify the name of this pattern');
for ip = 1:numel(d.pattern)
    s.(answer{:}){ip} = d.pattern{ip};
end
p = stimulus_pattern(answer{:},s);
close(d.F);
stimuli_pattern(d.nunits);

function local_select(hO, ed)
d = guidata(hO);
name = d.popup(1).String{d.popup.Value};
p = stimulus_pattern(name);

N = d.nunits;

full = floor(N/numel(p));

P = repmat(p,1,full);
P(full*numel(p)+1: N) = p(1:mod(N, numel(p)));



h5cre = findobj('Tag','h5creator');
if ~isempty(h5cre)
    name = d.popup(1).String{d.popup(1).Value};
    D = guidata(h5cre);
    D.stim_pattern = P;
    D.stim_pattern_name = name;
    mtb = findobj('Tag', 'pattern');
    set(mtb, 'String',name);
    guidata(D.F, D);
    msgbox('stimulus pattern accepted!');
else
    assignin('base','P',P);
    msgbox('stimulus pattern exported to workspace as P');
end
close(d.F);