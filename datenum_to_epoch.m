function time = datenum_to_epoch(time)
% time = datenum_to_epoch(time)
%
% Convert from Matlab's datenum to C library seconds since Jan 1, 1970
% epoch (we call this "epoch" time).
%
% Author: John Paden
%
% See also epoch_to_datenum.m, datenum_to_epoch.m, epoch_to_gps_sow.m,
%   epoch_to_sod.m, utc_leap_seconds.m

epoch = datenum(1970,1,1,0,0,0);

time = (time - epoch)*86400;

return;
