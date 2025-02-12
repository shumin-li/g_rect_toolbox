%% demo_main
% this script contains the main workflow of using sl_g_rect to geo-rectify
% a batch of drone images.

%% Step 1: create an input structure
opts = sl_make_opts('demo');
% here, you can change the values in the fields of opts structure

%% Step 2: call sl_g_rect function
sl_g_rect(opts);
% after done properly, the corrections should have been save to the
% database (path to opts.databaseDir)

%% Step 3: find a region for mapping onto
% draw a region of interest on the map
axisLimits = sl_g_select_axis_limits(opts,'cut',3,'alp',0.5);

%% Step 4: do the geo-mapping for the whole batch, save as cetain formats
% one or a combination of .png, .fig, .mat and .avi files (add to 'formatList')

sl_g_batch_mapping(opts,axisLimits, 'formatList',{'png','avi'},...
    'position',[0 0 800 800],'dir',opts.outputDir,'resolution',0.3,...
    'referenceShow','y','frameRate',2);
