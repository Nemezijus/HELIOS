function list_HELIOS
% list_HELIOS - displays on the screen all HELIOS functions, methods and
% classes
p = mfilename('fullpath');
prts = strsplit(p,'\');
prts = prts(1:end-1);
HELIOS_path = strjoin(prts,'\');

Hd = dir(HELIOS_path);
Hd = Hd(3:end);
disp('  ')
disp('  ')
for iHd = 1:numel(Hd)
    if Hd(iHd).isdir
        disp('-------SubDIR--------')
        disp(Hd(iHd).name);
        disp('-------SubDIR--------')
        disp('------children--------')
        Hd_child = dir([Hd(iHd).folder,'\',Hd(iHd).name]);
        Hd_child = Hd_child(3:end);
        for ich = 1:numel(Hd_child)
            disp(Hd_child(ich).name);
        end
        disp('-------end--------')
        disp('  ')
    else
        disp(Hd(iHd).name);
    end
end