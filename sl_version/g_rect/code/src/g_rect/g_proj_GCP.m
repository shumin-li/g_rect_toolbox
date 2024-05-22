function [lon_gcp,lat_gcp] = g_proj_GCP(LON0,LAT0,H,lon_gcp0,lat_gcp0,h_gcp,frameRef)
%G_PROJ_GCP
%
% This function projects the GCPs that have an elevation greater than 0 
% onto the water level of zero elevation. This is a trick in order to be 
% able  to deal with GCPs that have elevation. The principle can be 
% illustrated in 1D like this. Consider the position x of a GCP that has an 
% elevation h. Then, the projection (xp) of this GCP onto the plane that has 
% zero elevation and along a line that joins the camera position of elevation
% H and the GCP is given by:
%
%      xp = x * (H - h)/H
%
% INPUTS:
%
%     LON0:     The longitiude or x-position of the camera
%     LAT0:     The latitude or y-position of the camera
%     H:        The elevation of the camera
%     lon_gcp0: The longitudes or x-position of the GCPs
%     lat_gcp0: The latitudes or y-position of the GCPs
%     h_gcp:    The elevations of the GCPs
%
% OUTPUTS:
%     lon_gcp:  The projected longitudes or x-position of the GCPs
%     lat_gcp:  The projected latitudes or y-position of the GCPs
%

n_gcp = length(h_gcp);
lon_gcp=[];
lat_gcp=[];

for i = 1:n_gcp    
    
    if strcmp(frameRef,'Geodetic') == true
        
        % The calculation for the distance between the GCPs and the camera
        % is done on an elliptical earth and this takes a long calculation
        % with the command m_idist from the m_map package. Therefore, the
        % calculation is done only on the GCPs with no elevation, hence
        % the 'if' condition here. 
        if h_gcp(i) > 0
            [range,a12,a21] = m_idist(LON0,LAT0,lon_gcp0(i),lat_gcp0(i));
            proj_factor     = H/(H - h_gcp(i));
            new_range       = range*proj_factor;
            [lon_gcp(i),lat_gcp(i),a21] = m_fdist(LON0,LAT0,a12,new_range);
            if lon_gcp(i) > 180
                lon_gcp(i) = lon_gcp(i) - 360;
            end
        else
            % If there's no elevation, then there's nothing to do.
            lon_gcp(i) = lon_gcp0(i);
            lat_gcp(i) = lat_gcp0(i);
        end
        
    elseif strcmp(frameRef,'Cartesian') == true
        
        % For cartesian situations where positions are provided in meters rather
        % than in latitude longitude the calculation is simpler.
        dx          = lon_gcp0(i) - LON0;
        dy          = lat_gcp0(i) - LAT0;
        range       = sqrt(dx^2 + dy^2);
        proj_factor = H/(H - h_gcp(i));
        new_range   = range*proj_factor;
        beta        = atan2(dy,dx);
        
        lon_gcp(i) = new_range*cos(beta) + LON0;
        lat_gcp(i) = new_range*sin(beta) + LAT0;
        
    end
end