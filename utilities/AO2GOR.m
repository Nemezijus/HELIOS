function AO2GOR
%AO2GOR - interactive GUI which creates a gor file for every unit in the
%mes file. In order to process, all the necessary data has to be in the same
%directory. Requires to have the same amount of behavior csv files as there
%are units in the mes file. The directory also must contain info.txt file 
%which has only one line of text 'unit = [];', where in square brackets 
%user has specified the numerical unit values. e.g. 'unit = [11 12 13 14 15];'
% C.bgcol_1 = 'w';
% C.fgcol_1 = 'k';
C.bgcol_1 = [0.0627 0.3020 0.3020];
C.bgcol_2 = [0.4431 0.5608 0.4510];
C.fgcol_1 = [1 0.7882 0.2118];
fsz = 10;

decision = function_check;
if ~decision
    return
end

F = figure;
set(F,'units', 'normalized', 'position', [0.354 0.517 0.292 0.389],...
    'Color',C.bgcol_1,'MenuBar','None','Name','AO2GOR','NumberTitle','off');
PB(1) = uicontrol(F,'Style', 'Pushbutton', 'String', 'Select Directory',...
    'Units','Normalized','Position', [0.4, 0.8 0.2 0.1],...
    'background',C.bgcol_2,'ForegroundColor',C.fgcol_1,'FontSize',10,...
    'Callback', @local_select_directory,'Tag','figure','FontWeight','Bold');

PB(2) = uicontrol(F,'Style', 'Pushbutton', 'String', 'Done',...
    'Units','Normalized','Position', [0.4, 0.2 0.2 0.1],...
    'background',C.bgcol_2,'ForegroundColor',C.fgcol_1,'FontSize',10,...
    'Callback', @local_done,'Tag','figure','FontWeight','Bold','Enable','Off');

uibg = uibuttongroup(F, 'Position',[0.45 0.5 0.2 0.2],'Title','Experiment mode',...
    'BackgroundColor',C.bgcol_1,'ForegroundColor',C.fgcol_1);
cb(1) = uicontrol(uibg,'Style', 'checkbox', 'String', 'moculus',...
    'tag','moculus',...
    'Units','Normalized','Position', [0.02 0.75 0.9 0.22],'FontSize',8,...
    'Callback',@local_select_mode,'Value',1,'BackgroundColor',C.bgcol_1,...
    'ForegroundColor',C.fgcol_1,'FontSize',fsz);
cb(2) = uicontrol(uibg,'Style', 'checkbox', 'String', 'photostim',...
    'tag','photostim',...
    'Units','Normalized','Position', [0.02 0.5 0.9 0.22],'FontSize',8,...
    'Callback',@local_select_mode,'Value', 0,'BackgroundColor',C.bgcol_1,...
    'ForegroundColor',C.fgcol_1,'FontSize',fsz);

uibg2 = uibuttongroup(F, 'Position',[0.66 0.5 0.3 0.2],'Title','ROI mode',...
    'BackgroundColor',C.bgcol_1,'ForegroundColor',C.fgcol_1);
CB(1) = uicontrol(uibg2,'Style', 'checkbox', 'String', 'multi (selected)',...
    'tag','multi',...
    'Units','Normalized','Position', [0.02 0.75 0.9 0.22],'FontSize',8,...
    'Callback',@local_select_roimode,'Value',1,'BackgroundColor',C.bgcol_1,...
    'ForegroundColor',C.fgcol_1,'FontSize',fsz);
CB(2) = uicontrol(uibg2,'Style', 'checkbox', 'String', 'scanfield (whole field)',...
    'tag','scanfield',...
    'Units','Normalized','Position', [0.02 0.5 0.9 0.22],'FontSize',8,...
    'Callback',@local_select_roimode,'Value', 0,'BackgroundColor',C.bgcol_1,...
    'ForegroundColor',C.fgcol_1,'FontSize',fsz);

d.F = F;
d.C = C;
d.mode = 'moculus';%'moculus' or 'photostim'
d.roimode = 'multi';%'scanfield' or 'multi'
d.stimloc = [];
d.PB = PB;
d.cb = cb;
d.CB = CB;
guidata(F,d);


function local_select_directory(hO, ed)
d = guidata(hO);
directory = uigetdir('Please Select the Directory with all the Files!');
directory = [directory,'\'];
[d, state] = dir_contents(directory,d);
if ~state
    return
end
d.root = directory;
C = d.C;
approved = 0;
%annotations
if iscell(d.mesfile)
    N = numel(d.mesfile);
else
    if ~isempty(d.mesfile)
        N = 1;
    else
        N = 0;
    end
end
if N == 1
    approved = 1;
end
mTB(1) = uicontrol(d.F,'style','text','Units','Normalized',...
    'Position',[0.1 0.6 0.5 0.05]);
set(mTB(1),'String',['Number of mes files: ', num2str(N)],'FontSize',10,...
    'foregroundcolor',C.fgcol_1,...
    'backgroundcolor',C.bgcol_1,'fontweight','bold','Tag','smalltext',...
    'HorizontalAlignment','Left');
if iscell(d.csvfile)
    N = numel(d.csvfile);
else
    if ~isempty(d.csvfile)
        N = 1;
    else
        N = 0;
    end
end
approved = approved & (N>0);
mTB(2) = uicontrol(d.F,'style','text','Units','Normalized',...
    'Position',[0.1 0.5 0.5 0.05]);
set(mTB(2),'String',['Number of csv files: ',num2str(N)],'FontSize',10,...
    'foregroundcolor',C.fgcol_1,...
    'backgroundcolor',C.bgcol_1,'fontweight','bold','Tag','smalltext',...
    'HorizontalAlignment','Left');

if iscell(d.infofile)
    N = numel(d.infofile);
else
    if ~isempty(d.infofile)
        N = 1;
    else
        N = 0;
    end
end
approved = approved & (N==1);
if N == 1
    str = 'yes';
else
    str = 'no';
end
mTB(3) = uicontrol(d.F,'style','text','Units','Normalized',...
    'Position',[0.1 0.4 0.5 0.05]);
set(mTB(3),'String',['info.txt is present: ',str],'FontSize',10,...
    'foregroundcolor',C.fgcol_1,...
    'backgroundcolor',C.bgcol_1,'fontweight','bold','Tag','smalltext',...
    'HorizontalAlignment','Left');
d.approved = approved;
%ADD FOR MESCROI FILE TOO
if approved
    d.PB(2).Enable = 'On';
end
guidata(d.F, d);

function local_done(hO, ed)
d = guidata(hO);
if strcmp(d.mode,'none')
    msgbox('experiment mode is not specified!')
    return
end
if strcmp(d.roimode,'none')
    msgbox('ROI mode is not specified!')
    return
end
vrlog2gor(d.mode,d.csvfilename,d.root);
local_VRSync(d.roimode,d.mesfile, d.root, d.stimloc);
msgbox('DONE! Gor file exported!');

function local_select_mode(hO, ed)
d = guidata(hO);
if sum([d.cb.Value]) == 0
    d.mode = 'none';
else
    d.mode = hO.String;
    d.cb(~ismember({d.cb.String},d.mode)).Value = 0;
end

guidata(d.F, d);

function local_select_roimode(hO, ed)
d = guidata(hO);
if sum([d.CB.Value]) == 0
    d.roimode = 'none';
else
    d.roimode = hO.Tag;
    d.CB(~ismember({d.CB.Tag},d.roimode)).Value = 0;
end
guidata(d.F, d);

function [d, state] = dir_contents(root,d)
state = 0;
allfiles = dir(root);
allfiles = allfiles(3:end);
allfiles = allfiles(~[allfiles.isdir]);
allextensions = {};
allfilepaths = {};
allnames = {};
for ifile = 1:numel(allfiles)
    filename = fullfile(allfiles(ifile).folder, allfiles(ifile).name);
    [filepath,name,ext] = fileparts(filename);
    allextensions{ifile} = ext;
    allnames{ifile} = name;
    allfilepaths{ifile} = filepath;
end

if sum(ismember(allextensions, '.mes')) == 0
    msgbox('no mes files found!');
    return
elseif sum(ismember(allextensions, '.mes')) > 1
    msgbox('more than one mes file found!');
    return
else
    mesfile = fullfile(allfilepaths(ismember(allextensions, '.mes')),...
        allnames(ismember(allextensions, '.mes')));
end
if sum(ismember(allextensions, '.csv')) == 0
    msgbox('no csv files found!');
    return
else
        csvfile = fullfile(allfilepaths(ismember(allextensions, '.csv')),...
            allnames(ismember(allextensions, '.csv')));
        csvfilename = allnames(ismember(allextensions, '.csv'));
        for iname = 1:numel(csvfilename)
            csvfilename{iname} = [csvfilename{iname},'.csv'];
        end
end
if sum(ismember(allextensions, '.txt')) == 0
    msgbox('no txt files found!')
else
    txtnames = allnames{ismember(allextensions, '.txt')};
    if ismember('info',lower(txtnames))
        infofile = fullfile(allfilepaths(ismember(allextensions, '.txt')),...
            allnames(ismember(allextensions, '.txt')));
    else
        msgbox('info.txt not found!')
        return
    end
end
state = 1;
d.mesfile = mesfile;
d.csvfile = csvfile;
d.csvfilename = csvfilename;
d.infofile = infofile;
guidata(d.F, d);

function local_VRSync(mode, filelocation, folder, stimlocation)
% mode='scanfield'
% filelocation='D:\OVR\M2\VR\M2_08_18\m2d1.mes';
% folder='D:\OVR\M2\VR\M2_08_18';
% stimlocation='D:\111111111KOKI\MouseAO\b1.csv'; 
% exportlocation='D:\OVR\M2\VR\M2_08_18'
exportlocation = folder;
% mode='multi';
%%units=[10 11 12 13];
[dname,pathML,name] = DirRead(folder,'Type','NoUI');
filt = PathFilter(pathML,'.gor',1);
mesfile = PathFilter(pathML,'.mes',1);
mesfile = PathFilter(mesfile,'.mescroi',0);
rois = PathFilter(pathML,'.mescroi',1);
folder = dname;
exportlocation = dname;
filelocation = mesfile{1};
A = importdata([folder '\info.txt']);
eval(A{1})
%
filtFilted = filt(1:length(units));
filt = natsortfiles(filtFilted);
%
for iunit = 1:length(units)
    out = AOExporterVR(filelocation,rois{iunit},stimlocation,exportlocation,mode,units(iunit))
    d(iunit).data = out;
end
%
data=[];
for iunit = 1:length(units)
   data = [data d(iunit).data]
end
save([exportlocation '\data.mat'],'data','-v7.3')
%
load([exportlocation '\data.mat'])
%
clear vr g stack
for (unitID=1:length(data))
    vr=loadWithoutFig(filt{unitID});
    
    for (cellID=1:length(data(1).CaTransient))
        x=data(unitID).CaTransient(cellID).event(1,:);
        y=data(unitID).CaTransient(cellID).event(2,:);
        
        fy=y(y~=0);
        fx=x(y~=0);
        xtype='double';
        ytype='double';
        dff = visc_percentile_dff(fx, fy, 8, 1000,0);
        %%dff=y;
        g(cellID)=gorobj(xtype,fx,ytype,dff);
        g(cellID)=set(g(cellID),'axis',2);
        %
        
    end
   
    [x y]=get(vr(end),'extract');
    trig= abs(diff(y));
    [id]=find(trig,1);
    shift=x(id);
    
    for ic=1:length(g)
          g(ic)=xscale(g(ic), 1/1000);
          g(ic)=xadd(g(ic), shift);
          g(ic)=set(g(ic),'name','cell');
          g(ic)=set(g(ic),'csoport',ic);
          g(ic)=set(g(ic),'vars',[ic data(unitID).CaTransient(ic).RealRoi ...
              data(unitID).CaTransient(ic).Realxyz(1)  ...
              data(unitID).CaTransient(ic).Realxyz(2)  ...
              data(unitID).CaTransient(ic).Realxyz(3)
              ] );
          g(ic)=set(g(ic),'varnames',{'ID';'ChessID';'X';'Y';'Z'});
          
    end
    stack=[g vr];
    gor2file([exportlocation '\' num2str(unitID) '.gor'],stack);
end


function dec = function_check
dec = 0;
if exist('natsort.m') == 0
    msgbox('Function "natsort" is not in the path!');
    return
end
if exist('AOExporterVR.m') == 0
    msgbox('Function "AOExporterVR" is not in the path!');
    return
end
if exist('PathFilter.m') == 0
    msgbox('Function "PathFilter" is not in the path!');
    return
end
if exist('vrlog2gor') == 0
    msgbox('Function "vrlog2gor" is not in the path!');
    return
end
dec = 1;