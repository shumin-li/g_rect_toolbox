function sl_g_rect(inputFname,image_num,nostop)
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
%                      precision.
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

imgDir=[];
outputDir=[];

%------------------------------------------------------------------
% Defaults related to mapping camera pixesl to ground points
% (can be altered in .dat file)

lens.geometry='camera.json'; % or 'thin'
lens.k=[0 0 0];  % Radial distorion (default none).
lens.p=[0 0];    % Tangential distortions (default none)
lens.ic=0;       % Principle point offset from center (default none)
lens.jc=0;

lens.Re= 6378135.0;   % Earth's radius (m)

% Refractive ray curvature for a standard atmosphere
% 1/5.3 for standard atmosphere lapse rate 6.5K/km
% 1/6 for a convective lapse rate of 10K/km
% 1/4.3 for an isothermal atmosphere
% 0 for no atmospheric refraction
lens.Refractedcurvatureratio=1/5.3;

%---------------------------------------------------------------------



%%
% The minimization is repeated nMinimize times where each time a random
% combination of the initial guesses is chosen within the given
% uncertainties provided by the user. This is becasue the algorithm often
% converges toward a local minimum. The repetition is used to increase chances
% that the minimum found is a true minimum within the uncertainties provided.
nMinimize = 50;

%% Read the parameter file
% Count the number of header lines before the ground control points (GCPs)
% The GCPs start right after the variable gcpData is set to true.
display('  ');
display('  Welcome to g_rect: a package for georectifying oblique images on a flat ocean');
display('  Authors: Daniel Bourgault and Rich Pawlowicz');
display('  Test version of Shumin Li');
display('  ');

if nargin==0
   inputFname = input('  Enter the name of the parameter file: ','s')
   image_num=1;
end

if isempty(inputFname)
    inputFname = 'g_rect_params.dat'; % Default value
    image_num=1;
end

%
% 0 - stop for text input
% 1 - stop for gui input
% 2 - no stop
%
if nargin<3
    nostop='text';
else
    if ~ischar(nostop)
        switch nostop
            case 0
                nostop='text';
            case 1
                nostop='gui';
            case 2
                nostop='none';
        end
    end
end


fid = fopen(inputFname);

nHeaderLine  = 0;
gcpData      = false;
AxisLimits=NaN;
GraticuleType=2;

% Read and execute each line of the parameter file until gcpData = true
% after which the GCP data appear and are read below with the 'importdata'
% function.
while gcpData == false
    l=fgetl(fid);
    while contains(l,'...')   % Line continuations
        icont=strfind(l,'...');
        l=[l(1:icont-1) fgetl(fid)];
    end
    try
       eval(l);
    catch
        error(l);
    end
    nHeaderLine = nHeaderLine + 1;
end
fclose(fid);

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
if ~exist('frameRef')
    if field == true
        frameRef = 'Geodetic';
    elseif field == false
        frameRef = 'Cartesian';
    end
end

%%

    
%% Import the GCP data at the end of the parameter file
gcp      = importdata(inputFname,' ',nHeaderLine);
if isfield('data',gcp)
    i_gcp    = gcp.data(:,1);
    j_gcp    = gcp.data(:,2);
    lon_gcp0 = gcp.data(:,3);
    lat_gcp0 = gcp.data(:,4);

    [ngcp n_column] = size(gcp.data);

    % If there are 5 columns it means that elevation are provided
    if n_column == 5
        h_gcp    = gcp.data(:,5);
    else % otherwise elevation are considered to be zero
        h_gcp(1:ngcp,1) = 0.0;
    end
    ncontrol=ngcp;
else
    lon_gcp0=[];
    lat_gcp0=[];
    i_gcp=[];
    j_gcp=[];
    ncontrol=0;
end

% If a coastline file was given - we expect the
% coast points to be in an nx2 vector 'ncst' of [long lat].

if exist('coastline')
    load(coastline);
    lon_gcp0 = [lon_gcp0; ncst(:,1)];
    lat_gcp0 = [lat_gcp0; ncst(:,2)];
    
    % Cut out points far away (crudely)
    % Earth's radius (m)
    Re   = 6378135.0;
    meterPerDegLat = 1852*60.0;
    Dhoriz2 = (2*H*Re)/meterPerDegLat.^2;
    
    irm=((lon_gcp0-LON0).^2*cosd(LAT0).^2+(lat_gcp0-LAT0).^2)>Dhoriz2;
    lon_gcp0(irm)=[];
    lat_gcp0(irm)=[];
    
    h_gcp = zeros(size(lon_gcp0));
    i_gcp = zeros(size(lon_gcp0));
    j_gcp = zeros(size(lon_gcp0));

    ngcp=length(lon_gcp0);
    
end


i_gcp    = i_gcp';
j_gcp    = j_gcp';
lon_gcp0 = lon_gcp0';
lat_gcp0 = lat_gcp0';
h_gcp    = h_gcp';


% load driftertrack data
if exist('driftertracks')
    load(driftertracks);

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
            drift(kk).lon(gd_idx) + drift(kk).lat(gd_idx)*1i, UTC-7/24);
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
        [0 0.4470 0.7410]
        [0.8500 0.3250 0.0980]
        [0.9290 0.6940 0.1250]
        [0.4940 0.1840 0.5560]
        [0.4660 0.6740 0.1880]
        [0.3010 0.7450 0.9330]
        [0.6350 0.0780 0.1840]
        };

end

% load ship GPS data

if exist('ship','var')
    ship_gps = ozi_rd(ship);
    CC = interp1(ship_gps.mtime, ship_gps.lon + ship_gps.lat*1i, UTC-7/24);
    shiplonC = real(CC);
    shiplatC = imag(CC);
end


%%
% Check if the elevation of the GCPs are not too high and above
% a certain fraction (gamma) of the camera height. If so, stop.
gamma = 0.75;
i_bad = find(h_gcp > gamma*(H+dH));
if length(i_bad) > 0
    display([' ']);
    display(['  WARNING:']);
    for i = 1:length(i_bad)
        display(['      The elevation of GCP #',num2str(i_bad(i)),' is greater than ',num2str(gamma),'*(H+dH).']);
    end
    display(['  FIX AND RERUN.']);
    return
end

% Get the image size
imgInfo   = imfinfo([imgDir imgFname]);
imgWidth  = imgInfo.Width;
imgHeight = imgInfo.Height;

if precision == 'single'
    imgWidth  = single(imgWidth);
    imgHeight = single(imgHeight);
end

%% Display information
fprintf('\n')
fprintf('  INPUT PARAMETERS\n')
fprintf('    Image filename: (imgFname):........... %s\n',imgFname)
% fprintf('    First image: (firstImgFname):......... %s\n',firstImgFname)
% fprintf('    Last image: (lastImgFname):........... %s\n',lastImgFname)
fprintf('    Output filename: (outputFname):....... %s\n',outputFname);
fprintf('    Image width (imgWidth):............... %i\n',imgWidth)
fprintf('    Image width (imgHeight):.............. %i\n',imgHeight)
fprintf('    Frame of reference:................... %s\n',frameRef)
fprintf('    Camera longitude or x coord. (LON0):.. %f\n',LON0)
fprintf('    Camera latitude or y coord. (LAT0):... %f\n',LAT0)
fprintf('    Principal point offset (ic):.......... %f\n',lens.ic)
fprintf('    Principal point offset (jc):.......... %f\n',lens.jc)
fprintf('    Field of view (hfov):................. %f\n',lens.hfov)
fprintf('    Dip angle (lambda):................... %f\n',lambda)
fprintf('    Tilt angle (phi):..................... %f\n',phi)
fprintf('    Camera altitude (H):.................. %f\n',H)
fprintf('    View angle from North (theta):........ %f\n',theta)
fprintf('    Uncertainty in hfov (dhfov):.......... %f\n',dhfov)
fprintf('    Uncertainty in dip angle (dlambda):... %f\n',dlambda)
fprintf('    Uncertainty in tilt angle (dphi):..... %f\n',dphi)
fprintf('    Uncertainty in altitude (dH):......... %f\n',dH)
fprintf('    Uncertainty in view angle (dtheta):... %f\n',dtheta)
fprintf('    Polynomial order (polyOrder):......... %i\n',polyOrder)
fprintf('    Number of GCPs (ncontrol):............ %i\n',ncontrol)
fprintf('    Number of GPs  (ngcp):................ %i\n',ngcp)
fprintf('    Precision (precision):................ %s\n',precision)
fprintf('\n')

% Display the image with GCPs;
%image(imread(imgFname));

figure(1);clf;set(gcf,'color','w');

imagesc(imread([imgDir imgFname]));
set(gca,'tickdir','out','tickdirmode','manual','plotboxaspectratiomode','auto',...
    'dataaspectratiomode','auto');
colormap(gray);
hold on

% Save originals
theta0=theta;lambda0=lambda;phi0=phi;H0=H;
dleft=0;dup=0;droll=0;dH=0;

if strcmp(nostop,'gui')
   uicontrol(gcf,'style','text','string','Left - Right',    'unit','normalized','position',[.1 .97 .15 .02]);
   yawmode  =uicontrol(gcf,'style','slider','tag','yaw',  'unit','normalized','position',[.1 .95  .15 .02],...
                     'value',0,'max',40,'min',-40,'sliderstep',[.01 .1]);

   uicontrol(gcf,'style','text','string','(pitch) Down - Up',       'unit','normalized','position',[.3 .97 .15 .02]);
   pitchmode=uicontrol(gcf,'style','slider','tag','pitch','unit','normalized','position',[.3 .95  .15 .02],...
                     'value',0,'max',20,'min',-20,'sliderstep',[.005 .05]);
   uicontrol(gcf,'style','text','string','(roll) CCW - CW',        'unit','normalized','position',[.5 .97 .15 .02]);
   rollmode =uicontrol(gcf,'style','slider','tag','roll', 'unit','normalized','position',[.5 .95  .15 .02],...
                     'value',0,'max',10,'min',-10,'sliderstep',[.005 .05]);
  uicontrol(gcf,'style','text','string','(Altitude) Lower - Higher',  'unit','normalized','position',[.7 .97 .15 .02]);
  altmode  =uicontrol(gcf,'style','slider','tag','alt',  'unit','normalized','position',[.7 .95  .15 .02],...
                     'value',0,'max',40,'min',-40,'sliderstep',[.01 .1]);
   oldcorr=[0 0 0 0];
   corr=oldcorr;
   
  sensbut=uicontrol(gcf,'style','checkbox','tag','sensitivity',  'unit','normalized','position',[.87 .95  .11 .04],...
                     'string','High Sensitivity','min',0,'max',1,'value',0,'userdata',0);
 resbut=uicontrol(gcf,'style','pushbutton','tag','reset',  'unit','normalized','position',[.92 .85  .07 .04],...
                     'string','reset','callback','set(gcbo,''userdata'',''reset'')','userdata','ok');
  donbut=uicontrol(gcf,'style','pushbutton','tag','reset',  'unit','normalized','position',[.92 .75  .07 .04],...
                     'string','SAVE','callback','set(gcbo,''userdata'',''done'')','userdata','not done');
  extbut=uicontrol(gcf,'style','pushbutton','tag','reset',  'unit','normalized','position',[.92 .65  .07 .04],...
                     'string','EXIT','callback','set(gcbo,''userdata'',''exit'')','userdata','continue');
  
                 
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


for i = 1:ncontrol
        hc(i)=plot(i_gcp(i),j_gcp(i),'r.');
        ht(i)=text(i_gcp(i),j_gcp(i),[' ',num2str(i),'(',num2str(h_gcp(i)),')'],...
            'color','r',...
            'horizontalalignment','left',...
            'fontsize',10);
end

% Show control points that have lat/longs on map
 
if exist('coastline','var')
   % Transform camera coordinate to ground coordinate.
   [xp,yp] = g_ll2pix(lon_gcp0(ncontrol+1:ngcp),lat_gcp0(ncontrol+1:ngcp),imgWidth,imgHeight,...
                     lambda,phi,theta,H,LON0,LAT0,frameRef,lens);
   hR=line(xp,yp,'color','r');
end


if exist('driftertracks')

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


% Draw the graticule
hg=g_graticule(imgWidth,imgHeight,lambda,phi,theta,...
            H,LON0,LAT0,frameRef,lens,GraticuleType);


if exist('ship','var')
   [xp,yp] = g_ll2pix(ship_gps.lon,ship_gps.lat,imgWidth,imgHeight,...
                     lambda,phi,theta,H,LON0,LAT0,frameRef,lens);
 
   hS=line(xp,yp,'color','k','marker','.');
   
   [xp,yp] = g_ll2pix(shiplonC,shiplatC,imgWidth,imgHeight,...
                     lambda,phi,theta,H,LON0,LAT0,frameRef,lens);
 
   hSC=line(xp,yp,'color','k','marker','x','markersize',10);
end   
        
        
title([ imgFname ': Ground Control Points Number (elevation in meters)'],...
        'color','r','interpreter','none');
%daspect([1 1 1]);

ylabel('Pixel')
drawnow;

if save_orig
   print('-dpng','-r300',[outputDir imgFname(1:end-4),'_GCP.png']);
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
            dH=dH+corr(4);
            H=H0+dH;
            if abs(lambda0)<45
               fprintf('[yaw/pitch/roll/alt] = [ %.2f %.2f %.2f %.2f ]\n',dleft,dup,droll,dH);
               theta=theta+corr(1);
               lambda=lambda+corr(2);
               phi=phi+corr(3);
               H=H+corr(4);
            else
              [theta,lambda,phi]=rotate3(theta0,lambda0,phi0,dleft,dup,droll,0);%cosd(lambda0));
              fprintf('[left/up/roll/alt] = [ %.2f %.2f %.2f %.2f ] [yaw/pitch/roll/alt] = [ %.2f %.2f %.2f %.2f ]\n',...
                      dleft,dup,droll,dH,theta-theta0,lambda-lambda0,phi-phi0,H-H0);
              H=H+corr(4);
            end          
        elseif length(corr)==1  % reset values
            dleft=0;
            dup=0;
            droll=0;
            dH=0;
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
  
    while all(corr==oldcorr)
       corr=[get(yawmode,'value') get(pitchmode,'value') get(rollmode,'value') get(altmode,'value')];
       if strcmp(get(resbut,'userdata'),'reset')
          set(yawmode,'value',0);
          set(pitchmode,'value',0);
          set(rollmode,'value',0); 
          set(altmode,'value',0);
          corr=[ 0 0 0 0];
          set(resbut,'userdata','ok');
       end
       if strcmp(get(donbut,'userdata'),'done')
         ok='y';
         fprintf('Reset all corrections back to zero\n');
         oldcorr=[Inf Inf Inf Inf];
       end
       if strcmp(get(extbut,'userdata'),'exit')
          fprintf('Exit without saving\n');
          return
       end
       if get(sensbut,'value')==1  & get(sensbut,'userdata')==0
           set(yawmode,'sliderstep',[.001 .01]);
           set(pitchmode,'sliderstep',[.0005 .005]);
           set(rollmode,'sliderstep',[.0005 .005]);
           set(altmode,'sliderstep',[.001 .01]);
           set(sensbut,'userdata',1);
       elseif get(sensbut,'value')==0  & get(sensbut,'userdata')==1
            set(yawmode,'sliderstep',[.01 .1]);
           set(pitchmode,'sliderstep',[.005 .05]);
           set(rollmode,'sliderstep',[.005 .05]);
           set(altmode,'sliderstep',[.01 .1]);
           set(sensbut,'userdata',0);
       end
       pause(.05)
    end
    if abs(lambda0)<45
       fprintf('[yaw/pitch/roll/alt] = [ %.2f %.2f %.2f %.2f ]\n',corr);
       theta=theta0-corr(1);
       lambda=lambda0+corr(2);
       phi=phi0+corr(3);
       H=H0+corr(4);
    else
       % fprintf('YPR inp q: %f %f %f\n',[theta0 lambda0 phi0]);

       [theta,lambda,phi]=rotate3(theta0,lambda0,phi0,-corr(1),corr(2),corr(3),0);%cosd(lambda0));
       fprintf('[left/up/roll/alt] = [ %.2f %.2f %.2f %.2f ] [yaw/pitch/roll/alt] = [ %.2f %.2f %.2f %.2f ]\n',...
           corr,theta-theta0,lambda-lambda0,phi-phi0,H-H0);
        H=H0+corr(4);
    end
    oldcorr=corr;

    delete(hg);
    if exist('hc')
       delete(hc);delete(ht);
    end
    if exist('hR'), delete(hR); end
    if exist('hS'), delete(hS); delete(hSC);end
    if exist('hD'), delete(hD); delete(hDC);end
   
else  % No stops
    ok='y';
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
                 'errGeoFit','errPolyFit',...
                 'precision','Delta');


fprintf('\n')
fprintf('Making figure\n');

if strcmp(frameRef,'Geodetic')
    g_viz_geodetic([outputDir outputFname],'axislimits',AxisLimits,'showtime',1);
elseif strcmp(frameRef,'Cartesian')
    g_viz_cartesian(imgFname,outputFname);
end

if exist('ship','var')
    m_line(ship_gps.lon,ship_gps.lat,'color','r');
    m_line(shiplonC,shiplatC,'color','r','marker','o');
end

fprintf('Saving Image as %s\n',[outputDir imgFname(1:end-4),'_grect.png']);
print('-dpng','-r300',[outputDir imgFname(1:end-4),'_grect.png']);
