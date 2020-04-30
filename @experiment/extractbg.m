function EX = extractbg(EX,method)
% EX = extractbg(EX,method) - extracts background signal from motion
% corrected images for every roi.
% part of HELIOS
Npicks = 10;
if nargin < 2
    method = 'staticpixels';
end
Npixels = 5;


%AO data is not hdf5 readable, thus if the dataset is from AO, it requires
%the MES to open and extract raw data. The logical check below checks the
%setup and in case it is AO, it looks whether MES exists
setup = EX.setup;
if strcmp(setup, 'ao')
    isao = 1;
else
    isao = 0;
end
if isao
    %initialize MES
    W = evalin('caller','whos');
    doesExist = ismember('proginfo',{W(:).name});
    if ~doesExist
        try
            mes
        catch
            warndlg('mes could not be started')
            disp('BG was not calculated');
            return
        end
    end
    if doesExist
        varidx = strcmp({W(:).name},'proginfo');
        checkvariable = W(varidx);
        if checkvariable.bytes == 0
            try
                mes
            catch
                warndlg('mes could not be started')
                return
            end
        end
    end
    %MES initialized
end
if isao
    hrf = findhrf(EX.id);
end


for istage = 1:EX.N_stages
    disp(['WORKING ON STAGE ',num2str(istage),'/',num2str(EX.N_stages)])
    mcorrfileloc = h5readatt(EX.file_loc,...
        ['/DATA/STAGE_',num2str(istage)],'MOTIONCORRECTEDDATAPATH');
    P1{istage} = mcorrfileloc;
    
    if ~isao %DUAL
        err = 1;
        while err
            try
                info = h5info(mcorrfileloc);
                err = 0;
            catch
            end
        end
        fnames = fieldnames(info);
        if ismember('GroupHierarchy', fnames)
            RAWdata = info.GroupHierarchy.Groups.Groups;
        else
            RAWdata = info.Groups.Groups;
        end
        ROIsequence = 1:EX.N_roi;
    else %AO
        d = load(hrf.analysis.imaging.data_matrices.file_path{istage});
        Nrecs = numel(d.data);
        Nrois = numel(d.data(1).logicalROI);
        roiH = d.data(1).attribs(1).TransversePixNum;
        roiW = d.data(1).attribs(1).AO_collection_usedpixels;%ff width
        Nsquares = d.data(1).attribs(1).Linelength./roiW;
        fs(1) = roiH;
        fs(2) = d.data(1).attribs(1).Width;
        FS = local_frameset_descript(fs, roiH, roiW, Nsquares, EX, istage);
        ROIsequence = [FS.containROI];%in which order where they drawn
        if numel([FS.containROI])~=Nrois
            error('cant attribute FF to ROI selection');
        end
        RAWdata = d.data;% only for indexing in the loop below
    end
    
    switch method
        case 'staticpixels'
            %--------------------------------STATIC-PIXELS--------------------------------------------%
            %raw data is accessed, we loop in each unit one by one
            for irec = 1:numel(RAWdata)
                if ~isao
                    [frameSet, steadydiff] = getDUALframeset(RAWdata,irec,mcorrfile);
                else
                    frameSet = getAOframeset(P1{istage}, irec);
                end
                
                Nframes = numel(frameSet(1,1,:));
                
                if isao
                    Nframes = Nframes - 15;
                    blankframe = zeros(size(frameSet(:,:,1)'));
                    idxframe = reshape(1:numel(blankframe), size(blankframe));
                end
                
                
                %now we loop inside each frame of that unit
                for iframe = 1:Nframes
                    cframe = frameSet(:,:,iframe);
                    
                    if isao
                        cframe = cframe';
                        for iroi = ROIsequence
                            for ifs = 1:numel(FS)
                                if ismember(iroi,FS(ifs).containROI)
                                    nFS = FS(ifs);
                                    break
                                end
                            end
                            roisqmask = nFS.squareframe; %SQUARE MASK OF THE ROI
                            flds = fieldnames(d.data(irec).logicalROI(iroi));
                            if ismember('roiRaw',flds)
                                roiselmask = d.data(irec).logicalROI(iroi).roiRaw;
                            else
                                roiselmask = logical(poly2mask(d.data(irec).CaTransient(iroi).poly(1,:),...
                                    d.data(irec).CaTransient(iroi).poly(2,:),fs(1),fs(2)));
                            end
                            roioutermask = logical((roisqmask.*(~roiselmask))); %all pixels in the rectangular frame excluding inside ROI
                            pixelsoutside = cframe(roioutermask);
                            idxoutside = idxframe(roioutermask);
                            for ipx = 1:numel(idxoutside)
                                R(iroi).data(ipx,iframe) = pixelsoutside(ipx);
                                R(iroi).px(ipx,iframe) = idxoutside(ipx);
                            end
                        end
                    else
                        for iroi = 1:EX.N_roi
                            croimask = h5read(EX.file_loc,...
                                ['/ANALYSIS/ROI_',num2str(iroi),'/STAGE_',num2str(istage),'/ROIMASK']);
                            ROI = roi(croimask, Npixels);
                            idxs = find(ROI.mask_around_roi);
                            Npix = numel(idxs);
                            for ipx = 1:Npix
                                R(iroi).data(ipx,iframe) = cframe(idxs(ipx));
                                R(iroi).px(ipx,iframe) = idxs(ipx);
                            end
                        end
                    end
                    
                    
                end
                
                h3 = waitbar(0,'Gathering pixel data');
                
                for iroi = ROIsequence
                    waitbar(iroi/EX.N_roi,h3);
                    npix = numel(R(iroi).data(:,1));
                    if ~all(ismember(R(iroi).px(:,1),R(iroi).px))
                        disp('some pixels for the same outer mask dont have the same indices');
                    end
                    for ipx = 1:npix
                        RR(iroi).data(ipx,irec) = mean(R(iroi).data(ipx,:));
                        RR(iroi).px(ipx,irec) = R(iroi).px(ipx,1);
                    end
                end
                close (h3)
                clear R
            end
            for iroi = ROIsequence
                cRR = RR(iroi);
                cM = cRR.data;
                cP = cRR.px(:,1);
                nanfilter = any(isnan(cM),2);
                cM(nanfilter,:) = [];
                cP = cP(~nanfilter);
                mean_cM = mean(cM,2);
                Npx = numel(cP);
                if Npx == 0
                    disp(['No pixels had values without NaNs for ROI ',num2str(iroi)]);
                    nonans = sum(~isnan(cM),2);
                    [aa,bb] = sort(nonans);
                    bbb = bb(end-9:end);
                    cP = cP(bbb);
                    Npx = numel(cP);
                    PXROI(iroi).pixels_to_use = cP;
                    continue
                end
                perc = floor(Npx*0.1);% 10%
                if perc < 10
                    disp(['for ROI ',num2str(iroi),' only ',num2str(Npx),' pixels out of ',...
                        num2str(numel(cRR.px(:,1))),' have no NaNs']);
                    if Npx > 10
                        Npx = 10;
                    end
                    perc = Npx;
                end
                [~,sortidx] = sort(mean_cM);
                cPsorted = cP(sortidx);
                PXROI(iroi).pixels_to_use = cPsorted(1:perc);
            end
            clear RR
            %ROUND 2 - using the good/selected pixels extract dynamic background
            h2 = waitbar(0,'Recordings of this stage in progress. STEP 2 ');
            for irec = 1:numel(RAWdata)
                waitbar(irec/numel(RAWdata),h2);
                if ~isao
                    [frameSet, steadydiff] = getDUALframeset(RAWdata,irec,mcorrfile);
                else
                    frameSet = getAOframeset(P1{istage}, irec);
                end
                
                for iroi = 1:ROIsequence
                    loc = ['/DATA/STAGE_',num2str(istage),'/UNIT_',num2str(irec),'/ROI_',num2str(iroi),'/BG'];
                    for iframe = 1:numel(frameSet(1,1,:));
                        cframe = frameSet(:,:,iframe);
                        if isao
                            cframe = cframe';
                            cands = cframe(PXROI(iroi).pixels_to_use);
                        else
                            cands = cframe(PXROI(iroi).pixels_to_use)-steadydiff;
                        end
                        
                        bg(iframe) = nanmean(double(cands));
                    end
                    try
                        allocatespace(EX.file_loc, {bg}, {loc});
                    catch
                    end
                    storedata(EX.file_loc, {bg}, {loc});
                    clear bg
                end
            end
            close (h2)
            %--------------------------------STATIC-PIXELS--------------------------------------------%
        case 'dynamicpixels'
            %-------------------------------DYNAMIC-PIXELS--------------------------------------------%
            h2 = waitbar(0,'Recordings of this stage in progress');
            for irec = 1:numel(RAWdata)
                waitbar(irec/numel(RAWdata),h2);
                
                if ~isao
                    [frameSet, steadydiff] = getDUALframeset(RAWdata,irec,mcorrfile);
                else
                    frameSet = getAOframeset(P1{istage}, irec);
                end
                
                Nframes = numel(frameSet(1,1,:));
                
                if isao
%                     Nframes = Nframes - 15;
                    blankframe = zeros(size(frameSet(:,:,1)'));
                    idxframe = reshape(1:numel(blankframe), size(blankframe));
                end
                
                %now we loop inside each frame of that unit
                for iroi = 1:ROIsequence
                    if isao
                        for ifs = 1:numel(FS)
                            if ismember(iroi,FS(ifs).containROI)
                                nFS = FS(ifs);
                                break
                            end
                        end
                        roisqmask = nFS.squareframe; %SQUARE MASK OF THE ROI
                        flds = fieldnames(d.data(iunit).logicalROI(iroi));
                        if ismember('roiRaw',flds)
                            roiselmask = d.data(iunit).logicalROI(iroi).roiRaw;
                        else
                            roiselmask = logical(poly2mask(d.data(irec).CaTransient(iroi).poly(1,:),...
                                d.data(irec).CaTransient(iroi).poly(2,:),fs(1),fs(2)));
                        end
                        roioutermask = logical((roisqmask.*(~roiselmask)));
                    else
                        croimask = h5read(EX.file_loc,...
                            ['/ANALYSIS/ROI_',num2str(iroi),'/STAGE_',num2str(istage),'/ROIMASK']);
                        ROI = roi(croimask, Npixels);
                        idxs = find(ROI.mask_around_roi);
                        Npix = numel(idxs);
                    end
                    
                    

                    for iframe = 1:numel(frameSet(1,1,:));
                        
                        if isao
                            cframe = frameSet(:,:,iframe)';
                            pixelsoutside = cframe(roioutermask);
                            [pixelsoutsidesorted, sortidx] = sort(pixelsoutside);
                            pixelsoutsidesorted = pixelsoutsidesorted(pixelsoutsidesorted>0);
                            if isempty(pixelsoutsidesorted)
                                cands = 0;
                            else
                                cands = pixelsoutsidesorted(1:Npicks);  
                            end
                            
                        else
                            cframe = frameSet(:,:,iframe);
                            cpooldezero = cframe(idxs)-steadydiff;
                            cpooldezerosorted = sort(cpooldezero);
                            cands = cpooldezerosorted(1:Npicks);
                        end 
                        
                        bg(iframe) = nanmean(double(cands));
                    end
                    loc = ['/DATA/STAGE_',num2str(istage),'/UNIT_',num2str(irec),'/ROI_',num2str(iroi),'/BG'];
                    try
                        allocatespace(EX.file_loc, {bg}, {loc});
                    catch
                    end
                    storedata(EX.file_loc, {bg}, {loc});
                end
            end
            close (h2)
            %-------------------------------DYNAMIC-PIXELS--------------------------------------------%
        case 'alloutside'
            %-------------------------------ALL-OUTSIDE-----------------------------------------------%
            h2 = waitbar(0,'Recordings of this stage in progress');
            for irec = 1:numel(RAWdata)
                waitbar(irec/numel(RAWdata),h2);
                
                if ~isao
                    [frameSet, steadydiff] = getDUALframeset(RAWdata,irec,mcorrfile);
                else
                    frameSet = getAOframeset(P1{istage}, irec);
                end
                Nframes = numel(frameSet(1,1,:));
                
                if isao
%                     Nframes = Nframes - 15;
                    blankframe = zeros(size(frameSet(:,:,1)'));
                    idxframe = reshape(1:numel(blankframe), size(blankframe));
                end
                
                %now we loop inside each frame of that unit
                for iroi = 1:ROIsequence
                    if isao
                        for ifs = 1:numel(FS)
                            if ismember(iroi,FS(ifs).containROI)
                                nFS = FS(ifs);
                                break
                            end
                        end
                        roisqmask = nFS.squareframe; %SQUARE MASK OF THE ROI
                        flds = fieldnames(d.data(iunit).logicalROI(iroi));
                        if ismember('roiRaw',flds)
                            roiselmask = d.data(iunit).logicalROI(iroi).roiRaw;
                        else
                            roiselmask = logical(poly2mask(d.data(irec).CaTransient(iroi).poly(1,:),...
                                d.data(irec).CaTransient(iroi).poly(2,:),fs(1),fs(2)));
                        end
                        roioutermask = logical((roisqmask.*(~roiselmask)));
                    else
                        croimask = h5read(EX.file_loc,...
                            ['/ANALYSIS/ROI_',num2str(iroi),'/STAGE_',num2str(istage),'/ROIMASK']);
                        ROI = roi(croimask, Npixels);
                        idxs = find(ROI.mask_around_roi);
                        Npix = numel(idxs);
                    end
                    
                    

                    for iframe = 1:numel(frameSet(1,1,:));
                        
                        if isao
                            cframe = frameSet(:,:,iframe)';
                            pixelsoutside = cframe(roioutermask);
                            [pixelsoutsidesorted, sortidx] = sort(pixelsoutside);
                            pixelsoutsidesorted = pixelsoutsidesorted(pixelsoutsidesorted>0);
                            if isempty(pixelsoutsidesorted)
                                cands = 0;
                            else
                                cands = pixelsoutsidesorted;  
                            end
                            
                        else
                            cframe = frameSet(:,:,iframe);
                            cpooldezero = cframe(idxs)-steadydiff;
                            cpooldezerosorted = sort(cpooldezero);
                            cands = cpooldezerosorted;
                        end 
                        
                        bg(iframe) = nanmean(double(cands));
                    end
                    loc = ['/DATA/STAGE_',num2str(istage),'/UNIT_',num2str(irec),'/ROI_',num2str(iroi),'/BG'];
                    try
                        allocatespace(EX.file_loc, {bg}, {loc});
                    catch
                    end
                    storedata(EX.file_loc, {bg}, {loc});
                end
            end
            close (h2)
            %-------------------------------ALL-OUTSIDE-----------------------------------------------%
    end
    
    
end
h5writeatt(EX.file_loc,['/ANALYSIS'], 'BGEXTRACTMETHOD', method);
h5writeatt(EX.file_loc,['/ANALYSIS'], 'ISBGCORRECTED', 1);
EX = experiment(EX.file_loc);



function value = findAttrib(inStruct,str)
for ii = 1:numel(inStruct)
    try
        name = inStruct(ii).Shortname;
    catch
        name = inStruct(ii).Name;
    end
    if strcmp(name,str)
        value = inStruct(ii).Value;
    end
end

function FS = local_frameset_descript(fs, H, W, Nsq, EX, Nstage);
%Nsq - number of squares
N = EX.N_roi;%number of ROIs
blankframe = zeros(fs);

Nroicols = fs(2)/W;
Nroirows = fs(1)/H;
colcount = 0;
for iN = 1:Nsq
    roisqmask = blankframe;
    roisqmask(:,(iN-1)*W+1:W*iN) = 1;
    roisqmaskidx = find(roisqmask);
    roisqmaskidx(roisqmaskidx>0);
    FS(iN).squareframe = roisqmask;
    %     FS(iN).idxs = roisqmaskidx;
    count = 1;
    for iM = 1:N
        poly = h5readatt(EX.file_loc, ['/DATA/STAGE_',num2str(Nstage),'/UNIT_1/ROI_',num2str(iM)],'POLYGON');
        %         roiselmask = cR.roi;
        roiselmask = logical(poly2mask(poly(1,:),...
            poly(2,:),fs(1),fs(2)));
        roiselmaskidx = find(roiselmask);
        
        memberpixelcheck = ismember(roiselmaskidx,roisqmaskidx);
        if sum(memberpixelcheck) > 0.8*numel(roiselmaskidx)
            FS(iN).containROI(count) = iM;
            count = count+1;
        end
    end
end


function frameSet = getAOframeset(P, irec)
err = 1;
while err
    try
        [frameSet,attval] = AORawExport(P,irec);
        err = 0;
    catch
    end
end


function [frameSet, steadydiff] = getDUALframeset(RAWdata,irec,mcorrfile)
upper = findAttrib(RAWdata(irec).Attributes,'Channel_0_Conversion_UpperLimitUint16');
offset = findAttrib(RAWdata(irec).Attributes,'Channel_0_Conversion_ConversionLinearOffset');
steadydiff = upper - offset;
nameCh = {[RAWdata(irec).Name,'/',RAWdata(irec).Datasets(1).Name]};
fnameCh = {mcorrfileloc};
err = 1;
while err
    try
        frameSet = 65535-flip(h5read(fnameCh{1},nameCh{1}),2);
        err = 0;
    catch
    end
end