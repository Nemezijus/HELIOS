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
COLORS.plotting.lick = [0.3882, 0.4588, 0.0980];
COLORS.plotting.lickdelta = [0.5804, 0.6784, 0.1843];
COLORS.plotting.licklock = [0.2 0.3 0.4];
COLORS.plotting.teleport = [0.7882, 0.4745, 0.6196];
COLORS.plotting.trigger = [0.9020, 0.1529, 0.5020];
COLORS.plotting.port_a = [0.5725, 0.6588, 0.4039];
COLORS.plotting.port_b = [0.4902, 0.6706, 0.1333];
COLORS.plotting.port_c = [0.2824, 0.3804,0.0863];
COLORS.plotting.luminance = [1, 1, 0];
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
d.offset = 0;
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

%button group export
cb = local_bg_export(F, COLORS);
guidata(F, d);
PB(1) = uicontrol(F,'Style', 'Pushbutton', 'String', 'Export 2 GOR',...
    'Units','Normalized','Position', [0.35 0.9 0.075 0.05],...
    'background',COLORS.bgcol_1,'ForegroundColor',COLORS.fgcol_1,'FontSize',10,...
    'Callback', @local_export_all,'Tag','figure','FontWeight','Bold');


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
axes(d.ax);
for ir = 1:nright
    local_right_plot(d.GUI.plotting.right.cb(ir),[]);
end
yyaxis right

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
local_plot(hO);

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
        d.plotting.right.X = Xr';
        d.plotting.right.Y = vertcat(d.plotting.right.Y, Yr');
        if ~isempty(ed)
            d.plotting.right.tags{numel(d.plotting.right.tags)+1} = lower(hO.String);%!!!
        end
    case 0
        mask = ~ismember(d.plotting.right.tags, lower(hO.String));
        if ~isempty(ed)
            d.plotting.right.Y = d.plotting.right.Y(mask,:);
            d.plotting.right.tags = d.plotting.right.tags(mask);
        end
end
guidata(d.F, d);
local_plot(hO);

function local_plot(hO, ax)
d = guidata(hO);
if nargin == 1
    cla reset;
    axes(d.ax);
else
    axes(ax);
end
% W = traces(d.ob, {d.cROI, d.cSTAGE}, 'dff');
%LEFT
X1 = d.plotting.left.X;
if d.offset
    X1 = X1+d.B.stage(d.cSTAGE).unit(d.cUNIT).time_offset-X1(1);
end
Y1 = d.plotting.left.Y;
% m1 = max(abs(Y1));

%RIGHT

X2 = d.plotting.right.X;
Y2 = d.plotting.right.Y;


% yyaxis right
if ~isempty(Y2)
    yyaxis right
    col = 'r';
    for iy = 1:numel(Y2(:,1))
        pl(iy) = plot(X2,Y2(iy,:),'-','Color',[d.C.plotting.(d.plotting.right.tags{iy}),0.5]); hold on;
    end
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
if ~isempty(Y1)
    yyaxis left
%     col = d.C.plotting.(lower(hO.Tag));
    col = 'k';
    for iy = 1:numel(Y1(:,1))
        plot(X1,Y1(iy,:),'-','Color',d.C.plotting.(d.plotting.left.tags{iy})); hold on
    end
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
CB = uicontrol(F,'Style', 'checkbox', 'String', 'adjust offset',...
    'tag','offset',...
    'Units','Normalized','Position', [0.02 0.63 0.075 0.05],'FontSize',8,...
    'Callback',@local_offset, 'Value',0);

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

function PB = local_bg_export(F, C)
uibg = uibuttongroup(F, 'Position',[0.09 0.4 0.155 0.1],'Title','Export Selection');

PB(1) = uicontrol(uibg,'Style', 'Pushbutton', 'String', 'Figure',...
    'Units','Normalized','Position', [0.005 0.3 0.3 0.4],...
    'background',C.bgcol_1,'ForegroundColor',C.fgcol_1,'FontSize',10,...
    'Callback', @local_export,'Tag','figure','FontWeight','Bold');
PB(2) = uicontrol(uibg,'Style', 'Pushbutton', 'String', 'PNG',...
    'Units','Normalized','Position', [0.35 0.3 0.3 0.4],...
    'background',C.bgcol_1,'ForegroundColor',C.fgcol_1,'FontSize',10,...
    'Callback', @local_export,'Tag','png','FontWeight','Bold');
PB(3) = uicontrol(uibg,'Style', 'Pushbutton', 'String', 'Curves',...
    'Units','Normalized','Position', [0.7 0.3 0.3 0.4],...
    'background',C.bgcol_1,'ForegroundColor',C.fgcol_1,'FontSize',10,...
    'Callback', @local_export,'Tag','gor','FontWeight','Bold');

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

function local_export(hO, ed)
d = guidata(hO);
saveloc = d.ob.file_loc;
saveloc = strsplit(saveloc,'\');
saveloc = saveloc(1:end-1);
cdir = cd;
switch hO.Tag
    case 'figure'
        FF = figure;
        set(FF,'units', 'normalized', 'position', [0.189 0.0972 0.675 0.76]);
        AX = axes(FF);
        local_plot(hO, AX);
    case 'png'
        saveloc{end+1} = 'show_images';
        saveloc = strjoin(saveloc,'\');
        mkdir(saveloc);
        name = ['\',d.ob.id,'_stage_',num2str(d.cSTAGE),'_unit_',num2str(d.cUNIT),...
            '.png'];
        saveloc = [saveloc,name];
        FF = figure;
        set(FF,'units', 'normalized', 'position', [0.189 0.0972 0.675 0.76]);
        AX = axes(FF);
        local_plot(hO, AX);
        saveas(FF,saveloc);
        close(FF);
    case 'gor'
        saveloc{end+1} = 'show_curves';
        saveloc = strjoin(saveloc,'\');
        mkdir(saveloc);
        name = [d.ob.id,'_ROI_',num2str(d.cROI),'_stage_',num2str(d.cSTAGE),'_unit_',num2str(d.cUNIT),...
            '.gor'];
        L = d.plotting.left;
        R = d.plotting.right;
        idx = 1;
        for il = 1:numel(L.Y(:,1))
            G(idx) = gorobj('double',L.X,...
                'double',L.Y(il,:));
            G(idx)=set(G(idx),'xname','time (s)');
            G(idx)=set(G(idx),'name',['ROI ',num2str(d.cROI),' stage ',num2str(d.cSTAGE),' unit ',...
                num2str(d.cUNIT),' ', L.tags{il}]);
            G(idx)=set(G(idx),'varnames',{'ROI','STAGE','UNIT','D','E','F','G'});
            G(idx)=set(G(idx),'vars',[d.cROI,d.cSTAGE,d.cUNIT,0,0,0,0]);
            G(idx)=set(G(idx),'Color',d.C.plotting.(L.tags{il}));
            G(idx)=compress(G(idx));
            idx = idx + 1;
        end
        for ir = 1:numel(R.Y(:,1))
            G(idx) = gorobj('double',R.X,...
                'double',R.Y(ir,:));
            G(idx)=set(G(idx),'xname','time (s)');
            G(idx)=set(G(idx),'name',['ROI ',num2str(d.cROI),' stage ',num2str(d.cSTAGE),' unit ',...
                num2str(d.cUNIT),' ', R.tags{ir}]);
            G(idx)=set(G(idx),'varnames',{'ROI','STAGE','UNIT','D','E','F','G'});
            G(idx)=set(G(idx),'vars',[d.cROI,d.cSTAGE,d.cUNIT,0,0,0,0]);
            G(idx)=set(G(idx),'Color',d.C.plotting.(R.tags{ir}));
            G(idx)=compress(G(idx));
            idx = idx + 1;
        end
        cd(saveloc);
        gor2file(name,G)
%         save(name,'G','-v7.3','-nocompression');
        winopen(saveloc);
        cd(cdir);
end

function local_export_all(hO, ed)
d = guidata(hO);
idx = 1;
cdir = cd;
hh = msgbox('Creating and saving gor file! Please wait!');
for ir = 1:d.ob.N_roi
    W = traces(d.ob, {ir, d.cSTAGE}, 'dff');
    G(idx) = gorobj('double',W.time(d.cUNIT,:)*1e-3,'double',W.data(d.cUNIT,:));
    G(idx)=set(G(idx),'xname','time (ms)');
    G(idx)=set(G(idx),'yname','dFF');
    G(idx)=set(G(idx),'name',['ROI ',num2str(ir),' stage ',num2str(d.cSTAGE),' unit ',...
        num2str(d.cUNIT),' ', 'dff']);
    G(idx)=set(G(idx),'varnames',{'ROI','STAGE','UNIT','D','E','F','G'});
    G(idx)=set(G(idx),'vars',[ir,d.cSTAGE,d.cUNIT,0,0,0,0]);
    G(idx)=compress(G(idx));
    idx = idx+1;
end
%BEHAVIOR
B = d.B.stage(d.cSTAGE).unit(d.cUNIT);
X = B.time';

[D1, names1] = behave_read_for_gor(B);
[D2, names2] = behave_read_for_gor(B.events);
[D3, names3] = behave_read_for_gor(B.ports);
[D4, names4] = behave_read_for_gor(B.zones.control);
[D5, names5] = behave_read_for_gor(B.zones.discrim);
[D6, names6] = behave_read_for_gor(B.zones.neutral);
D = vertcat(D1,D2,D3,D4,D5,D6);
names = horzcat(names1,names2,names3,names4,names5,names6);

for iname = 1:numel(names)
    G(idx) = gorobj('double',X,'double',D(iname,:));
    G(idx)=set(G(idx),'xname','time (s)');
    G(idx)=set(G(idx),'name',['ROI ',num2str(ir),' stage ',num2str(d.cSTAGE),' unit ',...
        num2str(d.cUNIT),' ', names{iname}]);
    G(idx)=set(G(idx),'varnames',{'ROI','STAGE','UNIT','D','E','F','G'});
    G(idx)=set(G(idx),'vars',[ir,d.cSTAGE,d.cUNIT,0,0,0,0]);
    G(idx)=set(G(idx),'Color',d.C.plotting.(names{iname}));
    G(idx)=compress(G(idx));
    idx = idx+1;
end

saveloc = d.ob.file_loc;
saveloc = strsplit(saveloc,'\');
saveloc = saveloc(1:end-1);
saveloc{end+1} = 'show_curves';
saveloc = strjoin(saveloc,'\');
mkdir(saveloc);
name = [d.ob.id,'_all_ROIs','_stage_',num2str(d.cSTAGE),'_unit_',num2str(d.cUNIT),...
    '.gor'];
cd(saveloc);
gor2file(name,G);
close(hh);
winopen(saveloc);
cd(cdir);

function [D, names] = behave_read_for_gor(s)
fn = fieldnames(s);
idx = 1;
for ifn = 1:numel(fn)
    if ~isstruct(s.(fn{ifn})) & numel(s.(fn{ifn})) > 1 & ~strcmp(fn{ifn},'time')
        D(idx,:) = s.(fn{ifn})';
        names{idx} = fn{ifn};
        idx = idx+1;
    end
end

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

function local_offset(hO, ed)
d = guidata(hO);
d.offset = hO.Value;
guidata(d.F, d);
local_plot(hO);