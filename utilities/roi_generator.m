function roi_generator
% if numel(img) == 2
%     img = zeros(img);
% end

F = figure;
set(F,'units', 'normalized', 'position', [0.449 0.432 0.245 0.112],'color','w',...
    'MenuBar','None','Name','ROI generator','NumberTitle','Off');
C.BT1 = 'w';
C.BTtxt1 = 'k';
PB(1) = uicontrol(F,'Style', 'Pushbutton', 'String', '.mesc file',...
    'Units','Normalized','Position', [0.01 0.54 0.45 0.45],...
    'background',C.BT1,'ForegroundColor',C.BTtxt1,'FontSize',10,...
    'Callback', @local_add,'Tag','MESC','FontWeight','Bold');

PB(2) = uicontrol(F,'Style', 'Pushbutton', 'String', 'source directory',...
    'Units','Normalized','Position', [0.01 0.04 0.45 0.45],...
    'background',C.BT1,'ForegroundColor',C.BTtxt1,'FontSize',10,...
    'Callback', @local_add,'Tag','dir','FontWeight','Bold');

PB(3) = uicontrol(F,'Style', 'Pushbutton', 'String', 'Start',...
    'Units','Normalized','Position', [0.501 0.04 0.45 0.95],...
    'background',C.BT1,'ForegroundColor',C.BTtxt1,'FontSize',10,...
    'Callback', @local_start,'Tag','start','FontWeight','Bold');

d.F = F;
d.PB = PB;
d.mescloc = [];
d.rtmc_rois = [];
d.z = [];
guidata(F,d);


% root = 'N:\DATA\andrius.plauska\test\RTMC_test_run_2\';
% fl{1} = [root,'20210427_mouse686_visualstimulation_hsaf_layer1.mescroi'];
% fl{2} = [root,'20210427_mouse686_visualstimulation_hsaf_layer2.mescroi'];
% fl{3} = [root,'20210427_mouse686_visualstimulation_hsaf_layer3.mescroi'];
% fl{4} = [root,'20210427_mouse686_visualstimulation_hsaf_layer4.mescroi'];
% fl{5} = [root,'20210427_mouse686_visualstimulation_hsaf_layer5.mescroi'];
% fl{6} = [root,'20210427_mouse686_visualstimulation_hsaf_layer6.mescroi'];
% 
% zcoord = [-15864.7, -15834.7, -15804.7, -15774.7, -15744.7, -15714.7];
% for icount = 1:6
%     floc = fl{icount};
%     [a,b,c] = fileparts(floc);
%     saveloc = [a,'\R_',num2str(icount),'.mat'];
%     R = RTMC_mescroi_refinement(floc, info, img, mescloc, zcoord(icount), icount-1);
%     save(saveloc,'R');
%     disp(['file ', num2str(icount), ' saved']);
% end

function local_add(hO, ed)
d = guidata(hO);

switch hO.Tag
    case 'MESC'
        [a,b,c] = uigetfile('*.mesc','Please Select the .mesc file');
        if a ~=0 
            d.mescloc = [b,a];
            set(d.PB(1), 'BackgroundColor',[0.3020 0.7451 0.9333]);
        end
    case 'dir'
        [di] = uigetdir('Please select the source directory');
        inside = dir(di);
        inside = inside(3:end);
        inside = inside(~[inside.isdir]);
        d.rtmc_rois = collect_rois(inside);
        [d.z,d.root] = collect_z(inside);
end

guidata(d.F, d)


function r = collect_rois(cont)
r = {};
% counter = 1;
for icont = 1:numel(cont)
    fpath = [cont(icont).folder,'\',cont(icont).name];
    [a,b,c] = fileparts(fpath);
    bb = strsplit(b,'_');
    bb = bb{end};
    if strcmp(c, '.mescroi') & strcmp(bb(1:end-1),'layer')
        r{str2num(bb(end))} = fpath;
%         counter = counter+1;
    end
end

function [z,a] = collect_z(cont)
z = '';
for icont = 1:numel(cont)
    fpath = [cont(icont).folder,'\',cont(icont).name];
    [a,b,c] = fileparts(fpath);
    if strcmp([b,c], 'zcoord.txt')
        z = fpath;
    end
end

function local_start(hO, ed)
d = guidata(hO);
A = importdata(d.z);
eval(A{1})
if numel(d.rtmc_rois) ~= numel(zcoord)
    error('number of z values does not match number of mescroi files!')
end
d.zcoord = zcoord;
Nlayers = numel(zcoord);
d.root = [d.root,'\ROIsets'];
mkdir(d.root);

dvec = datevec(now);
dvec(end) = round(dvec(end));
for iv = 1:numel(dvec)
    dstr{iv} = num2str(dvec(iv));
end
dstr = strjoin(dstr,'_');
dirname = [d.root,'\',dstr];
mkdir(dirname);
logname = [dirname,'\log.txt'];
log_init(d, logname);

info = h5info(d.mescloc);
logme(logname, 'Info of MESc file retrieved!');

Nunits = numel(info.Groups.Groups);
logme(logname, ['Number of units: ',num2str(Nunits)]);
logme(logname,'');
logme(logname, 'UNIT DIMENSIONS: ', 1);
for iunit = 1:Nunits
    XDim = info.Groups.Groups(iunit).Attributes(contains({info.Groups.Groups(iunit).Attributes.Name},'XDim')).Value;
    YDim = info.Groups.Groups(iunit).Attributes(contains({info.Groups.Groups(iunit).Attributes.Name},'YDim')).Value;
    ZDim = info.Groups.Groups(iunit).Attributes(contains({info.Groups.Groups(iunit).Attributes.Name},'ZDim')).Value;
    logme(logname, ['UNIT ',num2str(iunit),' : ', num2str(XDim),'x',num2str(YDim),'x',num2str(ZDim)]);
end


img = zeros(XDim, YDim);
for icount = 1:Nlayers
    logme(logname,'');
    logme(logname, ['Working on Layer: ', num2str(icount)]);
    floc = d.rtmc_rois{icount};
    [a,b,c] = fileparts(floc);
%     saveloc = [a,'\R_',num2str(icount),'.mat'];
    R = RTMC_mescroi_refinement(floc, info, img, d.mescloc,...
        d.zcoord(icount), icount-1, dirname, logname);
    RR(icount).R = R;
    save([dirname,'\R_', num2str(icount)],'R');
    disp(['file ', num2str(icount), ' saved']);
    logme(logname, ['Layer: ', num2str(icount),' processed!']);
end
save([dirname,'\R_all'],'RR');
disp('Done translating mescroi files!');
disp('Making mean projections!');

logme(logname,'');
logme(logname, ['Creating mean images of the layers. ',datestr(now)]);
PROJ = multilayer_projections(d.mescloc, Nlayers);
save([dirname,'\PROJ'],'PROJ');
logme(logname, ['mean images of the layers created and saved ']);
logme(logname,'');

logme(logname, ['Visualizing contours on mean images ',datestr(now)]);
multilayer_rois(PROJ, RR, dirname);
logme(logname, ['Contours on mean images saved ']);

logme(logname,'');
logme(logname,['DONE ',datestr(now)]);

function log_init(d,logname)
try
    fid = fopen(logname , 'wt' );
    
    string = ['MESc file: '];
    fprintf( fid, '%s\n', string);
    
    string = [,d.mescloc];
    fprintf( fid, '%s\n', string);
    
    fprintf( fid, '%s\n', '');
    
    string = ['mescroi files: '];
    fprintf( fid, '%s\n', string);
    
    for iroi = 1:numel(d.rtmc_rois)
        string = d.rtmc_rois{iroi};
        fprintf( fid, '%s\n', string);
    end
    
    fprintf( fid, '%s\n', '');
    
    string = ['Starting Conversion! DateTime: ', datestr(now)];
    fprintf( fid, '%s\n', string);
    
    string = ['Number of layers: ', num2str(numel(d.rtmc_rois))];
    fprintf( fid, '%s\n', string);
    
    string = ['Layer depths: ',num2str(d.zcoord)];
    fprintf( fid, '%s\n', string);
    
    fprintf( fid, '%s\n', '');
catch
    fclose(fid);
end
fclose(fid);

