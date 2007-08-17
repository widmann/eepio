% $Id$

function writeriffeeph(fid, EEG, isAvg, condLabel, colorCode)

if nargin < 2
    error('Not enough input arguments.')
end

if nargin < 3
    isAvg = false;
end

if isAvg 
    if nargin < 5
        colorCode = 16;
    end
    if nargin < 4
        condLabel = EEG.setname;
    end
end

% Chunk header
chunkOffset = writeriffchunk(fid, 'eeph');

% EEP common header
fprintf(fid, '[File Version]\n%s\n', '4.0');
fprintf(fid, '[Sampling Rate]\n%.10f\n', EEG.srate);
fprintf(fid, '[Samples]\n%d\n', EEG.pnts);
fprintf(fid, '[Channels]\n%d\n', EEG.nbchan);
fprintf(fid, '[Basic Channel Data]\n');
fprintf(fid, ';label    calibration factor\n');
if ~isfield(EEG.chanlocs, 'calib')
    [EEG.chanlocs(:).calib] = deal(1);
end
for iChan = 1:EEG.nbchan
    expn = floor(log10(abs(EEG.chanlocs(iChan).calib)));
    mant = EEG.chanlocs(iChan).calib / 10^expn;
    fprintf(fid, '%-010s 1.0000000000e+00 %.10fe%+03d uV\n', EEG.chanlocs(iChan).labels, mant, expn);
end

% EEP average header
if isAvg
    fprintf(fid, '[Averaged Trials]\n%d\n', EEG.trials);
    fprintf(fid, '[Total Trials]\n%d\n', EEG.trials);
    fprintf(fid, '[Condition Label]\n%s\n', condLabel);
    fprintf(fid, '[Condition Color]\ncolor:%-2d\n', colorCode);
    fprintf(fid, '[Pre-stimulus]\n%.10f\n', -EEG.xmin);
end

% History
fprintf(fid, '[History]\n%s\nEOH\n', EEG.history);

% Write chunk size and word align file pointer
writeriffchunksize(fid, chunkOffset);
