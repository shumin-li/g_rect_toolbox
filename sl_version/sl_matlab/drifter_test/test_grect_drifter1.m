%% test_grect_drifter1

base_dir = '/Users/shuminli/g_rect_toolbox/';
addpath(genpath(base_dir));

% drone_dir = '/Users/shuminli/Documents/research/Drones/rich/';
% addpath(genpath([drone_dir,'../']));


sl_g_rect([base_dir,'sl_matlab/drifter_test/g_rect_params_drifter_test_Jul19.dat'],1,'gui');

%%

imgDir = '/Users/shuminli/Documents/research/field_project/July_2023/july19/drone/flight_5/';

PHOT=sl_readphotometa([imgDir '../metadata.csv']);

this_idx = find(strcmp(PHOT.SourceFile, 'flight_5/DJI_0423.JPG'));

imgFname = PHOT.name{this_idx};
UTC = PHOT.mtime(this_idx);


outputDir= '/Users/shuminli/Documents/research/field_project/July_2023/matlab/taskDrone/drifter_test/proc/';
outputFname = [imgFname(1:8) '_grect.mat'];

driftertracks = '/Users/shuminli/Documents/research/field_project/July_2023/july19/drifter/Plume23_L3_20230719.mat';
ship = '/Users/shuminli/Documents/research/field_project/July_2023/july19/OziExplorer/TrackLog 2023-07-19 daily.plt';


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

% load ship GPS data

ship_gps = ozi_rd(ship);
CC = interp1(ship_gps.mtime, ship_gps.lon + ship_gps.lat*1i, UTC-7/24);
shiplonC = real(CC);
shiplatC = imag(CC);




%%
figure(2)
clf
AxisLimits=[-123.394 -123.3818 49.1238 49.129];
g_viz_geodetic([outputDir outputFname],'axislimits',AxisLimits,'showtime',1);

%%
clear hD hDC

for ii = 1:numel(dr_idx)
    kk = dr_idx(ii);
    gd_idx = drift(kk).atSea == 1;

    % [xp,yp] = m_line(drift(kk).lon(gd_idx),drift(kk).lat(gd_idx),imgWidth,imgHeight,...
    %     lambda,phi,theta,H,LON0,LAT0,frameRef,lens);
    hD(ii)=m_line(drift(kk).lon(gd_idx),drift(kk).lat(gd_idx),'color',gd_colors{ii},'marker','.');
    % [xpC,ypC] = g_ll2pix(driftlonC(ii),driftlatC(ii),imgWidth,imgHeight,...
    %     lambda,phi,theta,H,LON0,LAT0,frameRef,lens);
    hDC(ii)=m_line(driftlonC(ii),driftlatC(ii),'color',gd_colors{ii},'marker','x','linestyle','none','markersize',10);

    id = drift(kk).id;
    lgd_str{ii} = ['T00', sprintf('%02d',str2num(id))];

end


% [xp,yp] = g_ll2pix(ship_gps.lon,ship_gps.lat,imgWidth,imgHeight,...
                     % lambda,phi,theta,H,LON0,LAT0,frameRef,lens);
 
   hS=m_line(ship_gps.lon,ship_gps.lat,'color','k','marker','.');
   
   % [xp,yp] = g_ll2pix(shiplonC,shiplatC,imgWidth,imgHeight,...
                     % lambda,phi,theta,H,LON0,LAT0,frameRef,lens);
 
   hSC=m_line(shiplonC,shiplatC,'color','k','marker','x','markersize',10);

legend(hD, lgd_str, 'Location','northwest');
set(gca,'FontSize',13);

%% Now try an example on July05
% figure(3)
base_dir = '/Users/shuminli/Documents/research/field_project/July_2023/matlab/taskDrone/drifter_test/';
addpath(genpath([base_dir,'../']));

drone_dir = '/Users/shuminli/Documents/research/Drones/rich/';
addpath(genpath([drone_dir,'../']));
sl_g_rect([base_dir,'g_rect_params_drifter_test_Jul05.dat'],1,'gui');


%%
base_dir = '/Users/shuminli/Documents/research/field_project/July_2023/matlab/taskDrone/drifter_test/';
addpath(genpath([base_dir,'../']));

drone_dir = '/Users/shuminli/Documents/research/Drones/rich/';
addpath(genpath([drone_dir,'../']));
figure(4)
clf
AxisLimits=[-123.4852 -123.4816 49.0583 49.0627];
g_viz_geodetic([outputDir outputFname],'axislimits',AxisLimits,'showtime',1);

m_ruler([0.1, 0.4], 0.15,'ticklen',.01);
