function sl_get_meta(imgDir, imgFname)


%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% INPUT/OUTPUT INFORMATION
%    imgFname:      This is the only image that will actually be treated
%
%    firstImgFname: This is really just a comment not actually used by the algorithm 
%                   that indicates the name of the first image of a sequence to which 
%                   the georectification of image 'imgFname' could also be applied to.
%
%    lastImgFname:  Same as 'firstImgFname'but for the last sequential image.
%
%    outputFname:   This is the name of the output fil that will contain, among other 
%                   variables, the matrices LON and LAT that will give the ground 
%                   coordinate of every pixel of the image that are below the horizon.
%
imgDir = '/Users/shuminli/Documents/research/Drones/photo_test/mini3_pro/UBC/23Feb02_UBC/flight_2/';
imgFname      =  {'DJI_0393.JPG','DJI_0419.JPG','DJI_0466.JPG',...
                  'DJI_0468.JPG'};
imgFname = imgFname{image_num};

firstImgFname =  'IMG_6614.JPG';
lastImgFname  =  'IMG_6614.JPG';

outputDir= '/Users/shuminli/Documents/research/Drones/rich/sl_proc/';
outputFname   =  {'DJI_0393_grect.mat','DJI_0419_grect.mat','DJI_0466_grect.mat',...
                  'DJI_0468_grect.mat'};
outputFname = outputFname{image_num};


%% FRAME OF REFERENCE
%    The frame of reference could be either 'Geodetic' or 'Cartesian'.
%    If 'Geodetic' is used, longitudes and latitudes are expected for positions.
%    If 'Cartesian' is used, x-y positions are expected (in m)
%
frameRef = 'Geodetic';
GraticuleType = 3;

%% CAMERA POSITION 
%    Set the longitude and latitude for ‘Geodetic’ frame of reference 
%    Set the x-y coordinate for ‘Cartesian’ frame of reference 
%    H:      Camera altitude relative to the local water level (m)
%
LON0 = [-123.270232805556 -123.281015833333 -123.269191666667 -123.264622777778];                 
LAT0 = [49.2599081944444  49.2557966666667 49.2499893055556 49.2569965833333];             
H      = [102 101 105 105 ];

LON0=LON0(image_num);LAT0=LAT0(image_num);H=H(image_num);


%% CAMERA ORIENTATION
%    These are either the initial guesses for the uncertain parameters, i.e. those
%    with an uncertainty > 0 (see next section) or the exact values for the parameters
%    with an uncertainty set to 0 below.
%
%    lambda: Dip angle (degree) below horizontal (e.g. straight down = 90, horizontal = 0)
%            (-pitch)
%    phi:    Tilt angle (degree), generally close to 0 (positive is CCW)
%            (roll)
%    theta:  View angle (degree) clockwise from North (e.g. straight East = 90)
%            (yaw)

lambda =  [ 23.   25.3      26.   24.1];  
phi    =  [    0.3  -.2    -.1     0.1 ];  
theta  =  [-113.4  16.3    -10.6   27.1]; 

lambda = lambda(image_num);phi = phi(image_num);theta = theta(image_num);


%% LENS PARAMETERS
%    Offset from center of the principal point (generally zero)
%    hfov:   Field of view of the camera (degree)
%
%ic = 0;
%jc = 0;
%hfov   =  73.74;

ic = --0.00388919027283902;   % y direction
jc = -0.001055072144606377;  % x direction
 

% Get camera.json parameters
lens.geometry='camera.json';
lens.hfov = 2*atand(tand(73.74/2)*.935);
lens.k=[1  0.12972187263071938 -0.18856367135787402 0.12972187263071938];  % From Camera.json
lens.p=[0.0017523636559856292 -7.148567323936884e-06];



%% UNCERTAINTIES 
%    Set here the uncertainties of the associated camera parameters. 
%    Set the uncertainty to 0 for fixed parameters.
%
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
polyOrder = 0;

%% PRECISION
%    To save memory, calculations can be done in single precision. 
%    For higher precision set the variable 'precision' to 'double';
%
precision = 'double';

%% AXIS LIMITS
%  Option limits for final map (comment this out until your angles are
%  close to correct)
%AxisLimits=[-72-28.5/60 -72-24.8/60 -42-23.45/60 -42-21.55/60];
%if image_num==3, AxisLimits=[-72-25.45/60 -72-25.1/60 -42-23./60 -42-22.75/60]; end
%f image_num==5, AxisLimits=[-72-25.05/60 -72-24.95/60 -42-22.93/60 -42-22.85/60]; end
%if image_num==6, AxisLimits=[-72-25.4/60 -72-25.10/60 -42-23./60 -42-22.8/60]; end
%if image_num==7, AxisLimits=[-72-26.2/60 -72-25.5/60 -42-22.6/60 -42-22.1/60]; end
%if image_num==8 || image_num==9 || image_num==10, AxisLimits=[-72-25.5/60 -72-24.7/60 -42-22.9/60 -42-22.2/60]; end



% COASTLINE (or other GROUND POINTS)
% If you have a coastline for the area it is useful to map it
%
coastline='/Users/shuminli/Nextcloud/data/others/PNW.mat';
save_orig=false;

%% GROUND CONTROL POINTS (GCPs). 
%    The GCP data must come right after the 'gcpData = true' instruction 
%    Column 1: horizontal image index of GCPs
%    Column 2: vertical image index of GCPs
%    Column 3: longitude (Geodetic) or x-position (Cartesian) of GCPs
%    Column 4: latitude (Geodetic) or y-position (Cartesian) of GCPs
%    Column 5: elevation (in m) of GCPs (optional)

gcpData = true;
% 360  829  -70.561367  47.303783  0
%  54  719  -70.54500   47.335     0
%  99  661  -70.505     47.375     0
% 452  641  -70.435     47.389     0
% 429  633  -70.418     47.408     0
% 816  644  -70.393     47.368     0




end