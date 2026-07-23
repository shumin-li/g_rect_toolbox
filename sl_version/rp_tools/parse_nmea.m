function gps=parse_nmea(flsname,varargin)
% PARSE_NMEA Reads a GPS logfile and parses out positions.
%  GPS=PARSE_NMEA(FILENAME) reads the ascii GPS logfile
%   FILENAME and produces a structure of GPS data.
%
%   $GPGGA strings are used for lat/long, time-of-day.
%   $GPRMC or GPZDA strings are used for date.
%
%   GPS=PARSE_NMEA(...,STRINGS) where STRINGS is a cell
%   array of other strings allows other strings to be
%   parsed. Information is stored at the index of the immediately
%   preceding $GPGGA string. Currently STRINGS could include:
%     '$RDENS' : Teledyne-RDI string that gives ping number
%                from an ADCP.
%     '$GPHDT' : Heading
%     '$GPVTG' : Track made good (speed and direction)
%     '$GPGMS' : KCA Proprietary code with compass/pitch/roll
%
%  FILENAME can also be a cell array of filenames, so
%  that an entire deployment can be read into one structure.
%

% R Pawlowicz  Aug/2018
% Sep/2024 - added other strings option.

if isstr(flsname)
    flsname={flsname};
end

parse_strings={'$GPZDA','$GPRMC'};
if ~isempty(varargin),
    strings=varargin{1};
    if isstr(strings)
        parse_strings={parse_string{:},strings};
    else
        parse_strings={parse_strings{:},strings{:}};
    end
end


parsedate='serial';  % Date stamp in front of string

bn=86400*10;  % 10 days?

gps=struct('comment','GPS','mtime',NaN(bn,1),...
           'tzone','UTC',...
           'lat',NaN(bn,1),'lon',NaN(bn,1),...
           'qual',NaN(bn,1),...
           'nsat',NaN(bn,1),'alt',NaN(bn,1),'msl',NaN(bn,1),...
           'filnum',NaN(bn,1));
for k2=1:length(parse_strings)
    switch parse_strings{k2}
        case '$GPHDT'
            gps.heading=NaN(bn,1);
        case '$GPVTG'
            gps.speed=NaN(bn,1);
            gps.direc=NaN(bn,1);
        case '$RDENS'
            gps.ping_num=NaN(bn,1);
        case '$GPGMS'     
            gps.Cheading=NaN(bn,1);
            gps.Coffset=NaN(bn,1);
            gps.pitch=NaN(bn,1);
            gps.roll=NaN(bn,1);
    end
end

m=0;cnt=0;

% Default Year/month/day if no ZDA or RMC strings.
YR=2024;MON=08;DAY=13;

mfirst=[];

for k=[1:length(flsname)]
  disp(['Opening: ' flsname{k}]);
  fd=fopen(flsname{k});
   
  l=fgets(fd);

  
  while length(l)>0 && l(1)>-1
    words=split_string(l);
    if length(words)>=14 && strcmp(words{1},'$GPGGA') && length(words{2})>=2 && length(words{3})>=4
      m=m+1;
      if m==bn
          disp('WARNING - Number of points Exceeds preallocation, things will get SLOOOOWWWWW now...')
      end

      gps.mtime(m)=datenum(YR,MON,DAY,str2num(words{2}(1:2)),str2num(words{2}(3:4)),str2num(words{2}(5:end)));
      
      % Day wrap-around
      if m>1 && gps.mtime(m)-gps.mtime(m-1)<-0.9
          DAY=DAY+1;
          gps.mtime(m)=gps.mtime(m)+1;
      end
      
      gps.lat(m)=  str2num(words{3}(1:2))+str2num(words{3}(3:end))/60;
      if words{4}=='S' 
          gps.lat(m)=-gps.lat(m); 
      end
      gps.lon(m)= str2num(words{5}(1:3))+str2num(words{5}(4:end))/60;
      if words{6}=='W' 
          gps.lon(m)=-gps.lon(m); 
      end
      gps.qual(m)=str2num(words{7});
      gps.nsat(m)=str2num(words{8});
      gps.alt(m)=str2num(words{10});
      gps.msl(m)=str2num(words{12});
      gps.filnum(m)=k;
      
      cnt=0;
      if rem(m,1000)==0, fprintf('.'); end
      if rem(m,1000*80)==0, fprintf('\n'); end
       
    elseif m>0
      for k2=1:length(parse_strings);
          switch parse_strings{k2},
              case '$GPZDA'        
                 if length(words)>=6 && strcmp(words{1},'$GPZDA') && length(words{3})>=1
                    if isempty(mfirst)
                       mfirst=m+1;
                    end
                    DAY=str2num(words{3});
                    MON=str2num(words{4});
                    YR=str2num(words{5});
                 end
              case '$GPRMC'
                 if length(words)>=10 && strcmp(words{1},'$GPRMC') && length(words{10})==6
                    if isempty(mfirst)
                       mfirst=m+1;
                    end
                    DAY=str2num(words{10}(1:2));
                    MON=str2num(words{10}(3:4));
                    YR=str2num(words{10}(5:6))+2000;
                 end
              case '$GPHDT'
                  if length(words)>=3 && strcmp(words{1},'$GPHDT') 
                      gps.heading(m)=str2num(words{2});
                  end
              case '$RDENS'
                  if length(words)>=3 && strcmp(words{1},'$RDENS') 
                      gps.ping_num(m)=str2num(words{2});
                  end
              case '$GPVTG'
                  if length(words)>=8 && strcmp(words{1},'$GPVTG') 
                      if length(words{8})>0
                         gps.speed(m)=str2num(words{8})*1000/3600;  % kmh to m/s
                         gps.direc(m)=str2num(words{2});
                      end
                  end
              case '$GPGMS'
                  if length(words)>=5 && strcmp(words{1},'$GPGMS') 
                      try
                      gps.Cheading(m)=str2num(words{2});
                      gps.Coffset(m)=str2num(words{3});
                      gps.pitch(m)=str2num(words{4});
                      gps.roll(m)=str2num(words{5});
                      catch
                          disp(words)
                      end
                   %%   if gps.pitch(m)<0, disp(l); end
                  end
          end
          cnt=cnt+1;
      end
      %%if length(l)>100, disp('*');  end; 
    end
    
    l=fgets(fd);
    
  end
  fclose(fd);
end

fprintf('Done\n');


gps.mtime(m+1:end)=[];
gps.lon(m+1:end)=[];
gps.lat(m+1:end)=[];
gps.qual(m+1:end)=[];
gps.nsat(m+1:end)=[];
gps.alt(m+1:end)=[];
gps.msl(m+1:end)=[];
gps.filnum(m+1:end)=[];
for k2=1:length(parse_strings)
    switch parse_strings{k2}
        case '$GPHDT'
            gps.heading(m+1:end)=[];
        case '$RDENS'
            gps.ping_num(m+1:end)=[];
        case '$GPVTG'
            gps.speed(m+1:end)=[];
            gps.direc(m+1:end)=[];
        case '$GPGMS'
            gps.Cheading(m+1:end)=[];
            gps.Coffset(m+1:end)=[];
            gps.pitch(m+1:end)=[];
            gps.roll(m+1:end)=[];
    end
end

  
 % Handle times before first ZDA/RMC
 if ~isempty(mfirst) && mfirst>1  % a ZDA string arrived
    doff=round(gps.mtime(mfirst)-gps.mtime(mfirst-1));
    gps.mtime(1:mfirst-1)=gps.mtime(1:mfirst-1)+1;
 end
  
end

 

function words=split_string(l)

% Splits up sentence into words
%if strcmp(parsedate,'serial'),
    ii=strfind(l,': ');
    if any(ii)
       l=l(ii(1)+2:end);
    end
%end
  
ii=find([',' l ',']==',')-1;

for k=1:length(ii)-1
    words{k}=l((ii(k)+1):(ii(k+1)-1));
end    


end



