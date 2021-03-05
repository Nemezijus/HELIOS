function value = geth5attribute(info, name, value)
% value = geth5attribute(info,name) - locates the attribute specified by
% string variable name and returns its value. info - the info struct of h5
% file called by h5info. If the same attribute is present in multiple
% branches, all values are gathered in an array.

if nargin == 2
    value = [];
end
try
    if ~isempty(info.Groups)
        for ig = 1:numel(info.Groups)
            cg = info.Groups(ig);
            if ~isempty(cg.Attributes)
                attnames = {cg.Attributes.Name};
                membership = ismember(attnames, name);
                if sum(membership) > 0
                    vals = cg.Attributes(membership).Value;
                    if ischar(vals(1)) | iscell(vals(1)) | numel(vals) > 1
                        value{numel(value)+1:numel(value)+sum(membership)} = vals;
                    else
                        value = [value, vals];
                    end
                end
                value = geth5attribute(cg, name, value);
            end
        end
    end
catch
    value = [];
end
