% pop_writeeeptrg - Write ANT EEP .trg file
%
% Usage:
%   >> com = pop_writeeeptrg(EEG); % pop-up window mode
%   >> com = pop_writeeeptrg(EEG, 'key1', value1, 'key2', value2, ...
%                            'keyn', valuen);
%
% Inputs:
%   EEG           - EEGLAB EEG structure
%
% Optional inputs:
%   'filename'    - char array file name
%   'pathname'    - char array path name {default ''}
%   'strip'       - flag strip non-numeric parts of event type {default
%                   false}
%
% Outputs:
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

function [com] = pop_writeeeptrg(EEG, varargin)

com = '';

if nargin < 1
    error('Not enough input arguments')
end

% Pop-up window mode
if nargin < 2

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
[fid message] = fopen(fullfile(Arg.pathname, Arg.filename), 'w');
if fid == -1
    error(message)
end

% Sort events
[tmp, idxArray] = sort([EEG.event.latency]);
EEG.event = EEG.event(idxArray);

% Boundaries
[EEG.event(strmatch('boundary', {EEG.event.type})).type] = deal('__');

% Remove non-numerical substrings
if isfield(Arg, 'strip') && Arg.strip
    typeArray = regexprep({EEG.event.type}, '\D*(\d+|__)\D*', '$1');
    [EEG.event(:).type] = deal(typeArray{:});
end

% Header
blocksize = EEG.nbchan * 2 + 4;
offset = 900 + EEG.nbchan * 75;
fprintf(fid, '%18.16f %d\n', 1 / EEG.srate, blocksize);

% Write events
for iEvt = 1:length(EEG.event)
    fprintf(fid, '%12.6f %9.0f % 3s\n', (EEG.event(iEvt).latency - 1) / EEG.srate,  offset + (EEG.event(iEvt).latency - 1) * blocksize, EEG.event(iEvt).type);
end

% Close file
fclose(fid);
