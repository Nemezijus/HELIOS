function out = moculus_datareduced2hdf5(file_loc, data, stagetag)
% out = moculus_datareduced2hdf5(file_loc, data, tag) - stores experiment data from data
% file into hdf5 file with specified location file_loc. stagetag - identifier of
% the data file (a short struct) stagetag.idx and stagetag.id
% this version of data2hdf5 runs a single ROI data extraction to get
% essential information needed for h5 file, used only for OnAcid embedding
% adapted for moculus data 
% part of HELIOS
Nunits = numel(data);
Nroi = data(1).Nroi;

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
% stimlist = [999, 0:45:315];
% h5writeatt(file_loc,cloc,'STIMLIST',stimlist);

disp('Converting mescroi file to poly struct');
setup = h5readatt(file_loc,'/DATA','SETUP');
R = mescroi2poly(data(1).roiSpec, data(1).geomTrans, setup, data(1));
disp('Conversion done');
for iunit = 1:Nunits
    disp(['Current Unit: ',num2str(iunit)]);
    parentloc = strjoin({'','DATA',['STAGE_',num2str(istage)],...
        ['UNIT_',num2str(iunit)]},'/');
    cloc = strjoin({'','DATA',['STAGE_',num2str(istage)],...
        ['UNIT_',num2str(data(iunit).MeasureNumber)],'IMAGING'},'/');
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
    h5writeatt(file_loc,parentloc, 'REPID', data(iunit).PredictedSession);
    %STIMID
    h5writeatt(file_loc,parentloc, 'STIMID', data(iunit).PredictedOrientationID);
    try
        h5writeatt(file_loc,parentloc, 'STIM', data(iunit).ProtocolStim);
    catch
        h5writeatt(file_loc,parentloc, 'STIM', 'NaN');
    end
    %TIMEUNITS
    h5writeatt(file_loc,cloc, 'TIMEUNITS', 'ms');

    disp('Storing ROI data for this unit');
    tic
    for iroi = 1:Nroi
        cloc = strjoin({'','DATA',['STAGE_',num2str(istage)],...
            ['UNIT_',num2str(data(iunit).MeasureNumber)],'IMAGING'...
            ['ROI_',num2str(iroi)]},'/');
        %YDATA
        loc = [cloc, '/YDATA'];
        d = repmat(NaN, size(data(iunit).CaTransient(1).event(1,:)'));
%         d = data(iunit).CaTransient(iroi).event(2,:)';
        allocatespace(file_loc, {d}, {loc});
        storedata(file_loc, {d}, {loc});
        %ROIMASK
        if iunit == 1
            image = data(iunit).meanPic;
            [logicalROI, roi_indexed] = roimask(R(iroi).poly, image);
            logicalROI = uint64(logicalROI);
%             roi_indexed = data(iunit).logicalROI(iroi).roi;
%             logicalROI = zeros(size(image));
%             logicalROI(uint64(roi_indexed)) = 1;
            maskpath = strjoin({'/ANALYSIS',['ROI_',num2str(iroi)],['STAGE_',num2str(istage)],'ROIMASK'},'/');
            allocatespace(file_loc, {logicalROI}, {maskpath});
            storedata(file_loc, {logicalROI}, {maskpath});
            %DIMENSIONS FOR AO FF
            
        end
        %attributes
        POLY = R(iroi).poly;
        xpoly = POLY(1,:);
        ypoly = POLY(2,:);
        xpoly = xpoly(~isnan(xpoly));
        ypoly = ypoly(~isnan(ypoly));
        POLY = [];
        POLY(1,:) = xpoly;
        POLY(2,:) = ypoly;
        %CENTROID
        h5writeatt(file_loc,cloc, 'CENTROID', []);%data(iunit).logicalROI(iroi).centroid);
        %POLYGON
        h5writeatt(file_loc,cloc, 'POLYGON', POLY);%data(iunit).CaTransient(iroi).poly);
        %ROIID
        h5writeatt(file_loc,cloc, 'ROIID', iroi);%data(iunit).CaTransient(iroi).RoiID);
        %UNIQUEID
        h5writeatt(file_loc,cloc, 'UNIQUEID', iroi);%data(iunit).CaTransient(iroi).RoiIDReal);
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
    
    t = toc;
    disp(['ROI data stored, time spent: ',num2str(t)]);

end
out = 1;

function [MP,LUT] = maxProjection(data)
for frame=1:length(data)
    frameSet(:,:,frame)=data(frame).meanPic;
end

MP = max(frameSet,[],3);
LUT = data(1).gmap;
