

function [data_image_01]=combined_echogram(data_image_0,data_image_1,st_vector,IntN,adc_sampFreq,dec,gps_path,pulse_width,chirp_rate)
% Mode 0 power spectrum
m = 0;
xdft = data_image_0(:,1);                     % get one chirp
Fs = adc_sampFreq/dec;                      % halve due to complex sampling
L = length(xdft(:,1));
xdft = xdft(1:L/2+1);                       % get half the chirp
psdx = (1/(Fs*L)) * abs(xdft).^2;           % compute power spectrum
freq = 0:Fs/L:Fs/2;
figure; plot(freq/(10^6),10*log10(psdx)); title(num2str(m));
grid on;
title('Periodogram Using FFT Mode 0');
xlabel('Frequency (MHz)'); ylabel('dB')

% Mode 1 power spectrum
m = 1;
xdft = data_image_1(:,1);                     % get one chirp
Fs = adc_sampFreq/dec;                      % halve due to complex sampling
L = length(xdft(:,1));
xdft = xdft(1:floor(L/2)+1);                       % get half the chirp
psdx = (1/(Fs*L)) * abs(xdft).^2;           % compute power spectrum
freq = 0:Fs/L:Fs/2;
figure; plot(freq/(10^6),10*log10(psdx)); title(num2str(m));
grid on;
title('Periodogram Using FFT Mode 1');
xlabel('Frequency (MHz)'); ylabel('dB')

% Create echogram from results.
% Mode 0
h = waitbar(0, 'Creating echogram...');
freq = (Fs/2)*linspace(0,1,size(data_image_0,1)/2);
data_norm = 10*log10(abs(data_image_0(1:floor(L/2),:)));
for ii=1:size(data_norm,2)
    data_norm(:,ii) = data_norm(:,ii) - max(data_norm(1:1000,ii));
    waitbar(ii/size(data_norm,2));
end
close(h);
figure; 
imagesc([], freq/1e6, data_norm);
title('Echogram using mode 0 (long chirp 10-12 GHz)');
colormap(1-gray);
ylabel('Beat frequency (MHz)');
xlabel('Slow time index');

% Mode 1
h = waitbar(0, 'Creating echogram...');
freq = (Fs/2)*linspace(0,1,size(data_image_1,1)/2);
data_norm = 10*log10(abs(data_image_1(1:floor(L/2),:)));
for ii=1:size(data_norm,2)
    data_norm(:,ii) = data_norm(:,ii) - max(data_norm(1:1000,ii));
    waitbar(ii/size(data_norm,2));
end
close(h);
figure; 
imagesc([], freq/1e6, data_norm);
title('Echogram using mode 1 (short chirp 2-10 GHz)');
colormap(1-gray);
ylabel('Beat frequency (MHz)');
xlabel('Slow time index');


%combine mode0 and mode1
% concatenate in time domain
display('Generating combined data for modes 0 and 1...')
hann_old = hanning(size(data_image_0, 1));
hann_new = hanning(size(data_image_0, 1)+size(data_image_1, 1)); 
data_t_0 = ifft(data_image_0, [], 1)./hann_old; 
data_t_1 = ifft(data_image_1, [], 1)./hann_old; 
%slow time index mismatch
%find minimum slow time index
slow_data0=size(data_t_0,2);
slow_data1=size(data_t_1,2 );
slow_indx=min(slow_data0,slow_data1);
data_t_0=data_t_0(:,1:slow_indx);
data_t_1=data_t_1(:,1:slow_indx);
%concatente in fast time dimension

data_image_01 = fft((vertcat(data_t_1, data_t_0).*hann_new), [], 1);     

L = length(data_image_01(:,1));
data_norm = 10*log10(abs(data_image_01(1:floor(L/2),:)));

% check if the indexing for data_norm needs to be changed in the second
% term
for ii=1:size(data_norm,2)
    data_norm(:,ii) = data_norm(:,ii) - max(data_norm(1:1000,ii));
end

freq = (Fs/2)*linspace(0,1,size(data_image_01,1)/2);
figure; 
imagesc([], freq/1e6, data_norm);
title('Echogram using both modes (concatenate data for a total 2-18 GHz)');
colormap(1-gray);
ylabel('Beat frequency (MHz)');
xlabel('Slow time index');

%% GPS Correction
[row,col]=size(data_image_01);
ft_vector=(0:1:row)*(1/Fs);          % Fast time vector
     

%verify gps filename format

c=3e8;
data_gps_corr = gps_corr_Japan(data_image_01, gps_path, st_vector, ft_vector, pulse_width, c, chirp_rate,''); %calling gps_corr_japan function
disp('Generating gps corrected echogram...')
L = length(data_gps_corr(:,1));
data_norm = 10*log10(abs(data_gps_corr(1:floor(L/2),:)));

% check if the indexing for data_norm needs to be changed in the second
% term
for ii=1:size(data_norm,2)
    data_norm(:,ii) = data_norm(:,ii) - max(data_norm(1:1000,ii)); %1000 is hard_coded, need to be replaced with the position of first peak in fft
end


freq = (Fs/2)*linspace(0,1,size(data_gps_corr,1)/2);
figure; 
imagesc([], freq/1e6, data_norm);
title('Echogram using both modes (concatenate data for a total 2-18 GHz)');
colormap(1-gray);
ylabel('Beat frequency (MHz)');
xlabel('Slow time index');

end     % end of function
