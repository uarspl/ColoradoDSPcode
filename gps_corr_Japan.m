% 
% INPUT PARAMS:
%* datain            -  freq domain data matrix (full, uncropped data)
%* gps_file_path     -  full path to the .txt GPS data file
%* st_vector         -  slow time vectors
%* ft_vector         - fast time range vector
%* c - propogation speed
% ref_chirp_time_dec - time-decimated reference chirp 
% 
% HARD CODED PARAMS:
% gps_file_length   -  length of GPS file name 
% gps file name format ('20181218_220558_ARENA__CTU-CTU-gps.txt')
% gps.utc_time format 
% 
%* -- needed for elevation compensation
% 

function[data_gps_corr] = gps_corr_Japan(data_in, gps_path, st_vector, ft_vector, pulse_wd, c,chirp_rate, ref_chirp_time_dec)

%% Part 1 - load and parse GPS data
% assume GPS filename's length is always 38 (including .txt)
workspace;
gps_file_length = 38; 
gps_file = gps_path(end-gps_file_length+1:end); 
L=length(gps_file);
% date
date0 = gps_file(end-L+1:8);
date1 = [gps_file(end-L+1:4) '-' gps_file(end-L+5:6) '-' gps_file(end-L+7:8)] ;
% load gps data
display(' Parsing GPS data ...')
gps = parse_gps_data(gps_path);
display(' Finished parsing')
gps_utc_time_tmp = gps.utc_time; 

% epoch time vectors
for ii = 1 : length(gps.utc_time)
    gps_utc_time_str = num2str(gps_utc_time_tmp(ii));
    while (length(gps_utc_time_str) < 8)    
        gps_utc_time_str = ['0' gps_utc_time_str(1:end)];
    end
    if (length(gps_utc_time_str) ~= 8)    
        error('The gps_utc_time_str variable in elev_comp_Japan has an unexpected format/length. '); 
    end
    % update the utc_time_str to standard form 
    gps_time_stamp = [date1 ' ' gps_utc_time_str(1:2) ':' gps_utc_time_str(3:4) ':' gps_utc_time_str(5:6)];
    gps_epoch_time(ii) = posixtime(datetime(gps_time_stamp));
end
gps_epoch=gps_epoch_time;

%% elevation compensation

data_gps_corr = data_in; 
% gps record starts after data record 
st_tmp = st_vector;
if gps_epoch_time(1)>= st_tmp(1)  %gps record started after data record, so trancate in slow-time vector
   idx0 = find(st_tmp >= gps_epoch_time(1), 1 ); 
    st_tmp = st_tmp(idx0:end);
    idx1 = find(gps_epoch_time>=st_tmp(1), 1 ); 
   idx2 = find(gps_epoch_time>=st_tmp(end), 1 );
   data_in   = data_in(:, idx0:end);
else                          %gps record started before data record, so trancate in gps_epoch_time
     idx0 = find(gps_epoch_time >= st_tmp(1), 1 ); 
     gps_epoch_time=gps_epoch_time(idx0:end);
    idx1 = find((st_tmp>=gps_epoch_time(1)),1); 
   idx2 = find(st_tmp>=gps_epoch_time(end), 1 );
end       
gps_epoch_time_gated=gps_epoch_time(idx1:idx2);


 
[r,col]=size(data_gps_corr);
slow_time=(0:1:col)*pulse_wd;
% Type convert
    year = str2double(date0(1:4));
    month = str2double(date0(5:6));
    day = str2double(date0(7:8));
    radar_gps_time = datenum_to_epoch(datenum(year,month,day,0,0,slow_time)) + utc_leap_seconds(gps.utc_time(1));

   
   
   
% offset index - disabled
%if there is any offset in hardware,we have to replace this 0 with that
%offset value
%gps_offset_idx = 0*round(1/(gps.utc_time(2)-gps.utc_time(1)));


 %interpolate
 

% elev = interp1(gps.utc_time(idx1-1*gps_offset_idx:idx2-1*gps_offset_idx),...
%         gps.altitude(idx1-1*gps_offset_idx:idx2-1*gps_offset_idx),radar_gps_time,'linear','extrap');
 
[x,indx]=(unique(gps_epoch_time(idx1:idx2),'stable')); %get-rid of duplicate values
 v=gps.altitude(indx)-gps.altitude(1);                 %only the altitude variaion is being taken into account 

elev= interp1(x,v,radar_gps_time,'linear','extrap');  %interpolation for elevation/altitude

figure; plot(v); title('altitude variation');
figure; plot(elev); title('inerpolated altitude');

%latitude and longitude
gps_lat=gps.latitude(indx);
gps_lon=gps.longitude(indx);


% interpolate latitude, longitude
lat = interp1(x, gps_lat, ...
    linspace(gps_epoch_time_gated(1), max(gps_epoch_time_gated), length(st_tmp)));
lon = interp1(x, gps_lon, ...
    linspace(gps_epoch_time_gated(1), max(gps_epoch_time_gated), length(st_tmp)));

pt=idx2-idx1;
lat_pt=(lat(end)-lat(1))/pt;
lon_pt=(lon(end)-lon(1))/pt;
%point=norm(start-ending)/pt;
%making latitude and longitude equal in size of elevation
%extra added values are set equal to the end point value's of latitude and
%longitude
latd=zeros(size(elev));
latd(:,1:length(lat))=lat;
latd(:,length(lat)+1:end)=lat(end);

lond=zeros(size(elev));
lond(:,1:length(lon))=lon;
lond(:,length(lon)+1:end)=lon(end);
%finding the deviation in range in each elevation point
%considered an ideal path as reference without any elevation variation  
% find the actual path which has elevation variation,
%subtract them and find range deviation
for ii=length(elev)
        ideal_lat=latd(1)+ii*lat_pt;
        ideal_lon=lond(1)+ii*lon_pt;
        Rid_1=[0,ideal_lat,ideal_lon];
        Rid_2=[elev(1),ideal_lat,ideal_lon];
        Ract_2=[elev(ii),latd(ii),lond(ii)];
        R_ideal(ii)=norm(Rid_1-Rid_2);
        R_act(ii)=norm(Rid_1-Ract_2);
       
end
del_R=R_act-R_ideal; %deviaton in range 
new_R=R_act-del_R; %new range
    


% shift data in fast time
shift_direction=1;  % MUST BE +1 OR -1! --  changes whether data is shifted up or down
dt = ft_vector(2) - ft_vector(1);
for ii=1:size(data_in,2)
    shift_idx(ii)   = round(1*(1/dt)*chirp_rate*(new_R(ii)-new_R(1))/3e8); 
    data_gps_corr(:,ii) = circshift(data_gps_corr(:,ii),shift_direction*shift_idx(ii));
end
end

%% Latitude, longitude, range/distance
% % crop in fast time 
% gps_lat              = gps.latitude(idx1:idx2); 
% gps_long             = gps.longitude(idx1:idx2); 
% % interpolate latitude, longitude
% lat = interp1(gps_epoch_time_gated, gps_lat, ...
%     linspace(gps_epoch_time_gated(1), max(gps_epoch_time_gated), length(st_tmp)));
% lon = interp1(gps_epoch_time_gated, gps_lon, ...
%     linspace(gps_epoch_time_gated(1), max(gps_epoch_time_gated), length(st_tmp)));

% % distance/range vector
% dist(1) = 0; 
% for ii=1:length(lat)-1
%     dist(ii+1) = dist(ii) + sw_dist([lat(ii) lat(ii+1)], [lon(ii) lon(ii+1)], 'km'); 
% end

% % surface time
% [c, idx] = max(20*log10(abs(data(:, 1))))
% surf_time = ref_chirp_time_dec(idx);
% % range vector
%     var1=3.15; %update this, current from greenland code
% range = (ft_vector - surf_time) .* c ./ sqrt(var1) ./ 2;
