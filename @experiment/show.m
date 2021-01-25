function F = show(ob)
% F = show(ob) - interactive tool to visualize data.
% a method to experiment object
% work in progress
% part of HELIOS
close all
F = figure;
set(F,'units', 'normalized', 'position', [0.187 0.147 0.675 0.669]);

main_axes = axes(F, 'Position', [0.3 0.4 0.4 0.4],'units','normalized');

%colors
COLORS.bgcol = 'w';
COLORS.bgcol_1 = 'w';
COLORS.fgcol_1 = 'k';
COLORS.plotting.position = [0.251, 0.4157, 0.502];
COLORS.plotting.velocity = [0, 0.2784, 0.4314];
COLORS.plotting.left = [0.8588, 0.4471, 0.3451];
COLORS.plotting.right = [0.4667, 0.6745, 0.1882];
COLORS.plotting.aversive = [0.6510, 0.4706, 0.7608];
COLORS.plotting.black = [0.2588, 0.2431, 0.2431];
COLORS.plotting.cloud = [0.651, 0.651, 0.651];
COLORS.plotting.reward = [0.2314, 0.4784, 0.3647];
COLORS.plotting.lick = [];
COLORS.plotting.lickdelta = [];
COLORS.plotting.licklock = [];
COLORS.plotting.teleport = [];
COLORS.plotting.trigger = [];
COLORS.plotting.port_a = [];
COLORS.plotting.port_b = [];
COLORS.plotting.port_c = [];
COLORS.plotting.dff = [0.5294, 0.3137, 0.1255];
COLORS.plotting.raw = [0.5804, 0, 0];



roilist = num2str([1:ob.N_roi]');
stagelist = num2str([1:ob.N_stages]');
unitlist = num2str(ob.restun{1}');

B = ob.behavior;

d.F = F;
d.ob = ob;
d.ax = main_axes;
d.B = B;
d.lists.roilist = roilist;
d.lists.stagelist = stagelist;
d.lists.unitlist = unitlist;
d.cROI = 1;
d.cSTAGE = 1;
d.cUNIT = 1;
d.C = COLORS;
d.plotting.left.X = [];
d.plotting.left.Y = [];
d.plotting.left.tags = {};
d.plotting.right.X = [];
d.plotting.right.Y = [];
d.plotting.right.tags = {};
d.axes_params.Xlim = [0,1];
d.axes_params.Xlim_locked = 0;
d.axes_params.Xtype = 'lin';
d.axes_params.Yllim = [0,1];
d.axes_params.Yllim_locked = 0;
d.axes_params.Yltype = 'lin';
d.axes_params.Yrlim = [0,1];
d.axes_params.Yrlim_locked = 0;
d.axes_params.Yrtype = 'lin';


guidata(F, d);
%button group 1
popup = local_bg_1(F, COLORS);
d.GUI.popup_RSU = popup;
guidata(F, d);


%button group left plot
cb_left = local_bg_left(F, COLORS);
d.GUI.plotting.left.cb = cb_left;

%button group right plot
cb_right = local_bg_right(F, COLORS, B.protocol);
d.GUI.plotting.right.cb = cb_right;

%button group 3
[ED, cb] = local_bg_3(F, COLORS);
d.GUI.axes_limits.ED = ED;
d.GUI.axes_limits.cb = cb;
guidata(F, d);

function local_pick_RSU(hO, ev)
d = guidata(hO);
fn = ['c',hO.Tag];
d.(fn) = hO.Value;
if strcmp(hO.Tag,'STAGE')
    d.GUI.popup_RSU(3).Value = 1;
    d.GUI.popup_RSU(3).String = num2str(d.ob.restun{hO.Value}');
    d.cUNIT = 1;
end
guidata(d.F, d);
local_plot_after_pick(d);

function local_plot_after_pick(d)
nleft = numel(d.GUI.plotting.left.cb);
d.plotting.left.Y = []; 
% d.plotting.right.Y = []; 
guidata(d.F, d);
for il = 1:nleft
    local_left_plot(d.GUI.plotting.left.cb(il),[]);
end
d = guidata(gcf);
%HERE GOES THE RIGHT SIDE
nright = numel(d.GUI.plotting.right.cb);
d.plotting.right.Y = []; 
guidata(d.F, d);
for ir = 1:nright
    local_right_plot(d.GUI.plotting.right.cb(ir),[]);
end

function local_left_plot(hO, ed)
d = guidata(hO);
tag = hO.Tag;
switch hO.Value
    case 1
        W = traces(d.ob, {d.cROI, d.cSTAGE}, tag);
        Xl = W.time(d.cUNIT,:)*1e-3;
        Yl = W.data(d.cUNIT,:);
        
        d.plotting.left.X = Xl;
        d.plotting.left.Y = vertcat(d.plotting.left.Y, Yl);
        if ~isempty(ed)
            d.plotting.left.tags{numel(d.plotting.left.tags)+1} = tag;
        end
    case 0
        mask = ~ismember(d.plotting.left.tags, tag);
        
        if ~isempty(ed)
            d.plotting.left.Y = d.plotting.left.Y(mask,:);
            d.plotting.left.tags = d.plotting.left.tags(mask);
        end
end
guidata(d.F, d);
local_plot(hO,lower(tag));

function local_right_plot(hO, ed)
d = guidata(hO);
tag = hO.Tag;
B = d.B.stage(d.cSTAGE).unit(d.cUNIT);
switch hO.Value
    case 1
        Xr = B.time;
        if ~isempty(tag)
            spl = strsplit(tag,'/');
            if numel(spl) == 1
                Yr = B.(lower(tag)).(lower(hO.String));
            else
                Yr = B.(lower(spl{1})).(lower(spl{2})).(lower(hO.String));
            end
        else
            Yr = B.(lower(hO.String));
        end
        d.plotting.right.X = Xr;
        d.plotting.right.Y = vertcat(d.plotting.right.Y, Yr');
        if ~isempty(ed)
            d.plotting.right.tags{numel(d.plotting.right.tags)+1} = tag;
        end
    case 0
        mask = ~ismember(d.plotting.right.tags, tag);
        if ~isempty(ed)
            d.plotting.right.Y = d.plotting.right.Y(mask,:);
            d.plotting.right.tags = d.plotting.right.tags(mask);
        end
end
guidata(d.F, d);
local_plot(hO,lower(hO.String));

function local_plot(hO, flag)
d = guidata(hO);
cla reset;
axes(d.ax);
% W = traces(d.ob, {d.cROI, d.cSTAGE}, 'dff');
%LEFT
X1 = d.plotting.left.X;
Y1 = d.plotting.left.Y;
% m1 = max(abs(Y1));

%RIGHT

X2 = d.plotting.right.X;
Y2 = d.plotting.right.Y;

if ~isempty(Y1)
    yyaxis left
%     col = d.C.plotting.(lower(hO.Tag));
    col = 'k';
    plot(X1,Y1,'-','color',col);
    if d.axes_params.Xlim_locked
        xlim(d.axes_params.Xlim);
    else
        xl = xlim;
        set(d.GUI.axes_limits.ED(1), 'String', num2str(xl(1)));
        set(d.GUI.axes_limits.ED(2), 'String', num2str(xl(2)));
        d.axes_params.Xlim = xl;
    end
    if d.axes_params.Yllim_locked
        ylim(d.axes_params.Yllim);
    else
        yl = ylim;
        set(d.GUI.axes_limits.ED(3), 'String', num2str(yl(1)));
        set(d.GUI.axes_limits.ED(4), 'String', num2str(yl(2)));
        d.axes_params.Yllim = yl;
    end
    
    hold on;
end
% yyaxis right
if ~isempty(Y2)
    yyaxis right
    col = 'r';
    plot(X2,Y2,'-','Color',col);
    if d.axes_params.Xlim_locked
        xlim(d.axes_params.Xlim);
    else
        xl = xlim;
        set(d.GUI.axes_limits.ED(1), 'String', num2str(xl(1)));
        set(d.GUI.axes_limits.ED(2), 'String', num2str(xl(2)));
        d.axes_params.Xlim = xl;
    end
    if d.axes_params.Yrlim_locked
        ylim(d.axes_params.Yrlim);
    else
        yl = ylim;
        set(d.GUI.axes_limits.ED(5), 'String', num2str(yl(1)));
        set(d.GUI.axes_limits.ED(6), 'String', num2str(yl(2)));
        d.axes_params.Yrlim = yl;
    end
end

guidata(d.F, d);

function popup = local_bg_1(F, C)
d = guidata(F);
uibg = uibuttongroup(F, 'Position',[0.0200 0.89 0.31 0.057]);
mTB(1) = uicontrol(uibg,'style','text','Units','Normalized',...
    'Position',[0.001 0.27 0.15 0.54]);
set(mTB(1),'String',['ROI: '],'FontSize',10,'foregroundcolor',C.fgcol_1,...
    'backgroundcolor',C.bgcol_1,'fontweight','bold','Tag','smalltext');
popup(1) = uicontrol(uibg,'Style', 'popup',...
    'String', d.lists.roilist,'units','normalized',...
    'Position', [0.2 0.27 0.14 0.54],'background',C.bgcol,...
    'Value',1,'ForegroundColor',C.fgcol_1,'Callback',@local_pick_RSU,'Tag','ROI');

mTB(2) = uicontrol(uibg,'style','text','Units','Normalized',...
    'Position',[0.351 0.27 0.15 0.54]);
set(mTB(2),'String',['STAGE: '],'FontSize',10,'foregroundcolor',C.fgcol_1,...
    'backgroundcolor',C.bgcol_1,'fontweight','bold','Tag','smalltext');
popup(2) = uicontrol(uibg,'Style', 'popup',...
    'String', d.lists.stagelist,'units','normalized',...
    'Position', [0.5 0.31 0.14 0.54],'background',C.bgcol,...
    'Value',1,'ForegroundColor',C.fgcol_1,'Callback',@local_pick_RSU,'Tag','STAGE');

mTB(3) = uicontrol(uibg,'style','text','Units','Normalized',...
    'Position',[0.651 0.27 0.15 0.54]);
set(mTB(3),'String',['UNIT: '],'FontSize',10,'foregroundcolor',C.fgcol_1,...
    'backgroundcolor',C.bgcol_1,'fontweight','bold','Tag','smalltext');
popup(3) = uicontrol(uibg,'Style', 'popup',...
    'String', d.lists.unitlist,'units','normalized',...
    'Position', [0.8 0.31 0.14 0.54],'background',C.bgcol,...
    'Value',1,'ForegroundColor',C.fgcol_1,'Callback',@local_pick_RSU,'Tag','UNIT');

function cb = local_bg_left(F, C)
%d = guidata(F);
uibg = uibuttongroup(F, 'Position',[0.02 0.68 0.06 0.11],'Title','Left axis');
cb(1) = uicontrol(uibg,'Style', 'checkbox', 'String', 'dff',...
    'tag','dff',...
    'Units','Normalized','Position', [0.02 0.75 0.9 0.22],'FontSize',8,...
    'Callback',@local_left_plot,'Value',0);
cb(2) = uicontrol(uibg,'Style', 'checkbox', 'String', 'raw',...
    'tag','raw',...
    'Units','Normalized','Position', [0.02 0.5 0.9 0.22],'FontSize',8,...
    'Callback',@local_left_plot,'Value', 0);

function cb = local_bg_right(F, C, prot)
uibg = uibuttongroup(F, 'Position',[0.09 0.5 0.155 0.29],'Title','Right axis');
mTB(1) = uicontrol(uibg,'style','text','Units','Normalized',...
    'Position',[0.02 0.91 0.22 0.07]);
set(mTB(1),'String',['base'],'FontSize',10,'foregroundcolor',C.fgcol_1,...
    'backgroundcolor',C.bgcol_1,'fontweight','bold','Tag','smalltext',...
    'HorizontalAlignment', 'Left');
cb(1) = uicontrol(uibg,'Style', 'checkbox', 'String', 'Velocity',...
    'tag','',...
    'Units','Normalized','Position', [0.02 0.8 0.4 0.1],'FontSize',8,...
    'Callback',@local_right_plot,'Value',0);
cb(2) = uicontrol(uibg,'Style', 'checkbox', 'String', 'Luminance',...
    'tag','',...
    'Units','Normalized','Position', [0.02 0.7 0.4 0.1],'FontSize',8,...
    'Callback',@local_right_plot,'Value',0);
cb(3) = uicontrol(uibg,'Style', 'checkbox', 'String', 'Position',...
    'tag','',...
    'Units','Normalized','Position', [0.02 0.6 0.4 0.1],'FontSize',8,...
    'Callback',@local_right_plot,'Value', 0);


mTB(2) = uicontrol(uibg,'style','text','Units','Normalized',...
    'Position',[0.02 0.51 0.22 0.07]);
set(mTB(2),'String',['events'],'FontSize',10,'foregroundcolor',C.fgcol_1,...
    'backgroundcolor',C.bgcol_1,'fontweight','bold','Tag','smalltext',...
    'HorizontalAlignment', 'Left');
cb(4) = uicontrol(uibg,'Style', 'checkbox', 'String', 'Lick',...
    'tag','EVENTS',...
    'Units','Normalized','Position', [0.02 0.4 0.4 0.1],'FontSize',8,...
    'Callback',@local_right_plot,'Value', 0);
cb(5) = uicontrol(uibg,'Style', 'checkbox', 'String', 'Lickdelta',...
    'tag','EVENTS',...
    'Units','Normalized','Position', [0.02 0.3 0.4 0.1],'FontSize',8,...
    'Callback',@local_right_plot,'Value', 0);
cb(6) = uicontrol(uibg,'Style', 'checkbox', 'String', 'Licklock',...
    'tag','EVENTS',...
    'Units','Normalized','Position', [0.02 0.2 0.4 0.1],'FontSize',8,...
    'Callback',@local_right_plot,'Value', 0);
cb(7) = uicontrol(uibg,'Style', 'checkbox', 'String', 'Teleport',...
    'tag','EVENTS',...
    'Units','Normalized','Position', [0.02 0.1 0.4 0.1],'FontSize',8,...
    'Callback',@local_right_plot,'Value', 0);
cb(8) = uicontrol(uibg,'Style', 'checkbox', 'String', 'Trigger',...
    'tag','EVENTS',...
    'Units','Normalized','Position', [0.02 0.001 0.4 0.1],'FontSize',8,...
    'Callback',@local_right_plot,'Value', 0);

mTB(3) = uicontrol(uibg,'style','text','Units','Normalized',...
    'Position',[0.5 0.91 0.22 0.09]);
set(mTB(3),'String',['ports'],'FontSize',10,'foregroundcolor',C.fgcol_1,...
    'backgroundcolor',C.bgcol_1,'fontweight','bold','Tag','smalltext',...
    'HorizontalAlignment', 'Left');
cb(9) = uicontrol(uibg,'Style', 'checkbox', 'String', 'Port_A',...
    'tag','PORTS',...
    'Units','Normalized','Position', [0.5 0.8 0.4 0.1],'FontSize',8,...
    'Callback',@local_right_plot,'Value', 0);
cb(10) = uicontrol(uibg,'Style', 'checkbox', 'String', 'Port_B',...
    'tag','PORTS',...
    'Units','Normalized','Position', [0.5 0.7 0.4 0.1],'FontSize',8,...
    'Callback',@local_right_plot,'Value', 0);
cb(11) = uicontrol(uibg,'Style', 'checkbox', 'String', 'Port_C',...
    'tag','PORTS',...
    'Units','Normalized','Position', [0.5 0.6 0.4 0.1],'FontSize',8,...
    'Callback',@local_right_plot,'Value', 0);

mTB(4) = uicontrol(uibg,'style','text','Units','Normalized',...
    'Position',[0.5 0.51 0.22 0.07]);
set(mTB(4),'String',['zones'],'FontSize',10,'foregroundcolor',C.fgcol_1,...
    'backgroundcolor',C.bgcol_1,'fontweight','bold','Tag','smalltext',...
    'HorizontalAlignment', 'Left');
switch prot
    case 'photostim'
        str = 'Aversive';
    case 'moculus'
        str = 'Left';        
end
cb(12) = uicontrol(uibg,'Style', 'checkbox', 'String', str,...
    'tag','ZONES/CONTROL',...
    'Units','Normalized','Position', [0.5 0.4 0.4 0.1],'FontSize',8,...
    'Callback',@local_right_plot,'Value', 0);
cb(13) = uicontrol(uibg,'Style', 'checkbox', 'String', 'Right',...
    'tag','ZONES/CONTROL',...
    'Units','Normalized','Position', [0.5 0.3 0.4 0.1],'FontSize',8,...
    'Callback',@local_right_plot,'Value', 0);

switch prot
    case 'photostim'
        str = 'Reward';
    case 'moculus'
        str = 'Aversive';        
end
cb(14) = uicontrol(uibg,'Style', 'checkbox', 'String', str,...
    'tag','ZONES/DISCRIM',...
    'Units','Normalized','Position', [0.5 0.2 0.4 0.1],'FontSize',8,...
    'Callback',@local_right_plot,'Value', 0);
cb(15) = uicontrol(uibg,'Style', 'checkbox', 'String', 'Black',...
    'tag','ZONES/NEUTRAL',...
    'Units','Normalized','Position', [0.5 0.1 0.4 0.1],'FontSize',8,...
    'Callback',@local_right_plot,'Value', 0);
cb(16) = uicontrol(uibg,'Style', 'checkbox', 'String', 'Cloud',...
    'tag','ZONES/NEUTRAL',...
    'Units','Normalized','Position', [0.5 0.001 0.4 0.1],'FontSize',8,...
    'Callback',@local_right_plot,'Value', 0);

function [ED, cb] = local_bg_3(F, C)
d = guidata(F);
ax = d.ax;
axes(ax);
xl = xlim;
yyaxis left
yl_l = ylim;
yyaxis right
yr_l = ylim;

uibg = uibuttongroup(F, 'Position',[0.3 0.1 0.125 0.25]);

mTB(1) = uicontrol(uibg,'style','text','Units','Normalized',...
    'Position',[0.001 0.85 0.26 0.1]);
set(mTB(1),'String','Xlim: ','FontSize',8,'foregroundcolor',C.fgcol_1,...
    'backgroundcolor',C.bgcol_1,'fontweight','bold','Tag','smalltext');

ED(1) = uicontrol(uibg,'Style', 'edit', 'String', num2str(xl(1)),...
    'tag','x_left',...
    'Units','Normalized','Position', [0.29, 0.85, 0.3,0.1],'FontSize',8,...
    'Callback',@local_change_limits,'Enable','on');
ED(2) = uicontrol(uibg,'Style', 'edit', 'String', num2str(xl(2)),...
    'tag','x_right',...
    'Units','Normalized','Position', [0.69, 0.85, 0.3,0.1],'FontSize',8,...
    'Callback',@local_change_limits,'Enable','on');
cb(1) = uicontrol(uibg,'Style', 'checkbox', 'String', 'lock',...
    'tag','x',...
    'Units','Normalized','Position', [0.02 0.725 0.3 0.1],'FontSize',8,...
    'Callback',@local_lock);


mTB(2) = uicontrol(uibg,'style','text','Units','Normalized',...
    'Position',[0.001 0.55 0.26 0.1]);
set(mTB(2),'String','Yl_lim: ','FontSize',8,'foregroundcolor',C.fgcol_1,...
    'backgroundcolor',C.bgcol_1,'fontweight','bold','Tag','smalltext');

ED(3) = uicontrol(uibg,'Style', 'edit', 'String', num2str(yl_l(1)),...
    'tag','yl_left',...
    'Units','Normalized','Position', [0.29, 0.55, 0.3,0.1],'FontSize',8,...
    'Callback',@local_change_limits,'Enable','on');
ED(4) = uicontrol(uibg,'Style', 'edit', 'String', num2str(yl_l(2)),...
    'tag','yl_right',...
    'Units','Normalized','Position', [0.69, 0.55, 0.3,0.1],'FontSize',8,...
    'Callback',@local_change_limits,'Enable','on');
cb(2) = uicontrol(uibg,'Style', 'checkbox', 'String', 'lock',...
    'tag','yl',...
    'Units','Normalized','Position', [0.02 0.425 0.3 0.1],'FontSize',8,...
    'Callback',@local_lock);

mTB(3) = uicontrol(uibg,'style','text','Units','Normalized',...
    'Position',[0.001 0.25 0.26 0.1]);
set(mTB(3),'String','Yr_lim: ','FontSize',8,'foregroundcolor',C.fgcol_1,...
    'backgroundcolor',C.bgcol_1,'fontweight','bold','Tag','smalltext');

ED(5) = uicontrol(uibg,'Style', 'edit', 'String', num2str(yr_l(1)),...
    'tag','yr_left',...
    'Units','Normalized','Position', [0.29, 0.25, 0.3,0.1],'FontSize',8,...
    'Callback',@local_change_limits,'Enable','on');
ED(6) = uicontrol(uibg,'Style', 'edit', 'String', num2str(yr_l(2)),...
    'tag','yr_right',...
    'Units','Normalized','Position', [0.69, 0.25, 0.3,0.1],'FontSize',8,...
    'Callback',@local_change_limits,'Enable','on');
cb(3) = uicontrol(uibg,'Style', 'checkbox', 'String', 'lock',...
    'tag','yr',...
    'Units','Normalized','Position', [0.02 0.125 0.3 0.1],'FontSize',8,...
    'Callback',@local_lock);

PB(1) = uicontrol(uibg,'Style', 'Pushbutton', 'String', 'reset',...
    'Units','Normalized','Position', [0.35 0.005 0.3 0.095],...
    'background',C.bgcol_1,'ForegroundColor',C.fgcol_1,'FontSize',10,...
    'Callback', @local_reset,'Tag','reset','FontWeight','Bold');



function local_lock(hO, ed)
d = guidata(hO);
switch hO.Value
    case 0 
        en = 'on';
    case 1
        en = 'off';
end
switch hO.Tag
    case 'x'
        d.axes_params.Xlim_locked = hO.Value;
        set(d.GUI.axes_limits.ED([1,2]),'Enable',en);
    case 'yl'
        d.axes_params.Yllim_locked = hO.Value;
        set(d.GUI.axes_limits.ED([3,4]),'Enable',en);
    case 'yr'
        d.axes_params.Yrlim_locked = hO.Value;
        set(d.GUI.axes_limits.ED([5,6]),'Enable',en);
end
guidata(d.F, d);

function local_change_limits(hO, ed)
d = guidata(hO);
lim = str2double(hO.String);
switch hO.Tag
    case 'x_left'
        d.ax.XLim(1) = lim;
        d.axes_params.Xlim(1) = lim;
    case 'x_right'
        d.ax.XLim(2) = lim;
        d.axes_params.Xlim(2) = lim;
    case 'yl_left'
        axes(d.ax);
        yyaxis left
        d.ax.YLim(1) = lim;
        d.axes_params.Yllim(1) = lim;
    case 'yl_right'
        axes(d.ax);
        yyaxis left
        d.ax.YLim(2) = lim;
        d.axes_params.Yllim(2) = lim;
    case 'yr_left'
        axes(d.ax);
        yyaxis right
        d.ax.YLim(1) = lim;
        d.axes_params.Yrlim(1) = lim;
    case 'yr_right'
        axes(d.ax);
        yyaxis right
        d.ax.YLim(2) = lim;
        d.axes_params.Yrlim(2) = lim;
end
guidata(d.F, d);

function local_reset(hO, ed)
d = guidata(hO);
set(d.GUI.axes_limits.ED,'Enable','on');
set(d.GUI.axes_limits.cb,'Value',0);
axes(d.ax);
xlim auto
yyaxis left
ylim auto
yyaxis right
ylim auto

xl = xlim;
yrl = ylim;
yyaxis left
yll = ylim;

set(d.GUI.axes_limits.ED(1), 'String', num2str(xl(1)));
set(d.GUI.axes_limits.ED(2), 'String', num2str(xl(2)));
set(d.GUI.axes_limits.ED(3), 'String', num2str(yll(1)));
set(d.GUI.axes_limits.ED(4), 'String', num2str(yll(2)));
set(d.GUI.axes_limits.ED(5), 'String', num2str(yrl(1)));
set(d.GUI.axes_limits.ED(6), 'String', num2str(yrl(2)));


d.axes_params.Xlim = xl;
d.axes_params.Xlim_locked = 0;
d.axes_params.Xtype = 'lin';
d.axes_params.Yllim = yll;
d.axes_params.Yllim_locked = 0;
d.axes_params.Yltype = 'lin';
d.axes_params.Yrlim = yrl;
d.axes_params.Yrlim_locked = 0;
d.axes_params.Yrtype = 'lin';

guidata(d.F, d);