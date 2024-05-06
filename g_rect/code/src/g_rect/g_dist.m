function distance = g_dist(lon1,lat1,lon2,lat2,frameRef);

% This function computes the distance (m) between two points given 
% either their geodetic coordinates or cartesian coordinates.
%


if strcmp(frameRef,'Geodetic') == true
    
    % Simplest calculation on a mercator plane
    %dlon = lon2 - lon1;
    %dlat = lat2 - lat1;
    % meterPerDegLat = 1852*60.0;
    % meterPerDegLon = meterPerDegLat * cosd(lat1);
    % dx = dlon*meterPerDegLon;
    % dy = dlat*meterPerDegLat;
    % distance = sqrt(dx^2 + dy^2)
   
    % Using the m_map package on a spherical Earth (more precise)
    distance = m_lldist([lon2 lon1],[lat2, lat1])*1000;
    
elseif strcmp(frameRef,'Cartesian') == true

    dx = lon2 - lon1;
    dy = lat2 - lat1;
    distance = sqrt(dx^2 + dy^2);
    
end
