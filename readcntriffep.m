% Epoch chunk

% $Id$

function Ep = readcntriffep(fid, Ep)

Ep.nEpochs = (Ep.size - 4) / 4;

Ep.epochLength = fread(fid, 1, 'uint32');

for iEpoch = 1:Ep.nEpochs
    Ep.epochOffsetArray(iEpoch) = fread(fid, 1, 'uint32');
end
