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

        opts.imgDir = './images/';
        opts.imgFnameList = {};
        opts.firstImgNum = 412;
        opts.lastImgNum = 432;
        opts.databasePath = './database/database_demo.mat';
        opts.backupDir = './database/backup/';
        opts.isMapping = false; % maybe in the future, design a button on the gui to do the mapping/saving
        opts.nostop = 'gui';
        opts.outputDir = './output/'; % not useful for now...
        opts.isgcp = false;
        opts.gcpPath = 'TBD';
        opts.isCoastline = true; % haven't figured out how to handle it yet...
        opts.coastlinePath = 'coastline_demo.mat';
        opts.isShipGPS = true;
        opts.shipPath = 'ship_track_demo.plt';
        opts.isDrifter = true;
        opts.drifterPath = 'drifter_demo.mat';
        opts.photoMetaPath = 'image_metadata_demo.csv';
        opts.flightRecordPath = 'flight_record_demo.csv';
        opts.frameRef = 'Geodetic'; % or 'Cartesian' (haven't touched it yet)
        opts.graticuleType = 3; % maybe we can integrate it into the gui as well...
        opts.launchAltitude = 1; % the altitude of the drone when launched

    case 'general'
        
        disp('... create opts, for general use');
        disp('*** Please specify the following fields of the opts struct:')
        disp('----------')
        disp("'imgDir'");
        disp("      - directory to the image, end with '/' ")
        disp("'imgFnameList' or ['firstImgNum' and 'lastImgNum'] ");
        disp("      - specify images to be processed. If both empty, ");
        disp("        visit all images in 'imgDir'.");
        disp("'databasePath'")
        disp("      - path to the database file (end with .mat),")
        disp("        the file should contain a data struct 'DB'");
        disp("'backupDir'" );
        disp("      - directory to a backup folder (end with '/').")
        disp("        Backup database after every 50 corrections.")
        disp("'isgcp'/'isCoastline'/'isShipGPS'/'isDrifter'");
        disp("      - ground references, set to be ture (1) or false (0)");
        disp("'gcpPath'/'coastlinePath'/'shipPath'/'drifterPath'")
        disp("      - paths to the ground reference files,")
        disp("        end with .mat (or can be .plt for shipGPS)")
        disp("'launchAltitude'")
        disp("      - the altitude of the drone when launched, in metres.")

        
        opts.type = 'general';
        opts.imgDir = 'TBD';
        opts.imgFnameList = {};
        opts.firstImgNum = [];
        opts.lastImgNum = [];
        opts.databasePath = 'TBD';
        opts.backupDir = '';
        opts.isMapping = false; % maybe in the future, design a button on the gui to do the mapping/saving
        opts.nostop = 'gui';
        opts.outputDir = 'TBD'; % not useful for now...
        opts.isgcp = false;
        opts.gcpPath = 'TBD';
        opts.isCoastline = true; % haven't figured out how to handle it yet...
        opts.coastlinePath = 'TBD';
        opts.isShipGPS = true;
        opts.shipPath = 'TBD';
        opts.isDrifter = true;
        opts.drifterPath = 'TBD';
        opts.photoMetaPath = 'TBD';
        opts.flightRecordPath = 'TBD';
        opts.frameRef = 'Geodetic'; % or 'Cartesian' (haven't touched it yet)
        opts.graticuleType = 3; % maybe we can integrate it into the gui as well...
        opts.launchAltitude = 1; % the altitude of the drone when launched

    case 'plume'
        disp('...create opts, for processing the fieldwork images over the plume front only');

        opts.type = 'plume';
        opts.imgDir = '/Users/shuminli/Documents/research/field_project/July_2023/july05/drone/flight_1/';
        opts.imgFnameList = {};
        opts.firstImgNum = 1;
        opts.lastImgNum = 1;
        opts.databasePath = '/Users/shuminli/g_rect_toolbox/sl_version/data/database_plume.mat';
        opts.backupDir = '/Users/shuminli/g_rect_toolbox/sl_version/data/plume_backup/';
        opts.isMapping = false; 
        opts.nostop = 'gui';
        opts.outputDir = 'TBD';
        opts.isgcp = false;
        opts.gcpPath = 'TBD';
        opts.isCoastline = true;
        opts.coastlinePath = '/Users/shuminli/g_rect_toolbox/sl_version/data/PNW.mat';
        opts.isShipGPS = true;
        opts.shipPath = 'TBD';
        opts.isDrifter = true;
        opts.drifterPath = 'TBD';
        opts.photoMetaPath = 'TBD';
        opts.flightRecordPath = 'TBD';
        opts.frameRef = 'Geodetic'; % or 'Cartesian'
        opts.graticuleType = 3;
        opts.launchAltitude = 1; % the altitude of the drone when launched


    otherwise
        error("input type must be one of the following options: 'demo','general','plume'");

end
























end