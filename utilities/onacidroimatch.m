function ROIseq = onacidroimatch(mescroi_before, mescroi_after)
% ROIseq = onacidroimatch(mescroi_before, mescroi_after) - remaps ROI ids
% from the larger pool in 'before' with those that are saved in 'after'.
% This is needed to pick out only good dff traces from OnAcid analysis
% part of HELIOS

mb = mescroi_before;
ma = mescroi_after;

a_fID = fopen(ma,'r');
b_fID = fopen(mb,'r');
A = fscanf(a_fID,'%c');
B = fscanf(b_fID,'%c');
fclose(a_fID);
fclose(b_fID);
% extractBetween
Ared = extractBetween(A,'<Polygon color=','</Polygon>');
Bred = extractBetween(B,'<Polygon color=','</Polygon>');

for iB = 1:numel(Bred)
    cB = extractBetween(Bred{iB},'id="','"');
    BEFORE(iB).roinum = str2num(cB{:});
    BEFORE(iB).string = extractAfter(Bred{iB},'">');
end
for iA = 1:numel(Ared)
    cA = extractBetween(Ared{iA},'id="','"');
    AFTER(iA).roinum = str2num(cA{:});
    AFTER(iA).string = extractAfter(Ared{iA},'">');
end
counter = 1;
for ia = 1:numel(AFTER)
    cafter = AFTER(ia).string;
    for ib = 1:numel(BEFORE)
        cbefore = BEFORE(ib).string;
        if strmatch(cafter,cbefore)
            ROIseq(counter,1) = BEFORE(ib).roinum;
            counter = counter+1;
        end
    end
end
ROIseq = ROIseq + 1; %compensate indexing starting from 0;
