%% this is a test script for using sl_g_batch_mapping function


%% TEST 1: July 19, 20 images
base_dir = '/Users/shuminli/g_rect_toolbox/sl_version/';
addpath(genpath(base_dir));

opts = sl_make_opts('plume'); % type = 'demo','plume','general'
opts.imgDir = '/Users/shuminli/Documents/research/field_project/July_2023/july19/drone/flight_5/';
opts.firstImgNum = 412;
opts.lastImgNum = 432;
%%
% previewList = {};
axisLimits = sl_g_select_axis_limits(opts,'cut',3,'alp',0.5);
%%
testDir1 = '/Users/shuminli/g_rect_toolbox/sl_version/sl_matlab/test_batch_mapping/test_1/';
sl_g_batch_mapping(opts,axisLimits, 'formatList',{'avi','png'},...
    'position',[0 0 800 800],'dir',testDir1,'resolution',0.3,'referenceShow','y','frameRate',2);




%% TEST 2: July 05, 60 images
base_dir = '/Users/shuminli/g_rect_toolbox/sl_version/';
addpath(genpath(base_dir));

opts = sl_make_opts('plume'); % type = 'demo','plume','general'
opts.imgDir = '/Users/shuminli/Documents/research/field_project/July_2023/july05/drone/flight_5/';
opts.firstImgNum = 648;
opts.lastImgNum = 708;
%%
% previewList = {};
axisLimits = sl_g_select_axis_limits(opts,'cut',3,'alp',0.5);
%%
testDir2 = '/Users/shuminli/g_rect_toolbox/sl_version/sl_matlab/test_batch_mapping/test_2/';
sl_g_batch_mapping(opts,axisLimits, 'formatList',{'png','avi'},...
    'position',[0 0 800 800],'dir',testDir2,'resolution',0.3,'referenceShow','y','frameRate',8);





%%





