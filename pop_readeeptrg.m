% pop_readeeptrg - Read ANT EEP .trg file
%
% Usage:
%   >> com = pop_readeeptrg; % pop-up window mode
%   >> com = pop_readeeptrg('key1', value1, 'key2', value2, ...
%                           'keyn', valuen);
%
% Optional inputs:
%   'filename'    - char array file name
%   'pathname'    - char array path name {default ''}
%
% Outputs:
%   Event         - EEGLAB event structure
%   srate         - sampling rate
%   nbchan        - number of channels
%   com           - history string
%
% Author: Andreas Widmann, University of Leipzig, 2011

%123456789012345678901234567890123456789012345678901234567890123456789012

% Copyright (C) 2011 Andreas Widmann, University of Leipzig, widmann@uni-leipzig.de
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

function [Event, srate, nbchan, com] = pop_readeeptrg(varargin)

com = '';

% Pop-up window mode
if nargin < 1

    % File dialog
    [Arg.filename Arg.pathname] = uigetfile('*.trg');
    if Arg.filename == 0, return, end

% Command line mode
else
    Arg = struct(varargin{:});
end

% Default pathname
if ~isfield(Arg, 'pathname')
    Arg.pathname = '';
end

% Open file
[fid message] = fopen(fullfile(Arg.pathname, Arg.filename), 'r');
if fid == -1
    error(message)
end

% Header
raw = fgetl(fid);
rawArray = sscanf(raw, '%f %f');
srate = 1 / rawArray(1);
blocksize = rawArray(2);
nbchan = (blocksize - 4) / 2;
offset = 900 + nbchan * 75;

% Read events
Event = struct([]);
while ~feof(fid)
    raw = fgetl(fid);
    rawArray = sscanf(raw, '%f %f %s');
    Event(end + 1).time = rawArray(1);
    Event(end).offset = rawArray(2);
    Event(end).type = strtrim(char(rawArray(3:end)'));
end

% Close file
fclose(fid);

% Latency
latencyArray = num2cell(round([Event.time] * srate + 1));
[Event(:).latency] = deal(latencyArray{:});
if any(([Event.offset] - offset) / blocksize + 1 ~= [Event.latency])
    warning('Offset does not match latency.')
end

% Boundaries
[Event(strmatch('__', {Event.type})).type] = deal('boundary');
