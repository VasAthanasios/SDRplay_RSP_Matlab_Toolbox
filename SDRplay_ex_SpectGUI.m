function varargout = SDRplay_ex_SpectGUI(varargin)
% SDRPLAY_EX_SPECTGUI MATLAB code for SDRplay_ex_SpectGUI.fig
%      SDRPLAY_EX_SPECTGUI, by itself, creates a new SDRPLAY_EX_SPECTGUI or raises the existing
%      singleton*.
%
%      H = SDRPLAY_EX_SPECTGUI returns the handle to a new SDRPLAY_EX_SPECTGUI or the handle to
%      the existing singleton*.
%
%      SDRPLAY_EX_SPECTGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in SDRPLAY_EX_SPECTGUI.M with the given input arguments.
%
%      SDRPLAY_EX_SPECTGUI('Property','Value',...) creates a new SDRPLAY_EX_SPECTGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before SDRplay_ex_SpectGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to SDRplay_ex_SpectGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help SDRplay_ex_SpectGUI

% Last Modified by GUIDE v2.5 08-Jun-2018 14:52:43

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @SDRplay_ex_SpectGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @SDRplay_ex_SpectGUI_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT

% --- Executes just before SDRplay_ex_SpectGUI is made visible.
function SDRplay_ex_SpectGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to SDRplay_ex_SpectGUI (see VARARGIN)

% Choose default command line output for SDRplay_ex_SpectGUI
handles.output = hObject;
handles.MySDRplay = sdrplay;
%% Set string on pushbutton
set(handles.Stream_ctr,'String','Stream on');
%% Set Frequency 
set(handles.Freq_inp,'String', num2cell(handles.MySDRplay.FrequencyMHz));
%% Set Gain reduction
set(handles.GainRed_inp,'String', num2cell(handles.MySDRplay.GainReduction));
%% Set Sample rate
set(handles.SR_inp,'String', num2cell(handles.MySDRplay.SampleRateMHz));
%% Set LNA state
set(handles.LNA_inp,'String', num2cell(handles.MySDRplay.LNAstate));
%% Set Correct Port
set(handles.Port_inp,'Value', 1);
%% Set BW
val = handles.MySDRplay.BandwidthMHz;
if val == 0
    set(handles.BW_inp,'Value',1);
elseif val == 200
    set(handles.BW_inp,'Value',2);
elseif val == 300
    set(handles.BW_inp,'Value',3);
elseif val == 600
    set(handles.BW_inp,'Value',4);
elseif val == 1536
    set(handles.BW_inp,'Value',5);
elseif val == 5000
    set(handles.BW_inp,'Value',6);
elseif val == 6000
    set(handles.BW_inp,'Value',7);
elseif val == 7000
    set(handles.BW_inp,'Value',8);
elseif val == 8000
    set(handles.BW_inp,'Value',9);
end
%% Set IF type 
val = handles.MySDRplay.IFtype;
if val == -1
    set(handles.IF_inp,'Value',1);
elseif val == 0
    set(handles.IF_inp,'Value',2);
elseif val == 450
    set(handles.IF_inp,'Value',2);
elseif val == 1620
    set(handles.IF_inp,'Value',2);
elseif val == 2048
    set(handles.IF_inp,'Value',2);
end
%% Start timer
handles.timer=timer('ExecutionMode','fixedDelay','Period',.5,'TimerFcn',{@update_display,hObject});
%% Initialize plot
handles.hSpectrum = dsp.SpectrumAnalyzer(...
    'Name',             'SDRplay streaming - Spectrum and Spectrogram',...
    'Title',            'SDRplay streaming - Spectrum and Spectrogram', ...
    'Method',           'Welch', ...
    'ViewType',         'Spectrum and spectrogram',...
    'FrequencySpan',    'Full', ...
    'SpectrumUnits',    'dBm', ...
    'SampleRate',       handles.MySDRplay.SampleRateMHz*1e6, ...
    'FrequencyOffset',  handles.MySDRplay.FrequencyMHz*1e6, ...
    'YLimits',          [-100,100], ...
    'YLabel',           'Absolute Magnitude, dBFS');

% Update handles structure
guidata(hObject, handles);


% UIWAIT makes SDRplay_ex_SpectGUI wait for user response (see UIRESUME)
% uiwait(handles.figure1);

% --- Outputs from this function are returned to the command line.
function varargout = SDRplay_ex_SpectGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

function update_display(hObject,eventdata,hfigure)
% Timer timer1 callback, called each time timer iterates.
% Gets surface Z data, adds noise, and writes it back to surface object.

handles = guidata(hfigure);
data = (handles.MySDRplay.GetPacket);
data = data - mean(data);  % remove DC component
step(handles.hSpectrum, data);
% % data = data(1:end/2);
% % if ~isempty(data)
% %     N_fft=length(data);
% %     fr=(-N_fft/2:N_fft/2-1)*handles.MySDRplay.FrequencyMHz/(N_fft);
% %     data_fft = mag2db(abs(fftshift(fft(real(data)))));
% %     set(handles.plot,'XData',fr+handles.MySDRplay.FrequencyMHz);
% %     set(handles.plot,'YData',data_fft./max(data_fft)-1);
% % end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% CALLBACKS ONLY %%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function GainRed_inp_Callback(hObject, eventdata, handles)
% hObject    handle to GainRed_inp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
input = str2double(hObject.String);
if isnan(input) || fix(input) ~= input
    set(handles.GainRed_inp,'String', num2cell(handles.MySDRplay.GainReduction));
    warning('Please enter integer in gain reduction!');
else
    handles.MySDRplay.GainReduction = input;
end
% Hints: get(hObject,'String') returns contents of GainRed_inp as text
%        str2double(get(hObject,'String')) returns contents of GainRed_inp as a double

function SR_inp_Callback(hObject, eventdata, handles)
% hObject    handle to SR_inp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
input = str2double(hObject.String);
if  isnan(input)
    set(handles.SR_inp,'String', num2cell(handles.MySDRplay.SampleRateMHz));
    warning('Please enter number!');
elseif input < 2 || input >10
    set(handles.SR_inp,'String', num2cell(handles.MySDRplay.SampleRateMHz));
    warning('Input out of range!');
else
    handles.MySDRplay.SampleRateMHz = input;
%     release(handles.hSpectrum);
%     handles.hSpectrum.SampleRate = handles.MySDRplay.SampleRateMHz*1e6;
end
% Hints: get(hObject,'String') returns contents of SR_inp as text
%        str2double(get(hObject,'String')) returns contents of SR_inp as a double

function LNA_inp_Callback(hObject, eventdata, handles)
% hObject    handle to LNA_inp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
input = str2double(hObject.String);
if isnan(input) || fix(input) ~= input
    set(handles.LNAstate,'String', num2cell(handles.MySDRplay.LNAstate));
    warning('Please enter integer in LNA state!');
else
    handles.MySDRplay.LNAstate = input;
end
% Hints: get(hObject,'String') returns contents of LNA_inp as text
%        str2double(get(hObject,'String')) returns contents of LNA_inp as a double

% --- Executes on selection change in BW_inp.
function BW_inp_Callback(hObject, eventdata, handles)
% hObject    handle to BW_inp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
bw = hObject.Value;
if bw == 0
	handles.MySDRplay.BandwidthMHz = 0;
elseif bw == 1
    handles.MySDRplay.BandwidthMHz = 200;
elseif bw ==  2  
    handles.MySDRplay.BandwidthMHz = 300;
elseif bw == 3
    handles.MySDRplay.BandwidthMHz = 600;
elseif bw == 4
    handles.MySDRplay.BandwidthMHz = 1536;
elseif bw == 5
    handles.MySDRplay.BandwidthMHz = 5000;
elseif bw == 6
    handles.MySDRplay.BandwidthMHz = 6000;
elseif bw == 7
    handles.MySDRplay.BandwidthMHz = 7000;
elseif bw == 8
    handles.MySDRplay.BandwidthMHz = 8000;
end
% Hints: contents = cellstr(get(hObject,'String')) returns BW_inp contents as cell array
%        contents{get(hObject,'Value')} returns selected item from BW_inp

% --- Executes on selection change in IF_inp.
function IF_inp_Callback(hObject, eventdata, handles)
% hObject    handle to IF_inp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
ift = hObject.Value;
if ift == 0
	handles.MySDRplay.IFtype = -1;
elseif ift == 1
    handles.MySDRplay.IFtype = 0;
elseif ift ==  2  
    handles.MySDRplay.IFtype = 450;
elseif ift == 3
    handles.MySDRplay.IFtype = 1620;
elseif ift == 3
    handles.MySDRplay.IFtype = 2048;
end
% Hints: contents = cellstr(get(hObject,'String')) returns IF_inp contents as cell array
%        contents{get(hObject,'Value')} returns selected item from IF_inp

% --- Executes on selection change in Port_inp.
function Port_inp_Callback(hObject, eventdata, handles)
% hObject    handle to Port_inp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
port = hObject.Value;
if port == 1
     handles.MySDRplay.Port = 'A';
elseif port == 2
     handles.MySDRplay.Port = 'B';
end
% Hints: contents = cellstr(get(hObject,'String')) returns Port_inp contents as cell array
%        contents{get(hObject,'Value')} returns selected item from Port_inp

% --- Executes on button press in Stream_ctr.
function Stream_ctr_Callback(hObject, eventdata, handles)
if strcmp(hObject.String,'Stream on')
    handles.MySDRplay.Stream
    set(hObject,'String','Stream off');
    start(handles.timer);
elseif strcmp(hObject.String,'Stream off')
    handles.MySDRplay.StopStream
    set(hObject,'String','Stream on');
    stop(handles.timer);
end

% hObject    handle to Stream_ctr (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

function Freq_inp_Callback(hObject, eventdata, handles)
% hObject    handle to Freq_inp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
fc = str2double(hObject.String);
if isnan(fc)
    set(handles.Freq_inp,'String', num2cell(handles.MySDRplay.FrequencyMHz));
    warning('Please enter integer in LNA state!');
elseif fc <= 1e-3 || fc >= 2e3
    set(handles.Freq_inp,'String', num2cell(handles.MySDRplay.FrequencyMHz));
    warning('Frequency is out of range');
else
    handles.MySDRplay.FrequencyMHz = fc;
    handles.hSpectrum.FrequencyOffset = handles.MySDRplay.FrequencyMHz*1e6;
end

% Hints: get(hObject,'String') returns contents of Freq_inp as text
%        str2double(get(hObject,'String')) returns contents of Freq_inp as a double

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Create Fun ONLY %%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% --- Executes during object creation, after setting all properties.
function Port_inp_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Port_inp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function IF_inp_CreateFcn(hObject, eventdata, handles)
% hObject    handle to IF_inp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function BW_inp_CreateFcn(hObject, eventdata, handles)
% hObject    handle to BW_inp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function LNA_inp_CreateFcn(hObject, eventdata, handles)
% hObject    handle to LNA_inp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function SR_inp_CreateFcn(hObject, eventdata, handles)
% hObject    handle to SR_inp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function GainRed_inp_CreateFcn(hObject, eventdata, handles)
% hObject    handle to GainRed_inp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function Freq_inp_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Freq_inp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
stop(handles.timer);
delete(handles.timer);
handles.MySDRplay.StopStream;
handles.MySDRplay.Close;
% Hint: delete(hObject) closes the figure
delete(hObject);
