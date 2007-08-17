% $Id$

function Chunk = readriffchunk(fid)

% Chunk id and size
Chunk.id = deblank(fread(fid, [1 4], '*char'));
Chunk.size = fread(fid, 1, 'uint32');
Chunk.offset = ftell(fid);

% Appropriate reading function
switch Chunk.id
    case {'RIFF' 'LIST'}
        readfunc = str2func('readrifflist');
    case {'chan' 'data' 'ep' 'eeph'}
        readfunc = str2func(['readcntriff' lower(Chunk.id)]);
    otherwise
        readfunc = @skipriffchunk;
end

% Read chunk
Chunk = readfunc(fid, Chunk);

% Word align file pointer
if mod(Chunk.size, 2)
    fseek(fid, 1, 0);
end
