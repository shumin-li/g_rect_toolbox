clear

%g_stabilize('HYPERLAPSE_0001.jpg','roi_file','roi_100_0243_0001.mat','L_level_Gaussian',6);
%cd ..

%folders = dir;

%ifolders = find(folders.isdir == 1);
%folders  = folders(ifolders);
%N_folders = length(folders);

%for i = 3:N_folders
%for i = 11:N_folders

%    cd(folders(i).name);
    
    DNG_filenames = dir('*.DNG');
    N_files       = length(DNG_filenames);

    for j = 1:N_files
    
        newFileName = strcat(DNG_filenames(j).name(1,1:end-3),'jpg');
        display(['   Converting ', DNG_filenames(j).name, ' to ',newFileName,' (',...
                 num2str(j),'/',num2str(N_files),')']);
    
        % Call the function that makes the conversion 
        g_DNG2jpg(DNG_filenames(j).name)
        
    end

    %if strcmp(folders(i).name,'100_0243');
    %    g_stabilize('HYPERLAPSE_0001.jpg','roi_file','roi_100_0243_0001.mat','L_level_Gaussian',6);
    %end
    %
    %cd ..
    
%end

