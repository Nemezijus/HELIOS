function F = profile(OB, iroi, flag)
% F = profile(OB, iroi, flag) - experiment class method which produces a
% matlab image - a profile (or overview) of the iroi ROI.
% OB - experiment object.
% part of HELIOS
if nargin < 3
    flag = [];
end
F = figure;
set(F,'units', 'normalized', 'position', [0.101 0.1 0.821 0.775]);


%1 - traces

%first - get the ylims
Ymin = Inf;
Ymax = -Inf;
for istage = 1:OB.N_stages
    for istim = 1:OB.N_stim(istage)
        W = OB.traces({iroi, istage, istim, 0},'dff');
        m = mean(W.data);
        if min(m) < Ymin
            Ymin = min(m);
        end
        if max(m) > Ymax
            Ymax = max(m);
        end
    end
end
AX_traces = autoaxes(F,OB.N_stages, 1,[0.1, 0.5, 0.005, 0.005],[0.025 0.025]);

for istage = 1:OB.N_stages
    axes(AX_traces(istage));
    for istim = 1:OB.N_stim(istage)
        W = OB.traces({iroi, istage, istim, 0},'dff');
        plot(W.time(1,:).*1e-3, mean(W.data), 'k-'); hold on
    end
    ylim([Ymin, Ymax]);
    if istage ~= OB.N_stages
        set(gca,'XTickLabel',[]);
    end
    if istage == OB.N_stages
        xlabel('time, s');
    end
    ylabel('dff');
end

%2 - images
AX_images = autoaxes(F, OB.N_stages, 1, [0.005 0.905 0.005 0.005],[0.025 0.025]);
for istage = 1:OB.N_stages
    [M(istage).IMmovie, M(istage).frames] = playroi(OB, iroi, istage);
    axes(AX_images(istage));
    imagesc(M(istage).IMmovie(:,:,:,1));
end

d.F = F;
d.M = M;
guidata(F,d);



function local_playframe(hObject, eventdata)
d = guidata(hObject);