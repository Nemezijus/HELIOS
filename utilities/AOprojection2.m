function data = AOprojection2(filelocation,roilocation,mode)
tic

%% Modes:
% multi: Multiroi xy.mescroi in .mes folder + .csv to stims
% scanfield: autoscanfields rois + .csv to stims
% previewer: Only creates previews

%Example

% filelocation='N:\DATA\Betanitas\!Mouse Gramophon\2_Imaging\group33\Groups_A\mouse33A2\33A2\Measurement data\Baseline1\baseline1_mcorr.mes'
% roilocation='N:\DATA\Betanitas\!Mouse Gramophon\2_Imaging\group33\Groups_A\mouse33A2\33A2\Measurement data\Baseline1\1.mescroi'
% stimlocation='C:\AMD\b1.csv'
% exportlocation='C:\AMD'
% mode='multi'

switch mode
    
       case 'saveRawOnly'
           
        savemode='multiMat';
        saveraw=true;
        stimload=false;
        calc=false;
        multiroi='noRoi';  %% 'NoRoi'
        preview=false;
        motioncorr=false;
        
        
       case 'multiRaw'
        savemode='multiMat';
        saveraw=true;
        stimload=true;
        calc=true;
        multiroi=true;
        preview=false;
        motioncorr=false;
    
    
    case 'scanfield'
        
        savemode='multiMat';
        saveraw=false;
        stimload=true;
        calc=true;
        multiroi=false;
        preview=false;
        motioncorr=false;
        
    case 'multi'
        savemode='multiMat';
        saveraw=false;
        stimload=false;
        calc=true;
        multiroi=true;
        preview=false;
        motioncorr=false;
        
    case 'previewer'
        savemode='multiMat';
        saveraw=false;
        stimload=false;
        calc=false;
        multiroi='noRoi';
        preview=true;
        motioncorr=false;   
end




%%

    
    %folder=strcat(dname,'\');
   % roifilt=PathFilter(pathML,'.mescroi',1)';
    
    %% LOAD folders Roiset
    %%%%%%%%%%%%%%%%%%%
    if multiroi==1
        outStruct = xml2struct2(roilocation);
        for i=1:size(outStruct.MESconfig.ROIs.Polygon,2)
            polysize=length(outStruct.MESconfig.ROIs.Polygon{1, i}.param);
            for p=1:polysize
                outStruct.MESconfig.ROIs.Polygon{1, i}.param{1, p}.Attributes.value;
                a=strsplit(outStruct.MESconfig.ROIs.Polygon{1, i}.param{1, p}.Attributes.value,{' '},'CollapseDelimiters',true);
                R(i).POLY(1,p)=str2num(a{1});
                R(i).POLY(2,p)=str2num(a{2});
            end
        end
    end
    %%%%%%%%%%%%%%%%%%%
    %% Datas
    disp('Data loading... Please wait!')
    chaninput=1;
    %%
    clear data


        file_open([],filelocation);
        mode='XYT';
        %%
        %global mainsettings
        f=mestaghandle('isf');
        if isempty(f)
            warndlg('Open a file first!', 'Export all XYZ to tiff')
            return
        end
        
        todel=false(size(f));
        for ID=1:numel(f)
            typ=get(f(ID), 1, 'Type');
            switch mode
                case 'XYZ'
                    if ~strcmp(typ, 'XY')
                        todel(ID)=true;
                    end
                case 'XYT'
                    if ~strcmp(typ, 'FF')
                        todel(ID)=true;
                    end
                otherwise
                    error('ezittnemkene 8362352')
            end
        end
        f(todel)=[];
        if isempty(f)
            warndlg('No appropriate measurement unit found!', 'Export all XYZ to tiff')
            return
        end
        
%         %diri=uigetdir(mainsettings.dirDATA);
%         diri=exportlocation;
%         if isnumeric(diri)
%             return
%         end
        
        h2 = waitbar(0,'Exporting measurement units...', 'Name', 'MES' );
        setp(h2, '+y', 90)
        clear AOCell
        unitcount=1;
        
        for unitID=1  %% unit level
            typ=get(f(unitID), 1, 'Type');
            mthnam=strrep(strrep(char(f(unitID)), '*', ''), ' ', '');
%             filenam=fullfile(diri, [mthnam, '.tiff']);
            switch typ
                case 'XY'
                    %expmultitiff(f(i), filenam)
                case 'FF'
                    clear info frameSet
                    info = Line2getxypos(f(unitID));
                    %fout=foldedframe2xyz2(f(unitID));
                    [subindex,prew,frameSet,lineInfo,attribs]=foldedframe2xyz2Own(f(unitID),chaninput);
                    
                    if preview
                        prev(:,:,unitcount)=mean(frameSet,3,'omitnan');
                        unitcount=unitcount+1;
                    end
                   
                    if unitID==1
                        %save('rescueAttrib.mat','attribs')
                    end
                    
                    AOSize=get(f(unitID), 1, 'AO_collection_usedpixels');
                    comment=get(f(unitID), 1, 'Comment');
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    switch multiroi
                        case 1
                        %% Fixating rois
                        
                        ax=size(frameSet,2);  % Swapped!!!!
                        ay=size(frameSet,1);   % Swapped!!!!
                        convX=attribs(1).TransverseStep;
                        convY=attribs(1).WidthStep;
                        clear mask maskBuffer
                        for i=1:size(R,2)
                            R(i).POLY2(1,:)=R(i).POLY(1,:)/convY;
                            R(i).POLY2(2,:)=R(i).POLY(2,:)/convX;
                        end
                        %% PolyCore
                        for i=1:size(R,2)  %% CELL LEVEL
                            
                            data(unitID).CaTransient(i).poly=[R(i).POLY2(1,:);R(i).POLY2(2,:)];
                            mask = logical(poly2mask(R(i).POLY2(1,:),R(i).POLY2(2,:),ax,ay));
                            data(unitID).CaTransient(i).mask = mask;
                            %% Finding centroid first
                            rawmask = regionprops(flipud(mask)','centroid','MajorAxisLength');
                            centr = cat(1, rawmask.Centroid);
                            cx=centr(1);
                            cy=centr(2);
                            [x,y,z,section,roiLoc]=Line2getxypos(round(cy),round(cx),info);
                            maskBuffer=maskfilter(mask,AOSize,roiLoc);
                            %% ROI COMPRESSION - Normal coordinates
                            s = regionprops(flipud(maskBuffer)','centroid','MajorAxisLength');
                            data(unitID).logicalROI(i).centroid = cat(1, s.Centroid);
                            data(unitID).logicalROI(i).axisLength=s.MajorAxisLength;
                            data(unitID).logicalROI(i).dims=[ax ay];
                            cx=data(unitID).logicalROI(i).centroid(1);
                            cy=data(unitID).logicalROI(i).centroid(2);
                            [x,y,z,section,roiLoc]=Line2getxypos(round(cy),round(cx),info); %%% SWAPPED!!! 
                            data(unitID).CaTransient(i).Realxyz=[x y z];
                            data(unitID).CaTransient(i).RealRoi=roiLoc;
                            data(unitID).CaTransient(i).RealSection=section;
                            %% Create chess ROIS
                            maskfilter(maskBuffer,AOSize,roiLoc);
                            %%
                            chessROI=transformROIToChess(flipud(maskBuffer),AOSize);
                            CC = bwconncomp(chessROI);
                            data(unitID).logicalROI(i).roi=uint64(CC.PixelIdxList{1, 1});
                            %data(unitID).logicalROI(i).roiRaw=maskBuffer;
                            
                            %% NEW CENTROID
                            s2 = regionprops(chessROI,'centroid','MajorAxisLength');
                            data(unitID).logicalROI(i).centroidChess = cat(1, s2.Centroid);
                            %%
                            if i==1;clear framePool;framePool=uint32(zeros([size(frameSet,2) size(frameSet,1) 1]));
                            end
                            
                            %%%%%% Indexing CORE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                            for j=1:size(frameSet,3) %% frame
                                I=flipud(frameSet(:,:,j)');
                                v=I(maskBuffer);
                                intensityVector(j)=mean(v,'omitnan');
                                if i==1;framePool=framePool+uint32(I);
                                end
                            end
                            
                            if i==1;meanPic=uint16(framePool/(size(frameSet,3)));
                            end
                            %%%%%%  Indexing CORE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                            %%%%%Correct sample time
                            
                            st=attribs(1).FoldedFrameInfo.firstFrameStartTime;
                            steps=attribs(1).FoldedFrameInfo.frameTimeLength;
                            stframe=st/steps;
                            AOSize=attribs(1).AO_collection_usedpixels;
                            FFnum=size(frameSet,1)/AOSize;
                            timeVect=(stframe:(size(frameSet,3)+stframe-1))*steps;
                            ROI(i).event(1,:)=timeVect;
                            ROI(i).event(2,:)=intensityVector;
                            ROI(i).RoiID=i;
   
                            %% Integrate data
                            data(unitID).CaTransient(i).event(1,:)=timeVect;
                            data(unitID).CaTransient(i).event(2,:)=intensityVector;
                            clear intensityVector;
                            data(unitID).CaTransient(i).RoiID=i;
                            data(unitID).CaTransient(i).RoiIDReal=i;
                            try
                                attribs = rmfield(attribs, 'IMAGE');
                            catch
                              %  warning('rmerr');
                            end
                            data(unitID).attribs=attribs;
                        end
                    %    disp ('G')
                        case 0 %% Scanfields
                            
                            
                        %%cell_level
                         for cellID=1:size(frameSet,1)/AOSize
                            clear start AOCell;
                            for id=1:size(frameSet,3)
                                start=((cellID-1)*AOSize)+1;
                                stop=(start+AOSize)-1;
                                AOCell(:,:,id)=frameSet(start:stop,:,id);
                            end

                            
                            switch savemode
                                case 'multiMat'
                                    try
                                        st=attribs(1).FoldedFrameInfo.firstFrameStartTime;
                                        steps=attribs(1).FoldedFrameInfo.frameTimeLength;
                                    catch
                                        load('rescueAttrib.mat');
                                    end
                                    stframe=st/steps;
                                    timeVect=stframe:(size(AOCell,3)+stframe-1);
                                    realtimeVect=timeVect*steps;
                                    
                                    data(unitID).CaTransient(cellID).event(1,:)=realtimeVect;
                                    data(unitID).CaTransient(cellID).event(2,:)=squeeze(mean(mean(AOCell,1,'omitnan'),2,'omitnan'));
                                    data(unitID).CaTransient(cellID).RoiID=cellID;
                                    data(unitID).CaTransient(cellID).RoiIDReal=cellID;
                                    try
                                        attribs = rmfield(attribs, 'IMAGE');
                                    catch
                                        warning('rmerr');
                                    end
                                    data(unitID).attribs=attribs;
                                    %unit(cellID).AOCell=AOCell;
                                    unit(cellID).mean=mean(AOCell,3,'omitnan');
                                    ysize=size(frameSet,2);
%                                     [x,y,z]=Line2getxypos(stop-(round(AOSize/2)),round(ysize/2), info);
%                                     data(unitID).CaTransient(cellID).Realxyz=[x y z];

                                    %disp('gr')
                                    
                                    %% HDF5 save
                                case 'hdf5'
                            end
                        end %% cell level
                        
                        case 'noRoi'
                            disp('NoRoi')
                    end
                    %% Calculate meanpic, rois
                    if calc
                        
                        if multiroi==1 %% Calc unit
                            for cellID=1:size(frameSet,1)/AOSize
                                clear start AOCell;
                                for id=1:size(frameSet,3)
                                    start=((cellID-1)*AOSize)+1;
                                    stop=(start+AOSize)-1;
                                    AOCell(:,:,id)=frameSet(start:stop,:,id);
                                end
                                unit(cellID).mean=mean(AOCell,3,'omitnan');
                            end %% cell level
                            
                        end
                        
                        
                        [idArray,meanPic]=unit2shape(unit,'Mode','chessboard','Dataname','mean','ConvertMap',1);
                        meanPic = im2uint16(meanPic);
                        greenVec=linspace(0,1,65535);
                        gmap=[zeros(65535,1)';greenVec;zeros(65535,1)']';
                        data(unitID).gmap=gmap;
                        data(unitID).meanPic=meanPic;
                        data(unitID).realSlice=prew;
                        data(unitID).subindex=subindex;
%                         Im=logical(zeros([414 240]))
%                         for i=1:9
%                             I=decompressROI(data(unitID).logicalROI(i).roi,[size(data(unitID).meanPic,1),size(data(unitID).meanPic,2)])
%                             Im=Im|logical(I);
%                         end
%                         
%                         figure,imagesc(imoverlay(data(unitID).meanPic,bwperim(Im),[1 0 0]))
%                         %figure,imagesc(meanPic), colormap(gmap);
                        %%
                        if multiroi~=1
                            blocksize=size(unit(1).mean);
                            meanpicsize=size(meanPic);
                            for idy=1:size(idArray,1)
                                for idx=1:size(idArray,2)
                                    meanpicMask=logical(zeros(meanpicsize));
                                    idArray(idy,idx);
                                    
                                    my=(1:blocksize(1))+(blocksize(1)*(idy-1));  %% 46
                                    mx=(1:blocksize(2))+(blocksize(2)*(idx-1));  %% 20
                                    if idArray(idy,idx)~=0
                                        meanpicMask(my,mx)=1;
                                        %%% ROI COMPRESSION
                                        CC = bwconncomp(meanpicMask);
                                        data(unitID).logicalROI(idArray(idy,idx)).roi=CC.PixelIdxList{1, 1};
                                        %%% ROI COMPRESSION
                                        s = regionprops(meanpicMask,'centroid','MajorAxisLength');
                                        data(unitID).logicalROI(idArray(idy,idx)).centroid = cat(1, s.Centroid);
                                        data(unitID).logicalROI(idArray(idy,idx)).axisLength=s.MajorAxisLength;
                                        %% Create poly roi
                                        mxp=mx;
                                        myp=my;
                                        xd=mxp(end)-mxp(1);
                                        yd=myp(end)-myp(1);
                                        polyx=[mxp(1) mxp(1)+xd mxp(1)+xd   mxp(1)  mxp(1)];
                                        polyy=[myp(1) myp(1)    myp(1)+yd   myp(1)+yd   myp(1)];
                                        data(unitID).CaTransient(idArray(idy,idx)).poly=[polyx;polyy];
                                    end
                                end
                            end
                            
                        end %% if multiroi OFF
                        %% Simulate Attribs
                        %% TODO IF Andy-s code is not working
                        data(unitID).Attributes(1).Shortname='XAxisConversionConversionLinearScale';
                        data(unitID).Attributes(1).Value=1;
                        
                        data(unitID).Attributes(2).Shortname='YAxisConversionConversionLinearScale';
                        data(unitID).Attributes(2).Value=1;
                        
                        data(unitID).Attributes(3).Shortname='GeomTransTransl';
                        data(unitID).Attributes(3).Value=[-300;-300;-6.663220000000000e+03];
                        
                        
                    end
                    
                otherwise
                    error('ezittnemkene 8362352')
            end
            if ishandle(h2), waitbar(unitID/numel(f),h2); else disp('Export interrupted by user.'),break, end
            
            data(unitID).MeasureNumber=unitID;

            % unit(unitID).meta=attribs;
            disp(['Unit ready: ' num2str(unitID)]);
            
            if saveraw
                
                h5groupName=['/Unit' num2str(unitID)];
                [pathstr,name,ext]=fileparts(filelocation)
                fname=[exportlocation '\' name '.h5'];
                %% frameSet
                type=whos('frameSet');
                h5create(fname,[h5groupName '/Frameset'],size(frameSet),'Datatype',type.class,'ChunkSize',size(frameSet),'Deflate',1,'Shuffle',true);
                h5write(fname,[h5groupName '/Frameset'],frameSet);
                fileattrib(fname,'+w');
                h5writeatt(fname,h5groupName,'unitID',unitID);
                disp(['Raw HDF5 saved from unit:' num2str(unitID)]);
                %% mean
            end
        end %% unit level
        
        if preview
            nmth=copy(f(1));
            I=get(nmth, 1, 'IMAGE');
            I=zeros(size(I));
            for i=1:size(prev,3)
                G=prev(:,:,i);
                I(:,(lineInfo.linenums(i):lineInfo.linenums(i)+lineInfo.lineshiftnum-1))=fliplr(uint16(G));
            end
%           stopIM=lineInfo.linenums(i)+lineInfo.lineshiftnum-1
%           I2=I(:,1:stopIM);
           %% TO DO line stop %%
            set(nmth, 1, 'IMAGE', I);
            
            filer('filelista_refresh');
            filer('file_new');
           [pathstr,name,ext]=fileparts(filelocation);
           fname=[name '_Preview' ext];
           file_write_mestag_mes([exportlocation '\' fname], nmth);
           delete(mestaghandle('isc'))
          %  succs2=file_save('noq', [], [exportlocation '\' fname]);
            
        end
        
        %end
        
%         mainsettings.dirDATA=diri;
        if ishandle(h2),close(h2);end
        
 
    
    
    
    disp(['Unit ready:' num2str(unitID)])
    
    %save([exportlocation '\meta.mat'],'unit','-v7.3')
    %% LOAD STIM BLOCKS
    if stimload
        clear stims stimCode
        errorlog=[];
        stims = dlmread(stimlocation,';',0,0);
        codes=[1 2 3  4  5   6   7   8   9; ...
            999 0 45 90 135 180 225 270 315]';
        toc
        
        stimsCode=stims
        % for c=1:length(codes)
        %    stimsCode(stims==codes(c,2))=codes(c,1);
        % end
        %%
        for sc=1:length(stimsCode)
            for c=1:length(codes)
                if stimsCode(sc,2)==codes(c,2)
                    stimsCode(sc,2)=codes(c,1);
                end
            end
        end
        
        
        
        disp('Stimd Data load: 100%');
        %%
        try
            
            for globalID=1:length(data)
                data(globalID).subindexRead=stims(globalID,1);
                if data(globalID).subindex~=data(globalID).subindexRead;
                    warning('Stim file incompatible!!!!!!!!!!!!!!!!!!!!!');
                    errorlog(end+1)=num2str(globalID)
                    save([exportlocation '\errorlog.mat'],'errorlog','-v7.3')
                end
                data(globalID).ProtocolOrientationID=stimsCode(globalID,2);
                data(globalID).PredictedOrientationID=stimsCode(globalID,2);
                data(globalID).ProtocolStim=stims(globalID,2);
            end
            [~,index] = sortrows([data.MeasureNumber].'); data = data(index); clear index
            [~,index] = sortrows([data.ProtocolOrientationID].'); data = data(index); clear index
            
            
            orientNumber=max([data(:).PredictedOrientationID]);
            sessionNumber=sum([data(:).PredictedOrientationID]==2);  %% check the 2. stim counts
            
            dataids=1:length(data);
            for orid=1:orientNumber
                num=numel(data([data.ProtocolOrientationID]==orid));
                idvect=[data.ProtocolOrientationID]==orid;
                dataids(idvect)=1:num;
            end
            dataids(dataids>sessionNumber)=0;
            
            for globalID=1:length(data)
                data(globalID).Session=dataids(globalID);
                data(globalID).PredictedSession=dataids(globalID);
            end
            %%
            data([data(:).Session]==0)=[];
            
            if strcmp(savemode,'multiMat')
                if ~preview
%                 save([exportlocation '\data.mat'],'data','-v7.3')
                end
            end
        catch
            warning('Parsing_error')
%             
%             save([exportlocation '\errorlog.mat'],'errorlog','-v7.3')
        end
    else
        if ~preview
%         save([exportlocation '\data.mat'],'data','-v7.3')
        end
    end
%%
disp(unitID)

figure;
FS = mean(frameSet,3);
FS = FS';
FS = flip(FS);
imagesc(FS);

nROI = numel(data.logicalROI);
hold on;
for iROI = 1:nROI
    [B,L] = bwboundaries(data.CaTransient(iROI).mask,'noholes');
    for k = 1:length(B)
        boundary = B{k};
        plot(boundary(:,2), boundary(:,1), 'w', 'LineWidth', 2);
        text(boundary(1,2), boundary(1,1),num2str(k));
    end
end

function [subindex,prew,frameSet,lineInfo,attribs]=foldedframe2xyz2Own(in,chaninput)
%usage foldedframe2xyz2 f21
%xyt meresse konvertalja a foldedframe merest
% getFold dFrameMestag-t kene hivni: todo
f=mestaghandle(in);
chan=getcontchannel(f, 'Measure');
chan=chan(chaninput);
%%
p=getcontchannel(f, 'Measure', chan{1});
DescFoldedFrames = parseFoldedFrames(in);
lineshiftnum=DescFoldedFrames.numFrameLines;
heightstep=DescFoldedFrames.TransverseStep;

N=get(f, p(1), 'Height');
I=get(f, 1, 'IMAGE'); %#ok<NASGU> %hogy biztos betöltõdjön az adat
I=get(f);
Ip=I(p(1));
prew=I(end).IMAGE;
subindex=I(1).FileSubindex;

lineindex=mod((Ip.Clipping.savedHeightBegin:Ip.Clipping.savedHeightEnd)-1, lineshiftnum);
lineindex=find(lineindex==0, 1);
linenums=lineindex:lineshiftnum:N;
if linenums(end)+lineshiftnum-1>N
    linenums(end)=[];
end
N=length(linenums);
if N==0
    error('No full frames saved')
end

lineInfo.linenums=linenums;
lineInfo.lineshiftnum=lineshiftnum;

Ib=[];
Ib.Type='XY';
Ib.Context='Measure';
Ib.D3Size=N;
Ib.D3Name='t';
Ib.D3Unit='ms';
Ib.D3Origin=Ip.HeightOrigin+(lineindex-1)*Ip.HeightStep;
Ib.D3Step=get(f, p, 'HeightStep')*lineshiftnum;
Ib.Width=size(Ip.IMAGE, 1);
Ib.WidthStep=Ip.WidthStep;
Ib.WidthOrigin=0;
Ib.WidthName='L_p';
Ib.WidthUnit='um';
Ib.Height=lineshiftnum;
Ib.HeightStep=heightstep;
Ib.HeightOrigin=0;
Ib.HeightName='L_t';
Ib.HeightDirection='normal';
Ib.HeightUnit='um';
Ib.Zlevel=Ip.Zlevel;
Ib.ZlevelOrigin=Ip.ZlevelOrigin;
Ib.ZlevelArm=Ip.ZlevelArm;
Ib.ZlevelFast=Ip.ZlevelFast;

I2=repmat(Ib, 1, (N*length(chan)));
wh=waitbar(0, 'Calc...');

for j=1:length(chan)
    p=getcontchannel(f, 'Measure', chan{j});
    Ip=I(p(1));
    I2=setfields(I2, 1+(j-1)*N, Ip); %elsõ mezõbe az infók
    I2=setfields(I2, 1+(j-1)*N, Ib);
    for i=1:N
        k=i+(j-1)*N;
        I2(k).Channel=chan{j};
        I2(k).D3Place=i;
        I2(k).IMAGE=fliplr(Ip.IMAGE(:, (linenums(i):linenums(i)+lineshiftnum-1)));
        frameSet(:,:,k)=I2(k).IMAGE;
        waitbar(k/(N*length(chan)), wh)
    end
end
close(wh)
f=[];
%fout=mestaghandle('clipboard', I2);
%I= rmfield(I,'IMAGE');
attribs=I;