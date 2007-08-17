% $Id$

function writecntriffevt(fid, Event)

if nargin < 2
    error('Not enough input arguments.')
end

% Chunk header
chunkOffset = writeriffchunk(fid, 'evt');

% Convert boundary to __
[Event(strmatch('boundary', {Event.type})).type] = deal('__');

for iEvt = 1:length(Event)

    % Write event offset
    fwrite(fid, ceil(Event(iEvt).latency) - 1, 'uint32');
    
    % Format and write event type
    evtTypeArray = num2str(zeropad(Event(iEvt).type, 8, 2));
    fwrite(fid, evtTypeArray(1:8), 'char');

end

% Write chunk size and word align file pointer
writeriffchunksize(fid, chunkOffset);
