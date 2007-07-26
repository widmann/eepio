% LIST chunk

% $Id$

function List = readrifflist(fid, List)

% List type
List.id = deblank(fread(fid, [1 4], '*char'));

% Recursion
while ftell(fid) < List.offset + List.size
    Chunk = readriffchunk(fid);
    List.(Chunk.id) = Chunk;
end
