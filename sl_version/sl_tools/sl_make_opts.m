function opts = sl_make_opts(varargin)

% this function generate a default data structure (opts) as a input to
% function sl_g_rect


% database:     the database file that contains the metadata and corrections
%               for each image visited
%
% isMapping:    - yes: create a data file containing the lon/lat grid and
%                       the RGB data for mapped image (requries lon/lat
%                       limits, outputDir)
%               - no:  Only view the image, do the corrections, but not
%                       mapping.
%
% nostop:       - gui: use the GUI for correction.
%               - text: only text
%               - none: 
%
% graticuleType:- 1: Make a circle al around our source
%               - 2: East/North
%               - 3: Grid in direction being faced


type = char(varargin{:});

if isempty(type)
    type = 'demo';
    disp("... no input provided, by defalt, type = 'demo' ");
elseif ~ischar(type)
    error("input type must be one of the following options: 'demo','general','plume'");
end

opts = struct;

switch type

    case 'demo'
        disp('...create opts, to process demo images in /sl_demo');
        opts.type = 'demo';

        % TODO: finish this part

    case 'general'
        disp('...create opts, for general use');
        opts.type = 'general';

        % TODO: finish this part

    case 'plume'
        disp('...create opts, for processing the fieldwork images over the plume front only');

        opts.type = 'plume';
        opts.fieldDir = '/Users/shuminli/Documents/research/field_project/';
        opts.year = 2023;
        opts.date = 5;
        opts.flightNum = 5;
        opts.firstImgNum = 543;
        opts.lastImgNum = 845;
        opts.databasePath = '/Users/shuminli/g_rect_toolbox/sl_version/data/database_plume.mat';
        opts.backupDir = '/Users/shuminli/g_rect_toolbox/sl_version/data/backup/';
        opts.isMapping = false; 
        opts.nostop = 'gui';
        opts.outputDir = '/Users/shuminli/g_rect_toolbox/sl_version/sl_matlab/test_database/';
        opts.isgcp = false;
        opts.gcpPath = 'TBD';
        opts.isCoastline = true;
        opts.coastlinePath = '/Users/shuminli/Nextcloud/data/others/PNW.mat';
        opts.isShipGPS = true;
        opts.shipPath = 'TBD';
        opts.isDrifter = true;
        opts.drifterPath = 'TBD';
        opts.frameRef = 'Geodetic'; % or 'Cartesian'
        opts.graticuleType = 3;
        opts.launchAltitude = 1; % the altitude of the drone when launched





    otherwise
        error("input type must be one of the following options: 'demo','general','plume'");

end
























end