% $Id$

function chunkOffset = writeriffchunk(fid, chunkId, chunkSize, chunkData)

if nargin < 2
    error('Not enough input arguments.')
end

if nargin < 3 || isempty(chunkSize) % Unknown chunk size
    chunkSize = 0;
end

% Chunk header
fwrite(fid, sprintf('%-4s', chunkId), 'char');
fwrite(fid, chunkSize, 'uint32');
chunkOffset = ftell(fid);

if nargin > 3

    % Chunk data
    fwrite(fid, chunkData, class(chunkData));

    % Write chunk size and word align file pointer
    if chunkSize == 0
        writeriffchunksize(fid, chunkOffset)
    elseif mod(chunkSize, 2)
        fwrite(fid, 0, 'char');
    end

end
