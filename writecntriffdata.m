% $Id$

function epochOffsetArray = writecntriffdata(fid, data, epochLength, compMeth)

% Compression method
if nargin < 4 || isempty(compMeth)
    compMeth = 12; % Float vectors
end

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
        
        switch compMeth

            % Uncompressed 32 bit integer
            case 8
                % Write data format and compression information
                fwrite(fid, 128, 'uint8');

                % Write data
                fwrite(fid, data(iChan, epochArray(iEpoch) + 1:epochArray(iEpoch + 1)), 'int32', 'b'); % Big endian!

            % EEP 4.0 average (float vectors)
            case 12
                % Write data format and compression information
                fwrite(fid, 12, 'uint8');

                % Write data
                fwrite(fid, data(iChan, epochArray(iEpoch) + 1:epochArray(iEpoch + 1)), 'float32');

            otherwise
                error('Unkown compression method.')
        end

    end

end

% Write chunk size and word align file pointer
writeriffchunksize(fid, chunkOffset);
