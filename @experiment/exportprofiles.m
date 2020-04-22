function exportprofiles(OB, saveloc)
% exportprofiles(OB, saveloc) - bulk export profiles to a given location
% saveloc. If location is not provided, user will be asked to specify the
% location manually.
% part of HELIOS
if nargin < 2
    saveloc = uigetdir;
end

Nroi = OB.N_roi;

for iroi = 1:3
    OB.profile(iroi);
    F = gcf;
    name = [OB.id,'_ROI_number_',num2str(iroi),'_ROI_PROFILE'];
    saveas(F,[saveloc,'\',name],'png');
%     export_fig([saveloc,'\',name],'-r256','-png','-painters');
    close(F)
end