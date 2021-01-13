function collectdata(setup, MC_ROI_PAIRS)
% collectdata(setup, MC_ROI_PAIRS) - creates data.mat files from provided
% pairs of motion corrected files and mescroifiles. If multiple mescroi 
% files are specified per one mot.corr. file then they are applied one by
% one for each unit within the mot.corr. file.

mrp = MC_ROI_PAIRS;
clear MC_ROI_PAIRS

for ip = 1:numel(mrp)
    mcfileloc = mrp(ip).motcorr;
    roifileloc = mrp(ip).mescroi;
    mcf = strsplit(mcfileloc,'\');
    mcf = mcf(1:end-1);
    saveloc = strjoin(mcf,'\');
    switch setup
        case 'ao'
            if iscell(roifileloc)
                mode='multi';
                units = 1:numel(roifileloc);
                for ic = 1:numel(roifileloc)
                    out = AOExporterVR(mcfileloc,roifileloc{ic},[],saveloc,mode,units);
                    d(ic).data = out;
                end
                data=[];
                for i=1:length(units)
                    data=[data d(i).data]
                end
                save([saveloc '\data.mat'],'data','-v7.3')
            else
            end
            
        case 'reso'
    end
end