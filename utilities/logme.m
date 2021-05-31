function logme(logname, string, new_line_count)
% logme(logname, string, new_line_count) - adds a new string line to the
% given text file (has to be .txt) which is treated as a log
% if new_line_count is specified, then that many empty lines will be added
% at the end of the operation
if nargin <3
    new_line_count = 0;
end
try
    fid = fopen(logname , 'a' );
    fprintf( fid, '%s\n', string);
    
    for inl = 1:new_line_count
        fprintf( fid, '%s\n', '');
    end
    fclose(fid);
catch
    fclose(fid);
end