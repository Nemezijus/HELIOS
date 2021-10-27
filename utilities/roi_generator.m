function roi_generator(R_custom)
if nargin < 1
    R_custom = [];
end

F = figure;
set(F,'units', 'normalized', 'position', [0.449 0.432 0.245 0.112],'color','w',...
    'MenuBar','None','Name','ROI generator','NumberTitle','Off');


d.F = F;
d.mescloc = [];
d.rtmc_rois = {};
d.z = {};
d.root = {};
d.R_custom = R_custom;
d.Nsources = 0;
d.recursive = 0;

C.BT1 = 'w';
C.BTtxt1 = 'k';
PB(1) = uicontrol(F,'Style', 'Pushbutton', 'String', '.mesc file',...
    'Units','Normalized','Position', [0.01 0.54 0.45 0.45],...
    'background',C.BT1,'ForegroundColor',C.BTtxt1,'FontSize',10,...
    'Callback', @local_add,'Tag','MESC','FontWeight','Bold');

PB(2) = uicontrol(F,'Style', 'Pushbutton', 'String', ['source directory (', num2str(d.Nsources),')'],...
    'Units','Normalized','Position', [0.01 0.04 0.29 0.45],...
    'background',C.BT1,'ForegroundColor',C.BTtxt1,'FontSize',10,...
    'Callback', @local_add,'Tag','dir','FontWeight','Bold');

PB(3) = uicontrol(F,'Style', 'Pushbutton', 'String', 'Start',...
    'Units','Normalized','Position', [0.501 0.04 0.45 0.95],...
    'background',C.BT1,'ForegroundColor',C.BTtxt1,'FontSize',10,...
    'Callback', @local_start,'Tag','start','FontWeight','Bold');

PB(4) = uicontrol(F,'Style', 'Pushbutton', 'String', ['Reset'],...
    'Units','Normalized','Position', [0.31 0.04 0.15 0.45],...
    'background',[0.89,0.60 0.60],'ForegroundColor',C.BTtxt1,'FontSize',10,...
    'Callback', @local_reset,'Tag','reset','FontWeight','Bold');

d.PB = PB;
guidata(F,d);


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
        d.Nsources = d.Nsources+1;
        [di] = uigetdir('Please select the source directory');
        inside = dir(di);
        inside = inside(3:end);
        inside = inside(~[inside.isdir]);
        d.rtmc_rois{numel(d.rtmc_rois)+1} = collect_rois(inside);
        [d.z{numel(d.z)+1},d.root{numel(d.root)+1}] = collect_z(inside);
        set(d.PB(2), 'BackgroundColor',[0.3020 0.7451 0.9333]);
        set(d.PB(2), 'String', ['source directory (', num2str(d.Nsources),')']);
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
z = [];
for icont = 1:numel(cont)
    fpath = [cont(icont).folder,'\',cont(icont).name];
    [a,b,c] = fileparts(fpath);
    if strcmp([b,c], 'zcoord.txt')
        z = fpath;
    end
end

function local_start(hO, ed)
d = guidata(hO);
d_copy = d;

for icycle = 1:d.Nsources
    
    if ~d.recursive
        d.rtmc_rois = d_copy.rtmc_rois{icycle};
        d.z = d_copy.z{icycle};
        d.root = d_copy.root{icycle};
    end
    %z coordinate parse
    if isempty(d.z)
        msgbox('zcoord.txt file is missing! Terminating!')
        return
    end
    disp('STARTING');
    A = importdata(d.z);
    eval(A{1})
    if numel(d.rtmc_rois) ~= numel(zcoord)
        error('number of z values does not match number of mescroi files!')
    end
    d.zcoord = zcoord;
    Nlayers = numel(zcoord);
    %z coordinates parsed
    
    %initializing logging
    d.root = [d.root,'\ROIsets'];
    mkdir(d.root);
    dvec = datevec(now);
    dvec(end) = round(dvec(end));
    for iv = 1:numel(dvec)
        dstr{iv} = num2str(dvec(iv));
    end
    dstr = strjoin(dstr,'_');
    dirname = [d.root,'\',dstr];
    if d.recursive
        dirname = [dirname,'_COMBO'];
    end
    mkdir(dirname);
    logname = [dirname,'\log.txt'];
    log_init(d, logname);
    %logging initialized
    
    
    
    if (isempty(d.R_custom))
        
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
    end
    if (~isempty(d.R_custom))
        RR = d.R_custom;
        Nlayers = numel(RR);
    end
    RRR(icycle).set = RR;
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
    
    logme(logname,['Creating centroid excel files!'],datestr(now));
    for ilayer = 1:numel(zcoord)
        floc = d.rtmc_rois{ilayer};
        [a,b,c] = fileparts(floc);
        floc = [dirname,'\',b,'_centers',c];
        if (~isempty(d.R_custom))
            parse_mescroi_onacid(floc, d.mescloc, dirname, zcoord(ilayer), RR(ilayer).R);
        else
            MR = parse_mescroi_onacid(floc, d.mescloc, dirname, zcoord(ilayer));
        end
    end
    logme(logname,['Centroid excel files created!']);
    
    logme(logname,'');
    logme(logname,['DONE ',datestr(now)]);
    disp('FINISHED');
    clear dstr;
    if d.recursive
        try
            close (d.F);
        catch
            disp("figure already closed");
        end
    else
        set(d.PB(2), 'String', ['source directory (', num2str(d.Nsources-icycle),')']);
    end

end

if numel(d_copy.rtmc_rois) > 1 & ~d.recursive
    disp('deoverlapping!');
    Rclean = deoverlap(RRR);
    d.R_custom = Rclean;
    d.recursive = 1;
    d.Nsources = 1;
    d.original = d_copy;
    guidata(d.F, d);
    
    local_start(d.F, []);
end

function log_init(d,logname)
fid = fopen(logname , 'wt' );
try
    
    
    string = ['USER: ',getenv('username'), ' COMPUTER: ', getenv('computername')];
    fprintf( fid, '%s\n', string);
    
    fprintf( fid, '%s\n', '');
    
    string = ['MESc file: '];
    fprintf( fid, '%s\n', string);
    
    string = [d.mescloc];
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

function local_reset(hO, ed)
d = guidata(hO);
d.mescloc = [];
d.rtmc_rois = {};
d.z = {};
d.root = {};
d.R_custom = [];
d.Nsources = 0;
d.recursive = 0;
d.original = [];

set(d.PB(1), 'background', 'w');
set(d.PB(2), 'background', 'w');
set(d.PB(2),'String', ['source directory (', num2str(d.Nsources),')']);
guidata(d.F, d);

