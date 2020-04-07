function [pl,ax] = plot(obj,ax,col,line,mark)
% [pl,ax] = plot(obj,ax,col,mark,line) - plots waveform object on the given axis
% ax
if nargin==2
    plotspec = ax;
    ax = gca;
elseif nargin == 3
    plotspec = col;
else

    if nargin < 4
        line = '-';
    end
    if nargin < 5
        mark = 'None';
    end
    if nargin < 3
        col = 'k';
    end
    if strcmp(mark, 'None')
        plotspec = [col,line];
    else
        plotspec = [col, line, mark];
    end
end


if nargin < 2
    ax = gca;
end
if isempty(ax)
    ax = gca;
end
hold on
for ipl = 1:numel(obj.data(:,1))
    pl(ipl) = plot(ax,obj.time(1,:), obj.data(ipl,:), plotspec);hold on
end

hold off