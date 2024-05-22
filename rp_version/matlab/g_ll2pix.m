function [xp,yp] = g_ll2pix(LON,LAT,imgWidth,imgHeight,...
                            lambda,phi,theta,H,LON0,LAT0,frameRef,lens)
% G_LL2PIX Converts ground to pixel coordinates
%
% input: 
%        LAT,LON: Ground coordinates
%        imgWidth:   Number of horizontal pixel of the image
%        imgHeight:  Number of vertical pixel of the image
%        ic, jc:     The number of pixel off center for the principal point
%                    (generally both set to 0)
%        hfov:       Horizontal field of view
%        lambda:     Dip angle below horizontal (straight down = 90, horizontal = 0)
%        phi:        Tilt angle clockwise around the principal axis
%        theta:      View angle clockwise from North (e.g. East = 90)
%        H:          Camera altitude (m) above surface of interest.
%        LON0, LAT0: Camera geodetic coordinates or cartesian coordinates
%
% output: 
%        xp, yp:     The image coordinate
%
% Authors:
%
% R. Pawlowicz 2002, University of British Columbia
%   Reference: Pawlowicz, R. (2003) Quantitative visualization of 
%                 geophysical flows using low-cost oblique digital 
%                 time-lapse imaging, IEEE Journal of Oceanic Engineering
%                 28 (4), 699-710.
%
% D. Bourgault 2012 - Naming convention slightly modified to match naming
%                     convention used in other part of the g_rect package.
%
%

% Earth's radius (m)
if isfield(lens,'Re')
   Re   = lens.Re;
else
   Re= 6378135.0;   % Earth's radius (m)
end

% Refractive ray curvature for a standard atmosphere
if isfield(lens,'Refractedcurvatureratio')
   Redr=lens.Refractedcurvatureratio;
else
   Redr=1/5.3;
end

% Transformation factors for local cartesian coordinate
meterPerDegLat = 1852*60.0;
meterPerDegLon = meterPerDegLat*cosd(LAT0);

% Image aspect ratio.
aspectRatio = imgWidth/imgHeight;

[n,m] = size(LON);

% Convert coordinates to distances using locally cartesian assumption

if strcmp(frameRef,'Geodetic') == true
    x_w=meterPerDegLon*(LON-LON0);
    z_w=meterPerDegLat*(LAT-LAT0);
elseif strcmp(frameRef,'Cartesian') == true
    x_w = LON-LON0;
    z_w = LAT-LAT0;
end
y_w=repmat(H,size(x_w));

% Spherical earth corrections
Dsph2    = (x_w.^2 + z_w.^2);
Dhoriz2 = (2*H*Re);  % Distance to spherical horizon

 
% This includes a correction for Refraction
s2f=1+Dsph2/Dhoriz2*(1-Redr);
s2f(s2f>2.1)=NaN;  % points past horizon

%fac             = (4*Dfl2/Dhoriz2);
%fac(fac > 1.1) = NaN;     % Points past horizon
%s2f             = 2*(1 - sqrt( 1 - fac )) ./ fac;

x_w = x_w./s2f;
z_w = z_w./s2f;

% The rotations are performed clockwise, first around the z-axis (rot), 
% then around the already once rotated x-axis (dip) and finally around the 
% twice rotated y-axis (tilt);

% Tilt angle-note sign is ngative of coordinate system for
% historical reasons.
R_phiT =  [ cosd(-phi),  sind( -phi), 0;
           -sind(-phi),  cosd( -phi), 0;
	               0,            0, 1];

% Dip angle
R_lambdaT = [ 1,          0,        0;
	         0,  cosd(-lambda),  sind(-lambda);
	         0, -sind(-lambda),  cosd(-lambda)];

% View from North
R_thetaT = [ cosd( theta), 0, -sind( theta);
	                   0, 1,           0;
	        sind( theta), 0,  cosd( theta)];


M=R_thetaT*[x_w(:)';y_w(:)';z_w(:)'];
xrot=M(1,:);
yrot=M(2,:);
zrot=M(3,:);

% First, blank out stuff behind camera, also stuff
% that is very far away (it just confuses things)
% (unless we are looking down, in which case we need
%  the negative zrot points)
if lambda<45
    kk=(zrot<=0 | zrot>=40e3 | abs(xrot)>15e3);
    xrot(kk)=NaN;
    yrot(kk)=NaN;
    zrot(kk)=NaN;
end

%apply dip

p=R_phiT*R_lambdaT*[xrot;yrot;zrot];

% normalization (making z==1 for numerical reasons)

x = reshape(p(1,:)./p(3,:),n,m);
y = reshape(p(2,:)./p(3,:),n,m);


% NaN out stuff too far outside image

% Image origin
x_c = imgWidth/2;
y_c = imgHeight/2;

% Compute the vertical angle of view (vfov) given the horizontal angle 
% of view (hfov) and the image aspect ratio. Then calculate the focal 
% length (fx, fy).
% In principle, the horizontal and vertical focal lengths are identical.
% However these may slighty differ from cameras. The calculation done here
% provides identical focal length.

fx   = (imgWidth/2)/tand(lens.hfov/2);
vfov = 2*atand(tand(lens.hfov/2)/aspectRatio);
fy   = (imgHeight/2)/tand(vfov/2);

kk=abs(x)>imgWidth/fx/1.5 | abs(y)>imgHeight/fy/1.5;
x(kk)=NaN;
y(kk)=NaN;

%% DNG spec - 

switch lens.geometry
    case 'dng'
        cx=1+lens.jc*(imgWidth-1);
        cy=1+lens.ic*(imgHeight-1);
        mx=max(abs(1-cx),abs(imgWidth-cx));
        my=max(abs(1-cy),abs(imgHeigth-cy));
        m = sqrt(mx^2+my^2);
        dx=(x-cx)/m;
        dy=(y-cy)/m;
        r2=dx.^2+dy.^2;
        kfac=len.k(1)+lens.k(2)*r2+lens.k(3)*r2.^2+lens.k(4)*r2.^3; % Starts at k0
        Dxr=kfac*dx;
        Dyr=kfac*dy;
        Dxt=2*lens.p(1)*dx*dy + lens.p2(2)*(r2+2*dx.^2);
        Dyt=2*lens.p(2)*dx*dy + lens.p2(1)*(r2+2*dy.^2);
        xp = cx + m*(Dxr + Dxt);
        yp = cy + m*(Dyr + Dyt);

    case 'camera.json'
        
        % Convert to normalized units (-.5 to 0.5 in x)
        x=x*fx/imgWidth;
        y=y*fy/imgWidth;

        % Correct for barrel/pincushion in normalized units.
        if lens.k(1)~=0
           r2=x.^2+y.^2;
           kfac=lens.k(1)+lens.k(2)*r2+lens.k(3)*r2.^2+lens.k(4)*r2.^3;
           xd = kfac.*x+2*lens.p(2)*x.*y + lens.p(1)*(r2+2*x.^2);
           yd = kfac.*y+2*lens.p(1)*x.*y + lens.p(2)*(r2+2*y.^2);
        else
           xd = x;
           yd = y;
        end

        xp=(xd+lens.jc)*imgWidth+x_c;
        yp=(yd+lens.ic)*imgWidth+y_c;
    case 'none'
         % Multiply by the focal length
         x_p = x*fx;
         y_p = y*fy;
       
         % Add the principal point
         xp = x_p + x_c + (lens.jc)*fx;
         yp = y_p + y_c - (lens.ic)*fy; 
  

    otherwise
        error('Unknown lens geometry');
end

       
        
       
