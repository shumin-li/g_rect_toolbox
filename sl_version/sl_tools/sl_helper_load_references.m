%% sl_helper_load_references


% load data for ground references.

% If a coastline file was given - we expect the
% coast points to be in an nx2 vector 'ncst' of [long lat].

if opts.isgcp, disp('TODO: deal with ground control points'); end

if opts.isCoastline,load(opts.coastlinePath); end

if opts.isDrifter

    if contains(opts.drifterPath,'.mat')
        load(opts.drifterPath)
    elseif strcmp(opts.type,'plume')
        drifterFind = dir([imgDir,'../../drifter/*.mat']);
        load([drifterFind.folder,'/',drifterFind.name]); % a struct named 'drift'
    else
        error('No drifter data file found!')
    end
end

if opts.isShipGPS
    if contains(opts.shipPath,'.mat') % a data struct named ship_gps
        load(opts.shipPath);
    elseif contains(opts.shipPath,'.plt') % a .plt file from the gps data logger
        ship_gps = ozi_rd(opts.shipPath);
    elseif strcmp(opts.type,'plume')
        shipFind = dir([imgDir,'../../OziExplorer/*.plt']);
        ship_gps = ozi_rd([shipFind.folder,'/',shipFind.name]);
    end
end

