% pop_readeepavr - Read ANT EEP .avr file
%
% Usage:
%   >> [EEG, com] = pop_readeepavr; % pop-up window mode
%   >> [EEG, com] = pop_writeeepavr('key1', value1, 'key2', value2, ...
%                                   'keyn', valuen);
%
% Optional inputs:
%   'fileName'    - char array file name
%   'pathName'    - char array path name {default '.'}
%   'fileVers'    - scalar integer file format version {default 4}
%
% Outputs:
%   EEG           - EEGLAB EEG structure
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

function [EEG com] = pop_readeepavr(varargin)

com = '';
EEG = [];

% Pop-up window mode
if nargin < 1

    % File dialog
    [Arg.fileName Arg.pathName] = uigetfile('*.avr');
    if Arg.fileName == 0, return, end

% Command line mode
else
    Arg = struct(varargin{:});
end

% Default pathname
if ~isfield(Arg, 'pathName')
    Arg.pathName = '.';
end

% Empty EEG dataset
try
    EEG = eeg_emptyset;
catch
end

% Open file
[fid message] = fopen(fullfile(Arg.pathName, Arg.fileName), 'r', 'l');
if fid == -1
    error(message)
end

% File format version
if ~isfield(Arg, 'fileVers') || isempty(Arg.fileVers)
    temp = fread(fid, [1 4], '*char');
    fseek(fid, 0, -1);
    if strcmp('RIFF', temp)
        Arg.fileVers = 4;
    else
        Arg.fileVers = 2;
    end
end

switch Arg.fileVers

    % EEP 2-3.2 (simple binary)
    case {2 3}

        % Read global header
        fread(fid, 1, 'uint16'); % Global header size
        fread(fid, 1, 'uint16'); % Channel header size
        EEG.nbchan = fread(fid, 1, 'uint16');
        EEG.pnts = fread(fid, 1, 'uint16');
        EEG.event.trials = fread(fid, 1, 'uint16');
        fread(fid, 1, 'uint16'); % N rejected trials
        EEG.xmin = fread(fid,  1, 'float32') / 1000;
        EEG.srate = 1000 / fread(fid, 1, 'float32');
        EEG.setname = deblank(fread(fid, [1 10], '*char')); % Condition label
        fread(fid, [1 8], '*char'); % Color code

        % Read channel header
        chanOffsetArray = zeros(1, EEG.nbchan);
        for iChan = 1:EEG.nbchan
            EEG.chanlocs(iChan).labels = deblank(fread(fid, [1 10], '*char')); % Channel label
            chanOffsetArray(iChan) = fread(fid, 1, 'uint32');  % Channel data file offset
            fseek(fid, 2, 0); % Reserved
        end

        % Read history
        histSize = chanOffsetArray(1) - ftell(fid);
        if histSize
            Arg.fileVers = 3;
            EEG.history = fread(fid, [1 histSize], '*char');
            EEG.history = char(regexp(EEG.history, '\[History\]\n(.*)\nEOH\n', 'tokens', 'once'));
        end

        % Read data
        EEG.data = zeros(EEG.nbchan, EEG.pnts);
        for iChan = 1:EEG.nbchan
            EEG.data(iChan, :) = fread(fid, EEG.pnts, 'float32');
            fseek(fid, EEG.pnts * 4, 0); % stdd
        end
        
        EEG.event.type = EEG.setname;

    % EEP 3.3- (CNT-RIFF float)
    case 4

        % Read file except data
        CNT = readriffchunk(fid);

        % Read, sort, and scale data
        CNT.rawf.data = readcntriffdata(fid, CNT.rawf.data, CNT.eeph.channels, CNT.eeph.samples, CNT.rawf.ep.epochLength);
        CNT.rawf.data.data = CNT.rawf.data.data(CNT.rawf.chan.index + 1, :);
        CNT.eeph.chanCalib = single(diag(CNT.eeph.chanCalib(:, 1) .* CNT.eeph.chanCalib(:, 2)));
        CNT.rawf.data.data = CNT.eeph.chanCalib * CNT.rawf.data.data;

        % Convert to EEGLAB EEG structure
        EEG.setname = CNT.eeph.conditionLabel;
        EEG.nbchan = CNT.eeph.channels;
        EEG.pnts = CNT.eeph.samples;
        EEG.srate = CNT.eeph.samplingRate;
        EEG.xmin = -CNT.eeph.prestimulus;
        EEG.data = CNT.rawf.data.data;
        [EEG.chanlocs(1:EEG.nbchan).labels] = deal(CNT.eeph.chanLabel{:});
        EEG.event.type = CNT.eeph.conditionLabel;
        EEG.event.trials = CNT.eeph.averagedTrials;
        EEG.history = CNT.eeph.history;

    otherwise
        error('Unkown file format version')

end

% Close file
fclose(fid);

EEG.filename = Arg.fileName;
EEG.filepath = Arg.pathName;
EEG.trials = 1;
EEG.xmax = EEG.xmin + (EEG.pnts - 1) / EEG.srate;
EEG.times = (EEG.xmin + (0:EEG.pnts - 1) / EEG.srate) * 1000;
EEG.event.latency = round(-EEG.xmin * EEG.srate) + 1;

try
    EEG = eeg_checkset(EEG);
catch
end

% History string
if nargout > 1
    com = [fieldnames(Arg) struct2cell(Arg)]';
    com = ['pop_readeepavr(' vararg2str(com(:)) ');'];
end
