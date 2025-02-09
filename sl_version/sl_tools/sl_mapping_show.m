%% sl_mapping_show

function [LG, LT, RGB, ALPHA] = sl_mapping_show(DB, corrFind, rgb0, axisLimits, varargin)

% this function is similar to g_viz_geodetic

% default values for some parameters
alphaScale = 1;
isplot = 'no';

k=1;
while k<=length(varargin)
    switch lower(varargin{k}(1:3))
        % case 'axi' % axisLimits
        %     axisLimits =varargin{k+1};
        case 'res' % resolution
            resolution = varargin{k+1};
        case 'dim' % dimension (of the grid created)
            dimension = varargin{k+1};
        case 'sho' % show?
            isPlot = varargin{k+1};
        case 'alp' % alphadata (or transparency)
            alphaScale = varargin{k+1};
    end
    k = k+2;
end


if exist('resolution','var')
    mid_lon = mean(axisLimits(1:2));
    mid_lat = mean(axisLimits(3:4));
    lon_step = ceil(m_idist(axisLimits(1), mid_lat, axisLimits(2), mid_lat)/resolution);
    lat_step = ceil(m_idist(mid_lon, axisLimits(3), mid_lon, axisLimits(4))/resolution);
    vLG=linspace(axisLimits(1),axisLimits(2),lon_step);
    vLT=linspace(axisLimits(3),axisLimits(4),lat_step);
    m_image_res = [lon_step, lat_step];

elseif ~exist('resolution','var') && exist('dimension','var')
    if numel(dimension) == 1
        vLG=linspace(axisLimits(1),axisLimits(2),dimension);
        vLT=linspace(axisLimits(3),axisLimits(4),dimension);
    elseif numel(dimension) == 2
        vLG=linspace(axisLimits(1),axisLimits(2),dimension(1));
        vLT=linspace(axisLimits(3),axisLimits(4),dimension(2));
    end
    m_image_res = dimension;

elseif ~exist('resolution','var') && ~exist('dimension','var')
    vLG=linspace(axisLimits(1),axisLimits(2),2000);
    vLT=linspace(axisLimits(3),axisLimits(4),2000);
    m_image_res = 2000;
    warning("neither 'dim'(dimension) or 'res'(resolution) input found. A 2000x2000 grid is created by default!");
end

if exist('resolution','var') && exist('dimension','var')
    warning("'dim'(dimension) input is ignored, 'res'(resolution) input is used instead!");
end

[LG,LT]=meshgrid(vLG,vLT);

[XX,YY]=ndgrid([1:DB(corrFind).imgHeight],[1:DB(corrFind).imgWidth]);


[XIm,YIm]=g_ll2pix(LG,LT,DB(corrFind).imgWidth,DB(corrFind).imgHeight,...
        DB(corrFind).lambda,DB(corrFind).phi,DB(corrFind).theta,...
        DB(corrFind).H,DB(corrFind).LON0,DB(corrFind).LAT0,...
        DB(corrFind).opts.frameRef, DB(corrFind).lens);

RGB = uint8(zeros([size(XIm),3]));
for k=1:size(rgb0,3)
    F=griddedInterpolant(XX,YY,single(rgb0(:,:,k)),'nearest','none');  % Set up interpolant
    RGB(:,:,k)=uint8(F(YIm,XIm));                                % Interpolate each color
end

ALPHA = alphaScale*ones(size(RGB,1),size(RGB,2),'logical');
ALPHA(isnan(XIm) | XIm<0 | XIm>DB(corrFind).imgWidth |...
    YIm<0 | YIm>DB(corrFind).imgHeight) = 0;


%% making a plot if required

if isPlot(1) == 'y' 

    m_image(vLG,vLT,RGB,'alphadata',ALPHA,'resolution',m_image_res);
    hold on
    m_line(DB(corrFind).LON0,DB(corrFind).LAT0,'marker','x',...
        'color','r','markersize',10,'linewidth',2);  % Camera location

    m_grid('FontSize',15);


end










end