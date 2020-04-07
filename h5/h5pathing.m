function P = h5pathing(f, P)
% P = h5pathing(f) - collects path segments into a cell array P of the
% provided f branch
if nargin == 1
    P = {};
end
if ~isempty(f.Groups)
    for ig = 1:numel(f.Groups)
        cg = f.Groups(ig);
        if isempty(cg.Groups)
            P{numel(P)+1} = cg.Name;
        else
            P = h5pathing(cg,P);
        end
    end
end
% regexprep(groupnames{1}, '\d+(?:_(?=\d))?', '')