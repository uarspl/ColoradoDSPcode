%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%% SNOW RADAR PROCESSOR                                   %%%%%%%%
%%%%%%%% VERSION 1.0                                            %%%%%%%% 
%%%%%%%% Last Edited:  3/12/19                                  %%%%%%%%
%%%%%%%% By: S.Z. Gurbuz                                        %%%%%%%%  
%%%%%%%%                                                        %%%%%%%%
%%%%%%%% INPUTS                                                 %%%%%%%%  
%%%%%%%% num_files:  number of files                            %%%%%%%%
%%%%%%%% first_filename: filename of first file, e.g. "xyz.mat" %%%%%%%%
%%%%%%%%      (function takes as input decompressed .mat files) %%%%%%%%
%%%%%%%% IntN: number of times hardware integration (hN) should %%%%%%%%  
%%%%%%%%       be repeated, e.g. IntN x hN = total integration  %%%%%%%%     
%%%%%%%%                                                        %%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


function [data_image_0,data_image_1] = snowradarp_colorado(num_files,first_filename,IntN,adc_sampFreq,dec,hN,gps_path,pulse_width,chirp_rate)

% Create wait bar.
wait_bar = waitbar(0, 'Reading in data files...');

% Loop through all target files and stitch their matrices together.
filename = first_filename;
final_data0 = [];
final_data1 = [];
st_vector1=[];
st_vector2=[];
for ii=0:num_files-1    
    % Load *.mat file and extract data matrix.
    indexable_name = char(filename);
    
    load(filename,'Long_Chirp_Profiles','Long_Chirp_PPS_Count_Values','Short_Chirp_Profiles','Short_Chirp_PPS_Count_Values');
    Long_mode0 = Long_Chirp_Profiles;
    final_data0 = [final_data0 Long_mode0]; %stitch matrix for long mode
    PPS=Long_Chirp_PPS_Count_Values;
    st_vector1=[st_vector1 PPS];        
  
    Short_mode1 = Short_Chirp_Profiles;
    final_data1 = [final_data1 Short_mode1]; %stitch matrix for short mode
    PPS1=Short_Chirp_PPS_Count_Values;
    st_vector2=[st_vector2 PPS1];
    
 
   
    
    % Create new filename.
    file_index = num2str(str2num(indexable_name(end-7:end-4)) + 1, '%04d')
    filename = [indexable_name(1:end-8) file_index indexable_name(end-3:end)]
    
    % Update wait bar.
    waitbar((ii+1)/num_files);

end;

% Save concatenated chirp data
%    concat_filename = num2str([char(first_filename(end-23:end-9)) '_concat.mat'])
%    save(concat_filename,'final_data');
% final_data too large to be saved; need mat-fie version 7.3 or later

% Close wait bar.
close(wait_bar);

% 
% Process the data
%

% Convert data type for long mode.
old_data0 = double(final_data0);


% Convert data type for short mode.
old_data1 = double(final_data1);




% Slice off unwanted regions for long mode0
d=abs(old_data0(:,1));
I=find(abs(diff(d))>mean(d)/2);
lowlim=min(I)
lowlim=66
for ii=1:size(old_data0,2),
    new_data0(:,ii)=old_data0(lowlim:13030,ii);
end;
L0 = length(new_data0(:,1))
sample_chirp_new0=real(new_data0(:,1));

% Slice off unwanted regions for short mode1
d=abs(old_data1(:,1));
I=find(abs(diff(d))>mean(d)/2);
lowlim=min(I)
lowlim=66
for ii=1:size(old_data1,2),
    new_data1(:,ii)=old_data1(lowlim:13030,ii);
end;
L1 = length(new_data1(:,1))
sample_chirp_new1=real(new_data1(:,1));

%plot the long chirp and short chirp together
figure;
plot(sample_chirp_new1,'r'); hold on; plot(sample_chirp_new0,'b'); hold off;
title('Long and Short Chirps'); xlabel('Time samples')
legend('Short Chirp, mode 1, 2-10GHz', 'Long Chirp, mode 0, 10-12GHz')

% Perform coherent average over 5 samples  for long mode 0
%hN = 5;  % Should be read from config file (num of pulses integrated)
message = ['Long mode Coherent integration of ' num2str(IntN) ' times ' num2str(hN) ' pulses...'];
h = waitbar(0, message);
for ii = 1:size(new_data0,2)
    if ii > IntN && ii < (size(new_data0,2) - IntN)
        avg_data0(:,ii) = mean(new_data0(:,ii-IntN:ii+IntN),2);
    else
        avg_data0(:,ii) = new_data0(:,ii);
    end
    waitbar(ii/size(new_data0,2));
end
close(h);

% Perform coherent average over 5 samples  for short mode 1
%hN = 5;  % Should be read from config file (num of pulses integrated)
message = ['short mode Coherent integration of ' num2str(IntN) ' times ' num2str(hN) ' pulses...'];
h = waitbar(0, message);
for ii = 1:size(new_data1,2)
    if ii > IntN && ii < (size(new_data1,2) - IntN)
        avg_data1(:,ii) = mean(new_data1(:,ii-IntN:ii+IntN),2);
    else
        avg_data1(:,ii) = new_data1(:,ii);
    end
    waitbar(ii/size(new_data1,2));
end
close(h);

% Set up a hanning window and perform the FFT on long chirp Data.
h = waitbar(0, 'Performing FFT on long chirp...');
hann_window0 = hanning(L0);
for ii=1:size(new_data0,2)
    data_image_0(:,ii) = fft(avg_data0(:,ii).*hann_window0);
    waitbar(ii/size(avg_data0,2));
end
close(h);

% Set up a hanning window and perform the FFT on short chirp Data.

h = waitbar(0, 'Performing FFT on short chirp...');
hann_window1 = hanning(L1);
for ii=1:size(new_data1,2)
    data_image_1(:,ii) = fft(avg_data1(:,ii).*hann_window1);
    waitbar(ii/size(avg_data1,2));
end
close(h);


%combine the slow time vectors
sz=length(st_vector1)+length(st_vector2);
st_vector=zeros(sz,1)';
st_vector(1:length(st_vector1))=st_vector1;
st_vector(length(st_vector1)+1:end)=st_vector2;

%Calling the combined_echogram function to generate echogram 

[data_iamge_01]=combined_echogram(data_image_0,data_image_1,st_vector,IntN,adc_sampFreq,dec,gps_path,pulse_width,chirp_rate);
end


