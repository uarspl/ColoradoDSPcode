%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This script is to parse raw GPS data
% 
% Author: Christopher Simpson
% Version: 1.0
% Last updated: 8-20-2018
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function gps_data = parse_gps_data( file_path )

key = 'nmea:$GPGGA';

file_lines = fileread( file_path );
lines = strsplit(file_lines, '\n');
match = strncmp(lines, key, length(key));

nmea_gpgga_lines = lines(match);

num_lines = length(nmea_gpgga_lines);

for i = 1:num_lines
    line = nmea_gpgga_lines{i};
    split_line = strsplit(line, ',');
    gps_data.utc_time(i) = str2double(split_line{2});
    gps_data.seconds_since_start(i) = utc2sec(gps_data.utc_time(i))-utc2sec(gps_data.utc_time(1));
    
    gps_data.latitude(i) = degmin2deg(str2double(split_line{3}));
    if split_line{4} == 'S'
        gps_data.latitude(i) = -gps_data.latitude(i);
    end
    
    gps_data.longitude(i) = degmin2deg(str2double(split_line{5}));
    if split_line{6} == 'W'
        gps_data.longitude(i) = -gps_data.longitude(i);
    end
    
    gps_data.fix_quality(i) = str2double(split_line{7});
    gps_data.num_satellites(i) = str2double(split_line{8});
    gps_data.position_dilution(i) = str2double(split_line{9});
    gps_data.altitude(i) = str2double(split_line{10});
    gps_data.geoid_height(i) = str2double(split_line{12});
end

% gps_data = nmea_lines;

end

function sec = utc2sec( t )
    hour = floor(t/10000);
    minute = floor((t-hour*10000)/100);
    second = floor((t-hour*10000-minute*100));
    sec = second + minute*60 + hour*3600;
end

function deg = degmin2deg( c )
    d = floor(c/100);
    m = c - (d*100);
    deg = d+m/60;
end