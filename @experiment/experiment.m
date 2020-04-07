classdef experiment
    properties
        file_loc
        id
        setup
        stim_type
        dff_type
        bg_corrected
        N_roi
        N_stages
        N_stim
        N_reps
        paths
        restun
    end
    methods
        function obj = experiment(fileloc)
            info = h5info(fileloc);
            %two branches
            datagroup = info.Groups(ismember({info.Groups.Name},'/DATA'));
            analysisgroup = info.Groups(ismember({info.Groups.Name},'/ANALYSIS'));
            obj.file_loc = fileloc;
            value = geth5attribute(info, 'ANIMALID');
            if iscell(value)
                obj.id = value{:};
            else
                obj.id = value(:);
            end
            
            value = geth5attribute(info, 'SETUP');
            if iscell(value)
                obj.setup = value{:};
            else
                obj.setup = value(:);
            end
            
            value = geth5attribute(info, 'STIMTYPE');
            unvalues = unique(value);
            if numel(unvalues) == 1
                obj.stim_type = unvalues{:};
            else
                obj.stim_type = unvalues;
            end
            
            value = geth5attribute(info, 'DFFTYPE');
            if iscell(value)
                obj.dff_type = value{:};
            else
                obj.dff_type = value(:);
            end
            
            value = geth5attribute(info, 'ISBGCORRECTED');
            obj.bg_corrected = value;
            if ~isempty(analysisgroup)
                obj.N_roi = numel(analysisgroup.Groups);
            else
                obj.N_roi = numel(datagroup.Groups(1).Groups(1).Groups);
            end
            obj.N_stages = numel(datagroup.Groups);
            N_stim = [];
            for istage = 1:obj.N_stages
                N_stim(istage) = numel(unique(geth5attribute(datagroup.Groups(istage), 'STIMID')));
            end
            obj.N_stim = N_stim;
%             obj.N_stim = numel(unique(geth5attribute(info, 'STIMID')));
            N_reps = [];
            for istage = 1:obj.N_stages
                N_reps(istage) = numel(unique(geth5attribute(datagroup.Groups(istage), 'REPID')));
            end
            obj.N_reps = N_reps;
            P = h5pathing(info);
            P = regexprep(P, '\d+(?:_(?=\d))?', '');%eliminates numbers
            P = unique(P);
            for ip = 1:numel(P)
                cp = strsplit(P{ip},'/');
                cp = cp(~cellfun(@isempty, cp));
                for icp = 1:numel(cp)
                    paths{ip,icp} = cp{icp};
                end
            end
            obj.paths = paths;
            
            for istage = 1:obj.N_stages
                try %first try in ANALYSIS branch
                    for istim = 1:obj.N_stim
                        for irep = 1:obj.N_reps(istage)
                            gr(istim, irep) = analysisgroup.Groups(1).Groups(istage).Groups(istim).Attributes.Value(irep);
                        end
                    end
                catch %otherwise go to DATA branch
                    nunits = numel(datagroup.Groups(istage).Groups);
                    for iunit = 1:nunits
                        irep = datagroup.Groups(istage).Groups(iunit).Attributes(ismember({datagroup.Groups(istage).Groups(iunit).Attributes.Name},'REPID')).Value;
                        istim = datagroup.Groups(istage).Groups(iunit).Attributes(ismember({datagroup.Groups(istage).Groups(iunit).Attributes.Name},'STIMID')).Value;
                        loc = datagroup.Groups(istage).Groups(iunit).Name;
                        locstr = strsplit(loc,'/');
                        unitstr = regexp(locstr{end},['\d+\.?\d*'],'match');
                        gr(istim,irep) = str2num(unitstr{:});
                    end
                end
                restun{istage} = gr;
                clear gr
            end
            obj.restun = restun;
        end
        
    end
end