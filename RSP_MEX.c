#include "mex.h"
#include <windows.h>
#include <stdio.h>
#include <conio.h>
#include "math.h"

#include "C:\Program Files\SDRplay\API\inc\sdrplay_api.h"

#define buflen 2000000

static short buf_i[buflen];
static short buf_q[buflen];

sdrplay_api_DeviceT chosenDevice;
sdrplay_api_DeviceParamsT *deviceParams = NULL;
sdrplay_api_RxChannelParamsT *chParams = NULL;
sdrplay_api_CallbackFnsT cbFns;
sdrplay_api_ErrT err;
int Device_Streaming = 0;

void StreamACallback(short *xi, short *xq, sdrplay_api_StreamCbParamsT *params, unsigned int numSamples, unsigned int reset, void *cbContext) {
    unsigned int i = 0;
	for(i = 0; i < numSamples; i++) 
	{
		buf_i[(params -> firstSampleNum+i)%buflen] = xi[i];
		buf_q[(params -> firstSampleNum+i)%buflen] = xq[i];
    }
	return;
}

void StreamBCallback(short* xi, short* xq, sdrplay_api_StreamCbParamsT* params, unsigned int numSamples, unsigned int reset, void* cbContext) {
	return;
}

mxArray * getdata(void) {
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

void EventCallback(sdrplay_api_EventT eventId, sdrplay_api_TunerSelectT tuner, sdrplay_api_EventParamsT *params, void *cbContext) {
   
}

// Close API
void Close_API(void){
    sdrplay_api_Close();
	printf("API Close\n");
}

// Open API
void Open_API(void){
    sdrplay_api_ErrT err;
    float ver = 0.0;
    if ((err = sdrplay_api_Open()) != sdrplay_api_Success) {
        printf("sdrplay_api_Open failed %s\n", sdrplay_api_GetErrorString(err));
    }
    else  
    {   // Check API versions match
        if ((err = sdrplay_api_ApiVersion(&ver)) != sdrplay_api_Success)    {
            printf("sdrplay_api_ApiVersion failed %s\n", sdrplay_api_GetErrorString(err));
        }
        if (ver != SDRPLAY_API_VERSION) {
            printf("API version don't match (local=%.2f dll=%.2f)\n", SDRPLAY_API_VERSION, ver);
            Close_API();
        }
    }
	printf("API Open\n");
}

void Print_UpdateMSG(sdrplay_api_ErrT err) {
	if (err == 1) { mexPrintf("Command Failed...\n"); }
	else if (err == 2) { mexPrintf("NULL pointer or invalid operating mode...\n"); }
	else if (err == 3) { mexPrintf("One or more parameters are set incorrectly...\n"); }
	else if (err == 7) { mexPrintf("HW error occured during tuner initialisation...\n"); }
	else if (err == 8) { mexPrintf("Failed to update sample rate...\n"); }
	else if (err == 9) { mexPrintf("Failed to update Rf frequency...\n"); }
	else if (err == 10) { mexPrintf("Failed to update gain...\n"); }
	else if (err == 11) { mexPrintf("Feature not enabled...\n"); }
	else if (err == 12) { mexPrintf("Communication channel with service broken...\n"); }
	else { mexPrintf("Successful completion!\n"); }

}

static void closedevice(void)
{
	if (Device_Streaming)
	{
		if ((err = sdrplay_api_Uninit(chosenDevice.dev)) != sdrplay_api_Success) {
			printf("sdrplay_api_Uninit failed %s\n", sdrplay_api_GetErrorString(err));
		}
		else {
			Device_Streaming = 0;
			printf("Stream Uninitialised!\n");
		}
	}
	if (deviceParams != NULL)
	{
		if ((err = sdrplay_api_ReleaseDevice(&chosenDevice)) != sdrplay_api_Success) {
			printf("sdrplay_api_ReleaseDevice failed %s\n", sdrplay_api_GetErrorString(err));
		}
		else {
			printf("Device Released!\n");
			deviceParams == NULL;
		}
	}
	Close_API();
}

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]){
    
    mexAtExit(closedevice);
    // if one input! 
    if(nrhs>0) { 
        // SDRplay API variables
        int i = 0;

        // Read command
        char cmd[32];
        mxGetString(prhs[0], cmd,32); 

        // If get Devices
		if(strcmp("get_devices", cmd)==0) {
			// Open API
            Open_API();

			// Variables for get_devices
			sdrplay_api_DeviceT devs[6];
			unsigned int ndev;
			unsigned int chosenIdx = 0;

             // Lock API while device selection is performed
            sdrplay_api_LockDeviceApi();
			
            // Fetch list of available devices         
            if ((err = sdrplay_api_GetDevices(devs, &ndev, sizeof(devs) / sizeof(sdrplay_api_DeviceT))) != sdrplay_api_Success) {
                printf("sdrplay_api_GetDevices failed %s\n", sdrplay_api_GetErrorString(err));
            }
            
            printf("MaxDevs=%d NumDevs=%d\n", sizeof(devs) / sizeof(sdrplay_api_DeviceT), ndev);
            if (ndev > 0) {
                for (i = 0; i < (int)ndev; i++) {
                    if (devs[i].hwVer != SDRPLAY_RSPduo_ID || devs[i].hwVer != SDRPLAY_RSPdx_ID) {
                        chosenIdx = i;
                        break;
                    }
                }
            }
            else {
                Close_API();
                mexErrMsgTxt ("Couldn't find a suitable device to open - exiting\n");
            }
            chosenDevice = devs[chosenIdx];
            printf("chosenDevice = %p\n", chosenDevice.dev);

            // Select chosen device
            if ((err = sdrplay_api_SelectDevice(&chosenDevice)) != sdrplay_api_Success) {
                printf("sdrplay_api_SelectDevice failed %s\n", sdrplay_api_GetErrorString(err));
            }
            
            // Unlock Device
            sdrplay_api_UnlockDeviceApi();
            
			// Enable debug
            if ((err = sdrplay_api_DebugEnable(chosenDevice.dev, sdrplay_api_DbgLvl_Verbose)) != sdrplay_api_Success) {
                printf("sdrplay_api_DebugEnable failed %s\n", sdrplay_api_GetErrorString(err));
            }
			
            // Get Devices Params
            if ((err = sdrplay_api_GetDeviceParams(chosenDevice.dev, &deviceParams)) != sdrplay_api_Success) {
                printf("sdrplay_api_GetDeviceParams failed %s\n",
                sdrplay_api_GetErrorString(err));
            }

            // Return to Matlab
            printf("RSP1A device successfully selected\n");    
            plhs[0] = mxCreateDoubleScalar(ndev);
            plhs[1] = mxCreateString(chosenDevice.SerNo);
            plhs[2] = mxCreateString(chosenDevice.dev);
            plhs[3] = mxCreateDoubleScalar(chosenDevice.hwVer);
        }
		
		// Else update Sample rate
		else if (strcmp("update_fs", cmd) == 0) {
			deviceParams->devParams->fsFreq.fsHz = mxGetScalar(prhs[1]);
			if (Device_Streaming == 1) {
				if ((err = sdrplay_api_Update(chosenDevice.dev, chosenDevice.tuner,
					sdrplay_api_Update_Dev_Fs, sdrplay_api_Update_Ext1_None)) != sdrplay_api_Success) {
					Print_UpdateMSG(err);
				}
				plhs[0] = mxCreateDoubleScalar(err);
			}
			else {plhs[0]=mxCreateDoubleScalar(-1);}
		}

		// Else update PPM
		else if (strcmp("update_ppm", cmd) == 0) {
			deviceParams->devParams->ppm = mxGetScalar(prhs[1]);
			if (Device_Streaming == 1) {
				if ((err = sdrplay_api_Update(chosenDevice.dev, chosenDevice.tuner,
					sdrplay_api_Update_Dev_Ppm, sdrplay_api_Update_Ext1_None)) != sdrplay_api_Success) {
					Print_UpdateMSG(err);
				}
				plhs[0] = mxCreateDoubleScalar(err);
			}
			else {plhs[0]=mxCreateDoubleScalar(-1);}
		}

		// Else update BiasTControl
		else if (strcmp("update_biasT", cmd) == 0) {
			if (chosenDevice.hwVer == SDRPLAY_RSP1A_ID || chosenDevice.hwVer == SDRPLAY_RSP1_ID){
				deviceParams->rxChannelA->rsp1aTunerParams.biasTEnable = mxGetScalar(prhs[1]);
				if (Device_Streaming == 1) {
					if ((err = sdrplay_api_Update(chosenDevice.dev, chosenDevice.tuner,
						sdrplay_api_Update_Rsp1a_BiasTControl, sdrplay_api_Update_Ext1_None)) != sdrplay_api_Success) {
						Print_UpdateMSG(err);
					}
					plhs[0] = mxCreateDoubleScalar(err);
				}
				else {plhs[0]=mxCreateDoubleScalar(-1);}
			}
			else if (chosenDevice.hwVer == SDRPLAY_RSP2_ID) {
				deviceParams->rxChannelA->rsp2TunerParams.biasTEnable = mxGetScalar(prhs[1]);
				if (Device_Streaming == 1) {
					if ((err = sdrplay_api_Update(chosenDevice.dev, chosenDevice.tuner,
						sdrplay_api_Update_Rsp2_BiasTControl, sdrplay_api_Update_Ext1_None)) != sdrplay_api_Success) {
						Print_UpdateMSG(err);
					}
					plhs[0] = mxCreateDoubleScalar(err);
				}
				else {plhs[0]=mxCreateDoubleScalar(-1);}
			}
		}

		// Else update RfNotchControl
		else if (strcmp("update_rfNotch", cmd) == 0) {
			if (chosenDevice.hwVer == SDRPLAY_RSP1A_ID || chosenDevice.hwVer == SDRPLAY_RSP1_ID) {
				deviceParams->devParams->rsp1aParams.rfNotchEnable = mxGetScalar(prhs[1]);
				if (Device_Streaming == 1) {
					if ((err = sdrplay_api_Update(chosenDevice.dev, chosenDevice.tuner,
						sdrplay_api_Update_Rsp1a_RfNotchControl, sdrplay_api_Update_Ext1_None)) != sdrplay_api_Success) {
						Print_UpdateMSG(err);
					}
					plhs[0] = mxCreateDoubleScalar(err);
				}
				else {plhs[0]=mxCreateDoubleScalar(-1);}
			}
			else if (chosenDevice.hwVer == SDRPLAY_RSP2_ID) {
				deviceParams->rxChannelA->rsp2TunerParams.rfNotchEnable = mxGetScalar(prhs[1]);
				if (Device_Streaming == 1) {
					if ((err = sdrplay_api_Update(chosenDevice.dev, chosenDevice.tuner,
						sdrplay_api_Update_Rsp2_BiasTControl, sdrplay_api_Update_Ext1_None)) != sdrplay_api_Success) {
						Print_UpdateMSG(err);
					}
					plhs[0] = mxCreateDoubleScalar(err);
				}
				else {plhs[0]=mxCreateDoubleScalar(-1);}
			}
		}

		// Else update RfDabNotchControl
		else if (strcmp("update_rfDab", cmd) == 0) {
			deviceParams->devParams->rsp1aParams.rfDabNotchEnable = mxGetScalar(prhs[1]);
			if (Device_Streaming == 1) {
				if ((err = sdrplay_api_Update(chosenDevice.dev, chosenDevice.tuner,
					sdrplay_api_Update_Rsp1a_RfDabNotchControl, sdrplay_api_Update_Ext1_None)) != sdrplay_api_Success) {
					Print_UpdateMSG(err);
				}
				plhs[0] = mxCreateDoubleScalar(err);
			}
			else {plhs[0]=mxCreateDoubleScalar(-1);}
		}

		// Else update Rsp2 AmPortSelect
		else if (strcmp("update_amPort", cmd) == 0) {
			deviceParams->rxChannelA->rsp2TunerParams.amPortSel = mxGetScalar(prhs[1]);
			if (Device_Streaming == 1) {
				if ((err = sdrplay_api_Update(chosenDevice.dev, chosenDevice.tuner,
					sdrplay_api_Update_Rsp2_AmPortSelect, sdrplay_api_Update_Ext1_None)) != sdrplay_api_Success) {
					Print_UpdateMSG(err);
				}
				plhs[0] = mxCreateDoubleScalar(err);
			}
			else {plhs[0]=mxCreateDoubleScalar(-1);}
		}

		// Else update Antenna Control
		else if (strcmp("update_antCont", cmd) == 0) {
			deviceParams->rxChannelA->rsp2TunerParams.antennaSel = mxGetScalar(prhs[1]);
			if (Device_Streaming == 1) {
				if ((err = sdrplay_api_Update(chosenDevice.dev, chosenDevice.tuner,
					sdrplay_api_Update_Rsp2_AntennaControl, sdrplay_api_Update_Ext1_None)) != sdrplay_api_Success) {
					Print_UpdateMSG(err);
				}
				plhs[0] = mxCreateDoubleScalar(err);
			}
			else {plhs[0]=mxCreateDoubleScalar(-1);}
		}

		// Else update External Ref Control
		else if (strcmp("update_extRefCont", cmd) == 0) {
			deviceParams->devParams->rsp2Params.extRefOutputEn = mxGetScalar(prhs[1]);
			if (Device_Streaming == 1) {
				if ((err = sdrplay_api_Update(chosenDevice.dev, chosenDevice.tuner,
					sdrplay_api_Update_Rsp2_ExtRefControl, sdrplay_api_Update_Ext1_None)) != sdrplay_api_Success) {
					Print_UpdateMSG(err);
				}
				plhs[0] = mxCreateDoubleScalar(err);
			}
			else {plhs[0]=mxCreateDoubleScalar(-1);}
		}

		// Else update LNA
		else if (strcmp("update_lna", cmd) == 0) {
			deviceParams->rxChannelA->tunerParams.gain.LNAstate = mxGetScalar(prhs[1]);
			if (Device_Streaming == 1) {
				if ((err = sdrplay_api_Update(chosenDevice.dev, chosenDevice.tuner,
					sdrplay_api_Update_Tuner_Gr, sdrplay_api_Update_Ext1_None)) != sdrplay_api_Success) {
					Print_UpdateMSG(err);
				}
				plhs[0] = mxCreateDoubleScalar(err);
			}
			else {plhs[0]=mxCreateDoubleScalar(-1);}
		}

		// Else update Fc
		else if (strcmp("update_fc", cmd) == 0) {
			deviceParams->rxChannelA->tunerParams.rfFreq.rfHz = mxGetScalar(prhs[1]);
			if (Device_Streaming == 1) {
				if ((err = sdrplay_api_Update(chosenDevice.dev, chosenDevice.tuner,
					sdrplay_api_Update_Tuner_Frf, sdrplay_api_Update_Ext1_None)) != sdrplay_api_Success) {
					Print_UpdateMSG(err);
				}
				plhs[0] = mxCreateDoubleScalar(err);
			}
			else {plhs[0]=mxCreateDoubleScalar(-1);}
		}

		// Else update BwType
		else if (strcmp("update_bwType", cmd) == 0) {
			deviceParams->rxChannelA->tunerParams.bwType = mxGetScalar(prhs[1]);
			if (Device_Streaming == 1) {
				if ((err = sdrplay_api_Update(chosenDevice.dev, chosenDevice.tuner,
					sdrplay_api_Update_Tuner_BwType, sdrplay_api_Update_Ext1_None)) != sdrplay_api_Success) {
					Print_UpdateMSG(err);
				}
				plhs[0] = mxCreateDoubleScalar(err);
			}
			else {plhs[0]=mxCreateDoubleScalar(-1);}
		}

		// Else update IfType
		else if (strcmp("update_ifType", cmd) == 0) {
			deviceParams->rxChannelA->tunerParams.ifType = mxGetScalar(prhs[1]);
			if (Device_Streaming == 1) {
				if ((err = sdrplay_api_Update(chosenDevice.dev, chosenDevice.tuner,
					sdrplay_api_Update_Tuner_IfType, sdrplay_api_Update_Ext1_None)) != sdrplay_api_Success) {
					Print_UpdateMSG(err);
				}
				plhs[0] = mxCreateDoubleScalar(err);
			}
			else {plhs[0]=mxCreateDoubleScalar(-1);}
		}

		// Else update DcOffset
		else if (strcmp("update_dcOffset", cmd) == 0) {
			deviceParams->rxChannelA->tunerParams.dcOffsetTuner.dcCal = mxGetScalar(prhs[1]);
			if (Device_Streaming == 1) {
				if ((err = sdrplay_api_Update(chosenDevice.dev, chosenDevice.tuner,
					sdrplay_api_Update_Tuner_DcOffset, sdrplay_api_Update_Ext1_None)) != sdrplay_api_Success) {
					Print_UpdateMSG(err);
				}
				plhs[0] = mxCreateDoubleScalar(err);
			}
			else {plhs[0]=mxCreateDoubleScalar(-1);}
		}

		// Else update LoMode
		else if (strcmp("update_loMode", cmd) == 0) {
			deviceParams->rxChannelA->tunerParams.loMode = mxGetScalar(prhs[1]);
			if (Device_Streaming == 1) {
				if ((err = sdrplay_api_Update(chosenDevice.dev, chosenDevice.tuner,
					sdrplay_api_Update_Tuner_LoMode, sdrplay_api_Update_Ext1_None)) != sdrplay_api_Success) {
					Print_UpdateMSG(err);
				}
				plhs[0] = mxCreateDoubleScalar(err);
			}
			else {plhs[0]=mxCreateDoubleScalar(-1);}
		}

		// Else update DCoffsetIQimbalance
		else if (strcmp("update_dcOffsetIQ", cmd) == 0) {
			deviceParams->rxChannelA->ctrlParams.dcOffset.DCenable = mxGetScalar(prhs[1]);
			if (Device_Streaming == 1) {
				if ((err = sdrplay_api_Update(chosenDevice.dev, chosenDevice.tuner,
					sdrplay_api_Update_Ctrl_DCoffsetIQimbalance, sdrplay_api_Update_Ext1_None)) != sdrplay_api_Success) {
					Print_UpdateMSG(err);
				}
				plhs[0] = mxCreateDoubleScalar(err);
			}
			else {plhs[0]=mxCreateDoubleScalar(-1);}
		}

		// Else update Decimation
		else if (strcmp("update_decimation", cmd) == 0) {
			deviceParams->rxChannelA->ctrlParams.decimation.enable = 1;
			deviceParams->rxChannelA->ctrlParams.decimation.decimationFactor = mxGetScalar(prhs[1]);
			if (Device_Streaming == 1) {
				if ((err = sdrplay_api_Update(chosenDevice.dev, chosenDevice.tuner,
					sdrplay_api_Update_Ctrl_Decimation, sdrplay_api_Update_Ext1_None)) != sdrplay_api_Success) {
					Print_UpdateMSG(err);
				}
				plhs[0] = mxCreateDoubleScalar(err);
			}
			else {plhs[0]=mxCreateDoubleScalar(-1);}
		}

		// Else update AGC
		else if (strcmp("update_agc", cmd) == 0) {
			deviceParams->rxChannelA->ctrlParams.agc.enable = mxGetScalar(prhs[1]);
			if (Device_Streaming == 1) {
				if ((err = sdrplay_api_Update(chosenDevice.dev, chosenDevice.tuner,
					sdrplay_api_Update_Ctrl_Agc, sdrplay_api_Update_Ext1_None)) != sdrplay_api_Success) {
					Print_UpdateMSG(err);
				}
				plhs[0] = mxCreateDoubleScalar(err);
			}
			else {plhs[0]=mxCreateDoubleScalar(-1);}
		}

		// Else initalize Stream
		else if(strcmp("init_stream",cmd)==0) {
            if (Device_Streaming == 0){

				// Assign callback functions to be passed to sdrplay_api_Init()
				cbFns.StreamACbFn = StreamACallback;
				cbFns.StreamBCbFn = StreamBCallback;

				cbFns.EventCbFn = EventCallback;
				
				// Now we're ready to start by calling the initialisation function
				// This will configure the device and start streaming
				err = sdrplay_api_Init(chosenDevice.dev, &cbFns, NULL);
				if (err == sdrplay_api_Success) {
					printf("Initialised!\n");
					Device_Streaming = 1;
				}
				else {printf("sdrplay_api_Init failed %s\n", sdrplay_api_GetErrorString(err));}
				plhs[0]=mxCreateDoubleScalar(err);
			}
			else { plhs[0]=mxCreateDoubleScalar(-1); }
		}

		// Else if Data
        else if(strcmp("data",cmd)==0) {	
			plhs[0]=getdata(); 
        }

		// Else if Uninitialise Stream
		else if(strcmp("uninit_stream",cmd)==0) {   
            if (Device_Streaming == 1){
				if ((err = sdrplay_api_Uninit(chosenDevice.dev)) != sdrplay_api_Success) {
					printf("sdrplay_api_Uninit failed %s\n", sdrplay_api_GetErrorString(err));				
				}
				else { 
					Device_Streaming = 0;
					printf("Uninitialised!\n");
				}
				plhs[0]=mxCreateDoubleScalar(err);
			}
			else {plhs[0]=mxCreateDoubleScalar(-1);}
        } 

		// Else if Close
		else if(strcmp("close",cmd)==0) {
						
			if ((err = sdrplay_api_ReleaseDevice(&chosenDevice)) != sdrplay_api_Success) {
            	printf("sdrplay_api_ReleaseDevice failed %s\n", sdrplay_api_GetErrorString(err));
            }	
			plhs[0]=mxCreateDoubleScalar(err);
			printf("Released!\n");
			deviceParams = NULL;

			//Close_API();
        }

		// Else unknown command
		else {	
			mexPrintf("Unknown command: %s\n",cmd);	
        }       
    } 

	// Else unknown number of input output
	else {
        mexErrMsgTxt("Wrong number of input/output arguments.");
    }
}


                                       