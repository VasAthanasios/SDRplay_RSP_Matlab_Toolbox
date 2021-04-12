# Required steps before you are ready!
There are some steps that you need to do in each machine to get the toolbox up and running.

  1. Download the API 3.07 from the official SDRplay website. [https://www.sdrplay.com/downloads/](https://www.sdrplay.com/downloads/)
  2. Install the API in the default location. (This is necessary as the default library paths are coded in the MEX/C file)
  3. Add the .dll/.lib path in the in the Windows Environment variables. (e.g. "C:\Program Files\SDRplay\API\x64" for 64 bit system)
  4. Run the "Build_MEX.m" file to create the MEX file which enables communication between Matlab and the RSP.
  5. You can now run the "Example.m" without any issue.

# How does it work?
Please take a look at the example. 

Line 4, attempts to connect to the first RSP device that is plugged in. You can open up the structure and look at the variables your self.

Lines 6-10, show you how to changes the RSP device parameters. You can  tune Sample Rate, Frequency, Bandwidth, and more! You can see all of them inside the structure.

Line 13, starts the stream.

Lines 15-32, create a Spectrum Analyzer and plots data every 0.25s (which is the time that the buffer takes to load)

Lines 34-36, stops the stream and closes the device. 

# What has changed?
Apart from the bug fixes that are posted in the SDRplay Specification .pdf one small improvement that I added was the ability to run code without requiring .dll/.lib 
in the same folder. Thats the purpose of step (3) above. By including the Windows Path step Matlab by default can find the .dll/.lib in their default location.
The RSP_func file is still required though!

# Does it support all RSP devices?
Unfortunately, no. The development was done with a RSP1A device, but I have included support for other devices as well as there are a few differences between them.

| Supported devices | Comments     | Unsupported devices  |
| ------------------|:------------:| --------------------:|
| RSP1A             | Tested       | RSPdX                |
| RSP1              | Untested     | RSPduo               |
| RSP2              | Untested     |                      |
| RSP2pro           | Untested     |                      |

If you use a device that I have marked as untested and it works without any issues please let me know and I will mark it as untested.
If it does not work as expected, please keep reading.

# What if I run into some issues?
Do not panic. Submit an issue right here at Github, or contact me at [vasathanasios@gmail.com](vasathanasios@gmail.com).

HUGE thanks to the SDRplay team for their assistance on the API usage!

Finally, big thanks to Tillmann Stübler for his work on the HackRF toolbox.
