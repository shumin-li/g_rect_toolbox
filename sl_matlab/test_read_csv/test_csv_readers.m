

%% Step 1, addpath of g_rect toolbox
base_dir = '/Users/shuminli/g_rect_toolbox/'; % change to your local dir
addpath(genpath(base_dir));


%% test sl_readflightrecord
fr_dir = [base_dir,'sl_matlab/test_read_csv/flight_record/'];
fr_info = dir([fr_dir,'*.csv']);

cd(fr_dir);

fr_names = {fr_info.name};

DJI = sl_readflightrecord(fr_names);


%% test sl_readflightrecord on PRODIGY24

fr_dir = [base_dir,'sl_matlab/test_read_csv/flight_records_PRODIGY24/'];
fr_info = dir([fr_dir,'*.csv']);

cd(fr_dir);

fr_names = {fr_info.name};

DJI = sl_readflightrecord(fr_names);

%% test sl_photo

meta_dir = [base_dir,'sl_matlab/test_read_csv/photo_meta/'];
meta_info = dir([meta_dir,'*.csv']);

cd(meta_dir);

meta_names = {meta_info.name};

PHOT = sl_readphotometa(meta_names);



