classdef sdrplay < handle
    % SDRPLAY construct sdrplay object.
    %
    %   The sdrplay object is a simple wrapper for the sdrplay library to
    %   receive directly from Matlab. It allows uninterrupted transfers 
    %   without storing signals on disk intermediately.
    %
    %   You can access parameters like Frequency, Sample rate, Bandwidth,
    %   and Gain reduction settings. For the appropriate settings please 
    %   look the specifications. To enable the stream, run the command Stream. 
    %   To receive, packet on command you need to provide callback function: 
    %   GetPacket. The timer is set to dump complex data every 0.25s.
    %   The internal buffer of the MEX file is set to 2000000, so depending 
    %   on your sample rate you can access data periodically. The output data
    %   can be an integer vector in the range [-127, 127], or a single or 
    %   double vector in the range [-1, 1]. By default, data type is double 
    %   and values are in the range [-1, 1]. Alternatively, you can set 
    %   rxNumericType to 'int16'.
    %
    %   Things to be implented in the future, if requested!
    %   Control of Gain Mode
    %   Control of Lo Mode
    %   Control of Ppm
    %   Control of DC offset IQ imbalance
    %   AGC Selection
    %   BiasT Selection 
    %   AM port Selection
    %   RF notch Selection
    %
    %   Big thanks to Tillmann Stübler for his work on the HackRF toolbox 
    %   and HUGE thanks to the SDRplay team for their assistance on the API
    %   usage!
    %
    %   For any questions or assistance you can find me at, 
    %   vasathanasios@gmail.com.
    %
    %   Vasileiadis Athanasios, 08 06 2018
    
    properties (SetObservable, SetAccess=private) 
        DevOpen             % Flag if SDRplay is open.
        DevInfo             % Struct with SDRplay information.
        StreamInit = false  % Flag if stream is initiated 
    end
        
    properties (SetObservable)
        GainReduction   % Set SDRplay gain reduction, based on specification table.
        SampleRateMHz   % Set SDRplay sample rate, 2 - 10 MHz.
        FrequencyMHz    % Set SDRplay tuner frequency, see specification for details.
        BandwidthMHz    % Set SDRplay BandwidthMHz, see table for details.
        IFtype          % Set SDRplay IF to be used, see specification for details.
        LNAstate        % Set SDRplay LNA state based on Grmode, see specification for details.
        StreamInitNumericType='double' % Numeric type of RX samples
        PacketData      % SDRplay data packet dropped here.
        Port            % SDRplay port selection, A (default) or B.
    end
    
    properties (GetAccess=public, SetAccess=private)
        GrMode          % Set SDRplay gain mode 0 - 2, see specification for details.
    end
    
    properties (Access=private)
        trxtimer            % Timer to execute rx/tx callback functions
    end
    
    methods
        function obj=sdrplay
            obj.trxtimer=timer('ExecutionMode','fixedDelay','Period',.25,'TimerFcn',@(~,~)obj.trxcallback);
            Open(obj)
            obj.GainReduction = 50;     % Set SDRplay gain reduction, based on specification table.
            obj.SampleRateMHz = 4;      % Set SDRplay sample rate, 2 - 10 MHz.
            obj.FrequencyMHz = 869;     % Set SDRplay tuner frequency, see specification for details.
            obj.BandwidthMHz = 600;     % Set SDRplay BandwidthMHz, see table for details.
            obj.IFtype = 0;             % Set SDRplay IF to be used, see specification for details.
            obj.LNAstate = 0;           % Set SDRplay LNA state based on Grmode, see specification for details.
            obj.Port = 'A';        % Set SDRplay Port, A (default) or B.
            obj.GrMode = 2;             % Set SDRplay gain mode 0 - 2, see specification for details.
        end
        %% Get dev info when start
        function Open(obj)
            % Get devices
            [obj.DevInfo.ndev,obj.DevInfo.SerNo,obj.DevInfo.DevNm,obj.DevInfo.hwVer,obj.DevInfo.DevAvail]=sdrplay_mex('get_devices');
            if (obj.DevInfo.ndev > 0)
                % If at least one is availiable open it!
                sdrplay_mex('set_device');
                obj.DevOpen = 1;
            end
        end
        %% GainReduction
        function set.GainReduction(obj,g)
            obj.GainReduction = g;
            if obj.StreamInit == true
                obj.ReInit('GR');
            end
        end
        %% LNAstate
        function set.LNAstate(obj,g)
            obj.LNAstate = g;
            if obj.StreamInit == true
                obj.ReInit('GR');
            end
        end
        %% SampleRateMHz
        function set.SampleRateMHz(obj,fs)
            if fs >= 2 && fs <= 10
                obj.SampleRateMHz = fs; ok = 1;
            else 
                warning('Sample rate not correct, please see specifications');
            end
            if obj.StreamInit == true && ok == 1
               obj.ReInit('FS');
            end
        end
        %% FrequencyMHz
        function set.FrequencyMHz(obj,fc)
            if fc >= 1e-3 && fc <= 2e3
            	obj.FrequencyMHz = fc;  ok = 1;
            else
                warning('Tuning frequency not correct, please see specifications');
            end
            if obj.StreamInit == true && ok == 1
                obj.ReInit('RF');
            end
        end
        %% BandwidthMHz
        function set.BandwidthMHz(obj,bw)
            if bw == 200
                obj.BandwidthMHz = bw; ok = 1;
            elseif bw ==  300  
                obj.BandwidthMHz = bw; ok = 1;
            elseif bw == 600
                obj.BandwidthMHz = bw; ok = 1;
            elseif bw == 1536
                obj.BandwidthMHz = bw; ok = 1;
            elseif bw == 5000
                obj.BandwidthMHz = bw; ok = 1;
            elseif bw == 6000
                obj.BandwidthMHz = bw; ok = 1;
            elseif bw == 7000
                obj.BandwidthMHz = bw; ok = 1;
            elseif bw == 8000
                obj.BandwidthMHz = bw; ok = 1;
            else
                warning('Bandwidth not correct, please see specifications');
            end
            if (obj.StreamInit == true &&  ok == 1)
               obj.ReInit('BW');
            end
        end
        %% IFtype
        function set.IFtype(obj,ift)
            if ift == -1
                obj.IFtype = ift; ok = 1;
            elseif ift == 0
                obj.IFtype = ift; ok = 1;
            elseif ift == 450
                obj.IFtype = ift; ok = 1;
            elseif ift == 1620
                obj.IFtype = ift; ok = 1;
            elseif ift == 2048
                obj.IFtype = ift; ok = 1;
            else 
                warning('IF type not correct, please see specifications');
            end
            if (obj.StreamInit == true &&  ok == 1)
                obj.ReInit('IF');
            end
        end
        %% Port
        function set.Port(obj,p)
            if p == 'A' || p == 'a'
                obj.Port = 'A';
                sdrplay_mex('port',5);
            elseif p == 'B' || p == 'b'
                obj.Port = 'B';
                sdrplay_mex('port',6);
            else
                warning('Port input not correct, please see specifications');
            end
        end
        %% Output Type
        function set.StreamInitNumericType(obj,t)
            if ~isnumerictype(t)
                error('''%s'' is not supported.\nIt would make sense to chose either ''double'', ''single'', or ''int8''.',t);
            end
            obj.StreamInitNumericType=t;
        end
        %% Initializes Stream
        function Stream(obj)
            m = sdrplay_mex('initstream',obj.GainReduction, obj.SampleRateMHz, obj.FrequencyMHz, ...
                                     obj.BandwidthMHz, obj.IFtype, obj.LNAstate, obj.GrMode);
            if (m == 0)
                obj.StreamInit=true;
                start(obj.trxtimer);
            end
        end
        %% Reinitalisation of the stram ... needs a reason!
        function ReInit(obj,reason)
           r = 0;
           reason = upper(reason);
           if reason == 'GR'
               r = 1;
           elseif reason == 'FS'
               r = 2;
           elseif reason == 'RF'
               r = 4;
           elseif reason == 'BW'
               r = 8;
           elseif reason == 'IF'
               r = 10;
           end
           if r ~= 0
               m = sdrplay_mex('reinitstream',obj.GainReduction, obj.SampleRateMHz, obj.FrequencyMHz, ...
                                              obj.BandwidthMHz, obj.IFtype, 0, obj.LNAstate, obj.GrMode, r);
               if m ~= 0
                    Warning('Wrong input, please see specifications and try again!');
               end
           end
        end
        %% Get packet 
        function data = GetPacket(obj)
            if obj.StreamInit
                data = sdrplay_mex('data');
                if ~isempty(data)
                    data=cast(data,obj.StreamInitNumericType);
                    if ismember(obj.StreamInitNumericType,{'single' 'double'})
                        data = data - mean(data);
                        data=data./16383.5;
                    end
                end
            else
                warning('SDRplay device not streaming!');
            end
        end
        %% Close SDRplay device
        function Close(obj)
            if obj.DevOpen
                sdrplay_mex('close');
                obj.DevOpen = 0;
                obj.StreamInit = 0;
            else
                warning('SDRplay device is not open.');
            end
        end            
        %% Stop Stream
        function StopStream(obj)
            if obj.StreamInit
                sdrplay_mex('streamunint');
                obj.StreamInit=false;
            end
        end
        %% Delete object
        function delete(obj)
            stop(obj.trxtimer);
            delete(obj.trxtimer);
            obj.DevOpen = 0;
            close(obj);
        end
    end
    
    methods (Access=private)
        function trxcallback(obj)
            % call the user-supplied rx function
            if obj.StreamInit
                z=sdrplay_mex('data');
                if ~isempty(z)
                    z=cast(z,obj.StreamInitNumericType);
                    if ismember(obj.StreamInitNumericType,{'single' 'double'})
                        z = z - mean(z);
                        z= z./16383.5;
                    end
                    obj.PacketData = z;
                end
            else
                stop(obj.trxtimer);
            end
            
        end
        
    end
end