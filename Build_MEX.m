% Simple script to determine the version of Matlab and build the MEX with 
% the corresponding SDRplay API.
%
% For any questions or assistance you can find me at, 
% vasathanasios@gmail.com.
%
% Athanasios Vasileiadis - 11/04/2021
 
if all(computer('arch') == 'win64')
    mex RSP_MEX.c 'C:\Program Files\SDRplay\API\x64\sdrplay_api.lib'
else 
    mex RSP_MEX.c 'C:\Program Files\SDRplay\API\x86\sdrplay_api.lib'
end 