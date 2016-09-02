program verifySettings ( "P=PFI, A=Qi2, S=IOC, X=cpi" ) /* these can be superceded at run time, i.e. in st.cmd */
#define VERIFY_SETTINGS_VERSION 1.0
/****************************************************************************************************
 *	Program to verify and monitor the polychromatic far-field interferometer (pfi) settings during 
 *  runtime. Useful for pre-scan verifications. 
 *
 *	by Alireza Panna, NIH/NHLBI/IPL
 *	1 January, 2016
 *
 *	#  P  		= prefix for all of the PV's associated with the seqControl ioc.
 *	#  A  		= prefix for all of the PV's associated with the area detector ioc.
 *	#  S    	= prefix for all the PV's associated with the scan ioc.
 *  #  X		= prefix for all the PV's associated with the x-ray ioc.
 *  
 *  __log__ 	= 1/10/2015: Version 1.0 created.
 *
 *	__to-do__  	= 			  	
 ****************************************************************************************************/ 

/*===========================Option statements========================*/
option +r; /* allows running more than one copy with different macros */
option -c; /* dont wait for channel connections */
option -l; /* use C line numbers in error messages etc */
option +d; /* Turn on run time debug messages */
option +w; /* Suppress snc compiler warnings */
option -s; /* dont run in safe mode */

#include "seqPVmacros.h"
/* Escape to C code for C includes using %% */
%% #include <stdio.h>
%% #include <string.h>

#if defined(_WIN32)
%% #include <Windows.h>
#endif
#if defined(__unix__) || defined(__unix) || defined(unix)
%% #include <unistd.h>								      // POSIX flags 
%% #include <time.h>								      // clock_gettime(), time()
%% #include <sys/time.h>					 
#endif
/* 0 long */
#ifndef NULL
#define NULL 0L
#endif
 /* 30 sec timeout */
#define COUNT_TIMEOUT  300
/* This defines the number of lines and max line length */
#define LINELENGTH 256
#define NLINES 20
/* This is LINELENGTH*NLINES. It must match NELM on the MESSAGE */
#define NELM 5120

/*==================================assignments/declarations==================================================*/
PV (int,		verify,					"{P}:VERIFY", 						EvFlag);	/* flag to start pfi settings verification */
PV (int,		verifyRBV,				"{P}:VERIFY_RBV", 					NoMon);		/* pfi settings verification readback */
/* Variables related to cpi x-ray generator */
PV (short,		cpiStatus,				"{X}:GeneratorStatus.RVAL", 		NoMon);		/* cpi generator status */
PV (short,		cpiHeat,				"{X}:AnodeTubeHeat", 				NoMon);		/* cpi anode heat */
/* Variables related to sscan. */
PV (short,		busy1,		   			"{S}:scan1.BUSY", 					EvFlag);	/* scan 1 is busy */
PV (short,		busy2,		   			"{S}:scan2.BUSY", 					EvFlag);	/* scan 2 is busy */
PV (short,		busy3,		   			"{S}:scan3.BUSY", 					EvFlag);	/* scan 3 is busy */
PV (short,		busy4,		   			"{S}:scan4.BUSY", 					EvFlag);	/* scan 4 is busy */
PV (short,		checkLimits1,			"{S}:scan1.CMND",					NoMon);
PV (short,		checkLimits2,			"{S}:scan2.CMND",					NoMon);
PV (short,		checkLimits3,			"{S}:scan3.CMND",					NoMon);
PV (short,		checkLimits4,			"{S}:scan4.CMND",					NoMon);
PV (short, 		alert1,					"{S}:scan1.ALRT",					NoMon);
PV (short, 		alert2,					"{S}:scan2.ALRT",					NoMon);
PV (short, 		alert3,					"{S}:scan3.ALRT",					NoMon);
PV (short, 		alert4,					"{S}:scan4.ALRT",					NoMon);
PV (short,		posCheck1,				"{S}:scan1.P1NV",					NoMon);
PV (short,		posCheck2,				"{S}:scan2.P1NV",					NoMon);
PV (short,		pauseGo,				"{S}:scanPause.VAL",				NoMon);
PV (short,		abortAll,				"{S}:AbortScans.PROC", 				NoMon);
/* Variables related to sscanProgess (These are the ones that cpiSync uses) */
PV(short,		scanProgRunningRBV,		"{S}:scanProgress:running",			NoMon);
PV(int,			scanProgNfinRBV,		"{S}:scanProgress:Nfinished",		NoMon);
PV(int,			scanProgNtotRBV,		"{S}:scanProgress:Ntotal",			NoMon);
/* Variables related to Area detector.*/
PV (short,		camCallbacks,			"{A}:cam1:ArrayCallbacks_RBV",		NoMon);		/* main AD cam callbacks */
PV (short,		image1Callbacks,		"{A}:image1:EnableCallbacks_RBV",	NoMon);		/* image1 callbacks */
PV (short,		image1ArrayCallbacks,	"{A}:image1:ArrayCallbacks_RBV",	NoMon);		/* image1 array callbacks */
PV (short,  	process1Callbacks,		"{A}:Proc1:EnableCallbacks_RBV", 	NoMon);		/* process1 callbacks */
PV (short,  	process1ArrayCallbacks,	"{A}:Proc1:ArrayCallbacks_RBV", 	NoMon);		/* process1 array callbacks */
PV (short,  	roi1Callbacks,			"{A}:ROI1:EnableCallbacks_RBV", 	NoMon);		/* roi1 callbacks */
PV (short,  	roi1ArrayCallbacks,		"{A}:ROI1:ArrayCallbacks_RBV", 		NoMon);		/* roi1 array callbacks */
PV (short,  	stats1Callbacks,		"{A}:Stats1:EnableCallbacks_RBV", 	NoMon);		/* stats1 callbacks */
PV (short,  	stats1ArrayCallbacks,	"{A}:Stats1:ArrayCallbacks_RBV", 	NoMon);		/* stats1 array callbacks */
PV (short,  	tiff1Callbacks,			"{A}:TIFF1:EnableCallbacks_RBV", 	NoMon);		/* tiff1 callbacks */
PV (short,  	tiff1ArrayCallbacks,	"{A}:TIFF1:ArrayCallbacks_RBV", 	NoMon);		/* tiff1 array callbacks */
PV (short,  	hdf1ArrayCallbacks,		"{A}:HDF1:ArrayCallbacks_RBV", 		NoMon);		/* hdf1 array callbacks */
PV (short,  	jpeg1ArrayCallbacks,	"{A}:JPEG1:ArrayCallbacks_RBV", 	NoMon);		/* jpeg1 array callbacks */
PV (short,  	nexus1ArrayCallbacks,	"{A}:Nexus1:ArrayCallbacks_RBV", 	NoMon);		/* nexus1 array callbacks */
PV (short,  	netcdf1ArrayCallbacks,	"{A}:netCDF1:ArrayCallbacks_RBV", 	NoMon);		/* netcdf1 array callbacks */
PV (short,  	magick1ArrayCallbacks,	"{A}:Magick1:ArrayCallbacks_RBV", 	NoMon);		/* magick1 array callbacks */
PV (string, 	tiffPort,				"{A}:TIFF1:NDArrayPort", 			NoMon);		/* tiff Port */
PV (short,  	autoSave,				"{A}:TIFF1:AutoSave", 				NoMon);		/* tiff autosave */
PV (short,  	inc,					"{A}:TIFF1:AutoIncrement", 			NoMon);		/* tiff increment */
PV (short,  	trigger,    			"{A}:cam1:NikonTriggerMode", 		NoMon);		/* set the trigger 0 for live, 1 for hard */
PV (short,  	acquire,    			"{A}:cam1:Acquire", 				NoMon);		/* acquire image set */
PV (short,		enableBgRBV,			"{A}:Proc1:EnableBackground_RBV",   NoMon);
PV (double,		offsetMeanRBV,			"{A}:OFFSET_MEAN_RBV",				NoMon);

char message[NELM];        
assign message to "{P}:MESSAGE";

int err_count, warn_count;
%% struct tm *tm1;
%% long mytime;
int i;
char *outLine;
char outMsg[20][256];
char header[256];
/*====================State Sets====================*/
ss verifySettings
{
	state init
	{	
		when (pvConnectCount() < pvChannelCount()) {
		} state init
		
		when (pvConnectCount() == pvChannelCount()) {
		} state idle
	}

	state idle {
		when (pvConnectCount() < pvChannelCount()) {
			outLine = "[ERROR]: IOC DISCONNECT\n";
			strcat(outMsg, outLine);
			PVPUTSTR(message, outLine);
			PVPUT(verifyRBV, 2);
		} state init

		when (efTestAndClear(verify_mon) && verify) {

		} state verify
	}

	state verify {
		when (1) {
			/* get current values of relevant pv's */
			PVPUT(checkLimits1, 1);
			PVPUT(checkLimits2, 1);
			PVPUT(checkLimits3, 1);
			PVPUT(checkLimits4, 1);
			pvGet(alert1);
			pvGet(alert2);
			pvGet(alert3);
			pvGet(alert4);
			pvGet(posCheck1);
			pvGet(posCheck2);
			pvGet(cpiStatus);
			pvGet(cpiHeat);
			pvGet(autoSave);
			pvGet(inc);
			pvGet(camCallbacks);
			pvGet(image1Callbacks);
			pvGet(image1ArrayCallbacks);
			pvGet(process1Callbacks);
			pvGet(process1ArrayCallbacks);
			pvGet(roi1Callbacks);
			pvGet(roi1ArrayCallbacks);
			pvGet(stats1Callbacks);
			pvGet(stats1ArrayCallbacks);
			pvGet(tiff1Callbacks);
			pvGet(tiff1ArrayCallbacks);
			pvGet(enableBgRBV);
			pvGet(offsetMeanRBV);
			err_count = 0;
			warn_count = 0;
			/* Clear output lines */
			for (i = 0; i < NLINES; i++) {
				strcpy(outMsg[i], "");
			}
			/* start checking */
%%			mytime = time(NULL);				
%%			tm1 = localtime(&mytime);
			sprintf(header, "~PFI VERIFICATION LOG: %.2d/%.2d/%.2d %.2d:%.2d:%.2d~\n", tm1->tm_year + 1900, tm1->tm_mon + 1, tm1->tm_mday, tm1->tm_hour, tm1->tm_min, tm1->tm_sec);
			strcat(outMsg, header);
			if (alert1 || alert2 || alert3 || alert4) {
				outLine = "[ERROR]: POSITIONER OUT OF BOUNDS\n";
				strcat(outMsg, outLine);
				err_count++;
			}
			if (posCheck1 == 6 || posCheck2 == 6) {
				outLine = "[ERROR]: BAD POSITIONER PV\n";
				strcat(outMsg, outLine);
				err_count++;
			}
			if (cpiStatus != 2 ) {
				outLine = "[ERROR]: X-RAY NOT READY\n";
				strcat(outMsg, outLine);
				err_count++;
			}
			if(cpiHeat > 70) {
				outLine = "[WARN]:  ANODE HEAT LIMIT\n";
				strcat(outMsg, outLine);
				warn_count++;
			}
			if (!autoSave) {
				outLine = "[WARN]:  AUTOSAVE DISABLED\n";
				strcat(outMsg, outLine);
				warn_count++;
			}
			if (!inc) {
				outLine = "[WARN]:  AUTO INCREMENT DISABLED\n";
				strcat(outMsg, outLine);
				warn_count++;
			}
			if (!camCallbacks || !image1Callbacks || !image1ArrayCallbacks) {
				outLine = "[ERROR]: ARRAY CALLBACKS DISABLED\n";
				strcat(outMsg, outLine);
				err_count++;
			}
			if (!process1Callbacks || !process1ArrayCallbacks) {
				outLine = "[ERROR]: PROCESS CALLBACKS DISABLED\n";
				strcat(outMsg, outLine);
				err_count++;
			}
			if (!tiff1Callbacks || !tiff1ArrayCallbacks) {
				outLine = "[ERROR]: TIFF CALLBACKS DISABLED\n";
				strcat(outMsg, outLine);
				err_count++;
			}
			if (!roi1Callbacks || !roi1ArrayCallbacks) {
				outLine = "[ERROR]: ROI CALLBACKS DISABLED\n";
				strcat(outMsg, outLine);
				err_count++;
			}
			if (!stats1Callbacks || !stats1ArrayCallbacks) {
				outLine = "[WARN]:  STATS CALLBACKS DISABLED\n";
				strcat(outMsg, outLine);
				warn_count++;
			}
			if (!enableBgRBV) {
				outLine = "[WARN]:  OFFSET CORR DISABLED\n";
				strcat(outMsg, outLine);
				warn_count++;
			}
			if ((offsetMeanRBV > 300 && offsetMeanRBV < 200) && enableBgRBV) {
				outLine = "[ERROR]: OFFSET COUNTS\n";
				strcat(outMsg, outLine);
				err_count++;
			}         
			/* finally update verify_rbv */
			if (err_count == 0 && warn_count == 0) {
				outLine = "[OK]: READY FOR SCAN\n";
				strcat(outMsg, outLine);
				PVPUT(verifyRBV, 0);
			}
			else if (err_count == 0  && warn_count != 0) {
				PVPUT(verifyRBV, 1);
			}
			else if (err_count != 0) {
				PVPUT(verifyRBV, 2);
			}
			PVPUTSTR(message, outMsg);
		} state idle
	} 
}
/* This state set simply monitors channel disconnects during scan.  It is a 
 * separate state set so that it is always active. When a channel(s) disconnects for 
 * some reason, the scan is aborted instantly. In a future version, this would allow
 * for the scan to be paused until the channels get reconnected.
 */
ss monitorScan {
	
	state init
	{	
		when (pvConnectCount() < pvChannelCount()) {
		} state init
	}
	
	
	state monitorDisconnect {
		entry {
			pvGet(busy1);
			pvGet(busy2);
			pvGet(busy3);
			pvGet(busy4);
		}

		when ((busy1 || busy2 || busy3 || busy4)) {
			if (pvConnectCount() < pvChannelCount()) {
				PVPUT(abortAll, 1);
				outLine = "[ERROR]: IOC DISCONNECT\n";
				strcat(outMsg, outLine);
				PVPUTSTR(message, outLine);
				PVPUT(verifyRBV, 2);
            	/*while (pvConnectCount() != pvChannelCount() && count < COUNT_TIMEOUT ) {
                	epicsThreadSleep(0.1);
                	count++;
                }
                if (count == COUNT_TIMEOUT) {
                	PVPUTSTR(message, "ABORT SCAN:TIMEOUT");
                	
            	} 
            	else {
					PVPUTSTR(message, "RESUME SCAN:CONNECT");
					PVPUT(acquire, 1);
					PVPUT(pauseGo, 0);
				}       
            	count = 0;*/
			}
		} state init
	}

}

