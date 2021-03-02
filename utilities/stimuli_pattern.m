function stimuli_pattern(nunits)
% P = stimuli_pattern(nunits) - a GUI to choose/create stimuli pattern used
% in the measurement
C.bgcol = 'w';
C.bgcol_2 = [0.6, 0.6, 0.6];
C.bgcol_3 = [0.9, 0.9, 0.9];
C.fgcol_1 = 'k';

sequence = [0:45:315];
seq1 = {'chessboard'};
seq2 = compose('%g', sequence);
clear sequence;
sequence = [seq1,seq2];

str = seq2str(sequence);
F = figure;
set(F,'units', 'normalized', 'position', [0.336 0.286 0.372 0.389],...
    'color',C.bgcol,'MenuBar','Figure','NumberTitle','Off', 'Name',...
    'Stimulus Sequence','Resize','Off');

AX1 = axes(F, 'Position', [0 0 0.2 1],'Units', 'Normalized');
set(AX1, 'YColor','none','XColor','None');
patch(AX1,[0 1 1 0],...
    [0, 0, 1, 1],[0.6 0.6 0.6],'EdgeColor','None');
AX2 = axes(F, 'Position', [0.2 0.8 0.8 0.2],'Units', 'Normalized');
set(AX2, 'YColor','none','XColor','None');
patch(AX2,[0 1 1 0],...
    [0, 0, 1, 1],[0.9 0.9 0.9],'EdgeColor','None');

mTB(1) = uicontrol(F,'style','text','Units','Normalized',...
    'Position',[0 0 0.2 0.9],'BackgroundColor',C.bgcol);
set(mTB(1),'String',str,'FontSize',10,'foregroundcolor',C.fgcol_1,...
    'backgroundcolor',C.bgcol_2,'fontweight','bold','Tag','smalltext',...
    'HorizontalAlignment','Center');

PB(1) = uicontrol(F,'Style', 'Pushbutton', 'String', 'Add',...
    'Units','Normalized','Position', [0.05 0.05 0.1 0.05],...
    'background',[0.5725 0.6588 0.4039],'ForegroundColor',C.fgcol_1,'FontSize',10,...
    'Callback', @local_add_stim,'Tag','figure','FontWeight','Bold',...
    'Enable', 'On');

PB(1) = uicontrol(F,'Style', 'Pushbutton', 'String', 'Add',...
    'Units','Normalized','Position', [0.05 0.05 0.1 0.05],...
    'background',[0.5725 0.6588 0.4039],'ForegroundColor',C.fgcol_1,'FontSize',10,...
    'Callback', @local_add_stim,'Tag','figure','FontWeight','Bold',...
    'Enable', 'On');

d.F = F;
d.C = C;
d.mTB = mTB;
d.PB = PB;
d.sequence = sequence;
d.str = str;
guidata(F, d);

function str = seq2str(seq)
str = '';
for ise = 1:numel(seq)
    str = sprintf('%s\n', [str, seq{ise}]);
end


function local_add_stim(hO, ed)
d = guidata(hO);
answer = inputdlg('Add new stimulus: ');
d.sequence = [d.sequence, answer];
str = seq2str(d.sequence);
set(d.mTB(1), 'String', str);
d.str = str;
guidata(d.F, d);
%here add update for dropbox

