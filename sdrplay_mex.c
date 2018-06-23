#include "mex.h"
#include <windows.h>
#include <stdlib.h>
#include <stdio.h>
#include <conio.h>
#include "mir_sdr.h"
#include "math.h"

#define buflen 1000000

static short buf_i[buflen];
static short buf_q[buflen];

static char is_rspii_open = 0;
static char is_rspii_streamin = 0;

void *closedevice(void)
{
	if(is_rspii_streamin) 
	{			
		mexPrintf("SDRplay stream off... \n");
		mir_sdr_StreamUninit();
		is_rspii_streamin = 0;
	}
	if(is_rspii_open) 
	{
		mexPrintf("SDRplay closing... =^(\n");
        mir_sdr_ReleaseDeviceIdx();
		is_rspii_open = 0;
    }
}

void grCallback(unsigned int gRdB, unsigned int lnaGRdB, void *cbContext)
{
   return;
}

void myCallback(short *xi, short *xq, unsigned int firstSampleNum, int grChanged, int rfChanged, int fsChanged, unsigned int numSamples, unsigned int reset, unsigned int hwRemoved, void *cbContext)
{
	unsigned int i = 0;
	for(i = 0; i < numSamples; i++) 
	{
		buf_i[(firstSampleNum+i)%buflen] = xi[i];
		buf_q[(firstSampleNum+i)%buflen] = xq[i];
    }
	return;
}

mxArray * getdata(void)
{
    mxArray * p;
    short	 *x,*y;
    unsigned int i;
	
    p=mxCreateNumericMatrix(buflen,1,mxINT16_CLASS,mxCOMPLEX);
    x=mxGetData(p);
    y=mxGetImagData(p);
    
    for(i = 0; i < buflen; i++) 
	{	
		x[i]=buf_i[i];
		y[i]=buf_q[i];
	}
    return p;
}

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]){

	char cmd[32];
   
    mexAtExit(closedevice);
	
	// if one input! 
	if(nrhs>0) 
	{   mxGetString(prhs[0],cmd,32); //read command
		// If Get devices
		if(strcmp("get_devices",cmd)==0) 
		{
			if(nlhs>0)
			{
				mir_sdr_DeviceT devs[4];
				unsigned int ndev; 
	
				if(mir_sdr_GetDevices(&devs[0], &ndev, 4)!=0) { mexErrMsgTxt("Error in mir_sdr_GetDevices()"); }
				plhs[0] = mxCreateDoubleScalar(ndev);
				plhs[1] = mxCreateString(devs -> SerNo);
				plhs[2] = mxCreateString(devs -> DevNm);
				plhs[3] = mxCreateDoubleScalar(devs -> hwVer);
				plhs[4] = mxCreateDoubleScalar(devs -> devAvail);
			}
		}
		// if else cmd is open
		else if(strcmp(cmd,"set_device")==0) 
		{   
			if(mir_sdr_SetDeviceIdx(0)!=0) { mir_sdr_SetDeviceIdx("Error in mir_sdr_SetDeviceIdx()"); }
			mexPrintf("SDRplay device selected!\n");
			is_rspii_open=1;   
		}		
		// else initalize stream
		else if(strcmp("initstream",cmd)==0) 
		{
			// Init some variables
			mir_sdr_ErrT msg;
			int sampsPerPkt;
			int sysgr;
			// Get the gain reduction
			int gr;
			gr = mxGetScalar(prhs[1]);
			// get the sample rate
			double fs;
			fs = mxGetScalar(prhs[2]);
			// get the frequency
			double fc; 
			fc = mxGetScalar(prhs[3]);
			// get the bandwidth
			mir_sdr_Bw_MHzT bwType;
			bwType = mxGetScalar(prhs[4]);
			// get the IF
			mir_sdr_If_kHzT ifType;
			ifType = mxGetScalar(prhs[5]);
			// get the rspLNA
			int rspLNA;
			rspLNA = mxGetScalar(prhs[6]);
			// get the gain reduction mode
			mir_sdr_SetGrModeT grMode;
			grMode = mxGetScalar(prhs[7]);
			// start the stream finally
			msg = mir_sdr_StreamInit(&gr, fs, fc, bwType, ifType, rspLNA, &sysgr, grMode, &sampsPerPkt, myCallback, grCallback, NULL);
			if (msg == 0) {mexPrintf("SDRplay stream initiated successfully!\n"); is_rspii_streamin = 1; plhs[0]=mxCreateDoubleScalar(0);}
			else if (msg == 1) {mexPrintf("Other failure mechanism...\n"); plhs[0]=mxCreateDoubleScalar(1);}
			else if (msg == 2) {mexPrintf("Invalid parameters...\n"); plhs[0]=mxCreateDoubleScalar(2);}
			else if (msg == 3) {mexPrintf("Stream initialisation out of range...\n"); plhs[0]=mxCreateDoubleScalar(3);}
			else if (msg == 7) {mexPrintf("Failed to access the device...\n"); plhs[0]=mxCreateDoubleScalar(7);}
			else if (msg == 9) {mexPrintf("SDRplay already initialized...\n"); plhs[0]=mxCreateDoubleScalar(9);}
		}
		// else initalize stream
		else if(strcmp("reinitstream",cmd)==0) 
		{
			// Init some variables
			mir_sdr_ErrT msg;
			int sampsPerPkt;
			int sysgr;
			// Get the gain reduction
			int gr;
			gr = mxGetScalar(prhs[1]);
			// get the sample rate
			double fs;
			fs = mxGetScalar(prhs[2]);
			// get the frequency
			double fc; 
			fc = mxGetScalar(prhs[3]);
			// get the bandwidth
			mir_sdr_Bw_MHzT bwType;
			bwType = mxGetScalar(prhs[4]);
			// get the IF
			mir_sdr_If_kHzT ifType;
			ifType = mxGetScalar(prhs[5]);
			// get the LoMode
			mir_sdr_LoModeT loMode;
			loMode = mxGetScalar(prhs[6]);
			// get the rspLNA
			int rspLNA;
			rspLNA = mxGetScalar(prhs[7]);
			// get the gain reduction mode
			mir_sdr_SetGrModeT grMode;
			grMode = mxGetScalar(prhs[8]);
			// get the reason for reinit
			mir_sdr_ReasonForReinitT reasonForReinit;
			reasonForReinit = mxGetScalar(prhs[9]);
			// reinit the stream finally
			msg = mir_sdr_Reinit(&gr, fs, fc, bwType, ifType, loMode, rspLNA, &sysgr, grMode, &sampsPerPkt, reasonForReinit);
			if (msg == 0) {mexPrintf("SDRplay stream reinitiated successfully!\n"); is_rspii_streamin = 1; plhs[0]=mxCreateDoubleScalar(0);}
			else if (msg == 1) {mexPrintf("Other failure mechanism...\n"); }
			else if (msg == 2) {mexPrintf("Invalid parameters...\n"); }
			else if (msg == 3) {mexPrintf("Stream reinitialisation out of range...\n"); }
			else if (msg == 7) {mexPrintf("Failed to access the device...\n"); }
			else if (msg == 8) {mexPrintf("Requested parameters can cause aliasing...\n"); }
		}		
		// else if Data
        else if(strcmp("data",cmd)==0)
		{	
			plhs[0]=getdata(); 
        } 
		// else if Port
		else if(strcmp("port",cmd)==0)
		{
			mir_sdr_RSPII_AntennaSelectT port;
			port = mxGetScalar(prhs[1]);
			if (mir_sdr_RSPII_AntennaControl(port) == 0); {mexPrintf("SDRplay port successfully selected!\n");}
		}
		// else if Stop
		else if(strcmp("streamunint",cmd)==0) 
		{   
			mir_sdr_StreamUninit();
			is_rspii_streamin = 0;
			mexPrintf("SDRplay stream off... \n");
        } 
		// else if Close
		else if(strcmp("close",cmd)==0) 
		{   
			mir_sdr_ReleaseDeviceIdx();
            is_rspii_open=0;
			mexPrintf("SDRplay closing... =^(\n");
        } 	
		// else wtf u talking about?
		else {	mexPrintf("Unknown command: %s\n",cmd);	}
    // Else wrong input bruh    
    } 
	else 
	{
        mexErrMsgTxt("Wrong number of input/output arguments.");
    }
}


                                       