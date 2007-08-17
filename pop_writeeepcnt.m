% pop_writeeepavr - Write ANT EEP .cnt file
%
% Usage:
%   >> com = pop_writeeepcnt(EEG); % pop-up window mode
%   >> com = pop_writeeepcnt(EEG, 'key1', value1, 'key2', value2, ...
%                                 'keyn', valuen);
%
% Inputs:
%   EEG        - EEGLAB EEG structure
%
% Optional inputs:
%   'fileName'    - char array file name
%   'pathName'    - char array path name {default '.'}
%
% Outputs:
%   com           - history string
%
% Author: Andreas Widmann, University of Leipzig, 2007

%123456789012345678901234567890123456789012345678901234567890123456789012

% Copyright (C) 2007 Andreas Widmann, University of Leipzig, widmann@uni-leipzig.de
%
% This program is free software; you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation; either version 2 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program; if not, write to the Free Software
% Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

% $Id$

function com = pop_writeeepcnt(EEG, varargin)

if nargout > 0
    com = '';
end
if nargin < 1
    help pop_writeeepcnt;
    return
end

% Pop-up window mode
if nargin < 1

    % File dialog
    [Arg.fileName Arg.pathName] = uiputfile('*.cnt');
    if Arg.fileName == 0, return, end

% Command line mode
else
    Arg = struct(varargin{:});
end

% Filename
if ~isfield(Arg, 'filename') || isempty(Arg.filename)
    error('Not enough input arguments.')
end

% Default pathname
if ~isfield(Arg, 'pathname')
    Arg.pathname = '.';
end

% Open file
[fid message] = fopen(fullfile(Arg.pathname, Arg.filename), 'w', 'l');
if fid == -1
    error(message)
end

% RIFF header
cntOffset = writeriffchunk(fid, 'RIFF', [], 'CNT ');

% rawf LIST header
rawOffset = writeriffchunk(fid, 'LIST', [], 'raw3');

% Channel chunk
writeriffchunk(fid, 'chan', EEG.nbchan * 2, int16(0:EEG.nbchan - 1));

% Scale data
calib = double(max(max(abs(EEG.data)))) / (2^31 - 1);
calib = ceil(calib * 10^(10 - floor(log10(abs(calib))))) / 10^(10 - floor(log10(abs(calib))));
data = round(double(EEG.data) ./ calib);
[EEG.chanlocs(:).calib] = deal(calib);

% Data chunk
epochLength = min(EEG.pnts, EEG.srate);
epochOffsetArray = writecntriffdata(fid, data, epochLength, 8);

% Epoch chunk
writeriffchunk(fid, 'ep', length(epochOffsetArray) * 4 + 4, uint32([epochLength epochOffsetArray]));

% rawf LIST size
writeriffchunksize(fid, rawOffset);

% EEP header chunk
writecntriffeeph(fid, EEG);

% Event chunk
writecntriffevt(fid, EEG.event);

% RIFF size
writeriffchunksize(fid, cntOffset);

% Close file
fclose(fid);

% History string
if nargout > 0
    com = [fieldnames(Arg) struct2cell(Arg)]';
    com = ['pop_writeeepcnt(' inputname(1) ', ' vararg2str(com(:)) ');'];
end
