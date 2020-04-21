function behavior2hdf_gui
% method definiton

%closefig
try
    hfig = findobj('Tag', 'b2h5');
    close(hfig);
catch
end

%color picking
%https://colorpalettes.net/color-palette-4191/
sand = [0.9000    0.8600    0.8200];
khaki = [0.4500    0.5100    0.3400];
lbasil = [0.6500    0.8600    0.7000];

%initial data
c = {sand, khaki, lbasil};
hr = hubroot; 

%app created with figure function 
fig = figure('Units', 'normalized', 'Position', [0.375 0.45 0.25 0.2],...
    'MenuBar', 'none', 'Name', 'Behavior translation GUI', 'Tag', 'b2h5');
set(fig, 'Color', sand);
b(1) = uicontrol(fig, 'Units', 'normalized', 'Position', [0.05, 0.8, 0.25, 0.1], ...
    'String', 'SELECT H5 FILE', 'Callback', @get_file);
t(1) = uicontrol(fig, 'Style', 'text', 'Units', 'normalized', ...
    'Position', [0.315, 0.8, 0.635, 0.1], 'Callback', @get_file);
set(t(1), 'BackgroundColor', sand);
dd = uicontrol(fig, 'Style', 'popupmenu', 'Units', 'normalized', ...
    'Position', [0.05, 0.675, 0.25, 0.1], 'String', hr.mouseIDs,  'Callback', @get_mouseID);
t(2) = uicontrol(fig, 'Style', 'text', 'Units', 'normalized', ...
    'Position', [0.315, 0.675, 0.635, 0.1], 'Callback', @get_mouseID);
set(t(2), 'BackgroundColor', sand);
%store data
data = struct('fig', fig, 'buttons', b, 'texts', t, 'dropdown', dd, ...
    'colors', {c}, 'hr', hr);
guidata(fig, data)

function get_file(hObject, eventdata)
hfig = findobj('Tag', 'b2h5');
d = guidata(hfig);
[file, selpath] = uigetfile('*.h5');
d.hdfloc = [selpath, file];
set(d.texts(1), 'String', d.hdfloc);
set(d.texts(1), 'BackgroundColor', d.colors{3});
guidata(d.fig, d)

function get_mouseID(hObject, eventdata)
d = guidata(hObject);
d.mousedata = d.hr.load_mousedata(hObject.String{hObject.Value});
set(d.texts(2), 'String', ['Data of mouse ', hObject.String{hObject.Value}, ' is loaded!']);
set(d.texts(2), 'BackgroundColor', d.colors{3});
b(2) = uicontrol(d.fig, 'Units', 'normalized', 'Position', [0.05, 0.1, 0.425, 0.55], ...
    'String', '<html><center> UPDATE H5 WITH <br /> BEHAVE DATA </center></html>',...
    'Callback', @run_behave2hdf);
b(3) = uicontrol(d.fig, 'Units', 'normalized', 'Position', [0.525, 0.1, 0.425, 0.55], ...
    'String', '<html><center> UPDATE H5 WITH <br /> DURING_IMAGING DATA </center></html>',...
    'Callback', @run_duringimaging2hdf);
d.buttons = b;
guidata(d.fig, d)

function run_behave2hdf(hObject, eventdata)
hfig = findobj('Tag', 'b2h5');
d = guidata(hfig);
behave_create_testscript(d.hdfloc, d.mousedata);
set(d.buttons(2), 'BackgroundColor', d.colors{3});

function run_duringimaging2hdf(hObject, eventdata)
hfig = findobj('Tag', 'b2h5');
d = guidata(hfig);
runningdata_embedding_testscript(d.hdfloc, d.mousedata);
set(d.buttons(3), 'BackgroundColor', d.colors{3});