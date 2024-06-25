%% test_database

% this is a test script for:
% 1. create a data base for all geo-rectified images
% 2. modify sl_g_rect to process multiple images in a roll, store the
% manually adjusted parametres, and save to the database.
% 3. sl_g_rect, separate rectification part from the interpolation part to
% save time

%% test 1: July-05, flight No.5

base_dir = '/Users/shuminli/g_rect_toolbox/sl_version/';
addpath(genpath(base_dir));

opts = sl_make_opts('plume'); % type = 'demo','plume','general'

opts.date = 1;
opts.flightNum = 5;
opts.firstImgNum = 543;
opts.lastImgNum = 550;

% 
sl_g_rect(opts);

%% test2: 

base_dir = '/Users/shuminli/g_rect_toolbox/sl_version/';
addpath(genpath(base_dir));

opts = sl_make_opts('plume'); % type = 'demo','plume','general'

opts.date = 3;
opts.flightNum = 5;
opts.firstImgNum = 412;
opts.lastImgNum = 432;

% 
sl_g_rect(opts);