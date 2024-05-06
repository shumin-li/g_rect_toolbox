function [h_figure,h_image,h_datetext] = g_viz_geodetic(rectFile,varargin)
%G_VIZ_FIELD Generates a map with a georectified image
%       G_VIZ_FIELD Generates a map with the georectified image in imgFname
%                   Converts in grayscale if needed.
%       Inputs:
%           rectFile,   .mat file created by g_rect
%       Parameters (name, value)
%           showTime,   Default 0, if 1, displays the timestamp of the
%                       image in the figure's title
%           showLand,   Default 0, if 'f' or 'h', displays the land contour
%                       with m_gshhs_f or m_gshhs_h, if a name, uses the
%                       filename with m_usercoast.
%           landcolor,  Default [241 235 144]/255, Color of the land on the
%                       map
%           axislimits  Overrides the auto-choice for axis limits
%                       (4 element vector [minLong,maxLong,minLat,maxLat).
%           raw         Default 0 for an m_map map, if 1 just draws on
%                       'raw' axes (useful if you want to plot_google_map()
%                       afterwards underneath).
%
%       Outputs:
%           h_figure, h_pcolor and h_datetext are the handles to the
%               corresponding objects in the figure, for use in g_viz_anim
%

% Changes
%    Jan/23 - removed imGname from inputs, made this work
%             for cell inputs to make mosaics, added Nval, axislimits
%             options.


% Set some plotting parameters
ms = 10;  % Marker Size
fs = 10;  % Font size
lw = 2;  % Line width

% Option
show_time = 0;
show_land = 0;
land_color = [241 235 144]/255;
Nval=2000;
AxisLimits=NaN;
raw=0;
feather=200;  

% Make a single input into a cell for compatability.
% Default no feathering for a single image.
if ~iscell(rectFile)
    rectFile={rectFile};
end
if length(rectFile)==1
    feather=0;
end

if length(varargin) > 1
    for i=1:2:length(varargin)
        switch lower(varargin{i})
            case 'showtime'
                show_time = varargin{i+1};
            case 'showland'
                show_land = varargin{i+1};
            case 'landcolor'
                land_color = varargin{i+1};
            case 'nval'
                Nval = varargin{i+1};
            case 'axislimits'
                AxisLimits=varargin{i+1};
            case 'raw'
                raw=varargin{i+1};
        end
    end
end



clf;drawnow;
set(gcf,'color','w');

for ii=1:length(rectFile)
    % Load the georectification file
    fprintf('Loading %s\n',rectFile{ii});
    load(rectFile{ii});

    if length(AxisLimits)==4
        lon_min = AxisLimits(1);
        lon_max = AxisLimits(2);
        lat_min = AxisLimits(3);
        lat_max = AxisLimits(4);
    else
        % Determine the region to plot, delimited by the GCP and the camera
        % position. Add a factor (fac) all around
        fac = 0.1;
        ip=isfinite(LON) &isfinite(LAT);

        lon_min = min([min(LON(ip)),lon_gcp(1:ncontrol),LON0]);
        lon_max = max([max(LON(ip)),lon_gcp(1:ncontrol),LON0]);
        lat_min = min([min(LAT(ip)),lat_gcp(1:ncontrol),LAT0]);
        lat_max = max([max(LAT(ip)),lat_gcp(1:ncontrol),LAT0]);

        lon_min = lon_min - fac*abs(lon_max - lon_min);
        lon_max = lon_max + fac*abs(lon_max - lon_min);
        lat_min = lat_min - fac*abs(lat_max - lat_min);
        lat_max = lat_max + fac*abs(lat_max - lat_min);
    end

    %figure('Renderer', 'painters', 'Position', [100 100 900 700])
    
    if ~raw, m_proj('equidistant','longitudes',[lon_min lon_max],'latitudes',[lat_min lat_max]); end
    hold on;

    % Original code using pcolor
    %rgb0 = double(imread(imgFname))/255;

    % pp = size(rgb0,3);
    % if pp == 3
    %   int = g_rgb2gray(rgb0); 
    % else
    %   int = rgb0;     
    % end
    % %clear rgb0;
    % int = int';

    % Normalize the image if wanted
    %int = int - nanmean(nanmean(int));

    %cmap = contrast(int,256);
    %colormap(cmap);
    %h = m_pcolor(LON,LAT,int);
    %shading('interp');



    % New code using griddedInterpolant (MUCH faster)
    rgb0=imread([imgDir imgFname]);

    [XX,YY]=ndgrid([1:size(LON,1)],[1:size(LON,2)]);

    vLG=linspace(lon_min,lon_max,Nval);
    vLT=linspace(lat_min,lat_max,Nval);
    [LG,LT]=meshgrid(vLG,vLT);

    [XIm,YIm]=g_ll2pix(LG,LT,size(LON,2),size(LON,1),...
                        lambda,phi,theta,H,LON0,LAT0,frameRef,lens);

    for k=1:size(rgb0,3)
           F=griddedInterpolant(XX,YY,single(rgb0(:,:,k)),'nearest','none');  % Set up interpolant
           GI(:,:,k)=uint8(F(YIm,XIm));                                % Interpolate each color
    end
    
    % Feathering
    if feather>0
       [nn,mm]=size(LON);
       feathfield=min(min((1:nn)/feather,(nn:-1:1)/feather)',1)*min(min((1:mm)/feather,(mm:-1:1)/feather),1);
       F=griddedInterpolant(XX,YY,feathfield,'nearest','none');
       alphadata = F(YIm,XIm);
    else
        alphadata = ones(size(GI,1),size(GI,2),'logical');
    end
  %  alphadata(squeeze(GI(:,:,1))==0 & squeeze(GI(:,:,2))==0 & squeeze(GI(:,:,3))==0) = 0;
  
   % Make invisible stuff that is invisible, or outside the limits of the
   % image.
    alphadata(isnan(XIm) | XIm<0 | XIm>size(LON,2) | YIm<0 | YIm>size(LON,1))=0;
   
    %GI(GI==0)=single(255);  % Change black (uninterpolated) to white
  
    if raw
       h = image(vLG,vLT,GI,'alphadata',alphadata);
       plot(LON0,LAT0,'kx','markersize',ms,'linewidth',lw);  % Camera location
   else
       h = m_image(vLG,vLT,GI,'alphadata',alphadata,'resolution',Nval);
       m_plot(LON0,LAT0,'kx','markersize',ms,'linewidth',lw);  % Camera location
    end
    
    h_image(ii)=h;
    
    drawnow;
end



% Uncomment one of these lines if you want the coastline to be plotted.
if show_land && ~raw
    if strcmpi(show_land,'fjord')
        m_usercoast('fjord_coastlines.mat', 'patch', land_color)
    elseif strcmpi(show_land, 'f')
        m_gshhs_f('patch',land_color)
    else
        m_gshhs_h('patch',land_color)
    end
end

if show_time
    info = imfinfo([imgDir imgFname]);
    if isfield(info,'DateTime')
        date = info.DateTime;
    elseif isfield(info,'Comment')
        date = info.Comment;
    else
        date = '';
    end
    ht = title(date);
end

%% Plot GCPs and ICPs.
 
for n=1:ncontrol
  if raw
      % Plot the original GCPs that may have elevations
      plot(lon_gcp0(n),lat_gcp0(n),'ko','markersize',ms,'linewidth',lw);

      % Plot the projected GCPs that are actually used for the minimization
      plot(lon_gcp(n),lat_gcp(n),'bo','markersize',ms,'linewidth',lw);

      % Plot the Image Control Points once georectified
      plot(LON(i_gcp(n),j_gcp(n)),LAT(i_gcp(n),j_gcp(n)),'rx','MarkerSize',ms,'linewidth',lw);
  else
      m_plot(lon_gcp0(n),lat_gcp0(n),'ko','markersize',ms,'linewidth',lw);
      m_plot(lon_gcp(n),lat_gcp(n),'bo','markersize',ms,'linewidth',lw);
      m_plot(LON(i_gcp(n),j_gcp(n)),LAT(i_gcp(n),j_gcp(n)),'rx','MarkerSize',ms,'linewidth',lw);
   end
end
  

% Coastline
if length(lon_gcp0)>ncontrol
    if raw
       plot(lon_gcp0(ncontrol+1:end),lat_gcp0(ncontrol+1:end),'color','r');
    else
       m_plot(lon_gcp0(ncontrol+1:end),lat_gcp0(ncontrol+1:end),'color','r');
    end
end

%title([datestr(mtime,31),' UTC']);
%title([time,' UTC']);

if ~raw, 
    m_grid('box','fancy','fontsize',fs); 
    m_ruler([.5 .8],.9,'ticklen',.01);
else
    axis([lon_min lon_max lat_min lat_max]);
    set(gca,'box','on','tickdir','out','tickdirmode','manual');
end

xlabel('Longitude');
ylabel('Latitude');


if nargout > 1
    h_figure = gcf;
    if nargout == 3
        h_datetext = ht;
    end
end
