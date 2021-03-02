function out = moculus_data2hdf5(file_loc, data, stagetag, behave_file_loc)
% out = moculus_data2hdf5(file_loc, data, stagetag, behave_file_loc) - stores
% experiment data from data file into hdf5 file with specified location file_loc.
% stagetag - identifier of the data file (a short struct)
% stagetag.idx and stagetag.id
% behave_file_loc - path to the corresponding behave csv struct for the
% same day as is the data file
%
% this is an adaptation for Moculus project
% part of HELIOS
if isempty(data)
    nodata = 1;
else
    nodata = 0;
end


istage = stagetag.idx;
stagestr = stagetag.id;
cloc = strjoin({'','DATA',['STAGE_',num2str(istage)]},'/');
if ~nodata
    Nunits = numel(data);
    Nroi = numel(data(1).logicalROI);
    [MP,LUT] = maxProjection(data);
    %MAXPROJ
    loc = [cloc,'/MAXPROJ'];
    allocatespace(file_loc, {MP}, {loc});
    storedata(file_loc, {MP}, {loc});
    %MAXPROJLUT
    loc = [cloc,'/MAXPROJLUT'];
    allocatespace(file_loc, {LUT}, {loc});
    storedata(file_loc, {LUT}, {loc});
    %DATAPATH
    try
        h5writeatt(file_loc,cloc,'DATAPATH',data(1).Filename);
    catch
        h5writeatt(file_loc,cloc,'DATAPATH','');
    end
    %STAGEID
    h5writeatt(file_loc,cloc,'STAGEID',stagestr);
end



%STIMLIST
%NO STIMULI SO FAR
% stimlist = [999, 0:45:315];
% h5writeatt(file_loc,cloc,'STIMLIST',stimlist);
if nodata
    Nunits = numel(behave_file_loc);
end
for iunit = 1:Nunits
    
    if ~nodata
        %%%%%%%%%%%%%%%%----IMAGING----%%%%%%%%%%%%%
        cloc = strjoin({'','DATA',['STAGE_',num2str(istage)],...
            ['UNIT_',num2str(iunit)],['IMAGING']},'/');
        %XDATA
        loc = [cloc,'/XDATA'];
        d = data(iunit).CaTransient(1).event(1,:)';
        allocatespace(file_loc, {d}, {loc});
        storedata(file_loc, {d}, {loc});
        %MEANFRAME
        loc = [cloc,'/MEANFRAME'];
        d = data(iunit).meanPic;
        allocatespace(file_loc, {d}, {loc});
        storedata(file_loc, {d}, {loc});
        %MEANFRAMELUT
        loc = [cloc,'/MEANFRAMELUT'];
        d = data(iunit).gmap;
        allocatespace(file_loc, {d}, {loc});
        storedata(file_loc, {d}, {loc});
        %attributes
        %REPID
        try
            h5writeatt(file_loc,cloc, 'REPID', data(iunit).PredictedSession);
        catch
            h5writeatt(file_loc,cloc, 'REPID', 'NaN');
        end
        %STIMID
        try
            h5writeatt(file_loc,cloc, 'STIMID', data(iunit).PredictedOrientationID);
        catch
            h5writeatt(file_loc,cloc, 'STIMID', 'NaN');
        end
        %TIMEUNITS
        h5writeatt(file_loc,cloc, 'TIMEUNITS', 'ms');
        for iroi = 1:Nroi
            cloc = strjoin({'','DATA',['STAGE_',num2str(istage)],...
                ['UNIT_',num2str(iunit)],['IMAGING']...
                ['ROI_',num2str(iroi)]},'/');
            %YDATA
            loc = [cloc, '/YDATA'];
            d = data(iunit).CaTransient(iroi).event(2,:)';
            allocatespace(file_loc, {d}, {loc});
            storedata(file_loc, {d}, {loc});
            %ROIMASK
            if iunit == 1
                image = data(iunit).meanPic;
                roi_indexed = data(iunit).logicalROI(iroi).roi;
                logicalROI = zeros(size(image));
                logicalROI(uint64(roi_indexed)) = 1;
                maskpath = strjoin({'/ANALYSIS',['ROI_',num2str(iroi)],['STAGE_',num2str(istage)],'ROIMASK'},'/');
                allocatespace(file_loc, {logicalROI}, {maskpath});
                storedata(file_loc, {logicalROI}, {maskpath});
                %DIMENSIONS FOR AO FF
                setup = h5readatt(file_loc,'/DATA','SETUP');
                if strcmp(setup,'ao')
                    dimspath = strjoin({'/ANALYSIS',['ROI_',num2str(iroi)],['STAGE_',num2str(istage)]},'/');
                    dims = data(iunit).logicalROI(iroi).dims;
                    h5writeatt(file_loc,dimspath, 'DIMENSIONS', dims);
                    try
                        ffwidth = data(iunit).attribs(1).TransversePixNum;
                        ffheight = data(iunit).attribs(1).AO_collection_usedpixels;
                        FFsize = [ffwidth, ffheight];
                    catch
                        FFsize = [];
                    end
                    h5writeatt(file_loc,dimspath, 'FFSIZE', FFsize);
                end
            end
            %attributes
            %CENTROID
            h5writeatt(file_loc,cloc, 'CENTROID', data(iunit).logicalROI(iroi).centroid);
            %POLYGON
            h5writeatt(file_loc,cloc, 'POLYGON', data(iunit).CaTransient(iroi).poly);
            %ROIID
            h5writeatt(file_loc,cloc, 'ROIID', data(iunit).CaTransient(iroi).RoiID);
            %UNIQUEID
            h5writeatt(file_loc,cloc, 'UNIQUEID', data(iunit).CaTransient(iroi).RoiIDReal);
            %X, Y, Z
            try
                h5writeatt(file_loc,cloc,'X',data(iunit).CaTransient(iroi).Realxyz(1));
            catch
                h5writeatt(file_loc,cloc,'X',[]);
            end
            try
                h5writeatt(file_loc,cloc,'Y',data(iunit).CaTransient(iroi).Realxyz(2));
            catch
                h5writeatt(file_loc,cloc,'Y',[]);
            end
            try
                h5writeatt(file_loc,cloc,'Z',data(iunit).CaTransient(iroi).Realxyz(2));
            catch
                h5writeatt(file_loc,cloc,'Z',[]);
            end
        end
    end
    
    
    
    
    %%%%%%%%%%%%%%%%----BEHAVIOR----%%%%%%%%%%%%%
    clocbeh = strjoin({'','DATA',['STAGE_',num2str(istage)],...
        ['UNIT_',num2str(iunit)],['BEHAVIOR/']},'/');
    
    cbehave = behave_file_loc{iunit};
    fid = fopen(cbehave);
    T = textscan(fid,'%s','Delimiter',{'/n'},'CollectOutput',1);
    T = T{1,1};
    fclose(fid);
    T_names = T(1);
    T_names = strsplit(T_names{:},';');
    if numel(T) > 1
        T_data = T(2:end);
        T_data = datamatrix(T_data);
    else
        T_data = [];
    end
    T = T_data;
    
    nsamples = 1;
    cstrings = {'time','position','velocity','luminance'};
    for ics = 1:numel(cstrings)
        cstring = cstrings{ics};
        v = getfromcsv(cstring, T_names, T, nsamples);
        if strcmp(cstring,'time')
            nsamples = numel(v);
        end
        allocatespace(file_loc, {v}, {[clocbeh,upper(cstring)]});
        storedata(file_loc, {v}, {[clocbeh,upper(cstring)]});
    end
    
    cloc = [clocbeh,'ZONES/NEUTRAL/'];
    cstrings = {'cloud','black'};
    for ics = 1:numel(cstrings)
        cstring = cstrings{ics};
        v = getfromcsv(cstring, T_names, T, nsamples);
        allocatespace(file_loc, {v}, {[cloc,upper(cstring)]});
        storedata(file_loc, {v}, {[cloc,upper(cstring)]});
    end
    
    cloc = [clocbeh,'ZONES/CONTROL/'];
    if ismember('lick',lower(T_names))
        cstrings = {'right','aversive'};
        h5writeatt(file_loc,clocbeh,'PROTOCOL','photostim');
    else
        cstrings = {'left', 'right'};
        h5writeatt(file_loc,clocbeh,'PROTOCOL','moculus');
    end
    for ics = 1:numel(cstrings)
        cstring = cstrings{ics};
        v = getfromcsv(cstring, T_names, T, nsamples);
        allocatespace(file_loc, {v}, {[cloc,upper(cstring)]});
        storedata(file_loc, {v}, {[cloc,upper(cstring)]});
    end
    
    cloc = [clocbeh,'ZONES/DISCRIM/'];
    if ismember('lick',lower(T_names))
        cstrings = {'left'};
    else
        cstrings = {'aversive'};
    end
    
    for ics = 1:numel(cstrings)
        cstring = cstrings{ics};
        v = getfromcsv(cstring, T_names, T, nsamples);
        if strcmp(cstring,'left')
            allocatespace(file_loc, {v}, {[cloc,'REWARD']});
            storedata(file_loc, {v}, {[cloc,'REWARD']});%THIS IS VERY CONFUSING MIGHT NEED TO CHANGE STUFF HERE
        else
            allocatespace(file_loc, {v}, {[cloc,upper(cstring)]});
            storedata(file_loc, {v}, {[cloc,upper(cstring)]});
        end
    end
    
    
    cloc = [clocbeh,'PORTS/'];
    cstrings = {'port_a','port_b','port_c'};
    for ics = 1:numel(cstrings)
        cstring = cstrings{ics};
        v = getfromcsv(cstring, T_names, T, nsamples);
        allocatespace(file_loc, {v}, {[cloc,upper(cstring)]});
        storedata(file_loc, {v}, {[cloc,upper(cstring)]});
    end
    
    cloc = [clocbeh,'EVENTS/'];
    cstrings = {'lick','lickdelta','licklock','trigger','teleport'};
    for ics = 1:numel(cstrings)
        cstring = cstrings{ics};
        v = getfromcsv(cstring, T_names, T, nsamples);
        if strcmp(cstring, 'trigger')
            [idxs, ~] = find(v);
            trigger_idx = idxs(1);
        end
        
        allocatespace(file_loc, {v}, {[cloc,upper(cstring)]});
        storedata(file_loc, {v}, {[cloc,upper(cstring)]});
    end
    
    %calculate TIME_OFFSET
    if ~isempty(T)
        t = getfromcsv('time', T_names, T);
        TIME_OFFSET = t(trigger_idx);
    else
        TIME_OFFSET = NaN;
    end
    h5writeatt(file_loc,clocbeh,'TIME_OFFSET',TIME_OFFSET);
end
out = 1;

function [MP,LUT] = maxProjection(data)
for frame=1:length(data)
    frameSet(:,:,frame)=data(frame).meanPic;
end

MP = max(frameSet,[],3);
LUT = data(1).gmap;

function v = getfromcsv(cstring, allnames, T, N)
if nargin == 3
    N = [];
end
if ~isempty(T) && ismember(cstring, lower(allnames))
    v = T(:,ismember(lower(allnames), cstring));%(:,ismember(allnames,'time'));
    %     if iscell(v)
    %         if ischar(v{1})
    %             v = replace(v,',','.');% a wild guess
    %             v = cellfun(@str2double,v);
    %         end
    %     end
else
    v = repmat(NaN,N,1);
end

function M = datamatrix(T)
nT = cellfun(@(s) replace(strsplit(s, ';'),',','.'), T, 'UniformOutput', false);
le = cellfun(@(s) numel(s),nT);
if le(end) ~= le(end-1)
    nT = nT(1:end-1);
end
T = vertcat(nT{:});
M = str2double(T);

%  cbehave = behave_file_loc{iunit};
%     T = readtable(cbehave);
%     T_names_orig = T.Properties.VariableNames;
%
%     if numel(T_names_orig) == 1%smashed together into one cell
%         [~,B] = xlsread(cbehave);
%         T_names = strsplit(B{1},';');
%         T_names(cellfun('isempty',T_names)) = [];
%         T_names_orig = T_names;
%     else
%         T_names = T_names_orig;
%     end
%
%     if ~ismember('time',T_names_orig)
%         [~,B] = xlsread(cbehave);
%         T_names = strsplit(B{1},';');
%         T_names(cellfun('isempty',T_names)) = [];
%         T.Properties.VariableNames = T_names;
%     end