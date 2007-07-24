% $Id$

function writeriffchunksize(fid, chunkOffset, chunkSize)

if nargin < 2
    error('not enough input arguments.')
end

% Current file offset
fileOffset = ftell(fid);

% Chunk size relative to current file offset
if nargin < 3
    chunkSize = fileOffset - chunkOffset;
end

% Write chunk size
fseek(fid, chunkOffset - 4, -1); % Rewind
fwrite(fid, chunkSize, 'uint32');
fseek(fid, fileOffset, -1); % Fast forward

% Word align file pointer
if nargin < 3 && mod(chunkSize, 2)
    fwrite(fid, 0, 'char');
end
