% $Id$

function epochOffsetArray = writeriffdata(fid, data, epochLength)

% Epoch length
if nargin < 3
    epochLength = size(data, 2);
end

% Chunk header
chunkOffset = writeriffchunk(fid, 'data');

% Epoch information
epochArray = [0:epochLength:size(data, 2)-1 size(data, 2)];
epochOffsetArray = zeros(1, length(epochArray) - 1);

for iEpoch = 1:length(epochArray) - 1

    epochOffsetArray(iEpoch) = ftell(fid) - chunkOffset;

    for iChan = 1:size(data, 1)

        % Write data format and compression information (currently
        % only 32 bit float w/o compression)
        fwrite(fid, 12, 'ubit4');
        fwrite(fid, 0, 'ubit4');

        % Write data
        fwrite(fid, data(iChan, epochArray(iEpoch) + 1:epochArray(iEpoch + 1)), 'float32');

    end

end

% Write chunk size and word align file pointer
writeriffchunksize(fid, chunkOffset);
