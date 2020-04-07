function info = visc2hdf5(fileloc, VISC, flag)
% info = visc2hdf5(fileloc, VISC, flag) - regroups data from VISC structs
% to a single hdf5 file format. fileloc - a full path with file name and
% extension for the hdf5 storage. VISC - struct array containing all
% relevant VISC structs. flag - reserved for future use

if nargin < 3
    flag = [];
end
hdf5create(fileloc, VISC, 'create');
hdf5attrwrite(fileloc, VISC);
% hdfcreate(fileloc, VISC,'create');
% hdfcreate(fileloc, VISC,'store');
% hdfattrwrite(fileloc, VISC);



info = h5info(fileloc);

function hdf5create(fileloc, VISC, flag)
NROI = numel(VISC.ROI);
NSTAGES = numel(VISC.ROI(1).STAGE);
if strcmp(flag,'create')
    create = 1;
else
    create = 0;
end
dataroot = '/DATA';

MN = visc_remap_measurenumber(VISC.ROI);
for istage = 1:NSTAGES
    STAGEstr = ['STAGE_',num2str(istage)];
    NUNITS = numel(MN.STAGE(istage).mn);
    %MAXPROJ
    dataloc = strjoin({dataroot,STAGEstr,'MAXPROJ'},'/');
    data = VISC.IMG.STAGE(istage).MaxProj;
    createorwrite(fileloc, dataloc, data, 'create');
    createorwrite(fileloc, dataloc, data, 'write');
    %MAXPROJLUT
    dataloc = strjoin({dataroot,STAGEstr,'MAXPROJLUT'},'/');
    data = VISC.IMG.STAGE(istage).MaxProjLUT;
    createorwrite(fileloc, dataloc, data, 'create');
    createorwrite(fileloc, dataloc, data, 'write');
    for iunit = 1:NUNITS
        UNITstr = ['UNIT_',num2str(iunit)];
        logv = MN.STAGE(istage).mn == iunit;
        istim = MN.STAGE(istage).stim(logv);
        irep = MN.STAGE(istage).rep(logv);
        loc = strjoin({dataroot,STAGEstr,UNITstr},'/');
        %XDATA
        dataloc = strjoin({loc,'XDATA'},'/');
        data = VISC.ROI(1).STAGE(istage).STIM(istim).Xdata;
        createorwrite(fileloc, dataloc, data, 'create');
        createorwrite(fileloc, dataloc, data, 'write');
        %MAXPROJ
        dataloc = strjoin({loc,'MEANFRAME'},'/');
        data = VISC.IMG.STAGE(istage).STIM(istim).REP(irep).meanPic;
        createorwrite(fileloc, dataloc, data, 'create');
        createorwrite(fileloc, dataloc, data, 'write');
        %MAXPROJLUT
        dataloc = strjoin({loc,'MEANFRAMELUT'},'/');
        data = VISC.IMG.STAGE(istage).STIM(istim).REP(irep).LUT;
        createorwrite(fileloc, dataloc, data, 'create');
        createorwrite(fileloc, dataloc, data, 'write');
        
        for iroi = 1:NROI
            ROIstr = ['ROI_',num2str(iroi)];
            loc = strjoin({dataroot,STAGEstr,UNITstr,ROIstr},'/');
            
            %YDATA
            data = VISC.ROI(iroi).STAGE(istage).STIM(istim).Ydata(irep,:);
            dataloc = strjoin({loc,'YDATA'},'/');
            createorwrite(fileloc, dataloc, data, 'create');
            createorwrite(fileloc, dataloc, data, 'write');
            
            %ROIBOX
            data = VISC.POLY(iroi).STAGE(istage).STIM(istim).REP(irep).ROIbox;
            dataloc = strjoin({loc,'ROIBOX'},'/');
            createorwrite(fileloc, dataloc, data, 'create');
            createorwrite(fileloc, dataloc, data, 'write');
            
            %BG
            fn = fieldnames(VISC.ROI(iroi).STAGE(istage).STIM(istim));
            fn2 = fieldnames(VISC);
            if ismember('BG', fn)
                data = VISC.ROI(iroi).STAGE(istage).STIM(istim);
            elseif  ismember('BG', fn2)
                data = VISC.BG.ROI(iroi).STAGE(istage).STIM(istim).REP(irep,:);
            else
                data = zeros(size(VISC.ROI(iroi).STAGE(istage).STIM(istim).Ydata(1,:)));
            end
            dataloc = strjoin({loc,'BG'},'/');
            createorwrite(fileloc, dataloc, data, 'create');
            createorwrite(fileloc, dataloc, data, 'write');
        end
    end
end
analysisroot = '/ANALYSIS';
for iroi = 1:NROI
    ROIstr = ['ROI_',num2str(iroi)];
    for istage = 1:NSTAGES
        STAGEstr = ['STAGE_',num2str(istage)];
        NSTIM = numel(VISC.ROI(iroi).STAGE(istage).STIM);
        %OSI
        data = double(VISC.OSI_A(iroi).STAGE(istage).osi);
        dataloc = strjoin({analysisroot, ROIstr, STAGEstr,'OSI'},'/');
        createorwrite(fileloc, dataloc, data, 'create');
        createorwrite(fileloc, dataloc, data, 'write');
        %OSIALT
        data = double(VISC.OSI_A(iroi).STAGE(istage).osi2);
        dataloc = strjoin({analysisroot, ROIstr, STAGEstr,'OSIALT'},'/');
        createorwrite(fileloc, dataloc, data, 'create');
        createorwrite(fileloc, dataloc, data, 'write');
        %SQUAREMASK
        data = double(VISC.POLY(iroi).STAGE(istage).squaremask);
        dataloc = strjoin({analysisroot, ROIstr, STAGEstr,'SQUAREMASK'},'/');
        createorwrite(fileloc, dataloc, data, 'create');
        createorwrite(fileloc, dataloc, data, 'write');
        %ROIMASK
        data = double(VISC.POLY(iroi).STAGE(istage).ROImask);
        dataloc = strjoin({analysisroot, ROIstr, STAGEstr,'ROIMASK'},'/');
        createorwrite(fileloc, dataloc, data, 'create');
        createorwrite(fileloc, dataloc, data, 'write');
        %MAXCORR
        data = double(VISC.POLY(iroi).STAGE(istage).MaxCorr);
        dataloc = strjoin({analysisroot, ROIstr, STAGEstr,'MAXCORR'},'/');
        createorwrite(fileloc, dataloc, data, 'create');
        createorwrite(fileloc, dataloc, data, 'write');
        %DOMINANTSTIMULUS
        data = double(VISC.OSI_A(iroi).STAGE(istage).domSTIM);
        dataloc = strjoin({analysisroot, ROIstr, STAGEstr,'DOMINANTSTIMULUS'},'/');
        createorwrite(fileloc, dataloc, data, 'create');
        createorwrite(fileloc, dataloc, data, 'write');
        for istim = 1:NSTIM
            STIMstr = ['STIM_',num2str(istim)];
            %DFF
            data = VISC.ROI(iroi).STAGE(istage).STIM(istim).Ydata_dff;
            dataloc = strjoin({analysisroot, ROIstr, STAGEstr, STIMstr,'DFF'},'/');
            createorwrite(fileloc, dataloc, data, 'create');
            createorwrite(fileloc, dataloc, data, 'write');
            %STIMSTRENGTH
            data = VISC.A(iroi).STAGE(istage).STIM(istim).stimstrength;
            dataloc = strjoin({analysisroot, ROIstr, STAGEstr, STIMstr,'STIMSTRENGTH'},'/');
            createorwrite(fileloc, dataloc, data, 'create');
            createorwrite(fileloc, dataloc, data, 'write');
            %SD
            data = VISC.A(iroi).STAGE(istage).STIM(istim).std;
            dataloc = strjoin({analysisroot, ROIstr, STAGEstr, STIMstr,'SD'},'/');
            createorwrite(fileloc, dataloc, data, 'create');
            createorwrite(fileloc, dataloc, data, 'write');
            %PEAKSINSTIMWIN
            dataloc = strjoin({analysisroot,ROIstr, STAGEstr,STIMstr,  'PEAKSINSTIMWIN'},'/');
            fns = fieldnames(VISC.ROI(iroi).STAGE(istage).STIM(istim));
            if ismember(fns, 'stim_peaks')
                data = VISC.ROI(iroi).STAGE(istage).STIM(istim).stim_peaks;
            else
                data = zeros(size(VISC.ROI(iroi).STAGE(istage).STIM(istim).MeasureNumber));
            end
            createorwrite(fileloc, dataloc, data, 'create');
            createorwrite(fileloc, dataloc, data, 'write');
        end
    end
end

function hdf5attrwrite(fileloc, VISC)
NROI = numel(VISC.ROI);
NSTAGES = numel(VISC.ROI(1).STAGE);
MN = visc_remap_measurenumber(VISC.ROI);
dataroot = '/DATA';
h5writeatt(fileloc,dataroot, 'ANIMALID', VISC.ROI(1).mouseID);
h5writeatt(fileloc,dataroot, 'SETUP', VISC.ROI(1).setup);
for istage = 1:NSTAGES
    S = visc_recall_stims(VISC.ROI(1).stimtype);
    STAGEstr = ['STAGE_',num2str(istage)];
    NUNITS = numel(MN.STAGE(istage).mn);
    loc = strjoin({dataroot,STAGEstr},'/');
    h5writeatt(fileloc,loc, 'DATAPATH', []);
    h5writeatt(fileloc,loc, 'STIMTYPE', VISC.ROI(1).stimtype);
    h5writeatt(fileloc,loc, 'STIMWIN', [S.static1 S.blank2]);
    h5writeatt(fileloc,loc, 'STIMSTART', S.static1);
    h5writeatt(fileloc,loc, 'STIMEND', S.blank2);
    h5writeatt(fileloc,loc, 'STIMSTATIC1', S.static1);
    h5writeatt(fileloc,loc, 'STIMSTATIC2', S.static2);
    h5writeatt(fileloc,loc, 'STIMMOVING', S.moving);
    h5writeatt(fileloc,loc, 'STAGEID', VISC.ROI(1).STAGE(istage).stageID);
    
    for iunit = 1:NUNITS
        UNITstr = ['UNIT_',num2str(iunit)];
        loc = strjoin({dataroot,STAGEstr,UNITstr},'/');
        logv = MN.STAGE(istage).mn == iunit;
        istim = MN.STAGE(istage).stim(logv);
        irep = MN.STAGE(istage).rep(logv);
        h5writeatt(fileloc,loc, 'STIMID', VISC.ROI(1).STAGE(istage).STIM(istim).stimID);
        h5writeatt(fileloc,loc, 'REPID', irep);
        h5writeatt(fileloc,loc, 'TIMEUNITS', 'ms');
        for iroi = 1:NROI
            ROIstr = ['ROI_',num2str(iroi)];
            loc = strjoin({dataroot, STAGEstr,UNITstr,ROIstr},'/');
            h5writeatt(fileloc,loc, 'ROIID', VISC.ROI(iroi).ID);
            h5writeatt(fileloc,loc, 'UNIQUEID', VISC.ROI(iroi).UNID);
            h5writeatt(fileloc,loc, 'CENTROID', VISC.ROI(iroi).STAGE(istage).logicalROI.centroid);%probably different for AO
            h5writeatt(fileloc,loc, 'POLYGON', VISC.ROI(iroi).STAGE(istage).logicalROI.poly);%probably different for AO
            fnames = fieldnames(VISC.ROI(iroi).STAGE(istage));
                if ismember('ROI_X',fnames)
                    h5writeatt(fileloc,loc, 'X', VISC.ROI(iroi).STAGE(istage).ROI_X);
                else
                    h5writeatt(fileloc,loc, 'X', []);
                end
                if ismember('ROI_Y',fnames)
                    h5writeatt(fileloc,loc, 'Y', VISC.ROI(iroi).STAGE(istage).ROI_Y);
                else
                    h5writeatt(fileloc,loc, 'Y', []);
                end
                if ismember('ROI_Z',fnames)
                    h5writeatt(fileloc,loc, 'Z', VISC.ROI(iroi).STAGE(istage).ROI_Z);
                else
                    h5writeatt(fileloc,loc, 'Z', []);
                end
        end
    end
end
analysisroot = '/ANALYSIS';
h5writeatt(fileloc,analysisroot, 'DFFTYPE', VISC.ROI(1).dfftype);
h5writeatt(fileloc,analysisroot, 'ISBGCORRECTED', VISC.ROI(1).BGcorrected);
h5writeatt(fileloc,analysisroot, 'BGCORRMETHOD', 'linear_subtraction');
fn2 = fieldnames(VISC);
if ismember('BG', fn2)
    h5writeatt(fileloc,analysisroot, 'BGEXTRACTMETHOD', VISC.BG.method);
else
    h5writeatt(fileloc,analysisroot, 'BGEXTRACTMETHOD', '');
end
for iroi = 1:NROI
    ROIstr = ['ROI_',num2str(iroi)];
    loc = strjoin({analysisroot, ROIstr},'/');
    h5writeatt(fileloc,loc, 'PROXIMITYFLAG', VISC.ROI(iroi).distance_check_failed);
    for istage = 1:NSTAGES
        STAGEstr = ['STAGE_',num2str(istage)];
        NSTIM = numel(VISC.ROI(iroi).STAGE(istage).STIM);
        loc = strjoin({analysisroot, ROIstr, STAGEstr},'/');
        h5writeatt(fileloc,loc, 'NOTCLOSETOEDGE', VISC.POLY(iroi).STAGE(istage).allin);
        h5writeatt(fileloc,loc, 'NBORDERPIXELS', VISC.POLY(iroi).STAGE(istage).borderpix);
        fns = fieldnames(VISC.ROI(1));
        if ismember('manually_flagged_stages', fns)
            if ~isempty(VISC.ROI(iroi).manually_flagged_stages)
                if ismember(VISC.ROI(iroi).STAGE(istage).stageID, VISC.ROI(iroi).flagged_stages)
                    flagged = 1;
                else
                    flagged = 0;
                end
            else
                flagged = [];
            end
        else
            flagged = [];
        end
        h5writeatt(fileloc,loc, 'FLAGGEDASBAD', flagged);
        for istim = 1:NSTIM
            STIMstr = ['STIM_',num2str(istim)];
            loc = strjoin({analysisroot, ROIstr, STAGEstr, STIMstr},'/');
            h5writeatt(fileloc,loc, 'UNITNUMBER', VISC.ROI(iroi).STAGE(istage).STIM(istim).MeasureNumber);
        end
    end
end

function hdfcreate(fileloc, VISC, flag)
dataloc = '/DATA/IMAGING';
analoc = '/ANALYSIS/IMAGING';
roots = {'/DATA', '/ANALYSIS'};
childroots = {'FRAMES', 'IMAGING', 'BEHAVIOR'};
NROI = numel(VISC.ROI);
NSTAGES = numel(VISC.ROI(1).STAGE);
if strcmp(flag,'create')
    create = 1;
else
    create = 0;
end

for iroi = 1:NROI
    ROIstr = ['ROI_',num2str(iroi)];
    for istage = 1:NSTAGES
        STAGEstr = ['STAGE_',num2str(istage)];
        
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        for iroot = 1:numel(roots)
            croot = roots{iroot};
%             if strcmp(croot, '/ANALYSIS') %no FRAMES in ANALYSIS
%                 childroots = setdiff(childroots,'FRAMES');
%             end

                cchild = 'IMAGING';
                switch croot
                    case '/DATA'
                        %MAXPROJ
                        loc = strjoin({croot,cchild,ROIstr, STAGEstr, 'MAXPROJ'},'/');
                        data = double(VISC.ROI(iroi).STAGE(istage).logicalROI.roi);
                        createorwrite(fileloc, loc, data, flag);
                    case '/ANALYSIS'
                        %MAXCORR
                        loc = strjoin({croot,cchild,ROIstr, STAGEstr, 'MAXCORR'},'/');
                        data = VISC.POLY(iroi).STAGE(istage).MaxCorr;
                        createorwrite(fileloc, loc, data, flag);
                        
                        %MEANCORR
                        loc = strjoin({croot,cchild,ROIstr, STAGEstr, 'MEANCORR'},'/');
                        data = VISC.POLY(iroi).STAGE(istage).MeanCorr;
                        createorwrite(fileloc, loc, data, flag);
                        
                        %SQUAREMASK
                        loc = strjoin({croot,cchild,ROIstr, STAGEstr, 'SQUAREMASK'},'/');
                        data = double(VISC.POLY(iroi).STAGE(istage).squaremask);
                        createorwrite(fileloc, loc, data, flag);
                        
                        %DOMINANTSTIMULUS
                        loc = strjoin({croot,cchild,ROIstr, STAGEstr, 'DOMINANTSTIMULUS'},'/');
                        data = double(VISC.OSI_A(iroi).STAGE(istage).domSTIM);
                        createorwrite(fileloc, loc, data, flag);
                        
                        %OSI
                        loc = strjoin({croot,cchild,ROIstr, STAGEstr, 'OSI'},'/');
                        data = double(VISC.OSI_A(iroi).STAGE(istage).osi);
                        createorwrite(fileloc, loc, data, flag);
                        
                        %OSIALT
                        loc = strjoin({croot,cchild,ROIstr, STAGEstr, 'OSIALT'},'/');
                        data = double(VISC.OSI_A(iroi).STAGE(istage).osi2);
                        createorwrite(fileloc, loc, data, flag);
                end
                if iroi == 1
                    cchild = 'FRAMES';
                    switch croot
                        case '/DATA'
                            %LUT
                            loc = strjoin({croot,cchild, STAGEstr, 'LUT'},'/');
                            data = VISC.IMG.STAGE(istage).MaxProjLUT;
                            createorwrite(fileloc, loc, data, flag);
                            
                            %MAXPROJ
                            loc = strjoin({croot,cchild, STAGEstr, 'MAXPROJ'},'/');
                            data = VISC.IMG.STAGE(istage).MaxProj;
                            createorwrite(fileloc, loc, data, flag);
                    end
                end

        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        
        
        
        NSTIM = numel(VISC.ROI(iroi).STAGE(istage).STIM);
        for istim = 1:NSTIM
            STIMstr = ['STIM_',num2str(istim)];
            
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            for iroot = 1:numel(roots)
                croot = roots{iroot};
%                 if strcmp(croot, '/ANALYSIS') %no FRAMES in ANALYSIS
%                     childroots = setdiff(childroots,'FRAMES');
%                 end
                    cchild = 'IMAGING';
                    switch croot
                        case '/DATA'
                            %BG
                            loc = strjoin({croot,cchild,ROIstr, STAGEstr,STIMstr,  'BG'},'/');
                            fns = fieldnames(VISC.ROI(iroi).STAGE(istage).STIM(istim));
                            if ismember(fns, 'BG')
                                data = VISC.ROI(iroi).STAGE(istage).STIM(istim).BG;
                            else
                                data = zeros(size(VISC.ROI(iroi).STAGE(istage).STIM(istim).Ydata));
                            end
                            createorwrite(fileloc, loc, data, flag);
                            
                            %XDATA
                            loc = strjoin({croot,cchild,ROIstr, STAGEstr,STIMstr,  'XDATA'},'/');
                            data = VISC.ROI(iroi).STAGE(istage).STIM(istim).Xdata;
                            createorwrite(fileloc, loc, data, flag);
                            
                            %YDATA
                            loc = strjoin({croot,cchild,ROIstr, STAGEstr,STIMstr,  'YDATA'},'/');
                            data = VISC.ROI(iroi).STAGE(istage).STIM(istim).Ydata;
                            createorwrite(fileloc, loc, data, flag);
                            
                        case '/ANALYSIS'
                            %INTERVAL
                            loc = strjoin({croot,cchild,ROIstr, STAGEstr,STIMstr,  'INTERVAL'},'/');
                            data = VISC.A(iroi).STAGE(istage).STIM(istim).interval;
                            createorwrite(fileloc, loc, data, flag);
                            
                            %MEANSUM
                            loc = strjoin({croot,cchild,ROIstr, STAGEstr,STIMstr, 'MEANSUM'},'/');
                            data = VISC.A(iroi).STAGE(istage).STIM(istim).meansum;
                            createorwrite(fileloc, loc, data, flag);
                            
                            %SEM
                            loc = strjoin({croot,cchild,ROIstr, STAGEstr,STIMstr, 'SEM'},'/');
                            data = VISC.A(iroi).STAGE(istage).STIM(istim).SEM;
                            createorwrite(fileloc, loc, data, flag);
                            
                            %SEP
                            loc = strjoin({croot,cchild,ROIstr, STAGEstr,STIMstr,  'SEP'},'/');
                            data = VISC.A(iroi).STAGE(istage).STIM(istim).SEP;
                            createorwrite(fileloc, loc, data, flag);
                            
                            %SD
                            loc = strjoin({croot,cchild,ROIstr, STAGEstr,STIMstr,  'SD'},'/');
                            data = VISC.A(iroi).STAGE(istage).STIM(istim).std;
                            createorwrite(fileloc, loc, data, flag);
                            
                            %STIMSTRENGTH
                            loc = strjoin({croot,cchild,ROIstr, STAGEstr,STIMstr,  'STIMSTRENGTH'},'/');
                            data = VISC.A(iroi).STAGE(istage).STIM(istim).stimstrength;
                            createorwrite(fileloc, loc, data, flag);
                            
                            %DFF
                            loc = strjoin({croot,cchild,ROIstr, STAGEstr,STIMstr, 'DFF'},'/');
                            data = VISC.ROI(iroi).STAGE(istage).STIM(istim).Ydata_dff;
                            createorwrite(fileloc, loc, data, flag);
                            
                            
                            %PEAKSINSTIMWIN
                            loc = strjoin({croot,cchild,ROIstr, STAGEstr,STIMstr,  'PEAKSINSTIMWIN'},'/');
                            fns = fieldnames(VISC.ROI(iroi).STAGE(istage).STIM(istim));
                            if ismember(fns, 'stim_peaks')
                                data = VISC.ROI(iroi).STAGE(istage).STIM(istim).stim_peaks;
                            else
                                data = zeros(size(VISC.ROI(iroi).STAGE(istage).STIM(istim).MeasureNumber));
                            end
                            createorwrite(fileloc, loc, data, flag);
                    end

            end
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            
            
            NREP = numel(VISC.ROI(iroi).STAGE(istage).STIM(istim).Ydata(:,1));
            for irep = 1:NREP
                REPstr = ['REP_',num2str(irep)];
                
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                for iroot = 1:numel(roots)
                    croot = roots{iroot};
                    cchild = 'IMAGING';
                    switch croot
                        case '/DATA'
                            loc = strjoin({croot,cchild,ROIstr,STAGEstr,STIMstr, REPstr, 'ROIBOX'},'/');
                            data = VISC.POLY(iroi).STAGE(istage).STIM(istim).REP(irep).ROIbox;
                            createorwrite(fileloc, loc, data, flag);
                    end
                end
                
                if iroi == 1
                    cchild = 'FRAMES';
                    croot = '/DATA';
%                         case '/DATA'
                            %LUT
                            loc = strjoin({croot,cchild,STAGEstr,STIMstr,REPstr 'LUT'},'/');
                            data = VISC.IMG.STAGE(istage).MaxProjLUT;
                            createorwrite(fileloc, loc, data, flag);
                            
                            %MAXPROJ
                            loc = strjoin({croot,cchild, STAGEstr, STIMstr, REPstr,'MAXPROJ'},'/');
                            data = VISC.IMG.STAGE(istage).MaxProj;
                            createorwrite(fileloc, loc, data, flag);
%                     end
                end
                
                
                
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            end
            
        end
    end
end

function hdfattrwrite(fileloc, VISC)
dataloc = '/DATA/IMAGING';
analoc = '/ANALYSIS/IMAGING';
roots = {'/DATA', '/ANALYSIS'};
childroots = {'FRAMES', 'IMAGING', 'BEHAVIOR'};
NROI = numel(VISC.ROI);
NSTAGES = numel(VISC.ROI(1).STAGE);
h5writeatt(fileloc,'/', 'ANIMALID', VISC.ROI(1).mouseID);
h5writeatt(fileloc,'/', 'SETUP', VISC.ROI(1).setup);

for iroot = 1:numel(roots)
    root = roots{iroot};
    if strcmp(root, '/ANALYSIS')
        child = 'IMAGING';
        loc = strjoin({root,child},'/');
        h5writeatt(fileloc,loc, 'DFFTYPE', VISC.ROI(1).dfftype);
        h5writeatt(fileloc,loc, 'ISBGCORRECTED', VISC.ROI(1).BGcorrected);
        h5writeatt(fileloc,loc, 'BGMETHOD', 'linear_subtraction');
        for iroi = 1:NROI
            ROIstr = ['ROI_',num2str(iroi)];
            loc = strjoin({root,child,ROIstr},'/');
            h5writeatt(fileloc,loc, 'PROXIMITYFLAG', VISC.ROI(iroi).distance_check_failed);
            h5writeatt(fileloc,loc, 'ROIID', VISC.ROI(iroi).ID);
            h5writeatt(fileloc,loc, 'UNIQUEID', VISC.ROI(iroi).UNID);
            for istage = 1:NSTAGES
                STAGEstr = ['STAGE_',num2str(istage)];
                loc = strjoin({root,child,ROIstr, STAGEstr},'/');
                h5writeatt(fileloc,loc, 'NOTCLOSETOEDGE', VISC.POLY(iroi).STAGE(istage).allin);
                h5writeatt(fileloc,loc, 'NBORDERPIXELS', VISC.POLY(iroi).STAGE(istage).borderpix);
                h5writeatt(fileloc,loc, 'STAGEID', VISC.ROI(iroi).STAGE(istage).stageID);
                fns = fieldnames(VISC.ROI(1));
                if ismember('manually_flagged_stages', fns)
                    if ~isempty(VISC.ROI(iroi).manually_flagged_stages)
                        if ismember(VISC.ROI(iroi).STAGE(istage).stageID, VISC.ROI(iroi).flagged_stages)
                            flagged = 1;
                        else
                            flagged = 0;
                        end
                    else
                        flagged = [];
                    end
                else
                    flagged = [];
                end
                h5writeatt(fileloc,loc, 'FLAGGEDASBAD', flagged);
                NSTIM = numel(VISC.ROI(iroi).STAGE(istage).STIM);
                for istim = 1:NSTIM
                    STIMstr = ['STIM_',num2str(istim)];
                    loc = strjoin({root,child,ROIstr, STAGEstr, STIMstr},'/');
                    h5writeatt(fileloc,loc, 'STIMID', VISC.ROI(iroi).STAGE(istage).STIM(istim).stimID);
                end
            end
        end
    end
    if strcmp(root, '/DATA')
        child = 'IMAGING';
        for iroi = 1:NROI
            ROIstr = ['ROI_',num2str(iroi)];
            loc = strjoin({root,child,ROIstr},'/');
            h5writeatt(fileloc,loc, 'ROIID', VISC.ROI(iroi).ID);
            h5writeatt(fileloc,loc, 'UNIQUEID', VISC.ROI(iroi).UNID);
            for istage = 1:NSTAGES
                S = visc_recall_stims(VISC.ROI(1).stimtype);
                STAGEstr = ['STAGE_',num2str(istage)];
                loc = strjoin({root,child,ROIstr, STAGEstr},'/');
                %time stamps
                h5writeatt(fileloc,loc, 'STIMWIN', [S.static1 S.blank2]);
                h5writeatt(fileloc,loc, 'TSSTIMSTART', S.static1);
                h5writeatt(fileloc,loc, 'TSSTIMEND', S.blank2);
                h5writeatt(fileloc,loc, 'TSSTATIC1', S.static1);
                h5writeatt(fileloc,loc, 'TSSTATIC2', S.static2);
                h5writeatt(fileloc,loc, 'TSMOVING', S.moving);
                %till here
                h5writeatt(fileloc,loc, 'STAGEID', VISC.ROI(iroi).STAGE(istage).stageID);
                h5writeatt(fileloc,loc, 'STIMTYPE', VISC.ROI(iroi).stimtype);
                h5writeatt(fileloc,loc, 'CENTROID', VISC.ROI(iroi).STAGE(istage).logicalROI.centroid);
                h5writeatt(fileloc,loc, 'POLYGON', VISC.ROI(iroi).STAGE(istage).logicalROI.poly);
                fnames = fieldnames(VISC.ROI(iroi).STAGE(istage));
                if ismember('ROI_X',fnames)
                    h5writeatt(fileloc,loc, 'X', VISC.ROI(iroi).STAGE(istage).ROI_X);
                else
                    h5writeatt(fileloc,loc, 'X', []);
                end
                if ismember('ROI_Y',fnames)
                    h5writeatt(fileloc,loc, 'Y', VISC.ROI(iroi).STAGE(istage).ROI_Y);
                else
                    h5writeatt(fileloc,loc, 'Y', []);
                end
                if ismember('ROI_Z',fnames)
                    h5writeatt(fileloc,loc, 'Z', VISC.ROI(iroi).STAGE(istage).ROI_Z);
                else
                    h5writeatt(fileloc,loc, 'Z', []);
                end
                
                NSTIM = numel(VISC.ROI(iroi).STAGE(istage).STIM);
                for istim = 1:NSTIM
                    STIMstr = ['STIM_',num2str(istim)];
                    loc = strjoin({root,child,ROIstr, STAGEstr, STIMstr},'/');
                    h5writeatt(fileloc,loc, 'STIMID', VISC.ROI(iroi).STAGE(istage).STIM(istim).stimID);
                    h5writeatt(fileloc,loc, 'MEASURENUMBER', VISC.ROI(iroi).STAGE(istage).STIM(istim).MeasureNumber);
                end
            end
        end
        child = 'FRAMES';
        for istage = 1:NSTAGES
            STAGEstr = ['STAGE_',num2str(istage)];
            loc = strjoin({root,child, STAGEstr},'/');
            h5writeatt(fileloc,loc, 'STAGEID', VISC.ROI(1).STAGE(istage).stageID);
            NSTIM = numel(VISC.ROI(1).STAGE(istage).STIM);
            for istim = 1:NSTIM
                STIMstr = ['STIM_',num2str(istim)];
                loc = strjoin({root,child, STAGEstr, STIMstr},'/');
                h5writeatt(fileloc,loc, 'STIMID', VISC.ROI(1).STAGE(istage).STIM(istim).stimID);
                NREP = numel(VISC.ROI(1).STAGE(istage).STIM(istim).MeasureNumber);
                for irep = 1:NREP
                    REPstr = ['REP_',num2str(irep)];
                    loc = strjoin({root,child, STAGEstr, STIMstr, REPstr},'/');
                    h5writeatt(fileloc,loc, 'MEASURENUMBER', VISC.ROI(1).STAGE(istage).STIM(istim).MeasureNumber(irep));
                end
            end
        end
    end
end

function createorwrite(fileloc, loc, data, flag)
if strcmp(flag ,'create')
    create = 1;
else
    create = 0;
end
if create
    try
        h5create(fileloc,loc,size(data),'ChunkSize',size(data), 'Deflate', 9);
    catch
    end
else
    h5write(fileloc,loc,data);
end
