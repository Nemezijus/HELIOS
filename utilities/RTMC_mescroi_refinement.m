function R = RTMC_mescroi_refinement(floc, info, img, mescloc, zcoord, ...
    zidx, saveloc, logname)
%floc - location of the mescroi file
%img - the max projection image [for dimensions only]
if nargin < 5
    zcoord = 0;
end
if nargin < 6
    zidx = 0;
end
MR = parse_mescroi_onacid(floc);
logme(logname, ['mescroi parsed successfuly']);
% info = h5info(info);
M0 = info.Groups(ismember({info.Groups.Name},'/MSession_0'));
U0 = M0.Groups(1);

img = imrotate(flip(img,2),90);
sz = size(img);
Xpix_scale = h5readatt(mescloc,U0.Name,'XAxisConversionConversionLinearScale');
Ypix_scale = h5readatt(mescloc,U0.Name,'YAxisConversionConversionLinearScale');
Xoff = (sz(1)/2)*Xpix_scale;
Yoff = (sz(2)/2)*Ypix_scale;
offset = h5readatt(mescloc,U0.Name, 'GeomTransTransl');
% Xoff = h5readatt(mescloc,U0.Name, 'XAxisConversionConversionLinearOffset');
% Yoff = h5readatt(mescloc,U0.Name, 'YAxisConversionConversionLinearOffset');
% figure; imagesc(img); hold on
for iroi = 1:numel(MR)
    M = [];
    M(1,:) = MR(iroi).X + abs(Xoff);
    M(2,:) = MR(iroi).Y + abs(Yoff);
    [logicalROI] = roimask(M, img);
    rawmask = regionprops(logicalROI,'centroid','MajorAxisLength');
    if numel(rawmask)>1
        rawmask = rawmask(1);
    end
    BW2 = bwboundaries(logicalROI);
    bwperim1 = BW2{1};
    temp = bwperim1(:,1);
    bwperim1(:,1) = bwperim1(:,2); bwperim1(:,2) = temp;
%     bwperim2 = BW2{2};
%     plot(bwperim1(:,1),bwperim1(:,2),'Linestyle','-','Color','w');hold on;
%     plot(bwperim2(:,1),bwperim2(:,2),'Linestyle','-','Color','w');
    R(iroi).original(1,:) = MR(iroi).X;
    R(iroi).original(2,:) = MR(iroi).Y;
    R(iroi).original_adjusted = M;
    R(iroi).pseudo = bwperim1';
    R(iroi).pseudo_centroid = rawmask.Centroid;
    R(iroi).adjusted(1,:) = bwperim1(:,1) - abs(Xoff);
    R(iroi).adjusted(2,:) = bwperim1(:,2) - abs(Yoff);
    R(iroi).adjusted_centroid(1) = rawmask.Centroid(1)- abs(Xoff);
    R(iroi).adjusted_centroid(2) = rawmask.Centroid(2)- abs(Yoff);
    R(iroi).adjusted_centroid(3) = zcoord;
    R(iroi).Xscale = Xpix_scale;
    R(iroi).Yscale = Ypix_scale;
    R(iroi).offset = offset;
end
logme(logname, ['R created successfuly']);

[a,b,c] = fileparts(floc);
[UNIDs, colors] = local_text_parse(floc);

%roi countours
type = 'contours';
saveloc_loc = [saveloc,'\',b,'_contours',c];
fid = fopen(saveloc_loc, 'wt');
local_text_write(fid, R, UNIDs, colors, type, zidx);
fclose(fid);
logme(logname, ['contour mescroi saved successfuly']);

%roi centroids
type = 'centroids';
saveloc_loc = [saveloc,'\',b,'_centroids',c];
fid = fopen(saveloc_loc, 'wt');
local_text_write(fid, R, UNIDs, colors, type, zidx);
fclose(fid);
logme(logname, ['centroid mescroi saved successfuly']);

type = 'centers';
saveloc_loc = [saveloc,'\',b,'_centers',c];
fid = fopen(saveloc_loc, 'wt');
local_text_write(fid, R, UNIDs, colors, type, zidx);
fclose(fid);
logme(logname, ['center mescroi saved successfuly']);



function [UNIDs, colors] = local_text_parse(floc)
text = fileread(floc);
UNIDs = extractBetween(text,'"uniqueID": "','"');
colors = extractBetween(text,'"color": "','"');

function local_text_write(fid, R, UNIDs, colors, type, zidx)
try
    fprintf(fid, '{\n');
    fprintf(fid, '    "rois": [\n');
    for ir = 1:numel(R)
        if ir == numel(R)
            stop = 1;
        else
            stop = 0;
        end
        local_block_write(fid, R(ir), UNIDs{ir}, colors{ir}, ir, stop, type, zidx);
    end
    fprintf(fid,'    ]\n');
    fprintf(fid,'}');
catch
    fclose(fid);
end

function local_block_write(fid, R, unid, color, ir, stop, type, zidx)

try
    fprintf(fid, '        {\n');
    fprintf(fid, ['            "color": "',color,'",\n']);
    fprintf(fid, '            "firstZPlane": %d,\n',zidx);
    fprintf(fid, ['            "label": "%d",\n'],ir);
    fprintf(fid, '            "lastZPlane": %d,\n',zidx);
    fprintf(fid, '            "role": "standard",\n');
    fprintf(fid, '            "type": "polygonXY",\n');
    fprintf(fid, ['            "uniqueID": "',unid,'",\n']);
    fprintf(fid, '            "vertices": [\n');
    switch type
        case 'contours'
            for idx = 1:numel(R.adjusted(1,:))
                fprintf(fid, '                [\n');
                fprintf(fid, ['                    %f,\n'],R.adjusted(2,idx));
                fprintf(fid, ['                    %f\n'],R.adjusted(1,idx));
                if idx==numel(R.adjusted(1,:))
                    fprintf(fid, '                ]\n');
                else
                    fprintf(fid, '                ],\n');
                end
            end
        case 'centroids'
            %             for idx = 1:4
            fprintf(fid, '                [\n');
            fprintf(fid, ['                    %f,\n'],R.adjusted_centroid(1)-1);
            fprintf(fid, ['                    %f\n'],R.adjusted_centroid(2)+1);
%             fprintf(fid, ['                    %f\n'],R.adjusted_centroid(3));
            fprintf(fid, '                ],\n');
            
            fprintf(fid, '                [\n');
            fprintf(fid, ['                    %f,\n'],R.adjusted_centroid(1)+1);
            fprintf(fid, ['                    %f\n'],R.adjusted_centroid(2)+1);
%             fprintf(fid, ['                    %f\n'],R.adjusted_centroid(3));
            fprintf(fid, '                ],\n');
            
            fprintf(fid, '                [\n');
            fprintf(fid, ['                    %f,\n'],R.adjusted_centroid(1)+1);
            fprintf(fid, ['                    %f\n'],R.adjusted_centroid(2)-1);
%             fprintf(fid, ['                    %f\n'],R.adjusted_centroid(3));
            fprintf(fid, '                ],\n');
            
            fprintf(fid, '                [\n');
            fprintf(fid, ['                    %f,\n'],R.adjusted_centroid(1)-1);
            fprintf(fid, ['                    %f\n'],R.adjusted_centroid(2)-1);
%             fprintf(fid, ['                    %f\n'],R.adjusted_centroid(3));
            fprintf(fid, '                ],\n');
            
            fprintf(fid, '                [\n');
            fprintf(fid, ['                    %f,\n'],R.adjusted_centroid(1)-1);
            fprintf(fid, ['                    %f\n'],R.adjusted_centroid(2)+1);
%             fprintf(fid, ['                    %f\n'],R.adjusted_centroid(3));
            fprintf(fid, '                ]\n');
            %                 if idx==4
            %                     fprintf(fid, '                ]\n');
            %                 else
            %                     fprintf(fid, '                ],\n');
            %                 end
            %             end
            case 'centers'
            %             for idx = 1:4
            fprintf(fid, '                [\n');
            fprintf(fid, ['                    %f,\n'],R.adjusted_centroid(1));
            fprintf(fid, ['                    %f\n'],R.adjusted_centroid(2));
            fprintf(fid, '                ]\n');
            %                 if idx==4
            %                     fprintf(fid, '                ]\n');
            %                 else
            %                     fprintf(fid, '                ],\n');
            %                 end
            %             end
    end
    fprintf(fid, '            ]\n');
    if ~stop
        fprintf(fid, '        },\n');
    else
        fprintf(fid, '        }\n');
    end
catch
    fclose(fid);
end