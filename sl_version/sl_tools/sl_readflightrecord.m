function DJI = sl_readflightrecord(flnam)


if ~iscell(flnam)
    flnam={flnam};
end

for k = 1:numel(flnam)
fprintf('Reading %s\n',flnam{k});

% test flnam
% flnam = {'/Users/shuminli/g_rect_toolbox/sl_matlab/test_read_csv/flight_record/DJIFlightRecord_2023-01-04_[06-49-43].csv'};
% flnam = {'/Users/shuminli/g_rect_toolbox/sl_matlab/test_read_csv/flight_record/DJIFlightRecord_2023-07-05_[14-15-50].csv'};

% define readtable options
opts = delimitedTextImportOptions("Encoding", "UTF-8");
opts.DataLines = [3, Inf];
opts.Delimiter = ",";

opts_vns = delimitedTextImportOptions("Encoding", "UTF-8");
opts_vns.DataLines = [2, 2];
opts_vns.Delimiter = ",";

% Import the data
this_table = readtable(flnam{k}, opts); % read everthing as text
vns = table2cell(readtable(flnam{k}, opts_vns)); % get table variables
this_table.Properties.VariableNames = vns; % read table variables



%% Clear temporary variables
clear opts opts_vns

%% making data structure DJI

m2f = 3.28084; % metre to foot

local_date_idx = find(contains(vns,'CUSTOM.date') & ~ contains(vns,'UTC'));
local_date_var = vns{local_date_idx};

local_time_idx = find(contains(vns,'CUSTOM.updateTime') & ~ contains(vns,'UTC'));
local_time_var = vns{local_time_idx};

local_time_strings =  string(this_table.(local_date_var)) + " " + string(this_table.(local_time_var));

formatIn = 'MM/dd/yyyy hh:mm:ss.SSS aa';
local_datetime = datetime(local_time_strings, 'InputFormat',formatIn);
local_mtime = datenum(local_datetime);


if k == 1
DJI=struct('mtime',local_mtime,...
    'datetime', local_datetime,...
    'timezone','Local',...
    'OSDlat',str2double(this_table.("OSD.latitude")),...
    'OSDlon',str2double(this_table.("OSD.longitude")),...
    'OSDheight',str2double(this_table.("OSD.height [ft]"))/m2f,...
    'OSDvpsheight',str2double(this_table.("OSD.vpsHeight [ft]"))/m2f,...
    'OSDaltitude',str2double(this_table.("OSD.altitude [ft]"))/m2f,...
    'OSDpitch',str2double(this_table.("OSD.pitch")),...
    'OSDroll',str2double(this_table.("OSD.roll")),...
    'OSDyaw',str2double(this_table.("OSD.yaw")),...
    'OSDgpsnum',str2double(this_table.("OSD.gpsNum")),...
    'battV',str2double(this_table.("BATTERY.voltage [V]")),....  % V
    'battC',str2double(this_table.("BATTERY.currentCapacity [mAh]")),...    % A
    'GIMBALpitch',str2double(this_table.("GIMBAL.pitch")),...
    'GIMBALroll',str2double(this_table.("GIMBAL.roll")),...
    'GIMBALyaw',str2double(this_table.("GIMBAL.yaw")), ...
    'GPSlat',str2double(this_table.("OSD.latitude")),...  % Repeat
    'GPSlon',str2double(this_table.("OSD.longitude"))  ); % Repeat again

else
    
    DJI.mtime=[DJI.mtime; local_mtime];
    DJI.datetime=[DJI.datetime; local_datetime];
    DJI.OSDlat=[DJI.OSDlat; str2double(this_table.("OSD.latitude"))];
    DJI.OSDlon=[DJI.OSDlon; str2double(this_table.("OSD.longitude"))];
    DJI.OSDheight=[DJI.OSDheight; str2double(this_table.("OSD.height [ft]"))/m2f];
    DJI.OSDvpsheight=[DJI.OSDvpsheight; str2double(this_table.("OSD.vpsHeight [ft]"))/m2f];
    DJI.OSDaltitude=[DJI.OSDaltitude; str2double(this_table.("OSD.altitude [ft]"))/m2f];
    DJI.OSDpitch=[DJI.OSDpitch; str2double(this_table.("OSD.pitch"))];
    DJI.OSDroll=[DJI.OSDroll; str2double(this_table.("OSD.roll"))];
    DJI.OSDyaw=[DJI.OSDyaw; str2double(this_table.("OSD.yaw"))];
    DJI.OSDgpsnum=[DJI.OSDgpsnum; str2double(this_table.("OSD.gpsNum"))];
    DJI.battV=[DJI.battV; str2double(this_table.("BATTERY.voltage [V]"))];
    DJI.battC=[DJI.battC; str2double(this_table.("BATTERY.currentCapacity [mAh]"))];
    DJI.GIMBALpitch=[DJI.GIMBALpitch; str2double(this_table.("GIMBAL.pitch"))];
    DJI.GIMBALroll=[DJI.GIMBALroll; str2double(this_table.("GIMBAL.roll"))];
    DJI.GIMBALyaw=[DJI.GIMBALyaw; str2double(this_table.("GIMBAL.yaw"))];
    DJI.GPSlat=[DJI.GPSlat; str2double(this_table.("OSD.latitude"))]; % repeat
    DJI.GPSlon=[DJI.GPSlon; str2double(this_table.("OSD.longitude"))];

end

end



end