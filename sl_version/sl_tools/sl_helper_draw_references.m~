%% sl_helper_draw_references




if opts.isgcp, disp('TODO: deal with ground control points'); end

% If a coastline file was given - we expect the
% coast points to be in an nx2 vector 'ncst' of [long lat].

if opts.isCoastline

    if ~exist('coast_lon','var')

        coast_lon = ncst(:,1);
        coast_lat = ncst(:,2);

        meterPerDegLat = 1852*60.0;
        Dhoriz2 = (2*DB(corrFind).H*DB(corrFind).lens.Re)/meterPerDegLat.^2;

        irm=((coast_lon-DB(corrFind).LON0).^2*cosd(DB(corrFind).LAT0).^2+(coast_lat-DB(corrFind).LAT0).^2)>Dhoriz2;
        coast_lon(irm)=[];
        coast_lat(irm)=[];
    end

        m_line(coast_lon, coast_lat,'color','r');

end

if opts.isDrifter

    driftlonC = [];
    driftlatC = [];
    dr_idx = [];

    clear first_comment_letters;
    for ii = 1:numel(drift)
        first_comment_letters(ii) = drift(ii).comment(1);
    end
    dr_idx = find(first_comment_letters ~= 'h');

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

    for ii = 1:numel(dr_idx)
        kk = dr_idx(ii);
        gd_idx = drift(kk).atSea == 1;
        CC = interp1(drift(kk).mtime(gd_idx), ...
            drift(kk).lon(gd_idx) + drift(kk).lat(gd_idx)*1i, DB(corrFind).mtimePhoto,'spline');
        driftlonC(ii) = real(CC);
        driftlatC(ii) = imag(CC);
        m_line(drift(kk).lon(gd_idx), drift(kk).lat(gd_idx),'color',gd_colors{ii},'marker','.');
        m_line(driftlonC(ii), driftlatC(ii),'color',gd_colors{ii},'marker','x',...
            'linestyle','none','markersize',10,'linewidth',2)

    end

    

   

end


if opts.isShipGPS
    CC = interp1(ship_gps.mtime, ship_gps.lon + ship_gps.lat*1i, DB(corrFind).mtimePhoto);
    shiplonC = real(CC);
    shiplatC = imag(CC);
    m_line(ship_gps.lon,ship_gps.lat,'color','k','marker','.');
    m_line(shiplonC,shiplatC,'color','k','marker','x','markersize',10, ...
        'linestyle','none','linewidth',2);

end

