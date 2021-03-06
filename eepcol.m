% $Id$

function colOut = eepcol(colIn)

EEPCOLARRAY = {
    16 'BLUE'; ...
    17 'STEEL'; ...
    18 'SKY'; ...
    19 'CYAN'; ...
    20 'MINT'; ...
    21 'SEA'; ...
    22 'LEAVES'; ...
    23 'GREEN'; ...
    24 'OLIVE'; ...
    25 'SIENNA'; ...
    26 'LIGHTGREEN'; ...
    27 'YELLOW'; ...
    28 'OCHRE'; ...
    29 'APRICOT'; ...
    30 'ORANGE'; ...
    31 'RED'; ...
    32 'CRIMSON'; ...
    33 'ROSE'; ...
    34 'PINK'; ...
    35 'MAGENTA'; ...
    36 'PURPLE'; ...
    37 'LILAC'; ...
    38 'AUBERGINE'; ...
    39 'PLUM'; ...
    40 'UV'};

% Number to string
if isnumeric(colIn)
    colOut = find([EEPCOLARRAY{:, 1}] == colIn);
    if ~isempty(colOut)
        colOut = EEPCOLARRAY{colOut, 2};
    else
        error('No EEP color code.')
    end

% String to number
elseif ischar(colIn)
    colOut = strmatch(upper(colIn), EEPCOLARRAY(:, 2), 'exact');
    if ~isempty(colOut)
        colOut = EEPCOLARRAY{colOut, 1};
    else
        error('No EEP color code.')
    end
end
