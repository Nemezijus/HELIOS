function MR = parse_mescroi_onacid(floc, tosave)
% MR = parse_mescroi_onacid(floc) - collect onacid exported mescroi file
% ROI contours to a struct MR
if nargin < 2
    tosave = 0;
end
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
if tosave
    ma = 0;
    for iMR = 1:numel(MR)
        if numel(MR(iMR).X) > ma
            ma = numel(MR(iMR).X);
        end
    end
    
    MM = zeros(ma,2*numel(MR)).*NaN;
    
    counter = 1;
    for iMR = 1:2:2*numel(MR)
        MM(1:numel(MR(counter).X),iMR) = MR(counter).X;
        MM(1:numel(MR(counter).Y),iMR+1) = MR(counter).Y;
        counter = counter+1;
    end
    
    [a,b,c] = fileparts(floc);
    filename = ['N:\DATA\andrius.plauska\test\RTMC_test\',b,'.xlsx'];
    writematrix(MM,filename,'Sheet',1,'Range','A2');
    writecell(repmat({'X','Y'},1,numel(MR)),filename,'Sheet',1,'Range','A1');
end