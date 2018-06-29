# Warning

This toolbox contains a precompiled x64 bit MEX. **You need to install the SDRplay_RSP_API-Windows-2.11.1.exe drivers first.**

If you you have an issue running the MEX or you have x86 bit version follow these steps:

    1. Copy paste the .dll and .lib from \dll_lib\x86 in the same folder.
    2. Compile the C/MEX file in Matlab with the following command, "mex sdrplay_mex.c mir_sdr_api.lib"

Latest .dll and .lib version can be found at https://www.sdrplay.com/downloads/. **Drivers after 2.11.1 are not compatible with this code.**

# Information

The SDRplay MEX/class is a simple wrapper for the SDRplay library to receive directly from Matlab. It allows uninterrupted transfers without storing signals on disk intermediately.

You can access parameters like Frequency, Sample rate, Bandwidth, and Gain reduction settings. For the appropriate settings please look at the specifications. To enable the stream, run the command Stream. To receive a packet of data when you want to use callback function: GetPacket. The timer is set to dump complex data every 0.25s. The internal buffer of the MEX file is set to 2000000, so depending on your sample rate you can access data periodically. The output data can be an integer vector in the range [-127, 127], or a single or double vector in the range [-1, 1]. By default, the data type is double and values are in the range [-1, 1]. Alternatively, you can set rxNumericType to 'int16'.

The class "sdrplay.m" is used with the compiled MEX "sdrplay_mex" to communicate with a single RSP2.

The file "sdrplay_mex.c" contains C/MEX code that enables the communication between Matlab and the RSP2. This version of C/MEX contains an overlapping buffer. When the buffer is full, it starts writing samples at the start, overwriting the previous samples. A circular buffer will be implemented in the future!
I have also included two spectral analysis examples, using the Communication System Toolbox.

"SDRplay_ex_SpectGUI" is a simple GUIDE which can be used interactively to look at the spectrum.

"SDRplay_ex_SpectrumAnalyzer.m" is a simple .m file which shows how the Class/MEX can be used from Matlab's editor.

Features to be implemented in the future if requested!
-- Control of Gain Mode
-- Control of Lo Mode
-- Control of Ppm
-- Control of DC offset IQ imbalance
-- AGC Selection
-- BiasT Selection
-- AM port Selection
-- RF notch Selection

HUGE thanks to the SDRplay team for their assistance on the API usage!

Big thanks to Tillmann Stübler for his work on the HackRF toolbox.

For any questions or assistance, you can find me at,

avasileiadis1@sheffield.ac.uk
