function EX = extractbg(EX,method)
% EX = extractbg(EX,method) - extracts background signal from motion
% corrected images for every roi.
% part of HELIOS
Npicks = 10;
if nargin < 2
    method = 'staticpixels';
end
Npixels = 5;
for istage = 1:EX.N_stages
    disp(['WORKING ON STAGE ',num2str(istage),'/',num2str(EX.N_stages)])
    mcorrfileloc = h5readatt(EX.file_loc,...
        ['/DATA/STAGE_',num2str(istage)],'MOTIONCORRECTEDDATAPATH');
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
    switch method
        case 'staticpixels'
            %--------------------------------STATIC-PIXELS--------------------------------------------%
            %raw data is accessed, we loop in each unit one by one
            for irec = 1:numel(RAWdata)
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
                
                %now we loop inside each frame of that unit
                for iframe = 1:numel(frameSet(1,1,:));
                    cframe = frameSet(:,:,iframe);
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
                h3 = waitbar(0,'Gathering pixel data');
                for iroi = 1:EX.N_roi
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
            for iroi = 1:EX.N_roi
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
            %ROUND 2 - using the good/selected pixels extract dynamic background
            h2 = waitbar(0,'Recordings of this stage in progress. STEP 2 ');
            for irec = 1:numel(RAWdata)
                waitbar(irec/numel(RAWdata),h2);
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
                
                for iroi = 1:EX.N_roi
                    loc = ['/DATA/STAGE_',num2str(istage),'/UNIT_',num2str(irec),'/ROI_',num2str(iroi),'/BG'];
                    for iframe = 1:numel(frameSet(1,1,:));
                        cframe = frameSet(:,:,iframe);
                        cands = cframe(PXROI(iroi).pixels_to_use)-steadydiff;
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
                
                %now we loop inside each frame of that unit
                for iroi = 1:EX.N_roi
                    croimask = h5read(EX.file_loc,...
                        ['/ANALYSIS/ROI_',num2str(iroi),'/STAGE_',num2str(istage),'/ROIMASK']);
                    ROI = roi(croimask, Npixels);
                    idxs = find(ROI.mask_around_roi);
                    Npix = numel(idxs);
                    for iframe = 1:numel(frameSet(1,1,:));
                        cframe = frameSet(:,:,iframe);
                        cpooldezero = cframe(idxs)-steadydiff;
                        cpooldezerosorted = sort(cpooldezero);
                        cands = cpooldezerosorted(1:Npicks);
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
                
                %now we loop inside each frame of that unit
                for iroi = 1:EX.N_roi
                    croimask = h5read(EX.file_loc,...
                        ['/ANALYSIS/ROI_',num2str(iroi),'/STAGE_',num2str(istage),'/ROIMASK']);
                    ROI = roi(croimask, Npixels);
                    idxs = find(ROI.mask_around_roi);
                    Npix = numel(idxs);
                    for iframe = 1:numel(frameSet(1,1,:));
                        cframe = frameSet(:,:,iframe);
                        cpooldezero = cframe(idxs)-steadydiff;
                        cpooldezerosorted = sort(cpooldezero);
                        bg(iframe) = nanmean(double(cpooldezerosorted));
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
h5writeatt(EX.file_loc,['/ANALYSIS'], 'BGCORRMETHOD', method);
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