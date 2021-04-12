clear all; close; clc;

%% Load SDRplay Default
MyRSP_dev = RSP_func;
%% Default values, example.
MyRSP_dev.SampleRateMHz = 4;    % Set SDRplay sample rate, 2 - 10 MHz.
MyRSP_dev.FrequencyMHz = 869;   % Set SDRplay tuner frequency, see specification for details.
MyRSP_dev.BandwidthMHz = 600;   % Set SDRplay BandwidthMHz, see table for details.
MyRSP_dev.IFtype = 0;           % Set SDRplay IF to be used, see specification for details.
MyRSP_dev.LNAstate = 0;         % Set SDRplay LNA state based on Grmode, see specification for details.
%MySDRplay.Port = 'A';           % SDRplay port selection, A (default) or B.
%% Initiallize Stream
MyRSP_dev.Stream;
%% DSP Spectrum Analyzer
hSpectrum = dsp.SpectrumAnalyzer(...
    'Name',             'Passband Spectrum',...
    'Title',            'Passband Spectrum', ...
    'Method',           'Welch', ...
    'ViewType',         'Spectrum and spectrogram',...
    'FrequencySpan',    'Full', ...
    'SpectrumUnits',    'dBm', ...
    'SampleRate',       MyRSP_dev.SampleRateMHz*1e6, ...
    'FrequencyOffset',  MyRSP_dev.FrequencyMHz*1e6, ...
    'YLabel',           'Magnitude, dBFS');
%% Open Spectrum Analyzer and show data
CaptureTime_s = 60;
Time2Fill_Buffer = 2e6/(MyRSP_dev.SampleRateMHz*1e6);  % (buffer size / sample rate)
for i = 0:CaptureTime_s/Time2Fill_Buffer      % While timer is less than 60 sec plot data
    data = RSP_MEX('data');
    step(hSpectrum, data);
    pause(Time2Fill_Buffer)
end
%% Stop stream, and exit the device
MyRSP_dev.StopStream;
MyRSP_dev.Close;
delete(MyRSP_dev);