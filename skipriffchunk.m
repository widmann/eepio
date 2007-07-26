% Skip chunk

% $Id$

function Chunk = skipriffchunk(fid, Chunk)

fseek(fid, Chunk.size, 0);
