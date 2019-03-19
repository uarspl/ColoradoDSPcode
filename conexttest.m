function [adc_sampFreq,dec,dac_sampFreq,hN,NumPoints,pulse_width]= conexttest(t) 


adc_sampFreq= str2double(t.VALUE{2})*10^6;
adc_mode= str2double(t.VALUE{3});
deci= str2double(t.VALUE{7});

if (adc_mode==0)
        decim=1;
elseif  (adc_mode==1)
        decim=deci;
else 
        decim=adc_mode*deci;
end

bypass=  str2double(t.VALUE{8});
deci2= str2double(t.VALUE{9});

if (bypass==0)
        decim2=deci2;
else
        decim2=1;
end
dec=decim*decim2 % final decimation rate

dac_sampFreq=str2double(t.VALUE{13})*10^6;

hN= str2double(t.VALUE{10});                           % Number of pulse integrated  

NumPoints=str2double(t.VALUE{19});

pulse_width=NumPoints/dac_sampFreq;
end