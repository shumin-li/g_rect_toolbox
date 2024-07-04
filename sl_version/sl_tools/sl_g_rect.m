function sl_g_rect(opts)
%G_RECT - Main function for georectifying oblique images.
%
% Syntax:  Simply type g_rect at the command line and follow the
%          instructions.
%
% Inputs:
%     inputFname
%     image_num
%     nostop: 'gui','text','none'
%
%    The function G_RECT reads an input parameter file that contains all
%     information required to perform a georectification of a given image.
%     The format of this parameter file is detailed on-line on the G_RECT
%     Wiki page.
%     In order to handle multiple images in the same parameter file,
%     image_num can be used as an index.
%
% Outputs:
%    The function G_RECT creates an output file that contains the following
%    variables:
%
%        imgFname:      The reference image for the georectification.
%
%        firstImgFname: The first image of a sequence of images to which the
%                       georectification could be applied to. This is really
%                       just a comment.
%
%        lastImgFname: The last image of a sequence of images to which the
%                      georectification could be applied to. This is really
%                      just a comment.
%
%        frameRef:     The reference frame used. It could be either
%                      'Geodetic' or 'Cartesian'.
%
%        LON:          The main matrix that contain either the longitude of each
%                      pixel of the reference image (imgFname) or the x-coordinate
%                      (in m) depending on whether the package is used in geodetic or
%                      cartesian coordinates.
%
%        LAT:          Same as LON but for the latitude or y-position.
%
%        LON0:         A scalar for the longitude or x-position of the camera.
%
%        LAT0:         Same as LON0 but for the latitude.
%
%        lon0_gcp:     A vector containing the longitude or x-position of each
%                      ground control points (GCP).
%
%        lat0_gcp:     Same as lon_gcp for latitude or y-position.
%
%        lon_gcp:      A vector containing the longitude or x-position of each
%                      ground control points (GCP) projected onto the water level
%                      i.e. at 0 m of elevation.
%
%        lat_gcp:      Same as lon_gcp for latitude or y-position.
%
%        h_gcp:        The elevation (in m) of the GCPs. The elevation is
%                      0 m if taken at water level.
%
%        i_gcp:        The horizontal index of the image ground control
%                      points.
%
%        j_gcp:        The vertical index of the image ground control
%                      points.
%
%        hfov:         The camera horizontal field of view [degree].
%
%        phi:          Camera tilt angle [degree].
%
%        lambda:       Camera dip angle [degree].
%
%        H:            The camera altitude relative to the water [m].
%
%        theta:        View angle clockwise from North [degree].
%
%        errGeoFit:    The rms error of the georectified image after
%                      geometrical transformation [m].
%
%        errPolyFit:   The rms error of the georectified image after
%                      geometrical transformation and the polynomial
%                      correction [m].
%
%        precision:    Calculation can be done in single or double
%                      precisions as defined by the user in the parameter
%                      file. With today's computers this is now obsolete
%                      and calculations can always be done in double
%                      precision. (deleted, not useful anymore)
%
%         Delta:       The effective resolution (im m) of the georectified image.
%
% Other m-files required: The m_map package.

% Subfunctions: all functions contained within the subdirectories g_rect/src/
%
% Author: Daniel Bourgault
%         Institut des sciences de la mer de Rimouski
%         email: daniel_bourgault@uqar.ca
%         Initial development: February 2013
%         Important update: May 2020

% Changes
%   Jan/23 - added graticule and coastline options to guide image,
%            added option for specifing parameter file as function
%            input, many smaller changes.

% Changes
%   Apr/24 - add drifter options to guide image, use a different function
%   of read the yaw/pitch/roll/alt metadata, many smaller changes (S. Li).

%% Display Welcome Message:
disp('  ');
disp('  Welcome to g_rect: a package for georectifying oblique images on a flat ocean');
disp('  Authors: Daniel Bourgault and Rich Pawlowicz');
disp('  Test version of Shumin Li');
disp('  ');


%% If there is no input: (default to run the demo)
% if nargin==0
%    opts = sl_make_opts('demo');
% end



switch opts.type

    case 'demo'
        % TODO
        disp('TODO: with demo option');

    case 'general'
        % TODO
        disp('TODO: with general option');

    case 'plume'

        switch opts.year
            case 2023
                yearFolder = 'July_2023/';
            case 2024
                yearFolder = 'August_2024/';
        end

        switch opts.date
            case 1
                dateFolder = 'july05/';
            case 2
                dateFolder = 'july12/';
            case 3
                dateFolder = 'july19/';
            case 4
                dateFolder = 'july27/';
        end

        dateDir = [opts.fieldDir, yearFolder, dateFolder];

        imgDir = [dateDir,'drone/flight_',num2str(opts.flightNum),'/'];

        photoMetaPath = [dateDir, 'drone/metadata.csv'];
        PHOT = sl_readphotometa(photoMetaPath);

        flightRecordPath = [dateDir, ...
            'drone/flight_records/csv/flight_',num2str(opts.flightNum),'.csv'];
        DJI = sl_readflightrecord(flightRecordPath);

        imgNumberList = opts.firstImgNum:opts.lastImgNum;

        % for ii = 1:numel(imgNumberList)
        %     kk = imgNumberList(ii);
        %     imgFnameList{ii} = ['DJI_',sprintf('%04d',kk),'.JPG'];
        % end

end

nostop = opts.nostop;


%% load data for ground references.

% If a coastline file was given - we expect the
% coast points to be in an nx2 vector 'ncst' of [long lat].

if opts.isCoastline,load(opts.coastlinePath); end

if opts.isDrifter
    if contains(opts.drifterPath,'.mat')
        load(opts.drifterPath)
    else
        drifterFind = dir([dateDir,'drifter/*.mat']);
        load([drifterFind.folder,'/',drifterFind.name]); % a struct named 'drift'
    end
end

if opts.isShipGPS
    if contains(opts.shipPath,'.mat')
        load(opts.shipPath);
    else
        shipFind = dir([dateDir,'OziExplorer/*.plt']);
        ship_gps = ozi_rd([shipFind.folder,'/',shipFind.name]);
    end
end




%---------------------------------------------------------------------

% The minimization is repeated nMinimize times where each time a random
% combination of the initial guesses is chosen within the given
% uncertainties provided by the user. This is becasue the algorithm often
% converges toward a local minimum. The repetition is used to increase chances
% that the minimum found is a true minimum within the uncertainties provided.

nMinimize = 50; % not useful for now


%% load database

findTempDatabase = dir('./database_temp.mat');

if contains(opts.databasePath,'.mat')
    load(opts.databasePath); % A data struct named 'DB'

elseif ~isempty(findTempDatabase)
    disp("opts.databasePath does not directly point to a .mat file");
    disp("A database_temp.mat file is found in the current path");
    disp("load('database_temp.mat')");
    load('database_temp.mat');
else
    % create a temporary database
    disp("temporary data base created, saved database_temp.mat to the current directory");
    disp("For better consistensy, please create your own database");
    DB = struct;
    save('database_temp.mat','DB');
end



%% Loop starts here:

imageNum = 1; 
while imageNum <= numel(imgNumberList)
    nn = imgNumberList(imageNum);
    imgFname = ['DJI_',sprintf('%04d',nn),'.JPG'];


    photoFinds = find(contains(PHOT.SourceFile, imgFname));

    if isempty(photoFinds)
        error(imgFname + "not found in the metadata (PHOT)!")
    elseif numel(photoFinds) == 1
        photoIndex = photoFinds;
    else
        photoIndex = find(contains(PHOT.SourceFile,['flight_', num2str(opts.flightNum),...
            '/',imgFname]));
    end

    photoTime = PHOT.mtime(photoIndex);

    if imageNum == 1
        for ii = 1:numel(imgNumberList)
            imgFnameList{ii} = ['DJI_',sprintf('%04d',imgNumberList(ii)),'.JPG'];

        end
    end


    % special condition, I need to handle it more properly later on (somehow
    % in the flight record, sometimes, it consider the eastern time as the
    % local timezone, so we get 3 hours of time difference between PHOT and DJI
    if round((DJI.mtime(1) - photoTime)*24) == 3
        DJI.mtime = DJI.mtime - 3/24;
        DJI.datetime = DJI.datetime - hours(3);
    end
    [timeDiff, flightRecordIndex] = min(abs(DJI.mtime - photoTime));

    if timeDiff > 1/(24*3600)
        error("Unable to find matching flight record by time for " + imgFname + ...
            "check time zones or threshold!");
    end



    % if this image bas been previously visited and corrected, nothing has to
    % be done here. We can simply load data from the database
    isPrevCorr = false;

    try % in case DB is a empty struct (no .mtimePhoto field)
        prevCorrFind = find(DB.mtimePhoto == photoTime);
    catch
        prevCorrFind = [];
    end

    if ~isempty(prevCorrFind) && strcmp(DB.imgFname, imgFname)
        disp("For " + imgFname + ", previous corrections are found and applied");
        isPrevCorr = true;

        LON0 = DB(prevCorrFind).LON0;
        LAT0 = DB(prevCorrFind).LAT0;
        H = DB(prevCorrFind).H0;

        ATT = DB(prevCorrFind).ATT;
        UI = DB(prevCorrFind).UI;

    else

        LON0 = PHOT.GPSlon(photoIndex);
        LAT0 = PHOT.GPSlat(photoIndex);
        H = PHOT.RelativeAltitude(photoIndex) + opts.launchAltitude;

        clear ATT

        ATT = struct;

        ATT.photo.gimbal.pitch = PHOT.GIMBALpitch(photoIndex);
        ATT.photo.gimbal.roll = PHOT.GIMBALroll(photoIndex);
        ATT.photo.gimbal.yaw = PHOT.GIMBALyaw(photoIndex);

        ATT.photo.aircraft.pitch = PHOT.OSDpitch(photoIndex);
        ATT.photo.aircraft.roll = PHOT.OSDroll(photoIndex);
        ATT.photo.aircraft.yaw = PHOT.OSDyaw(photoIndex);

        ATT.flightRecord.gimbal.pitch = DJI.GIMBALpitch(flightRecordIndex);
        ATT.flightRecord.gimbal.roll = DJI.GIMBALroll(flightRecordIndex);
        ATT.flightRecord.gimbal.yaw = DJI.GIMBALyaw(flightRecordIndex);

        ATT.flightRecord.aircraft.pitch = DJI.OSDpitch(flightRecordIndex);
        ATT.flightRecord.aircraft.roll = DJI.OSDroll(flightRecordIndex);
        ATT.flightRecord.aircraft.yaw = DJI.OSDyaw(flightRecordIndex);


    end


    % lambda --> - pitch
    % phi    -->   roll
    % theta  -->   yaw


    % lambda = - PHOT.GIMBALpitch(photoIndex); % (-pitch)
    % phi = PHOT.GIMBALroll(photoIndex); % (roll)
    % theta = PHOT.GIMBALyaw(photoIndex); % (yaw)

    frameRef = opts.frameRef;




    %% Lense information (can be written into opts?)
    % ------------------------------------------------------------------
    % Defaults related to mapping camera pixesl to ground points
    % (can be altered in .dat file)


    % TODO: should be written into opts and separate data file...

    lens.geometry='camera.json'; % or 'thin'??
    lens.hfov = 2*atand(tand(73.74/2)*.935);
    lens.k=[1  0.10658938237128054 -0.18856367135787402 0.12972187263071938];  % Radial distorion. From Camera.json
    lens.p=[0.0017523636559856292 -7.148567323936884e-06]; % Tangential distortions

    % lens.k=[0 0 0];  % Radial distorion (default none).
    % lens.p=[0 0];    % Tangential distortions (default none)
    lens.ic=-0.00388919027283902;       % Principle point offset from center (y direction)
    lens.jc=-0.001055072144606377;      % x direction
    lens.Re= 6378135.0;   % Earth's radius (m)

    % Refractive ray curvature for a standard atmosphere
    % 1/5.3 for standard atmosphere lapse rate 6.5K/km
    % 1/6 for a convective lapse rate of 10K/km
    % 1/4.3 for an isothermal atmosphere
    % 0 for no atmospheric refraction
    lens.Refractedcurvatureratio=1/5.3;

    %% UNCERTAINTIES
    %    Set here the uncertainties of the associated camera parameters.
    %    Set the uncertainty to 0 for fixed parameters.

    % TODO: should be written into opts later
    dhfov   = 0;
    dlambda = 0;
    dphi    =  0;
    dtheta  = 0;
    dH      =  0;

    %% POLYNOMIAL CORRECTION
    %    After the geometrical correction, a polynomial correction of degree 1 or 2
    %    could be applied. This could correct for some unknown distortions that cannot be
    %    corrected on geometrical grounds. Play carefully with this option as it is a purely
    %    mathematical fit which may lead to unphysical corrections or may hide other
    %    prior problems with the actual geometrical correction. Always first set this option
    %    to '0' in which case there will be no polynomial correction applied. In principle,
    %    the geometrical fit without this option should already be pretty good. You could then
    %    fine tune the image with this option. Be extra careful when using the second order
    %    polynomial fit, especially outside the region of the GCPs as the image could there
    %    be completely distorted.
    %
    polyOrder = 0; % not useful for now

    save_orig = false;
    % gcpData = false; % doesn't do anything
    %% Read the parameter file
    % Count the number of header lines before the ground control points (GCPs)
    % The GCPs start right after the variable gcpData is set to true.


    % if isempty(inputFname)
    %     inputFname = 'g_rect_params.dat'; % Default value
    %     image_num=1;
    % end

    %
    % 0 - stop for text input
    % 1 - stop for gui input
    % 2 - no stop
    %
    % if nargin<3
    %     nostop='text';
    % else
    %     if ~ischar(nostop)
    %         switch nostop
    %             case 0
    %                 nostop='text';
    %             case 1
    %                 nostop='gui';
    %             case 2
    %                 nostop='none';
    %         end
    %     end
    % end


    % fid = fopen(inputFname);
    %
    % nHeaderLine  = 0;
    % gcpData      = false;
    % AxisLimits=NaN;
    % GraticuleType=2;

    % Read and execute each line of the parameter file until gcpData = true
    % after which the GCP data appear and are read below with the 'importdata'
    % function.
    % while gcpData == false
    %     l=fgetl(fid);
    %     while contains(l,'...')   % Line continuations
    %         icont=strfind(l,'...');
    %         l=[l(1:icont-1) fgetl(fid)];
    %     end
    %     try
    %        eval(l);
    %     catch
    %         error(l);
    %     end
    %     nHeaderLine = nHeaderLine + 1;
    % end
    % fclose(fid);

    % lens.hfov = hfov; % add by S. Li, April 25, 2024

    % The older version of the code had a variable called 'field' that could be
    % set to 'true' or 'false' in the input parameters file depending on whether
    % the application was done for a field situation (field = true) or a lab
    % situation (field = false). It was implicitly assumed that positions were
    % given by a geodetic system (lon-lat) for field situations and by a
    % cartesian system (x-y) for lab situations. But this was a little confusing
    % as field situations could also use Cartesian coordinates, for example when
    % the Universal Transverse Mercator (UTM) system is used. This new version
    % of the code now rather specifies the frame of reference used that could
    % be either 'Cartesian' or 'Geodetic'. The following lines of code are
    % simply here to allow this new version of the code to be compatible with
    % the older version of the parameters file in which the now obsolete
    % variable 'field' appeared and the current variable 'frameRef' was absent.

    


    %% Import the GCP data at the end of the parameter file
    % gcp      = importdata(inputFname,' ',nHeaderLine);
    % if isfield('data',gcp)
    %     i_gcp    = gcp.data(:,1);
    %     j_gcp    = gcp.data(:,2);
    %     lon_gcp0 = gcp.data(:,3);
    %     lat_gcp0 = gcp.data(:,4);
    %
    %     [ngcp n_column] = size(gcp.data);
    %
    %     % If there are 5 columns it means that elevation are provided
    %     if n_column == 5
    %         h_gcp    = gcp.data(:,5);
    %     else % otherwise elevation are considered to be zero
    %         h_gcp(1:ngcp,1) = 0.0;
    %     end
    %     ncontrol=ngcp;
    % else
    %     lon_gcp0=[];
    %     lat_gcp0=[];
    %     i_gcp=[];
    %     j_gcp=[];
    %     ncontrol=0;
    % end

    if opts.isgcp
        % TODO: do something here...

        % h_gcp = zeros(size(coast_lon));
        % i_gcp = zeros(size(coast_lon));
        % j_gcp = zeros(size(coast_lon));
        % ngcp=length(coast_lon);
        %
        % i_gcp    = i_gcp';
        % j_gcp    = j_gcp';
        % h_gcp    = h_gcp';


    else
        ncontrol=0;
    end

    % If a coastline file was given - we expect the
    % coast points to be in an nx2 vector 'ncst' of [long lat].

    if opts.isCoastline



        if imageNum == 1

            coast_lon = ncst(:,1);
            coast_lat = ncst(:,2);

            meterPerDegLat = 1852*60.0;
            Dhoriz2 = (2*H*lens.Re)/meterPerDegLat.^2;

            irm=((coast_lon-LON0).^2*cosd(LAT0).^2+(coast_lat-LAT0).^2)>Dhoriz2;
            coast_lon(irm)=[];
            coast_lat(irm)=[];

            % coast_lon = coast_lon';
            % coast_lat = coast_lat';

        end

    end






    % load driftertrack data
    if opts.isDrifter

        driftlonC = [];
        driftlatC = [];
        dr_idx = [];

        clear first_comment_letters;
        for ii = 1:numel(drift)
            first_comment_letters(ii) = drift(ii).comment(1);
        end
        dr_idx = find(first_comment_letters ~= 'h');

        for ii = 1:numel(dr_idx)
            kk = dr_idx(ii);
            gd_idx = drift(kk).atSea == 1;
            CC = interp1(drift(kk).mtime(gd_idx), ...
                drift(kk).lon(gd_idx) + drift(kk).lat(gd_idx)*1i, photoTime,'spline');
            driftlonC(ii) = real(CC);
            driftlatC(ii) = imag(CC);
        end

        gd_colors = {
            'r'
            'g'
            'b'
            'c'
            'm'
            'y'
            [0 0.4470 0.7410] % col_db (dark blue)
            [0.8500 0.3250 0.0980] % col_lr (light red, or orange)
            [0.9290 0.6940 0.1250] % col_y (yellow)
            [0.4940 0.1840 0.5560] % col_p (purple)
            [0.4660 0.6740 0.1880] % col_g (green)
            [0.3010 0.7450 0.9330] % col_lb (light blue)
            [0.6350 0.0780 0.1840] % col_dr (dark red)
            };

    end

    % load ship GPS data

    if opts.isShipGPS
        CC = interp1(ship_gps.mtime, ship_gps.lon + ship_gps.lat*1i, photoTime);
        shiplonC = real(CC);
        shiplatC = imag(CC);
    end


    %%
    % Check if the elevation of the GCPs are not too high and above
    % a certain fraction (gamma) of the camera height. If so, stop.

    if exist('h_gcp','var')

        gamma = 0.75;
        i_bad = find(h_gcp > gamma*(H+dH));
        if ~ isempty(i_bad)
            disp(' ');
            disp('  WARNING:');
            for i = 1:length(i_bad)
                disp(['      The elevation of GCP #',num2str(i_bad(i)),' is greater than ',num2str(gamma),'*(H+dH).']);
            end
            disp('  FIX AND RERUN.');
            return
        end
    end

    % Get the image size
    imgInfo   = imfinfo([imgDir imgFname]);
    imgWidth  = imgInfo.Width;
    imgHeight = imgInfo.Height;

    % if precision == 'single'
    %     imgWidth  = single(imgWidth);
    %     imgHeight = single(imgHeight);
    % end

    %% Display information
    % fprintf('\n')
    % fprintf('  INPUT PARAMETERS\n')
    % fprintf('    Image filename: (imgFname):........... %s\n',imgFname)
    % % fprintf('    First image: (firstImgFname):......... %s\n',firstImgFname)
    % % fprintf('    Last image: (lastImgFname):........... %s\n',lastImgFname)
    % % fprintf('    Output filename: (outputFname):....... %s\n',outputFname);
    % % (outputFname may only be used in some special cases)
    % fprintf('    Image width (imgWidth):............... %i\n',imgWidth)
    % fprintf('    Image width (imgHeight):.............. %i\n',imgHeight)
    % fprintf('    Frame of reference:................... %s\n',frameRef)
    % fprintf('    Camera longitude or x coord. (LON0):.. %f\n',LON0)
    % fprintf('    Camera latitude or y coord. (LAT0):... %f\n',LAT0)
    % fprintf('    Principal point offset (ic):.......... %f\n',lens.ic)
    % fprintf('    Principal point offset (jc):.......... %f\n',lens.jc)
    % fprintf('    Field of view (hfov):................. %f\n',lens.hfov)
    % fprintf('    Dip angle (lambda):................... %f\n',lambda)
    % fprintf('    Tilt angle (phi):..................... %f\n',phi)
    % fprintf('    Camera altitude (H):.................. %f\n',H)
    % fprintf('    View angle from North (theta):........ %f\n',theta)
    % fprintf('    Uncertainty in hfov (dhfov):.......... %f\n',dhfov)
    % fprintf('    Uncertainty in dip angle (dlambda):... %f\n',dlambda)
    % fprintf('    Uncertainty in tilt angle (dphi):..... %f\n',dphi)
    % fprintf('    Uncertainty in altitude (dH):......... %f\n',dH)
    % fprintf('    Uncertainty in view angle (dtheta):... %f\n',dtheta)
    % fprintf('    Polynomial order (polyOrder):......... %i\n',polyOrder)
    % fprintf('    Number of GCPs (ncontrol):............ %i\n',ncontrol)
    % fprintf('    Number of GPs  (ngcp):................ %i\n',ngcp)
    % % fprintf('    Precision (precision):................ %s\n',precision)
    % fprintf('\n')

    % Display the image with GCPs;
    %image(imread(imgFname));

    figure(1);
    clf;
    set(gcf,'color','w');

    imagesc(imread([imgDir imgFname]));
    set(gca,'tickdir','out','tickdirmode','manual','plotboxaspectratiomode','auto',...
        'dataaspectratiomode','auto');
    % colormap(gray); % ??? why??? didn't do anything
    hold on


    sliderHeight = 0.02;
    sliderWidth = 0.1;
    sliderY = 0.95;

    textHeight = sliderHeight;
    textWidth = sliderWidth;
    textY = sliderY + sliderHeight;

    buttonHeight = sliderHeight + textHeight;
    buttonWidth = 0.07;

    toggleWidth = 0.05;
    toggleY = sliderY;
    toggleHeight = sliderHeight + textHeight;


    if strcmp(nostop,'gui')
        uicontrol(gcf,'style','text','string','(yaw) Left - Right',    'unit','normalized','position',[.1 textY textWidth textHeight]);
        yawmode  =uicontrol(gcf,'style','slider','tag','yaw',  'unit','normalized','position',[.1 sliderY  sliderWidth sliderHeight],...
            'value',0,'max',40,'min',-40,'sliderstep',[.01 .1]);
        yawGroup = uibuttongroup(gcf,"Position",[.1+textWidth toggleY toggleWidth toggleHeight],'BackgroundColor','w','BorderColor','w');
        yawToggleGIMBAL = uicontrol(yawGroup,'style','togglebutton','string','GIMBAL', ...
            'unit','normalized','position',[0 0.5 1 .5]);
        yawToggleOSD = uicontrol(yawGroup,'style','togglebutton','string','OSD', ...
            'unit','normalized','position',[0 0 1 .5]);


        uicontrol(gcf,'style','text','string','(pitch) Down - Up',       'unit','normalized','position',[.3 textY textWidth textHeight]);
        pitchmode=uicontrol(gcf,'style','slider','tag','pitch','unit','normalized','position',[.3 sliderY  sliderWidth sliderHeight],...
            'value',0,'max',20,'min',-20,'sliderstep',[.005 .05]);
        pitchGroup = uibuttongroup(gcf,"Position",[.3+textWidth toggleY toggleWidth toggleHeight],'BackgroundColor','w','BorderColor','w');
        pitchToggleGIMBAL = uicontrol(pitchGroup,'style','togglebutton','string','GIMBAL', ...
            'unit','normalized','position',[0 0.5 1 .5]);
        pitchToggleOSD = uicontrol(pitchGroup,'style','togglebutton','string','OSD', ...
            'unit','normalized','position',[0 0 1 .5]);


        uicontrol(gcf,'style','text','string','(roll) CCW - CW',        'unit','normalized','position',[.5 textY textWidth textHeight]);
        rollmode =uicontrol(gcf,'style','slider','tag','roll', 'unit','normalized','position',[.5 sliderY  sliderWidth sliderHeight],...
            'value',0,'max',10,'min',-10,'sliderstep',[.005 .05]);
        rollGroup = uibuttongroup(gcf,"Position",[.5+textWidth toggleY toggleWidth toggleHeight],'BackgroundColor','w','BorderColor','w');
        rollToggleGIMBAL = uicontrol(rollGroup,'style','togglebutton','string','GIMBAL', ...
            'unit','normalized','position',[0 0.5 1 .5]);
        rollToggleOSD = uicontrol(rollGroup,'style','togglebutton','string','OSD', ...
            'unit','normalized','position',[0 0 1 .5]);

        uicontrol(gcf,'style','text','string','(Altitude) Lower - Higher',  'unit','normalized','position',[.7 textY textWidth textHeight]);
        altmode  =uicontrol(gcf,'style','slider','tag','alt',  'unit','normalized','position',[.7 sliderY  sliderWidth sliderHeight],...
            'value',0,'max',40,'min',-40,'sliderstep',[.01 .1]);

        sensbut=uicontrol(gcf,'style','checkbox','tag','sensitivity',  'unit','normalized','position',[.87 sliderY  .11 buttonHeight],...
            'string','High Sensitivity','min',0,'max',1,'value',0,'userdata',0);

        % source group
        sourceGroup = uibuttongroup(gcf,"Position",[.92 0.83 buttonWidth buttonHeight*2],'BackgroundColor','w','BorderColor','w');
        sourceTogglePHOT = uicontrol(sourceGroup,'style','togglebutton','string','photo meta', ...
            'unit','normalized','position',[0 0.5 1 .5]);
        sourceToggleDJI = uicontrol(sourceGroup,'style','togglebutton','string','flight record', ...
            'unit','normalized','position',[0 0 1 .5]);


        resbut=uicontrol(gcf,'style','pushbutton','tag','reset',  'unit','normalized','position',[.92 .75  buttonWidth buttonHeight],...
            'string','Reset','callback','set(gcbo,''userdata'',''reset'')','userdata','ok');
        autobut=uicontrol(gcf,'style','pushbutton','tag','auto', 'unit','normalized','position',[.92 .65  buttonWidth buttonHeight],...
            'string','Prev. Corr.','callback','set(gcbo,''userdata'',''auto'')','userdata','none');
        savebut=uicontrol(gcf,'style','pushbutton','tag','save',  'unit','normalized','position',[.92 .55  buttonWidth buttonHeight],...
            'string','SAVE','callback','set(gcbo,''userdata'',''save'')','userdata','not done');
        extbut=uicontrol(gcf,'style','pushbutton','tag','reset',  'unit','normalized','position',[.92 .45  buttonWidth buttonHeight],...
            'string','EXIT','callback','set(gcbo,''userdata'',''exit'')','userdata','continue');

        prevbut = uicontrol(gcf,'style','pushbutton','tag','prev', 'unit','normalized','position',[.02 .1  buttonWidth buttonHeight],...
            'string','PREVIOUS','callback','set(gcbo,''userdata'',''prev'')','userdata','none');
        nextbut = uicontrol(gcf,'style','pushbutton','tag','next', 'unit','normalized','position',[.92 .1  buttonWidth buttonHeight],...
            'string','NEXT','callback','set(gcbo,''userdata'',''next'')','userdata','none');

    end

    % default corr
    oldcorr = [0 0 0 0];
    corr = oldcorr;

    % default toggle
    oldtoggle = [1 1 1 1];
    toggle = oldtoggle;

    theta = ATT.photo.gimbal.yaw;
    lambda = - ATT.photo.gimbal.pitch;
    phi = ATT.photo.gimbal.roll;

    theta0 = theta;
    lambda0 = lambda;
    phi0 = phi;
    H0 = H;

    dleft = 0;
    dup = 0;
    droll = 0;
    dh = 0;

    isExistingCorrection = false;



    % lambda --> - pitch
    % phi    -->   roll
    % theta  -->   yaw
    if exist('DB','var') && isfield(DB,'imgFname')
        thisCorrFind = find(contains({DB.imgFname}, imgFname) & contains({DB.folder}, imgDir));

        if ~isempty(thisCorrFind)
            thisUI = DB(thisCorrFind).UI;

            oldcorr = thisUI.corr; % [dleft, dup, droll, dh]
            oldtoggle = thisUI.toggle; % [yaw, pitch, roll, source]

            corr = oldcorr;
            toggle = oldtoggle;

            theta = thisUI.theta;
            lambda = thisUI.lambda;
            phi = thisUI.phi;
            H = thisUI.H;


            theta0 = thisUI.theta0;
            lambda0 = thisUI.lambda0;
            phi0 = thisUI.phi0;
            H0 = thisUI.H0;

            dleft = corr(1);
            dup = corr(2);
            droll = corr(3);
            dh = corr(4);


            set(yawmode,'value',dleft);
            set(yawToggleGIMBAL,'Value',thisUI.yawToggleGIMBAL);
            set(yawToggleOSD,'Value',thisUI.yawToggleOSD);

            set(pitchmode,'value',dup);
            set(pitchToggleGIMBAL,'Value',thisUI.pitchToggleGIMBAL);
            set(pitchToggleOSD,'Value',thisUI.pitchToggleOSD);

            set(rollmode,'value',droll);
            set(rollToggleGIMBAL,'Value',thisUI.rollToggleGIMBAL);
            set(rollToggleOSD,'Value',thisUI.pitchToggleOSD);

            set(altmode,'value',dh);

            set(sourceTogglePHOT,'Value',thisUI.sourceTogglePHOT);
            set(sourceToggleDJI,'Value',thisUI.sourceToggleDJI);

            isExistingCorrection = true;
        end


    end



    ok='n';
    while ok~='y'

        % axmode=uicontrol(gcf,'style','pushbutton','tag','axaspect',...
        %                 'unit','normalized','position',[.025 .93 .175 .07],...
        %                 'string','FREE ASPECT RATIO','userdata','go',...
        %                 'callback','set(gca,''dataaspectratiomode'',''auto'')');
        xlabel({sprintf('Heading (Yaw): %.2f (%.2f+{\\color{red}%.2f}) Dip: %.2f (%.1f+{\\color{red}%.2f}) Roll: %.2f (%.1f+{\\color{red}%.2f})',...
            theta,theta0,theta-theta0,...
            lambda,lambda0,lambda-lambda0,...
            phi,phi0,phi-phi0),...
            sprintf('Altitude: %.2f (%.1f+{\\color{red}%.2f}) m  FOV  %.2f',H,H0,H-H0,lens.hfov)});


        if opts.isgcp
            for i = 1:ncontrol
                hc(i)=plot(i_gcp(i),j_gcp(i),'r.');
                ht(i)=text(i_gcp(i),j_gcp(i),[' ',num2str(i),'(',num2str(h_gcp(i)),')'],...
                    'color','r',...
                    'horizontalalignment','left',...
                    'fontsize',10);
            end
        end

        % Show control points that have lat/longs on map

        if opts.isCoastline

            % Transform camera coordinate to ground coordinate.
            [xp,yp] = g_ll2pix(ncst(:,1),ncst(:,2),imgWidth,imgHeight,...
                lambda,phi,theta,H,LON0,LAT0,frameRef,lens);
            hR=line(xp,yp,'color','r');
        end


        if opts.isDrifter

            clear hD hDC

            for ii = 1:numel(dr_idx)
                kk = dr_idx(ii);
                gd_idx = drift(kk).atSea == 1;

                [xp,yp] = g_ll2pix(drift(kk).lon(gd_idx),drift(kk).lat(gd_idx),imgWidth,imgHeight,...
                    lambda,phi,theta,H,LON0,LAT0,frameRef,lens);
                hD(ii)=line(xp,yp,'color',gd_colors{ii},'marker','.');
                [xpC,ypC] = g_ll2pix(driftlonC(ii),driftlatC(ii),imgWidth,imgHeight,...
                    lambda,phi,theta,H,LON0,LAT0,frameRef,lens);
                hDC(ii)=line(xpC,ypC,'color',gd_colors{ii},'marker','x','linestyle','none','markersize',10);
            end

        end


        if opts.isShipGPS
            [xp,yp] = g_ll2pix(ship_gps.lon,ship_gps.lat,imgWidth,imgHeight,...
                lambda,phi,theta,H,LON0,LAT0,frameRef,lens);

            hS=line(xp,yp,'color','k','marker','.');

            [xp,yp] = g_ll2pix(shiplonC,shiplatC,imgWidth,imgHeight,...
                lambda,phi,theta,H,LON0,LAT0,frameRef,lens);

            hSC=line(xp,yp,'color','k','marker','x','markersize',10);
        end

        % Draw the graticule
        hg=g_graticule(imgWidth,imgHeight,lambda,phi,theta,...
            H,LON0,LAT0,frameRef,lens,opts.graticuleType);



        title(imgFname + " at " + datestr(photoTime),...
            'color','r','interpreter','none');
        %daspect([1 1 1]);

        ylabel('Pixel')
        drawnow;

        if save_orig
            print('-dpng','-r300',[opts.outputDir imgFname(1:end-4),'_GCP.png']);
        end

        if strcmp(nostop,'text')
            fprintf('\n')
            ok = input('Is it ok to proceed with the rectification (y/n): ','s');
            if isempty(ok)
                ok = 'y';  % Default value
            end
            if ok ~= 'y'
                ok=ok(ok~=' ');
                if ok(1)=='[' && ok(end)==']' % handles case when you just repeat the 4 elements
                    corr=eval(ok);
                else
                    corr=input('Add [left,up,CW,altitude] corrections: (<ret> for exit): ');
                end
                if length(corr)==4
                    % Properly handle the rotation angles
                    dleft=dleft+corr(1);
                    dup=dup+corr(2);
                    droll=droll+corr(3);
                    dh=dh+corr(4);
                    H=H0+dh;
                    if abs(lambda0)<45
                        fprintf('[yaw/pitch/roll/alt] = [ %.2f %.2f %.2f %.2f ]\n',dleft,dup,droll,dh);
                        theta=theta+corr(1);
                        lambda=lambda+corr(2);
                        phi=phi+corr(3);
                        H=H+corr(4);
                    else
                        [theta,lambda,phi]=rotate3(theta0,lambda0,phi0,dleft,dup,droll,0);%cosd(lambda0));
                        fprintf('[left/up/roll/alt] = [ %.2f %.2f %.2f %.2f ] [yaw/pitch/roll/alt] = [ %.2f %.2f %.2f %.2f ]\n',...
                            dleft,dup,droll,dh,theta-theta0,lambda-lambda0,phi-phi0,H-H0);
                        H=H+corr(4);
                    end
                elseif length(corr)==1  % reset values
                    dleft=0;
                    dup=0;
                    droll=0;
                    dh=0;
                else
                    return
                end
                delete(hg);
                if exist('hc')
                    delete(hc);delete(ht);
                end
                if exist('hR'), delete(hR); end
                if exist('hS'), delete(hS); delete(hSC);end
                if exist('hD'), delete(hD); delete(hDC);end
            end


        elseif strcmp(nostop,'gui')

            while all(corr==oldcorr) && all(toggle == oldtoggle)



                corr=[get(yawmode,'value') get(pitchmode,'value') ...
                    get(rollmode,'value') get(altmode,'value')];
                toggle = [get(yawToggleGIMBAL,'value') get(pitchToggleGIMBAL,'value') ...
                    get(rollToggleGIMBAL,'value') get(sourceTogglePHOT,'value')];




                if strcmp(get(prevbut,'userdata'),'prev')
                    if imageNum == 1
                        disp('This is the first image in the batch!');
                        disp('No previous image!');
                    else
                        imageNum = imageNum-1;
                        ok = 'y';
                        break;
                    end
                    set(prevbut,'userdata','none');
                end

                if strcmp(get(nextbut,'userdata'),'next')
                    if imageNum >= numel(imgNumberList)
                        disp('This is the last image in the batch!');
                        disp('No next image!');
                    else
                        imageNum = imageNum+1;
                        ok = 'y';
                        break;
                    end
                    set(nextbut,'userdata','none');
                end



                if strcmp(get(autobut,'userdata'),'auto')

                    if imageNum == 1
                        disp('This is the first image in the batch!');
                        disp('No previous correction applied!');
                        % TODO: in the future, if opts.type == 'plume', we can try
                        % to find any correction done for the same flight
                    else
                        prevNum = imageNum-1;
                        prevFname = imgFnameList(prevNum);
                        prevFind = find(contains({DB.imgFname}, prevFname) & contains({DB.folder}, imgDir));

                        if isempty(prevFind)

                            disp('No previous correction found!')
                        else
                            % prevATT = DB(prevFind).ATT;
                            prevUI = DB(prevFind).UI;
                            corr = prevUI.corr;
                            toggle = prevUI.toggle;

                            set(yawmode,'value',prevUI.yawmode);
                            set(yawToggleGIMBAL,'Value',prevUI.yawToggleGIMBAL);
                            set(yawToggleOSD,'Value',prevUI.yawToggleOSD);

                            set(pitchmode,'value',prevUI.pitchmode);
                            set(pitchToggleGIMBAL,'Value',prevUI.pitchToggleGIMBAL);
                            set(pitchToggleOSD,'Value',prevUI.pitchToggleOSD);

                            set(rollmode,'value',corr(3));
                            set(rollToggleGIMBAL,'Value',prevUI.rollToggleGIMBAL);
                            set(rollToggleOSD,'Value',prevUI.rollToggleOSD);

                            set(altmode,'value',prevUI.altmode);

                            set(sourceTogglePHOT,'Value',prevUI.sourceTogglePHOT);
                            set(sourceToggleDJI,'Value',prevUI.sourceToggleDJI);

                            set(sensbut,'Value',1)
                        end
                    end

                    set(autobut,'userdata','none');

                end





                if strcmp(get(resbut,'UserData'),'reset')

                    set(yawmode,'value',0);
                    set(yawToggleGIMBAL,'Value',1);
                    set(yawToggleOSD,'Value',0);

                    set(pitchmode,'value',0);
                    set(pitchToggleGIMBAL,'Value',1);
                    set(pitchToggleOSD,'Value',0);

                    set(rollmode,'value',0);
                    set(rollToggleGIMBAL,'Value',1);
                    set(rollToggleOSD,'Value',0);

                    set(altmode,'value',0);

                    set(sourceTogglePHOT,'Value',1);
                    set(sourceToggleDJI,'Value',0);

                    corr=[0 0 0 0];
                    toggle = [1 1 1 1];

                    set(resbut,'userdata','none');

                end



                if strcmp(get(savebut,'userdata'),'save')

                    UI.yawmode = get(yawmode,'value');
                    UI.pitchmode = get(pitchmode,'value');
                    UI.rollmode = get(rollmode,'value');
                    UI.altmode = get(altmode,'value');
                    UI.yawToggleGIMBAL = get(yawToggleGIMBAL,'value');
                    UI.yawToggleOSD = get(yawToggleOSD,'value');
                    UI.pitchToggleGIMBAL = get(pitchToggleGIMBAL,'value');
                    UI.pitchToggleOSD = get(pitchToggleOSD,'value');
                    UI.rollToggleGIMBAL = get(rollToggleGIMBAL,'value');
                    UI.rollToggleOSD = get(rollToggleOSD,'value');
                    UI.sourceTogglePHOT = get(sourceTogglePHOT,'value');
                    UI.sourceToggleDJI = get(sourceToggleDJI,'value');
                    UI.corr = corr;
                    UI.toggle = toggle;
                    UI.theta0 = theta0;
                    UI.lambda0 = lambda0;
                    UI.phi0 = phi0;
                    UI.H0 = H0;
                    UI.theta = theta;
                    UI.lambda = lambda;
                    UI.phi = phi;
                    UI.H = H;


                    % oldcorr=[Inf Inf Inf Inf];

                    if imageNum < numel(imgNumberList)
                        imageNum = imageNum + 1;
                    elseif imageNum == numel(imgNumberList)
                        disp('This is the last image in the batch!')
                    end

                    if ~exist('DB','var')
                        error('No database (DB struct) found, can not save corrections')
                    elseif isempty(fieldnames(DB))
                        dbIndex = 1;
                    else

                        if isExistingCorrection
                        isOverwrite = questdlg(['Do you want to overwrite existing corrections of ',imgFname,'?'], ...
                        	'Warning!','yes', 'cancel','yes');

                        switch isOverwrite
                            case 'yes'
                                disp('Overwrite existing corrections!');
                                dbIndex = thisCorrFind;
                            case 'cancel'
                                disp('Kept as original!');
                                break;
                        end

                        else 
                            dbIndex = numel(DB) + 1;
                        end

                        
                    end

                    DB(dbIndex).mtimePhoto = photoTime;
                    DB(dbIndex).imgFname = imgFname;
                    DB(dbIndex).folder = imgDir;
                    DB(dbIndex).opts = opts;
                    DB(dbIndex).ATT = ATT;
                    DB(dbIndex).UI = UI;
                    DB(dbIndex).lens = lens;
                    DB(dbIndex).yaw = theta;
                    DB(dbIndex).pitch = - lambda;
                    DB(dbIndex).roll = phi;
                    DB(dbIndex).theta = theta;
                    DB(dbIndex).lambda = lambda;
                    DB(dbIndex).phi = phi;
                    DB(dbIndex).H = H;
                    DB(dbIndex).H0 = H0;
                    DB(dbIndex).LON0 = LON0;
                    DB(dbIndex).LAT0 = LAT0;
                    DB(dbIndex).imgWidth = imgWidth;
                    DB(dbIndex).imgHeight = imgHeight;



                    ok='y';
                    save(opts.databasePath,'DB');
                    disp(['Corrections to ', imgFname, ' is saved!']);

                    % save as backups every 50 corrections. TODO: if that
                    % folder does not exist, then create a folder at the
                    % current dir
                    if mod(dbIndex,50) == 0
                        backupFname = ['database_backup_' num2str(dbIndex),'.mat'];
                        if exist(opts.backupDir,'dir') == 7 
                            if exist([opts.backupDir,backupFname],'file') == 2, break; end % if backup exist, then don't overwrite

                            save([opts.backupDir,backupFname],'DB');
                        else
                            mkdir('temp_backup');
                            save(['temp_backup/database_backup_' num2str(dbIndex),'.mat'],'DB');
                            warning(opts.backupDir,'- not found, created a temp_backup folder inthe current directory!');
                        end
                        disp([num2str(dbIndex),' corrections saved to backup!'])
                    end

                    break;

                end




                if strcmp(get(extbut,'userdata'),'exit')
                    fprintf('Exit \n');
                    return
                end


                if get(sensbut,'value')==1  && get(sensbut,'userdata')==0
                    set(yawmode,'sliderstep',[.001 .01]);
                    set(pitchmode,'sliderstep',[.0005 .005]);
                    set(rollmode,'sliderstep',[.0005 .005]);
                    set(altmode,'sliderstep',[.001 .01]);
                    set(sensbut,'userdata',1);
                elseif get(sensbut,'value')==0  && get(sensbut,'userdata')==1
                    set(yawmode,'sliderstep',[.01 .1]);
                    set(pitchmode,'sliderstep',[.005 .05]);
                    set(rollmode,'sliderstep',[.005 .05]);
                    set(altmode,'sliderstep',[.01 .1]);
                    set(sensbut,'userdata',0);
                end

                pause(.05)
            end


            % now, since either corr or toggle has changed, we need to redraw the
            % figure

            if sourceTogglePHOT.Value == 1 && sourceToggleDJI.Value == 0
                attSource = ATT.photo;
            elseif sourceTogglePHOT.Value == 0 && sourceToggleDJI.Value == 1
                attSource = ATT.flightRecord;
            else
                warning("choose source: 'photo meta' or 'flight record'!")
            end



            % theta  <-->   yaw
            if yawToggleGIMBAL.Value == 1 && yawToggleOSD.Value == 0
                theta0 = attSource.gimbal.yaw;
            elseif yawToggleGIMBAL.Value == 0 && yawToggleOSD.Value == 1
                theta0 = attSource.aircraft.yaw;
            else
                error("choose yaw: 'GIMBAL' or 'OSD'!")
            end

            % lambda <--> - pitch
            if pitchToggleGIMBAL.Value == 1 && pitchToggleOSD.Value == 0
                lambda0 = - attSource.gimbal.pitch;
            elseif pitchToggleGIMBAL.Value == 0 && pitchToggleOSD.Value == 1
                lambda0 = - attSource.aircraft.pitch;
            else
                error("choose pitch: 'GIMBAL' or 'OSD'!")
            end

            % phi    <-->   roll
            if rollToggleGIMBAL.Value == 1 && rollToggleOSD.Value == 0
                phi0 = - attSource.gimbal.roll;
            elseif rollToggleGIMBAL.Value == 0 && rollToggleOSD.Value == 1
                phi0 = - attSource.aircraft.roll;
            else
                error("choose roll: 'GIMBAL' or 'OSD'!")
            end


            if abs(lambda0)<45
                fprintf('[yaw/pitch/roll/alt] = [ %.2f %.2f %.2f %.2f ]\n',corr);
                theta=theta0-corr(1);
                lambda=lambda0+corr(2);
                phi=phi0+corr(3);
                H=H0+corr(4);
            else
                % fprintf('YPR inp q: %f %f %f\n',[theta0 lambda0 phi0]);

                [theta,lambda,phi]=rotate3(theta0,lambda0,phi0,-corr(1),corr(2),corr(3),0);% the last parameter is alpha, the weighting for the degree to which the angle changes are done first
                % fprintf('[left/up/roll/alt] = [ %.2f %.2f %.2f %.2f ] [yaw/pitch/roll/alt] = [ %.2f %.2f %.2f %.2f ]\n',...
                %     corr,theta-theta0,lambda-lambda0,phi-phi0,H-H0);
                H=H0+corr(4);
            end

            oldcorr=corr;
            oldtoggle = toggle;

            delete(hg);
            if exist('hc','var'), delete(hc);delete(ht); end
            if exist('hR','var'), delete(hR); end
            if exist('hS','var'), delete(hS); delete(hSC);end
            if exist('hD','var'), delete(hD); delete(hDC);end

        else  % No stops
            ok='y';
        end


    end

end

%%
nUnknown = 0;
if dhfov   > 0.0; nUnknown = nUnknown+1; end
if dlambda > 0.0; nUnknown = nUnknown+1; end
if dphi    > 0.0; nUnknown = nUnknown+1; end
if dH      > 0.0; nUnknown = nUnknown+1; end
if dtheta  > 0.0; nUnknown = nUnknown+1; end

if nUnknown > ncontrol
    fprintf('\n')
    fprintf('WARNING: \n');
    fprintf('         The number of GCPs is < number of unknown parameters.\n');
    fprintf('         Program stopped.\n');
    return
end

% Check for consistencies between number of GCPs and order of the polynomial
% correction
%ngcp = length(i_gcp);
if ncontrol < 3*polyOrder
    fprintf('\n')
    fprintf('WARNING: \n');
    fprintf('         The number of GCPs is inconsistent with the order of the polynomial correction.\n');
    fprintf('         ngcp should be >= 3*polyOrder.\n');
    fprintf('         Polynomial correction will not be applied.\n');
    polyCorrection = false;
else
    polyCorrection = true;
end

if polyOrder == 0
    polyCorrection = false;
end

%% This is the main section for the minimization algorithm

if nUnknown > 0

    % Options for the fminsearch function. May be needed for some particular
    % problems but in general the default values should work fine.
    %options=optimset('MaxFunEvals',100000,'MaxIter',100000);
    %options=optimset('MaxFunEvals',100000,'MaxIter',100000,'TolX',1.d-12,'TolFun',1.d-12);
    options = [];

    % Only feed the minimization algorithm with the GCPs. xp and yp are the
    % image coordinate of these GCPs.
    xp = i_gcp(1:ncontrol);
    yp = j_gcp(1:ncontrol);

    % This is the call to the minimization
    bestErrGeoFit = Inf;

    % Save inital guesses in new variables.
    hfovGuess   = len.hfov;
    lambdaGuess = lambda;
    phiGuess    = phi;
    HGuess      = H;
    thetaGuess  = theta;

    for iMinimize = 1:nMinimize

        % First guesses for the minimization
        if iMinimize == 1
            hfov0   = lens.hfov;
            lambda0 = lambda;
            phi0    = phi;
            H0      = H;
            theta0  = theta;
        else
            % Select randomly new initial guesses within the specified
            % uncertainties.
            hfov0   = (hfovGuess - dhfov)     + 2*dhfov*rand(1);
            lambda0 = (lambdaGuess - dlambda) + 2*dlambda*rand(1);
            phi0    = (phiGuess - dphi)       + 2*dphi*rand(1);
            H0      = (HGuess - dH)           + 2*dH*rand(1);
            theta0  = (thetaGuess - dtheta)   + 2*dtheta*rand(1);
        end

        % Create vector cv0 for the initial guesses.
        i = 0;
        if dhfov > 0.0
            i = i+1;
            cv0(i) = hfov0;
            theOrder(i) = 1;
        end
        if dlambda > 0.0
            i = i + 1;
            cv0(i) = lambda0;
            theOrder(i) = 2;
        end
        if dphi > 0.0
            i = i + 1;
            cv0(i) = phi0;
            theOrder(i) = 3;
        end
        if dH > 0.0
            i = i + 1;
            cv0(i) = H0;
            theOrder(i) = 4;
        end
        if dtheta > 0.0
            i = i + 1;
            cv0(i) = theta0;
            theOrder(i) = 5;
        end

        [cv, errGeoFit] = fminsearch('g_error_geofit',cv0,options, ...
            imgWidth,imgHeight,xp,yp,lens.ic,lens.jc,...
            hfov,lambda,phi,H,theta,...
            hfov0,lambda0,phi0,H0,theta0,...
            hfovGuess,lambdaGuess,phiGuess,HGuess,thetaGuess,...
            dhfov,dlambda,dphi,dH,dtheta,...
            LON0,LAT0,...
            i_gcp(1:ncontrol),j_gcp(1:ncontrol),...
            lon_gcp0(1:ncontrol),lat_gcp0(1:ncontrol),...
            h_gcp(1:ncontrol),...
            theOrder,frameRef);

        if errGeoFit < bestErrGeoFit
            bestErrGeoFit = errGeoFit;
            cvBest = cv;
        end

        fprintf('\n')
        fprintf('  Iteration # (iMinimize):                       %i\n',iMinimize);
        fprintf('  Max. number of iteration (nMinimize):          %i\n',nMinimize);
        fprintf('  RSM error (m)  for this iteration (errGeoFit): %f\n',errGeoFit);
        fprintf('  Best RSM error (m) so far (bestErrGeoFit):     %f\n',bestErrGeoFit);

    end

    for i = 1:length(theOrder)
        if theOrder(i) == 1; hfov   = cvBest(i); end
        if theOrder(i) == 2; lambda = cvBest(i); end
        if theOrder(i) == 3; phi    = cvBest(i); end
        if theOrder(i) == 4; H      = cvBest(i); end
        if theOrder(i) == 5; theta  = cvBest(i); end
    end

    fprintf('\n')
    fprintf('PARAMETERS AFTER GEOMETRICAL RECTIFICATION \n')
    fprintf('  Field of view (hfov):            %f\n',hfov)
    fprintf('  Dip angle (lambda):              %f\n',lambda)
    fprintf('  Tilt angle (phi):                %f\n',phi)
    fprintf('  Camera altitude (H):             %f\n',H)
    fprintf('  View angle from North (theta):   %f\n',theta)
    fprintf('\n')

    if length(theOrder) > 1
        fprintf('The rms error after geometrical correction (m): %f\n',bestErrGeoFit);
    end
else
    errGeoFit=0;
end

% Project the GCP that have elevation.
[lon_gcp,lat_gcp] = g_proj_GCP(LON0,LAT0,H,lon_gcp0(1:ncontrol),lat_gcp0(1:ncontrol),h_gcp(1:ncontrol),frameRef);

%%

if opts.isMapping

    % Now construct the matrices LON and LAT for the entire image using the
    % camera parameters found by minimization just above.

    % Camera coordinate of all pixels
    xp = repmat([1:imgWidth],imgHeight,1);
    yp = repmat([1:imgHeight]',1,imgWidth);

    % Transform camera coordinate to ground coordinate.
    [LON LAT] = g_pix2ll(xp,yp,imgWidth,imgHeight,...
        lambda,phi,theta,H,LON0,LAT0,frameRef,lens);


    figure(get(gcf,'Number')+1);
    clf;
    % Temporary figure
    plot(LON(1:3:end,1:3:end),LAT(1:3:end,1:3:end),'.b');
    line(lon_gcp0(1:ncontrol),lat_gcp0(1:ncontrol),'color','r','marker','o');
    line(lon_gcp0(ncontrol+1:ngcp),lat_gcp0(ncontrol+1:ngcp),'color','r');
    if exist('AxisLimits','var') && (length(AxisLimits)==4)
        line(AxisLimits([1 2 2 1 1]),AxisLimits([3 3 4 4 3]),'color','k','linewi',2,'linest','--');
    end
    drawnow;


    %% Apply polynomial correction if requested.
    if polyCorrection == true
        [LON LAT errPolyFit] = g_poly(LON,LAT,LON0,LAT0,i_gcp,j_gcp,lon_gcp,lat_gcp,polyOrder,frameRef,lens);
        fprintf('The rms error after polynomial stretching (m):  %f\n',errPolyFit)
    else
        errPolyFit = NaN;
    end
    %%

    % Compute the effective resolution
    Delta = g_res(LON, LAT, frameRef);

    fprintf('\n')
    fprintf('Saving rectification file in: %s\n',[outputDir outputFname]);

    save([outputDir outputFname],'imgDir','imgFname','frameRef',...
        'LON','LAT',...
        'LON0','LAT0',...
        'lon_gcp0','lat_gcp0',...
        'lon_gcp','lat_gcp','h_gcp',...
        'i_gcp','j_gcp','ncontrol',...
        'lens','lambda','phi','H','theta',...
        'errGeoFit','errPolyFit','Delta');


    fprintf('\n')
    fprintf('Making figure\n');

    if strcmp(frameRef,'Geodetic')
        g_viz_geodetic([outputDir outputFname],'axislimits',AxisLimits,'showtime',1);
    elseif strcmp(frameRef,'Cartesian')
        g_viz_cartesian(imgFname,outputFname);
    end

    if opts.isShipGPS
        m_line(ship_gps.lon,ship_gps.lat,'color','r');
        m_line(shiplonC,shiplatC,'color','r','marker','o');
    end

    fprintf('Saving Image as %s\n',[outputDir imgFname(1:end-4),'_grect.png']);
    print('-dpng','-r300',[outputDir imgFname(1:end-4),'_grect.png']);

end
