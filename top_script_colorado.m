% top level code to run snow radar processor script


 
clear all; close all; clc;

path(path,'/mnt/HDD02/UA_radar/')
first_file = '20160216_053844_MicrowaveRadar2019_CO_0000.mat';

fnum=4;                          % number of files in one time stamp 
IntN=8;                          % Number of integration 

% (1) extract parameter from config file (if you have Linux on our PC)
%Linux terminal directory should be same as your MATLAB Directory
%Change 'example' in the following two command with the config file name (.xml file name)

% system ('sh ./extract_xml_linux.sh dec_16_switch.xml');
% t=readtable('dec_16_switch.csv')
% [adc_sampFreq,dec,dac_sampFreq,hN,NumPoints,pulse_width]= conexttest(t)



%OR, (2)Just specify the parameters value wihtout parsing config file in linux 

hN=5                             % num of Pulses integrated over
adc_sampFreq=1200*10^6;
dec=4*4;                        %Decimation
NumPoints=60000;
dac_sampFreq=2400e6;
pulse_width=NumPoints/dac_sampFreq;
chirp_rate=4e9/pulse_width;
gps_path = '/mnt/HDD02/UA_radar/gpstemp/Log_files/20181218/20160216_053844_ARENA__CTU-CTU-gps.txt';


[data_image_0,data_image_1]=snowradarp_colorado(fnum,first_file,IntN,adc_sampFreq,dec,hN,gps_path,pulse_width,chirp_rate);











