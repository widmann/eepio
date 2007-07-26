% Channel chunk

% $Id$

function Chan = readcntriffchan(fid, Chan)

Chan.index = fread(fid, Chan.size / 2, 'int16');
