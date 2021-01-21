function collectdata(setup, MC_ROI_PAIRS)
% collectdata(setup, MC_ROI_PAIRS) - creates data.mat files from provided
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
                units = 1:numel(behaviorloc);
                for ic = 1:numel(behaviorloc)
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
                    out = AOExporterVR(mcfileloc,r,[],saveloc,mode,units(ic));
                    d(ic).data = out;
                end
                data=[];
                for i=1:length(units)
                    data=[data d(i).data];
                end
                disp('saving data.mat file');
                save([saveloc '\data.mat'],'data','-v7.3')
            else
            end
            
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