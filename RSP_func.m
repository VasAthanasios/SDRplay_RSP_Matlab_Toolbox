classdef RSP_func < handle
    % RSP construct RSP object.
    %
    %   The RSP object is a simple wrapper for the RSP1 and RSP2 devices from
    %   SDRplay to receive samples directly from Matlab. It allows uninterrupted 
    %   transfers without storing signals on disk intermediately.
    %
    %   You can access parameters like Frequency, Sample rate, Bandwidth,
    %   etc. For the appropriate settings please look the specifications. 
    %   To enable the stream, run the command Stream. 
    %   To receive, packet simply call the function data.
    %   The internal buffer of the MEX file is set to 2000000, with a cyclic
    %   buffer. So data might overlap. 
    %   The output data can be an integer vector in the range [-127, 127], 
    %   or a single or double vector in the range [-1, 1]. By default, data 
    %   type is double and values are in the range [-1, 1]. Alternatively, 
    %   you can set rxNumericType to 'int16'.
    %
    %   Big thanks to Tillmann Stübler for his work on the HackRF toolbox 
    %   and HUGE thanks to the SDRplay team for their assistance on the API
    %   usage!
    %
    %   For any questions or assistance you can find me at, 
    %   vasathanasios@gmail.com.
    %
    %   Vasileiadis Athanasios, 11 04 2021
    
    properties (SetAccess=private, SetObservable) 
        DevOpen             % Flag if RSP is open.
        DevInfo             % Struct with RSP information.
    end
       
    properties (SetObservable)
        SampleRateMHz       % Set RSP sample rate, 2 - 10 MHz.
        FrequencyMHz        % Set RSP tuner frequency, see specification for details.
        BandwidthKHz        % Set RSP BandwidthKHz, see table for details.
        IFtype              % Set RSP IF to be used, see specification for details.
        LNAstate            % Set RSP LNA state based on Grmode, see specification for details.
        AGC_Enable          % Enable or Disable the RSP AGC
        BiasT_Enable        % Enable of Disable the RSP Bias T
        Notch_Enable        % Enable or Disable the RSP Notch Filter
        DABNotch_Enable     % Enable or Disable the RSP DAB Notch Filter
        PPM_offset
        ExtRef_Enable
        Ant_Contr
        AMPortSelect
        DcOffset
        LoMode
        dcOffsetIQ
        Decimation
        Duo_DualTuner

        StreamInitNumericType = 'double' % Numeric type of RX samples
        PacketData      % RSP data packet dropped here.
    end
    
    methods
        function obj = RSP_func
            Open(obj)
            obj.SampleRateMHz = 6;
            obj.PPM_offset = 0;
            obj.FrequencyMHz = 2000;
            obj.BandwidthKHz = 1536;
            obj.IFtype = 0;
            obj.LNAstate = 0;
            obj.AGC_Enable = false;
        end
        
        %% Get dev info when start
        function Open(obj)
            % Get devices
            [obj.DevInfo.ndev,obj.DevInfo.SerNo,obj.DevInfo.DevNm,obj.DevInfo.hwVer] = RSP_MEX('get_devices');
            if (obj.DevInfo.ndev > 0)
                % If one is availiable open its now open!
                obj.DevOpen = 1;
                if (obj.DevInfo.hwVer == 3)
                    obj.Duo_DualTuner = 1; % Default dual mode
                end
            end
        end
        
        %% Else update Dual Tunner mode
        function set.Duo_DualTuner(obj, mode)
            if (obj.DevInfo.hwVer == 3)
                if (mode == 1 || mode == 0)
                    m = RSP_MEX('update_dualtuner', mode);
                    if (m <= 0)
                        obj.Duo_DualTuner = mode;
                    end
                else
                    warning('Duo_DualTuner accepts only True (1) or False (0). Please see specifications');
                end
            else
                warning('Device selected is not a SDRDuo.');
            end
        end

        %% Else update Sample rate
        function set.SampleRateMHz(obj,fs)
            if (obj.DevInfo.hwVer == 3) 
                if (fs==6) || (fs==8)
                    m = RSP_MEX('update_fs', fs*1e6);
                    if (m <= 0)
                        obj.SampleRateMHz = fs;
                    end
                else
                    warning('SDRDuo in Dual Mode, sample rate can only be 6 or 8 MHz. Please see specifications');
                end
            elseif (fs >= 2 && fs <= 10)
                m = RSP_MEX('update_fs', fs*1e6);
                if (m <= 0)
                    obj.SampleRateMHz = fs;
                end
            else 
                warning('Sample rate not correct. Please see specifications');
            end
        end
        
        %% Else update PPM
        function set.PPM_offset(obj, ppm_val)
            if ppm_val >= -1e5 && ppm_val <= 1e5
                m = RSP_MEX('update_ppm', ppm_val);
                if (m <= 0)
                    obj.PPM_offset = ppm_val;
                end
            else 
                warning('PPM not correct, please see specifications');
            end
        end

        %% Else update BiasTControl
        function set.BiasT_Enable(obj, cond)
            if (cond == 0) || (cond == 1)
                m = RSP_MEX('update_biasT', cond);
                if (m <= 0)
                    obj.BiasT_Enable = cond;
                end
            else 
                warning('BiasT Control is logic condition (0-1), please see specifications');
            end
        end
        
        %% Else update Rf Notch Control
        function set.Notch_Enable(obj, cond)
            if (cond == 0) || (cond == 1)
                m = RSP_MEX('update_rfNotch', cond);
                if (m <= 0)
                    obj.Notch_Enable = cond;
                end
            else 
                warning('BiasT Control is logic condition (0-1), please see specifications');
            end
        end
        
        %% Else update RF DAB Notch Control
        function set.DABNotch_Enable(obj, cond)
            if (cond == 0) || (cond == 1)
                m = RSP_MEX('update_rfDab', cond);
                if (m <= 0)
                    obj.DABNotch_Enable = cond;
                end
            else 
                warning('RF DAB Notch Control is logic condition (0-1), please see specifications');
            end
        end
        
        %% Else update Rsp2 AmPortSelect
        function set.AMPortSelect(obj, cond)
            if (cond == 0) || (cond == 1)
                m = RSP_MEX('update_amPort', cond);
                if (m <= 0)
                    obj.AMPortSelect = cond;
                end
            else 
                warning('AmPortSelect Control is logic condition (0-1), please see specifications');
            end
        end
        
        %% Else update Antenna Control
        function set.Ant_Contr(obj, cond)
            if (cond == 'A') || (cond == 'B')
                if (cond == 'A')
                    m = RSP_MEX('update_antCont', 5);
                else
                    m = RSP_MEX('update_antCont', 6);
                end
                if (m <= 0)
                    obj.Ant_Contr = cond;
                end
            else 
                warning('Antenna Control has two ports (A-B), please see specifications');
            end
        end
        
        %% Else update External Ref Control
        function set.ExtRef_Enable(obj, cond)
            if (cond == 0) || (cond == 1)
                m = RSP_MEX('update_extRefCont', cond);
                if (m <= 0)
                    obj.ExtRef_Enable = cond;
                end
            else 
                warning('External Ref Control is logic condition (0-1), please see specifications');
            end
        end
                
        %% Else update LNA
        function set.LNAstate(obj, lna_val)
            if (lna_val >= 0 && lna_val <= 3) && (obj.DevInfo.hwVer == 1) % RSP1
                m = RSP_MEX('update_lna', lna_val);
                if (m <= 0)
                    obj.LNAstate = lna_val;
                end 
            elseif (lna_val >= 0 && lna_val <= 9) && (obj.DevInfo.hwVer == 255) % RSP1A
                m = RSP_MEX('update_lna', lna_val);
                if (m <= 0)
                    obj.LNAstate = lna_val;
                end 
            elseif (lna_val >= 0 && lna_val <= 8) && (obj.DevInfo.hwVer == 2) % RSP2
                m = RSP_MEX('update_lna', lna_val);
                if (m <= 0)
                    obj.LNAstate = lna_val;
                end 
            elseif (lna_val >= 0 && lna_val <= 9) && (obj.DevInfo.hwVer == 3) % RSPDuo

            else
                warning('LNA state is not correct, please see specifications');  
            end
        end

        %% Else update Fc
        function set.FrequencyMHz(obj, fc)
            if fc >= 1e-3 && fc <= 2e3
                m = RSP_MEX('update_fc', fc*1e6);   
                if (m <= 0)
                    obj.FrequencyMHz = fc;      
                end
            else
                warning('Tuning frequency not correct, please see specifications');
            end
        end
        
        %% Else update BwType
        function set.BandwidthKHz(obj, bw)
            if (obj.DevInfo.hwVer == 3) 
                if (bw==1536) || (bw==200)
                    m = RSP_MEX('update_bwType', bw);
                    if (m <= 0)
                        obj.BandwidthKHz = bw;
                    end
                else
                    warning('SDRDuo in Master/Slave, Bandwidth can only be 200 or 1536 MHz. Please see specifications');
                end
            elseif (bw == 200) || (bw == 300) || (bw == 600) || (bw == 1536) || (bw == 5000) || (bw == 6000) || (bw == 7000) || (bw == 8000) 
                m = RSP_MEX('update_bwType', bw);
                if (m <= 0)
                    obj.BandwidthKHz = bw;
                end
            else
                warning('BandwidthKHz not correct, please see specifications');
            end
        end
        
        %% Else update IfType
        function set.IFtype(obj,ift)
            if (ift == -1) || (ift == 0) || (ift == 450) || (ift == 1620) || (ift == 2048)
                m = RSP_MEX('update_ifType', ift);
                if (m <= 0)
                    obj.IFtype = ift;
                end
            else 
                warning('IF type not correct, please see specifications');
            end
        end
         
        %% Else update DcOffset
        function set.DcOffset(obj, dc_offset)
            if (dc_offset >= 0) && (dc_offset < 6)
                m = RSP_MEX('update_dcOffset', dc_offset);
                if (m <= 0)
                    obj.DcOffset = dc_offset;
                end
            else
                warning('DC offset not correct, please see specifications');
            end
        end
        
        %% Else update LoMode
        function set.LoMode(obj, lo)  
            if (lo == 0) || (lo == 1) || (lo == 2) || (lo == 3) || (lo == 4)
                m = RSP_MEX('update_loMode', lo);
                if (m <= 0)
                    obj.LoMode = lo;
                end
            else 
                warning('LO value not correct, please see specifications');
            end
        end
              
        %% Else update DCoffsetIQimbalance
        function set.dcOffsetIQ(obj, cond)    
            m = RSP_MEX('update_dcOffsetIQ', cond);
            if (m <= 0)
                obj.dcOffsetIQ = cond;
            end
        end
        
        %% Else update Decimation
        function set.Decimation(obj, dec_value)  
            if (dec_value > 0)
                m = RSP_MEX('update_decimation', dec_value);
                if (m <= 0)
                    obj.Decimation = dec_value;
                end
            else
                warning('Decimation must be greater than zero');
            end
        end
        
        %% Else update AGC
        function set.AGC_Enable(obj, agc_val)
            if (agc_val == 0) || (agc_val == 1) || (agc_val == 2) || (agc_val == 3) || (agc_val == 4)
                m = RSP_MEX('update_agc', agc_val);
                if (m <= 0)
                    obj.AGC_Enable = agc_val;
                end
           else 
                warning('AGC value not correct, please see specifications');
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
            m = RSP_MEX('init_stream');
            if (m > 0)
                 Warning('Stream could not be initialised, please check the parameters and and try again!');
            end
        end

        %% Get packet 
        function [dataA_out, dataB_out] = GetPacket(obj)
            [dataA, dataB] = RSP_MEX('data');
            if ~isempty(dataA)
                dataA_out=cast(dataA,obj.StreamInitNumericType);
                if ismember(obj.StreamInitNumericType,{'single' 'double'})
                    dataA_out = dataA_out - mean(dataA_out);
                    dataA_out=dataA_out./16383.5;
                end
            end
            if ~isempty(dataB)
                dataB_out=cast(dataB,obj.StreamInitNumericType);
                if ismember(obj.StreamInitNumericType,{'single' 'double'})
                    dataB_out = dataB_out - mean(dataB_out);
                    dataB_out=dataB_out./16383.5;
                end
            end
        end
        
        %% Get packet Duo
        function [dataA_out, dataB_out] = GetPacketDuo(obj)
            [dataA, dataB] = RSP_MEX('data');
            if ~isempty(dataA)
                dataA_out=cast(dataA,obj.StreamInitNumericType);
                if ismember(obj.StreamInitNumericType,{'single' 'double'})
                    dataA_out = dataA_out - mean(dataA_out);
                    dataA_out=dataA_out./16383.5;
                end
            end
            if ~isempty(dataB)
                dataB_out=cast(dataB,obj.StreamInitNumericType);
                if ismember(obj.StreamInitNumericType,{'single' 'double'})
                    dataB_out = dataB_out - mean(dataB_out);
                    dataB_out=dataB_out./16383.5;
                end
            end
        end

        %% Close RSP device
        function Close(obj)
            if obj.DevOpen
                RSP_MEX('close');
                obj.DevOpen = 0;
            else
                warning('RSP device is not open.');
            end
        end    
        
        %% Stop Stream
        function StopStream(obj)
            RSP_MEX('uninit_stream');
        end
    end
end