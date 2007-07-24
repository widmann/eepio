% pop_writeeepavr - Write ANT EEP .avr file
%
% Usage:
%   >> com = pop_writeeepavr(EEG); % pop-up window mode
%   >> com = pop_writeeepavr(EEG, 'key1', value1, 'key2', value2, ...
%                                 'keyn', valuen);
%
% Inputs:
%   EEG        - EEGLAB EEG structure
%
% Optional inputs:
%   'fileName'    - char array file name
%   'fileVers'    - scalar integer file format version {default 4}
%   'pathName'    - char array path name {default '.'}
%   'condLabel'   - char array condition label {default EEG.setname}
%   'colorCode'   - scalar integer or char array color code {default 16}
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

function com = pop_writeeepavr(EEG, varargin)

if nargout > 0
    com = '';
end
if nargin < 1
    help pop_writeeepavr;
    return
end

% Pop-up window mode
if nargin < 2

    drawnow;
    uigeom = {[1 1] [1 1] [1 1]};
    uilist = {{'style' 'text' 'string' 'File format version:'} ...
              {'style' 'popupmenu' 'string' {'2 - EEP 2.x: simple binary, no history' '3 - EEP 3.0-3.2: simple binary' '4 - EEP 3.3: CNT-RIFF (float)'} 'value' 3} ...
              {'style' 'text' 'string' 'Condition label:'} ...
              {'style' 'edit' 'string' ''} ...
              {'style' 'text' 'string' 'Color code:'} ...
              {'style' 'edit' 'string' ''}};
    result = inputgui(uigeom, uilist, 'pophelp(''pop_writeeepavr'')', 'Write EEP .avr file -- pop_writeeepavr()');
    if isempty(result), return, end

    Arg.fileVers = result{1} + 1;
    Arg.condLabel = result{2};

    % Color code
    temp = str2num(result{3});
    if ~isempty(temp)
        Arg.colorCode = temp;
    else
        Arg.colorCode = result{3};
    end

    % File dialog
    [Arg.fileName Arg.pathName] = uiputfile('*.avr');
    if Arg.fileName == 0, return, end

% Command line mode
else
    Arg = struct(varargin{:});
end

% Argument check
if ~isfield(Arg, 'fileName') || isempty(Arg.fileName)
    error('Not enough input arguments.')
end

% Defaults
if ~isfield(Arg, 'pathName')
    Arg.pathName = '.';
end
if ~isfield(Arg, 'fileVers') || isempty(Arg.fileVers)
    Arg.fileVers = 4;
end
if ~isfield(Arg, 'condLabel') || isempty(Arg.condLabel)
    Arg.condLabel = EEG.setname;
end
if ~isfield(Arg, 'colorCode') || isempty(Arg.colorCode)
    Arg.colorCode = 16; % Blue
elseif ischar(Arg.colorCode)
    Arg.colorCode = eepcol(Arg.colorCode);
end

% Prepare data
stdd = std(EEG.data, 0, 3);
data = mean(EEG.data, 3);
epochLength = EEG.pnts;

% Open file
[fid message] = fopen(fullfile(Arg.pathName, Arg.fileName), 'w', 'l');
if fid == -1
    error(message)
end

switch Arg.fileVers

    % EEP 2-3.2
    case {2 3}

        % Write global header
        fwrite(fid, 38, 'uint16'); % Global header size
        fwrite(fid, 16, 'uint16'); % Channel header size
        fwrite(fid, EEG.nbchan, 'uint16');
        fwrite(fid, EEG.pnts, 'uint16');
        fwrite(fid, EEG.trials, 'uint16');
        fwrite(fid, 0, 'uint16'); % N rejected trials
        fwrite(fid, EEG.xmin * 1000, 'float32');
        fwrite(fid, 1000 / EEG.srate, 'float32');
        fprintf(fid, '%-10s', Arg.condLabel(1:min([end 10]))); % Condition label
        fprintf(fid, 'color:%-2d', Arg.colorCode); % Color code

        % Prepare history
        if Arg.fileVers > 2
            histArray = sprintf('[History]\n%s\nEOH\n', EEG.history);
        else
            histArray = '';
        end

        % Write channel header
        for iChan = 1:EEG.nbchan
            fprintf(fid, '%-10s', EEG.chanlocs(iChan).labels); % Channel label
            fwrite(fid, 38 + EEG.nbchan * 16 + length(histArray) + (iChan - 1) * EEG.pnts * 4 * 2, 'uint32'); % Channel data file offset
            fwrite(fid, char([0 0]), 'char'); % Reserved
        end

        % Write history
        fprintf(fid, '%s', histArray);
        
        % Write data
        for iChan = 1:EEG.nbchan
            fwrite(fid, [data(iChan, :) stdd(iChan, :)], 'float32');
        end

    % EEP 3.3-
    case 4

        % RIFF header
        cntOffset = writeriffchunk(fid, 'RIFF', [], 'CNT ');

        % rawf LIST header
        rawOffset = writeriffchunk(fid, 'LIST', [], 'rawf');

        % Channel chunk
        writeriffchunk(fid, 'chan', EEG.nbchan * 2, int16(0:EEG.nbchan - 1));

        % Data chunk
        epochOffsetArray = writeriffdata(fid, data, epochLength);

        % Epoch chunk
        writeriffchunk(fid, 'ep', length(epochOffsetArray) * 4 + 4, uint32([epochLength epochOffsetArray]));

        % rawf LIST size
        writeriffchunksize(fid, rawOffset);

        % stdd LIST header
        rawOffset = writeriffchunk(fid, 'LIST', [], 'stdd');

        % Channel chunk
        writeriffchunk(fid, 'chan', EEG.nbchan * 2, int16(0:EEG.nbchan - 1));

        % Data chunk
        epochOffsetArray = writeriffdata(fid, stdd, epochLength);

        % Epoch chunk
        writeriffchunk(fid, 'ep', length(epochOffsetArray) * 4 + 4, uint32([epochLength epochOffsetArray]));

        % stdd LIST size
        writeriffchunksize(fid, rawOffset);

        % EEP header chunk
        writeriffeeph(fid, EEG, true, Arg.condLabel, Arg.colorCode);

        % RIFF size
        writeriffchunksize(fid, cntOffset);

    otherwise
        error('Unkown file format version')

end

% Close file
fclose(fid);

if nargout > 0
    com = [fieldnames(Arg) struct2cell(Arg)]';
    com = ['pop_writeeepavr(' inputname(1) ', ' vararg2str(com(:)) ');'];
end
