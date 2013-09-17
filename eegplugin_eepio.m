% eegplugin_eepio() - EEGLAB plugin for exporting and importing ANT EEP
%                      .avr files
%
% Usage:
%   >> eegplugin_eepio(fig, trystrs, catchstrs);
%
% Inputs:
%   fig        - [integer]  EEGLAB figure
%   trystrs    - [struct] "try" strings for menu callbacks.
%   catchstrs  - [struct] "catch" strings for menu callbacks.
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

function vers = eegplugin_eepio(fig, trystrs, catchstrs)

    vers = 'eepio0.3.1';
    if nargin < 3
        error('eegplugin_eepio requires 3 arguments');
    end;

    % add folder to path
    % ------------------
    if ~exist('eegplugin_eepio')
        p = which('eegplugin_eepio.m');
        p = p(1:findstr(p,'eegplugin_eepio.m') - 1);
        addpath(p);
    end;

    % find import data menu
    % ---------------------
    menui = findobj(fig, 'tag', 'import data');
    menuo = findobj(fig, 'tag', 'export');

    % menu callbacks
    % --------------
    icadefs;
    versiontype = 1;
    if exist('EEGLAB_VERSION')
        if EEGLAB_VERSION(1) == '4'
            versiontype = 0;
        end;
    end;
    if versiontype == 0
        comcnt1 = [trystrs.no_check '[EEGTMP LASTCOM] = pop_readeepavr;'  catchstrs.new_non_empty];
   else
        comcnt1 = [trystrs.no_check '[EEG LASTCOM] = pop_readeepavr;'  catchstrs.new_non_empty];
    end;
    comcnt2 = [trystrs.no_check 'LASTCOM = pop_writeeepavr(EEG);'  catchstrs.add_to_hist];

    % create menus
    % ------------
    uimenu( menui, 'label', 'From EEP .avr file using eepio',  'callback', comcnt1, 'separator', 'on' );
    uimenu( menuo, 'label', 'Write EEP .avr file using eepio',  'callback', comcnt2, 'separator', 'on' );
