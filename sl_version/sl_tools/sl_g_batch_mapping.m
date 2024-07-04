%% sl_g_batch_mapping


function sl_g_batch_mapping(opts,axisLimits, varargin)


% default values of the parameters
figPosition = [0 0 800 800];
outDir = '';
outFormatList = {'png','avi'};
referenceShow = 'y';
frameRate = 0.5;

k=1;
while k<=length(varargin)
    switch lower(varargin{k}(1:3))
        case 'for' % output format list {...} choose from (png, fig, mat, avi)
            outFormatList =varargin{k+1};
        case 'pos' % position of the figure on the screen, default [0 0 800 800];
            figPosition = varargin{k+1};
        case 'dir' % output directory, defult current dir
            outDir = varargin{k+1};
        case 'img' % batch process a given list of figures
            imgFnameList = varargin{k+1};
        case 'res' % resolution
            resolution = varargin{k+1};
        case 'ref' % referenceShow (default 'y')
            referenceShow = varargin{k+1};
        case 'fra' % video frameRate
            frameRate = varargin{k+1};
            
    end
    k = k+2;
end

% creat subdirectories if they do not exist
if any(contains(outFormatList,'png'))
    pngDir = [outDir,'png'];
    if ~exist(pngDir,'dir')
        mkdir(pngDir);
    end
end

if any(contains(outFormatList,'fig'))
    figDir = [outDir,'fig'];
    if ~exist(figDir,'dir')
        mkdir(figDir);
    end
end

if any(contains(outFormatList,'mat'))
    matDir = [outDir,'mat'];
    if ~exist(matDir,'dir')
        mkdir(matDir);
    end
end

if any(contains(outFormatList,'avi'))
    aviDir = [outDir,'avi'];
    if ~exist(aviDir,'dir')
        mkdir(aviDir);
    end
end

% to save the necessary metadata for proceeding the batch process 
metaDir = [outDir,'meta'];
if ~exist(metaDir,'dir')
    mkdir(metaDir);
end


%% reading opts

switch opts.type

    case 'demo'
        % TODO
        disp('TODO: with demo option');

    case 'general'
        % TODO
        disp('TODO: with general option');

    case 'plume'

        switch opts.year
            case 2023
                yearFolder = 'July_2023/';
            case 2024
                yearFolder = 'August_2024/';
        end

        switch opts.date
            case 1
                dateFolder = 'july05/';
            case 2
                dateFolder = 'july12/';
            case 3
                dateFolder = 'july19/';
            case 4
                dateFolder = 'july27/';
        end

        dateDir = [opts.fieldDir, yearFolder, dateFolder];
        imgDir = [dateDir,'drone/flight_',num2str(opts.flightNum),'/'];

        % create a list of image filenames to be previewed
        if ~exist('imgFnameList','var')
                imgNumberList = opts.firstImgNum:opts.lastImgNum; 

            for mm = 1:numel(imgNumberList)
                imgFnameList{mm} = ['DJI_',sprintf('%04d',imgNumberList(mm)),'.JPG'];
                imgTitleList{mm} = ['DJI\_',sprintf('%04d',imgNumberList(mm)),'.JPG'];
            end

        end

end

% load database
load(opts.databasePath); % A data struct named 'DB'

if referenceShow(1) == 'y'
    % load references (gcps, drifters, coastlines, ship_tracks)
    sl_helper_load_references;
end


%%


figure(5)
    set(gcf,'color','w','position',figPosition); 
    m_proj('lambert','long',[axisLimits(1) axisLimits(2)],...
        'lat',[axisLimits(3) axisLimits(4)]);

    for mm = 1:numel(imgFnameList)

        clf

        imgFname = imgFnameList{mm};
        corrFind = find(contains({DB.imgFname}, imgFname) & contains({DB.folder}, imgDir));
        rgb0=imread([imgDir imgFname]);
        [LG, LT, RGB, ALPHA] = sl_mapping_show(DB, corrFind, rgb0, axisLimits, ...
            'res',resolution,'show','yes','alp',1);
        title(['batch ',sprintf('%03d',mm), ', ', ...
            imgTitleList{mm},', ', datestr(DB(corrFind).mtimePhoto)]);
        mtime = DB(corrFind).mtimePhoto;
        m_ruler(1.03,[.05 .4],'ticklen',[.008],'FontSize',14);



        if referenceShow(1) == 'y'
            sl_helper_draw_references;
        end

        if any(contains(outFormatList,'mat'))
            matFname = ['batch_',sprintf('%03d',mm),'.mat'];
            save([matDir,'/',matFname],'LG','LT','RGB','ALPHA','mtime')
        end

        if any(contains(outFormatList,'png'))
            pngFname = ['batch_',sprintf('%03d',mm)];
            print([pngDir,'/',pngFname],'-dpng','-r200');
        end

        if any(contains(outFormatList,'fig'))
            figFname = ['batch_',sprintf('%03d',mm)];
            savefig([figDir,'/',figFname]);
        end


        if any(contains(outFormatList,'avi'))
            FF(mm) = getframe(gcf);
        end

        disp(['batch ',sprintf('%03d',mm),' done!']);

    end

    % write vedio if required

    if any(contains(outFormatList,'avi'))
        aviFname = [aviDir,'/','batch_movie.avi'];
        writerObj = VideoWriter(aviFname);
        writerObj.FrameRate = frameRate; % set the seconds per image
        open(writerObj);
        for ii=1:length(FF)
            % convert the image to a frame
            frame = FF(ii) ;
            writeVideo(writerObj, frame);
        end
        close(writerObj);
    end



%%

% save to metaDir
save([metaDir,'/batchMeta.mat'],'opts','DB','imgDir','imgFnameList','axisLimits','varargin')



end




























