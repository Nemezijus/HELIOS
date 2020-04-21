classdef hubroot
properties
    fpath
    fdata
    mouseIDs
end
methods
    function [obj] = hubroot(~)
     obj.fpath = 'N:\DATA\Betanitas\!Mouse Gramophon\HUB_root';
     obj.fdata = dir(obj.fpath);
     obj.fdata = obj.fdata(~ismember({obj.fdata.name}, {'.', '..'}));
     obj.mouseIDs = cellfun(@(x)x(2:end-4),{obj.fdata.name},'UniformOutput', false);
    end
    
    function [mousedata] = load_mousedata(obj, mouseID)
        if any(ismember(obj.mouseIDs, mouseID))
            idx = find(strcmp(obj.mouseIDs, mouseID));
            mouse = load([obj.fdata(idx).folder, '\', obj.fdata(idx).name]);
            mousename = obj.fdata(idx).name;
            mousename = mousename(1:end-4);
            mousedata = mouse.(mousename);
        else
            disp(['HUBroot folder does not contain mouse identified as ', mouseID]);
        end
    end
end
end