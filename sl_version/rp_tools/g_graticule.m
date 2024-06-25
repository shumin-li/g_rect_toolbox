function [handles] = g_graticule(imgWidth,imgHeight,...
                              lambda,phi,theta,H,LON0,LAT0,frameRef,lens,grat_type)
% G_Graticule Draws a graticule
% input: 
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

if ~exist('grat_type')
   grat_type=3;
end


% Earth's radius (m)
Re   = 6378135.0;

% Transformation factors for local cartesian coordinate
meterPerDegLat = 1852*60.0;
meterPerDegLon = meterPerDegLat*cosd(LAT0);

% Image aspect ratio.
aspectRatio = imgWidth/imgHeight;

% Image origin
x_c = imgWidth/2;
y_c = imgHeight/2;


fx   = (imgWidth/2)/tand(lens.hfov/2);
vfov = 2*atand(tand(lens.hfov/2)/aspectRatio);
fy   = (imgHeight/2)/tand(vfov/2);

% Add lines every few km

ranges=[20 50 100 200 500 1000 2000 5000];
rlabels={'20m','50m','100m','200m','500m','1000m','2000m','5000m'};

switch grat_type
    case 1  % Range/bearing
        Xhoriz = sind(theta+[0:5:360]')*ranges;  % Make a circle al around our source
        Yhoriz = cosd(theta+[0:5:360]')*ranges;
    case 2  % East/North
        [Xhoriz,Yhoriz]=meshgrid([fliplr(-ranges) 0 ranges],[fliplr(-ranges) 0 ranges]);
    case 3  % Grid in direction being faced
        [Xhoriz,Yhoriz]=meshgrid([fliplr(-ranges) 0 ranges],[ranges]);
        zz=(Xhoriz+1i*Yhoriz)*exp(-1i*theta*pi/180);
        Xhoriz=real(zz);
        Yhoriz=imag(zz);
        
end


Hlat=Yhoriz/meterPerDegLat+LAT0;
Hlon=Xhoriz/meterPerDegLon+LON0;
  
[chj,chi]=g_ll2pix(Hlon,Hlat,imgWidth,imgHeight,...
                   lambda,phi,theta,H,LON0,LAT0,frameRef,lens);

gridcol=[.8 .8 .8];
                        
switch grat_type
    case 1
        h1=line(chj,chi,'color',gridcol,'linest',':','linewi',.5); % Range lines
        h2=line(chj',chi','color',gridcol,'linest',':','linewi',.5); % Angle lines
        h3=text(chj(2,:),chi(2,:),rlabels,...
            'vertical','bottom','color',gridcol); 
        hgrid=[h1;h2;h3];
    case 2
        h1=line(chj,chi,'color',gridcol,'linest',':','linewi',.5); % East lines
        h2=line(chj',chi','color',gridcol,'linest','--','linewi',.5); % North lines
        hgrid=[h1;h2];
    case 3
        h1=line(chj,chi,'color',gridcol,'linest',':','linewi',.5); % East lines
        h2=line(chj',chi','color',gridcol,'linest','--','linewi',.5); % North lines
        h3=text(chj(:,length(ranges)+1),chi(:,length(ranges)+1),rlabels,...
            'vertical','bottom','color',gridcol); 
        h4=text(chj(length(ranges)/2,length(ranges)+2:end),chi(length(ranges)/2,length(ranges)+2:end),rlabels,...
            'vertical','bottom','color',gridcol,'rotation',-90); 
        h5=text(chj(length(ranges)/2,1:length(ranges)),chi(length(ranges)/2,1:length(ranges)),fliplr(rlabels),...
            'vertical','bottom','color',gridcol,'rotation',90); 
        hgrid=[h1;h2;h3;h4;h5];
end


% Add horizon line
D2horiz=sqrt(2*Re*H);   % Distance to horizon
Xhoriz=D2horiz*cosd([0:2:358]);  % Make a circle al around our source
Yhoriz=D2horiz*sind([0:2:358]);
Hlat=Yhoriz/meterPerDegLat+LAT0;
Hlon=Xhoriz/meterPerDegLon+LON0;
  
[chj,chi]=g_ll2pix(Hlon,Hlat,imgWidth,imgHeight,...
                   lambda,phi,theta,H,LON0,LAT0,frameRef,lens);
                          
h8=line(chj,chi,'color','c','linest','--','linewi',2);
 

% Compute the vertical angle of view (vfov) given the horizontal angle 
% of view (hfov) and the image aspect ratio. Then calculate the focal 
% length (fx, fy).
% In principle, the horizontal and vertical focal lengths are identical.
% However these may slighty differ from cameras. The calculation done here
% provides identical focal length.

ii=isfinite(chj) & isfinite(chi);
if any(ii)
   hcy=interp1(chj(ii),chi(ii),x_c);
   if isfinite(hcy) && hcy>0 && hcy<imgHeight
       y_c=hcy;
   end
end



 dx=fx*tand(-10:10);  %Horizontal angle extent (also change in text commands just below)
 dy=fy*tand(-4:4);   %Vertical angle extent
 % Draw vertical lines
 h1=line(x_c+[1;1]*dx,y_c+[-1;1]*[10 5 5 5 5 10 5 5 5 5 40 5 5 5 5 10 5 5 5 5 10]/40*dy(end),'color','w'); 
 % Draw horizontal lines
 h2=line(x_c+[-1;1]*[10 5 10 5 100 5 10 5 10]/100*dx(end),y_c+[1;1]*dy,'color','w');
 
 % Label horizontal and vertical
 h3=text(x_c+dx(1),y_c,'+10^o ','color','w','horiz','right','fontsize',14,'fontweight','bold');
 h4=text(x_c,y_c+dy(1),'+4^o','color','w','horiz','center','vertical','bottom','fontsize',14,'fontweight','bold');
 
 % Tilt angle lines
 h5=line(x_c+ cosd(5)*dx([1 end]),y_c+ sind(5)*dx([1 end]),'color','w');
 h6=line(x_c+cosd(-5)*dx([1 end]),y_c+sind(-5)*dx([1 end]),'color','w','linest','--');
 % ...and label one of them
 h7=text(x_c+cosd(5)*dx(end),y_c+sind(5)*dx(end),' +5^o','color','w','fontsize',14,'fontweight','bold');
 
 handles=[hgrid;h1;h2;h3;h4;h5;h6;h7;h8];
  