% EEP header chunk

% $Id$

function Eeph = readcntriffeeph(fid, Eeph)

Eeph.raw = fread(fid, [1 Eeph.size], '*char');

% Remove history (may contain square brackets!)
Eeph.history = char(regexp(Eeph.raw, '\[History\]\n(.*)\nEOH\n', 'tokens', 'once'));
temp = regexprep(Eeph.raw, '\[History\].*EOH\n', '');

% Convert to structure
temp = regexp(temp, '\[(?<field>.+?)\]\n(?<value>.+?)\n(?=\[|$)', 'names');
for iter = 1:length(temp)
    temp(iter).field = regexprep(temp(iter).field, '[-\s]', '');
    temp(iter).field(1) = lower(temp(iter).field(1));
    Eeph.(temp(iter).field) = temp(iter).value;
end

% Convert numeric fields
numFieldArray = {'samplingRate' 'samples' 'channels' 'averagedTrials' 'totalTrials' 'prestimulus'};
for iNumField = 1:length(numFieldArray)
    if isfield(Eeph, numFieldArray{iNumField})
        Eeph.(numFieldArray{iNumField}) = str2double(Eeph.(numFieldArray{iNumField}));
    end
end

% Basic channel data
Eeph.basicChannelData = regexprep(Eeph.basicChannelData, ';.+?\n', '');
[Eeph.chanLabel Eeph.chanCalib(:, 1) Eeph.chanCalib(:, 2) Eeph.chanUnit] = ...
    strread(Eeph.basicChannelData, '%s %f %f %s\n');
