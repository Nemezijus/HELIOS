function R = mescroi2poly(mescroi_path, geomTrans, setup, flag)
% poly = mescroi2poly(mescroi_path, geomTrans, setup, flag) - creates poly struct from
% mescroi file (specified in mescroi_path file)
% part of HELIOS
if nargin < 3
    setup = 'dual';
end
if nargin < 2
    geomTrans = [-168.8; -168.8; -6716.1];
end
convX = 0.6592;
convY = 0.6592;
ax = 512;
ay = 512;

outStruct = xml2struct2(mescroi_path);

switch setup
    case 'ao'
    otherwise
        if isfield(outStruct.MESconfig.ROIs,'Polygon')
            polyType = 'Polygon';
            
        end
        
        if isfield(outStruct.MESconfig.ROIs,'RegularPolygon')
            polyType = 'RegularPolygon';
        end
        
        switch polyType
            case 'Polygon'
                for ip = 1:size(outStruct.MESconfig.ROIs.Polygon,2)
                    polysize=length(outStruct.MESconfig.ROIs.Polygon{1, ip}.param);
                    for p = 1:polysize
                        outStruct.MESconfig.ROIs.Polygon{1, ip}.param{1, p}.Attributes.value;
                        a = strsplit(outStruct.MESconfig.ROIs.Polygon{1, ip}.param{1, p}.Attributes.value,{' '},'CollapseDelimiters',true);
                        R(ip).POLY(1,p)=str2num(a{1});
                        R(ip).POLY(2,p)=str2num(a{2});
                    end
                end
                
            case 'RegularPolygon'
                for ip = 1:size(outStruct.MESconfig.ROIs.RegularPolygon,2)
                    polysize = length(outStruct.MESconfig.ROIs.RegularPolygon{1, ip}.param);
                    for p = 1:polysize
                        outStruct.MESconfig.ROIs.RegularPolygon{1, ip}.param{1, p}.Attributes.value;
                        a = strsplit(outStruct.MESconfig.ROIs.RegularPolygon{1, ip}.param{1, p}.Attributes.value,{' '},'CollapseDelimiters',true);
                        R(ip).POLY(1,p)=str2num(a{1});
                        R(ip).POLY(2,p)=str2num(a{2});
                    end
                    %% Octogon to Poly
                    clear POLY2 POLY3 POLY4 ang OCTPOLY
                    ang=360/8;
                    RS=[cosd(ang) -sind(ang);...
                        sind(ang) cosd(ang)];
                    POLY2= R(ip).POLY;
                    ZX=(0-(POLY2(1,1)));
                    ZY=(0-(POLY2(2,1)));
                    POLY3(1,:)=POLY2(1,:)+ZX;
                    POLY3(2,:)=POLY2(2,:)+ZY;
                    OCTPOLY(:,1)=POLY3(:,2);
                    for k = 1:8
                        OCTPOLY(:,k+1)=RS*OCTPOLY(:,k);
                    end
                    OCTPOLY(1,:)=OCTPOLY(1,:)-ZX;
                    OCTPOLY(2,:)=OCTPOLY(2,:)-ZY;
                    R(ip).POLY = [];
                    R(ip).POLY = OCTPOLY;
                end
        end
        
        for i = 1:size(R,2)
            ang=90;
            RS=[cosd(ang) -sind(ang);...
                sind(ang) cosd(ang)];
            clear POLY2 POLY3 POLY4
            POLY2=R(i).POLY;
            
            
            
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
            
        end
        R = ROI;
end