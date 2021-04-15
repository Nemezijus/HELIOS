function collectdata(setup, MC_ROI_PAIRS, stimlist)
% collectdata(setup, MC_ROI_PAIRS, stimlist) - creates data.mat files from provided
% pairs of motion corrected files and mescroifiles. If multiple mescroi
% files are specified per one mot.corr. file then they are applied one by
% one for each unit within the mot.corr. file.

mrp = MC_ROI_PAIRS;
clear MC_ROI_PAIRS
isonacid = 0;

for ip = 1:numel(mrp)
    disp(['working on day ',num2str(ip)]);
    mcfileloc = mrp(ip).motcorr;
    roifileloc = mrp(ip).mescroi;
    behaviorloc = mrp(ip).behavior;
    mcf = strsplit(mcfileloc,'\');
    mcf = mcf(1:end-1);
    saveloc = strjoin(mcf,'\');
    switch setup
        case 'ao'
            if iscell(roifileloc)
                Nmescroi = numel(roifileloc);
            else
                Nmescroi = 1;
            end
            mode='multi';
            file_open([],mcfileloc);
            r = mestaghandle('isf');
            sz = size(r);
            units = 1:sz(2);
            %                 units = 1:numel(behaviorloc);
            if isempty(stimlist)
                for ic = 1:numel(units)
                    if iscell(roifileloc)
                        if Nmescroi < ic
                            roiloc = roifileloc{end};
                        else
                            roiloc = roifileloc{ic};
                        end
                    else
                        roiloc = roifileloc;
                    end
                    disp(['working on unit ',num2str(ic)]);
%                     data = AOExporterVR(mcfileloc,roiloc,[],saveloc,mode,units(ic));
                    data = AOExporter_universal(mcfileloc,roiloc,[],saveloc,mode,units(ic));
                    d(ic).data = data;
                end
                data=[];
                for i=1:length(units)
                    data=[data d(i).data];
                end
            else
%                 data = AOExporter_HELIOS(mcfileloc,roifileloc,stimlist,saveloc,mode);
                data = AOExporter_universal(mcfileloc,roifileloc,stimlist,saveloc,mode,[]);
            end
            
            disp('saving data.mat file');
            save([saveloc '\data.mat'],'data','-v7.3')
            
        case 'reso'
            if isonacid
            else
                if iscell(roifileloc)
                    error('Multiple ROI files are not allowed for resonant data')
                end
                disp('Running ResonantExporter')
                resonantExporter(mcfileloc,roifileloc,saveloc);
                disp('ResonantExporter finished!');
            end
    end
end