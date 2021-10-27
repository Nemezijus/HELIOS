function MR = parse_mescroi_onacid(floc, mescloc, saveloc, z, RR)
% MR = parse_mescroi_onacid(floc) - collect onacid exported mescroi file
% ROI contours to a struct MR
if nargin < 5
    RR = [];
end
if nargin < 4
    z = 0;
end
if nargin < 3
    saveloc = [];
end

if isempty(saveloc)
    tosave = 0;
else
    tosave = 1;
end
if nargin > 1
    info = h5info(mescloc);
    M0 = info.Groups(ismember({info.Groups.Name},'/MSession_0'));
    U0 = M0.Groups(1);
    translocation = h5readatt(mescloc,U0.Name,'GeomTransTransl');
end

if isempty(RR)
    
    fid = fopen(floc);
    T = textscan(fid,'%s');
    T = T{1,1};
    fclose(fid);
    
    counter = 1;
    
    begin = 0;
    MR(1).X = [];
    MR(2).Y = [];
    isx = 1;
    for it = 1:numel(T)
        ct = T{it};
        if strcmp(ct,'"vertices":')
            begin = 1;
        end
        if strcmp(ct,'},')
            begin = 0;
            counter = counter +1;
            MR(counter).X = [];
            MR(counter).Y = [];
        end
        
        if begin
            if ~isnan(str2double(ct))
                if isx
                    MR(counter).Y = [MR(counter).Y,str2double(ct)];
                    isx = 0;
                else
                    MR(counter).X = [MR(counter).X,str2double(ct)];
                    isx = 1;
                end
            end
        end
    end
end
if tosave
    if (~isempty(RR))
        MM = reshape([RR.adjusted_centroid]', [3, numel([RR.adjusted_centroid])/3])';
        rMM = rotation(MM(:,[2,1]),-135) + translocation(1:2)';
        MM(:,1:2) = rMM;
    else
        ma = 0;
        for iMR = 1:numel(MR)
            if numel(MR(iMR).X) > ma
                ma = numel(MR(iMR).X);
            end
        end
        
        MM = zeros(numel(MR),3).*NaN;
        
        counter = 1;
        for iMR = 1:numel(MR)
            MM(iMR, 1) = MR(counter).Y;
            MM(iMR, 2) = MR(counter).X;
            MM(iMR, 3) = z;
            counter = counter+1;
        end
        rMM = rotation(MM(:,1:2),-135) + translocation(1:2)';
        MM(:,1:2) = rMM;
    end
    [a,b,c] = fileparts(floc);
    filename = [saveloc,'\',b,'.xlsx'];
    writematrix(MM,filename,'Sheet',1,'Range','A2');
    writecell({'X','Y','Z'},filename,'Sheet',1,'Range','A1');
end