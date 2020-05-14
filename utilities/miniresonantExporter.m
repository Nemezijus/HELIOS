function data = miniresonantExporter(filelocation,roilocation)
polyPi=0.01;
mescmod='1';
roiVer='all';  %%%'all'/egy ROI egy mesc,  'repeat' / roi, 'frameSet' :minden framesethez külön roi
measurementType='Resonant';
load('STIMS9RAND.mat');
protocol='2randBlock';
spec='Nontompadendritek';
%% Test
switch measurementType
    case 'Resonant'
 
        
        polyPi=0.1;
        %fast=handles.mode
        orientationDef=9; %% hány irány van egy sessionben
        fast='on';
        fmean=20;
        dynThreshold=0.4;
        clear info data
        info=hdf5info(filelocation);
        data=info.GroupHierarchy.Groups.Groups;
        
        for id=1:size(data,2)
            %%% LOAD Attribs
            data(id).frameTime=findAttrib(data(id).Attributes,'ZAxisConversionConversionLinearScale');
            data(id).frameTimeUnit=findAttrib(data(id).Attributes,'ZAxisConversionUnitName');
            data(id).frameRate=1/data(id).frameTime;
            data(id).MeasureDate=findAttrib(data(id).Attributes,'MeasurementDatePosix');
            upper=findAttrib(data(id).Attributes,'Channel_0_Conversion_UpperLimitUint16');
            offset=findAttrib(data(id).Attributes,'Channel_0_Conversion_ConversionLinearOffset');
            data(id).offset=double(upper-offset);
            data(id).offsetImp=offset;
            %%%%%%
            comment=findAttrib(data(id).Attributes,'Comment');
            c=str2num(char(comment'));
            data(id).Comment=c;
            if isempty(c)&&(~isempty(comment))
                c=char(comment') ;
                data(id).Comment=c;
            end
        end
        [~,index] = sortrows([data.MeasureDate].');data = data(index);clear index
        % data=motionImporterWithoutGUI(mescPath(mescID).mesc,data);
        %%%% KOMMENTEK (Session ID) kiolvasása és Sessionok beírása
        %%%% Predicted: Amit az elemszám alapján kiadna, (8 irány/session),
        %%%% Session: Amit a kommentekb?l kiolvas. Más string esetében egyel?re
        %%%% ''-t ad...
        cBuffer=data(id).Comment;
        sessionCounter=1;
        for id=1:size(data,2)
            data(id).One=1;
            data(id).MeasureNumber=id;
            data(id).PredictedOrientationID=mod(id,orientationDef);
            data(id).PredictedSession=sessionCounter;
            if(mod(id,orientationDef)==0)
                sessionCounter=sessionCounter+1;
                data(id).PredictedOrientationID=orientationDef;
            end
            if isnumeric(data(id).Comment)
                data(id).Session=data(id).Comment;
                cBuffer=data(id).Comment;
                data(id).MeasureNumber=id;
            else
                data(id).Session=cBuffer;
            end
            if (data(id).Session~=data(id).PredictedSession)
%                 warning(strcat('String session comment, please check element number manually at dataset: ',num2str(id)))
                log(id).commenterror=id;
            end
        end
        
        map=[zeros(256,1)'; [0:1/255:1]; zeros(256,1)']';
        
        %%%%%%%%%%%%% Clear pictures / MESc
        data=pathDelete(data,'Zdim1','Type','Picture');
        
        %%%%%%%%%%%%%% Protocol spec
        %%
        sessionNumber=max([data(:).PredictedSession]);
        repeatBlock=STIMS(2,:);
        repeatBlockAll=repmat(repeatBlock,1,round(sessionNumber/2));
        for i=1:size(data,2)
            data(i).ProtocolOrientationID=repeatBlockAll(i);
            switch protocol
                case '2randBlock'
                    data(i).PredictedOrientationID=repeatBlockAll(i);
                otherwise
            end
        end
        
        
        %%
        %%%%%%%%%%%%%% Protocol spec
        %%%%% Teljes frameSet m?velet
        outStruct = xml2struct2(roilocation);
        for id=1:size(data,2)  %% ID egy mérés videó
            data(id).Nroi = numel(outStruct.MESconfig.ROIs.Polygon);
%             disp(['Reading measure dataset:' num2str(id)]);
            %%
            %%
            nameCh={data(id).Datasets.Name};
            fnameCh={data(id).Datasets.Filename};
            frameSet=65535-flip(h5read(fnameCh{1},nameCh{1}),2);
            
            %%
            convY=findAttrib(data(id).Attributes,'YAxisConversionConversionLinearScale');
            convX=findAttrib(data(id).Attributes,'XAxisConversionConversionLinearScale');
            %disp(strcat('Converse rate 1 pixel/micron ratio: ',num2str(convY),'x',num2str(convX)));
            %%
            %%xylinoff
            
            %%
            ax=double(findAttrib(data(id).Attributes,'XDim'));
            ay=double(findAttrib(data(id).Attributes,'YDim'));
            geomTrans=double(findAttrib(data(id).Attributes,'GeomTransTransl'));
            data(id).geomTrans = geomTrans;
            data(id).convX = convX;
            data(id).convY = convY;
            %                 yoffset=double(findAttrib(data(id).Attributes,'YAxisConversionConversionLinearOffset'))
            %                 xoffset=double(findAttrib(data(id).Attributes,'XAxisConversionConversionLinearOffset'))
            if mescmod=='0'
                
                %% ZIP SUCKER
            end
            %%
            if mescmod=='1'
                clear R ROI %outStruct ;
                switch roiVer
                    
                    case 'all'
                        roiSpecial=data(id).One;
%                         outStruct = xml2struct2(roilocation);
                        data(id).roiSpec=roilocation;
                        
                end
                
                if isfield(outStruct.MESconfig.ROIs,'Polygon')
                    polyType='Polygon';
                    
                end
                
                if isfield(outStruct.MESconfig.ROIs,'RegularPolygon')
                    polyType='RegularPolygon';
                end
                
                switch polyType
                    case 'Polygon'
                        for i=1%:size(outStruct.MESconfig.ROIs.Polygon,2)
                            polysize=length(outStruct.MESconfig.ROIs.Polygon{1, i}.param);
                            for p=1:polysize
                                outStruct.MESconfig.ROIs.Polygon{1, i}.param{1, p}.Attributes.value;
                                a=strsplit(outStruct.MESconfig.ROIs.Polygon{1, i}.param{1, p}.Attributes.value,{' '},'CollapseDelimiters',true);
                                R(i).POLY(1,p)=str2num(a{1});
                                R(i).POLY(2,p)=str2num(a{2});
                            end
                        end
                        
                    case 'RegularPolygon'
                        for i=1%:size(outStruct.MESconfig.ROIs.RegularPolygon,2)
                            polysize=length(outStruct.MESconfig.ROIs.RegularPolygon{1, i}.param);
                            for p=1:polysize
                                outStruct.MESconfig.ROIs.RegularPolygon{1, i}.param{1, p}.Attributes.value;
                                a=strsplit(outStruct.MESconfig.ROIs.RegularPolygon{1, i}.param{1, p}.Attributes.value,{' '},'CollapseDelimiters',true);
                                R(i).POLY(1,p)=str2num(a{1});
                                R(i).POLY(2,p)=str2num(a{2});
                            end
                            %% Octogon to Poly
                            clear POLY2 POLY3 POLY4 ang OCTPOLY
                            ang=360/8;
                            RS=[cosd(ang) -sind(ang);...
                                sind(ang) cosd(ang)];
                            POLY2= R(i).POLY;
                            ZX=(0-(POLY2(1,1)));
                            ZY=(0-(POLY2(2,1)));
                            POLY3(1,:)=POLY2(1,:)+ZX;
                            POLY3(2,:)=POLY2(2,:)+ZY;
                            OCTPOLY(:,1)=POLY3(:,2);
                            for k=1:8
                                OCTPOLY(:,k+1)=RS*OCTPOLY(:,k);
                            end
                            OCTPOLY(1,:)=OCTPOLY(1,:)-ZX;
                            OCTPOLY(2,:)=OCTPOLY(2,:)-ZY;
                            R(i).POLY=[];
                            R(i).POLY=OCTPOLY;
                        end
                end
                
                
                %%%
                %%TODO Rectangular
                %%%
                %%
                
                
                %%
                
                
                %% PolyDefense patch
                
                for i=1:size(R,2)
                    if  size(R(i).POLY,2)<=3
                        R(i).Err=1;
                    else
                        R(i).Err=0;
                    end
                end
                R([R.Err]==1)=[];
                
               
                %%
                
                
                for i=1:size(R,2)
                    ang=90;
                    RS=[cosd(ang) -sind(ang);...
                        sind(ang) cosd(ang)];
                    clear POLY2 POLY3 POLY4
                    POLY2=R(i).POLY;
                    
                    if strcmp(spec,'tompadendritek')
                        %%%%%%%%%%%% csak tompaDendriteknl
                        info=hdf5info('C:\1\1.mesc');
                        dataT=info.GroupHierarchy.Groups.Groups;
                        geomTrans=double(findAttrib(dataT(1).Attributes,'GeomTransTransl'));
                        convY=findAttrib(dataT(1).Attributes,'YAxisConversionConversionLinearScale');
                        convX=findAttrib(dataT(1).Attributes,'XAxisConversionConversionLinearScale');                               %%%%%%%%%%%%%
                    end
                    
                    
                    POLY2(1,:)=(POLY2(1,:)-geomTrans(1))/convX;
                    POLY2(2,:)=(POLY2(2,:)-geomTrans(2))/convY;
                    
                    %% Shift back to rotate
                    POLY2(1,:)=(POLY2(1,:))-(ax/2);
                    POLY2(2,:)=(POLY2(2,:))-(ay/2);
                    %% Rot in pixel system
                    POLY3=RS*POLY2;
                    
                    %% Shift back to rotate
                    POLY4(1,:)=(POLY3(1,:))+(ax/2);
                    POLY4(2,:)=(POLY3(2,:))+(ay/2);
                    %
                    ROI(i).poly=POLY4;
                    
                    switch polyType
                        case 'Polygon'
                            ROI(i).RoiIDReal=outStruct.MESconfig.ROIs.Polygon{1, i}.Attributes.id;
                        case 'RegularPolygon'
                            ROI(i).RoiIDReal=outStruct.MESconfig.ROIs.RegularPolygon{1, i}.Attributes.id;
                    end
                end
            end
            [~,index] = sortrows({ROI.RoiIDReal}.'); ROI = ROI(index); clear index
            %%
            mask=zeros([ax ay]);
            for i=1%:size(ROI,2)
                p1 = denan(ROI(i).poly(1,:));
                p2 = denan(ROI(i).poly(2,:));
                ROI(i).poly = [];
                ROI(i).poly(1,:) = p1;
                ROI(i).poly(2,:) = p2;
                maskBuffer = logical(poly2mask(ROI(i).poly(1,:),ROI(i).poly(2,:),ax,ay));
                %%%%%1pixelimdilate,hogy szebb legyen az oval körvonal
                maskBuffer=imdilate(maskBuffer,strel('disk',1));
                
                if strcmp(fast,'off')
                    %%%%% DONUT or DO NOT? <- Pun
                    maskBuffer2 = bwdist(maskBuffer) <= 10;
                    maskBuffer=maskBuffer2-maskBuffer;
                    %%%%% DONUT
                end
                %mask=mask|maskBuffer;
            end
            
            %%%% mean pic LUT
            
            upper=findAttrib(data(id).Attributes,'Channel_0_Conversion_UpperLimitUint16');
            offset=findAttrib(data(id).Attributes,'Channel_0_Conversion_ConversionLinearOffset');
            LUT=findAttrib(data(id).Attributes,'Channel_0_LUT_VecBounds');
            stage=round(LUT(end))-round(LUT(1));
            Vec=zeros(upper,1)';
            greenVec=linspace(0,1,stage);
            Vec(round(LUT(1)):round(LUT(1))+stage-1)=greenVec;
            Vec(round(LUT(end)):upper)=1;
            gmap=[zeros(upper,1)';Vec;zeros(upper,1)']';
            
            
            for i=1%:size(ROI,2)
                intensityVector=[];
                RingIntensityVector=[];
                maskBuffer = logical(poly2mask(ROI(i).poly(1,:),ROI(i).poly(2,:),ax,ay));
                %%%%%%%%%%%%%%%%%%% Dilate 1pixel
                maskBuffer=imdilate(maskBuffer,strel('disk',1));
                %%%%%%%%%%%%%%%%%%% Dilate 1pixel
                %% ROI COMPRESSION
                CC = bwconncomp(maskBuffer);
                data(id).logicalROI(i).roi=uint64(CC.PixelIdxList{1, 1});
                %% ROI COMPRESSION
                s = regionprops(maskBuffer,'centroid','MajorAxisLength');
                data(id).logicalROI(i).centroid = cat(1, s.Centroid);
                data(id).logicalROI(i).axisLength=s.MajorAxisLength;
                
                %%
%                 disp(['ROI:' num2str(i) ' Dataset:' num2str(id)]);
                %%%%% Mean
                if i==1;clear framePool;framePool=uint32(zeros([size(frameSet,1) size(frameSet,2) 1]));
                end
                
                %%%%%% Indexing CORE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                 for j=1:size(frameSet,3) %% frame
%                     I=frameSet(:,:,j);
%                     frameOffset=(I)-data(id).offset;
%                     v=I(maskBuffer);
%                     intensityVector(j)=mean(v);
%                     if i==1;framePool=framePool+uint32(frameOffset);
%                     end
%                 end
                
                if i==1;meanPic=uint16(framePool/(size(frameSet,3)));
                end
                %%%%%%  Indexing CORE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                
                %%%%%Correct sample time
%                 t=0:size(intensityVector,2)-1;
                t=0:size(frameSet,3)-1;
                data(id).frameTime=findAttrib(data(id).Attributes,'ZAxisConversionConversionLinearScale');
                ROI(i).event(1,:)=(data(id).frameTime*t);
%                 offset=65535-data(id).offsetImp;
%                 ROI(i).event(2,:)=intensityVector-offset;
                ROI(i).RoiID=i;
                clear intensityVector;
            end
            
            %%%% CA GÖRBE RÖGZítés
            data(id).CaTransient=ROI;
            data(id).gmap=gmap;
            data(id).meanPic=meanPic;
%             disp(['Saved:' num2str(id)]);
            
            %%
        end
        [~,index] = sortrows([data.PredictedOrientationID].');
        data = data(index);
        clear index
        %%
     
%         save(strcat(exportlocation,'\data.mat'),'data','-v7.3');
%         disp('Data saved: 100%');

        
        
end
