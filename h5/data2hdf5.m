function out = data2hdf5(file_loc, data, stagetag)
% out = data2hdf5(file_loc, data, tag) - stores experiment data from data
% file into hdf5 file with specified location file_loc. stagetag - identifier of
% the data file (a short struct) stagetag.idx and stagetag.id
% part of HELIOS
Nunits = numel(data);
Nroi = numel(data(1).logicalROI);

istage = stagetag.idx;
stagestr = stagetag.id;
cloc = strjoin({'','DATA',['STAGE_',num2str(istage)]},'/');
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

%STIMLIST
stimlist = [999, 0:45:315];
h5writeatt(file_loc,cloc,'STIMLIST',stimlist);
for iunit = 1:Nunits
    cloc = strjoin({'','DATA',['STAGE_',num2str(istage)],...
        ['UNIT_',num2str(data(iunit).MeasureNumber)]},'/');
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
    h5writeatt(file_loc,cloc, 'REPID', data(iunit).PredictedSession);
    %STIMID
    h5writeatt(file_loc,cloc, 'STIMID', data(iunit).PredictedOrientationID);
    %TIMEUNITS
    h5writeatt(file_loc,cloc, 'TIMEUNITS', 'ms');
    for iroi = 1:Nroi
        cloc = strjoin({'','DATA',['STAGE_',num2str(istage)],...
            ['UNIT_',num2str(data(iunit).MeasureNumber)],...
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
out = 1;

function [MP,LUT] = maxProjection(data)
for frame=1:length(data)
    frameSet(:,:,frame)=data(frame).meanPic;
end

MP = max(frameSet,[],3);
LUT = data(1).gmap;
