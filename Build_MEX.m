% Simple script to determine the OS, x64 or not, and build the MEX with 
% the corresponding SDRplay API.
%
% For any questions or assistance you can find me at, 
% vasathanasios@gmail.com.
%
% Athanasios Vasileiadis - 30/12/2024
 
if ispc
    if all(computer('arch') == 'win64')
        mex RSP_MEX.c -g 'C:\Program Files\SDRplay\API\x64\sdrplay_api.lib'
    else 
        mex RSP_MEX.c -g 'C:\Program Files\SDRplay\API\x86\sdrplay_api.lib'
    end
else
   mex RSP_MEX.c -g '/usr/local/lib/libsdrplay_api.so.3'
end