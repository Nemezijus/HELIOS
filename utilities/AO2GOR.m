function AO2GOR
%AO2GOR - interactive GUI which creates a gor file for every unit in the
%mes file. In order to process, all the necessary data has to be in the same
%directory. Requires to have the same amount of behavior csv files as there
%are units in the mes file. The directory also must contain info.txt file 
%which has only one line of text 'unit = [];', where in square brackets 
%user has specified the numerical unit values. e.g. 'unit = [11 12 13 14 15];'
C.bgcol_1 = 'w';
C.fgcol_1 = 'k';

F = figure;
PB(1) = uicontrol(F,'Style', 'Pushbutton', 'String', 'Select Directory',...
    'Units','Normalized','Position', [0.4, 0.8 0.2 0.1],...
    'background',C.bgcol_1,'ForegroundColor',C.fgcol_1,'FontSize',10,...
    'Callback', @local_select_directory,'Tag','figure','FontWeight','Bold');

PB(2) = uicontrol(F,'Style', 'Pushbutton', 'String', 'Done',...
    'Units','Normalized','Position', [0.4, 0.2 0.2 0.1],...
    'background',C.bgcol_1,'ForegroundColor',C.fgcol_1,'FontSize',10,...
    'Callback', @local_done,'Tag','figure','FontWeight','Bold');

d.F = F;
d.mode = 'moculus';%'moculus' or 'photostim'
d.roimode = 'multi';%'scanfield' or 'multi'
d.stimloc = [];
guidata(F,d);


function local_select_directory(hO, ed)
d = guidata(hO);
directory = uigetdir('Please Select the Directory with all the Files!');
d = dir_contents(directory,d);
d.root = directory;
guidata(d.F, d);

function local_done(hO, ed)
d = guidata(hO);
vrlog2gor(d.mode,d.root,d.csvfile);
local_VRSync(d.roimode,d.mesfile, d.root, d.stimloc);
msgbox('DONE! Gor file exported!');

function d = dir_contents(root,d)

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
    for icsv = 1:sum(ismember(allextensions, '.csv'))
        csvfile{icsv} = fullfile(allfilepaths(ismember(allextensions, '.csv')),...
            allnames(ismember(allextensions, '.csv')));
    end
end
if sum(ismember(allextensions, '.txt')) == 0
    msgbox('no txt files found!')
else
    txtnames = allnames{ismember(allextensions, '.txt')};
    if ismember('info',lower(txtnames))
        infofile = fullfile(,);
    else
        msgbox('info.txt not found!')
        return
    end
end
d.mesfile = mesfile;
d.csvfile = csvfile;
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
%%
filtFilted = filt(1:length(units));
filt = natsortfiles(filtFilted);
%%
for iunit = 1:length(units)
    out = AOExporterVR(filelocation,rois{iunit},stimlocation,exportlocation,mode,units(iunit))
    d(iunit).data = out;
end
%%
data=[];
for iunit = 1:length(units)
   data = [data d(iunit).data]
end
save([exportlocation '\data.mat'],'data','-v7.3')
%%
load([exportlocation '\data.mat'])
%%
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
        %%
        
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
