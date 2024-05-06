function g_viz_cartesian(imgFname,rectFile);

figure

% Set some plotting parameters
ms = 10;  % Marker Size
fs = 10;  % Font size
lw = 2;  % Line width

load(rectFile);

% Determine the region to plot, delimited by the GCP and the camera
% position. Add a factor (fac) all around
fac = 0.1;
lon_min = min([lon_gcp,LON0]);
lon_max = max([lon_gcp,LON0]);
lat_min = min([lat_gcp,LAT0]);
lat_max = max([lat_gcp,LAT0]);

lon_min = lon_min - fac*abs(lon_max - lon_min);
lon_max = lon_max + fac*abs(lon_max - lon_min);
lat_min = lat_min - fac*abs(lat_max - lat_min);
lat_max = lat_max + fac*abs(lat_max - lat_min);

rgb0 = double(imread(imgFname))/255;

[mm nn pp] = size(rgb0);
if pp == 3
  int = (rgb0(:,:,1)+rgb0(:,:,2)+rgb0(:,:,3))/3; 
else
  int = rgb0;     
end
clear rgb0;
int = int';

%hold on;

colormap(gray);
pcolor(LON,LAT,int);
shading('flat');

hold;

plot(LON0,LAT0,'kx','markersize',ms,'linewidth',lw);  % Camera location

%% Plot GCPs and ICPs.
for n = 1:length(i_gcp)
    
    % Plot the original GCPs that may have elevations
    plot(lon_gcp0(n),lat_gcp0(n),'ko','markersize',ms,'linewidth',lw);
    
    % Plot the projected GCPs that are actually used for the minimization
    plot(lon_gcp(n),lat_gcp(n),'bo','markersize',ms,'linewidth',lw);
    
    % Plot the Image Control Points once georectified
    plot(LON(i_gcp(n),j_gcp(n)),LAT(i_gcp(n),j_gcp(n)),'rx','MarkerSize',ms,'linewidth',lw);

end

xlabel('x (m)');
ylabel('y (m)');
axis([lon_min lon_max lat_min lat_max]);
daspect([1 1 1]);