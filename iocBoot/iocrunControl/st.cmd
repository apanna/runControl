#!../../bin/windows-x64/runControl
############################################################################
< envPaths
# For deviocstats
epicsEnvSet("ENGINEER", "Alireza Panna")
epicsEnvSet("LOCATION", "B1D521D DT-SMLIN114")
epicsEnvSet("STARTUP","$(TOP)/iocBoot/$(IOC)")
epicsEnvSet("ST_CMD","st.cmd")

epicsEnvSet "P" "$(P=PFI)"
epicsEnvSet "EPICS_IOC_LOG_INET" "192.168.1.122"
epicsEnvSet "EPICS_IOC_LOG_PORT" "7004"
############################################################################
# Increase size of buffer for error logging from default 1256
errlogInit(20000)
############################################################################
cd $(TOP)
## Register all support components
dbLoadDatabase "dbd/runControl.dbd"
runControl_registerRecordDeviceDriver pdbbase
############################################################################
# Load save_restore.cmd
cd $(IPL_SUPPORT)
< save_restore.cmd
set_requestfile_path("$(TOP)", "runControlApp/Db")
############################################################################
# Load record instances
cd $(TOP)
dbLoadRecords("db/param.db","P=$(P)")
dbLoadRecords("db/iocAdminSoft.db","IOC=$(P)")
asSetFilename("$(IPL_SUPPORT)/security.acf")
############################################################################
# Start EPICS IOC
cd $(STARTUP)
iocInit
############################################################################
# Start sequence programs
seq verifySettings, "P=$(P), A=VPFI:Qi2, S=VPFI:SCAN, X=VPFI:OXFORD:xray"
############################################################################
create_monitor_set("auto_positions.req", 5, "P=$(P):")
create_monitor_set("auto_settings.req", 30, "P=$(P):")

# Handle autosave 'commands' contained in loaded databases
# Searches through the EPICS database for info nodes named 'autosaveFields' 
# and 'autosaveFields_pass0' and write the PV names to the files 
# 'info_settings.req' and 'info_positions.req'
makeAutosaveFiles()
create_monitor_set("info_positions.req",5,"P=$(P):")
create_monitor_set("info_settings.req",30,"P=$(P):")
############################################################################
# Start EPICS IOC log server
iocLogInit()
setIocLogDisable(0)
############################################################################
# Turn on caPutLogging:
# Log values only on change to the iocLogServer:
caPutLogInit("$(EPICS_IOC_LOG_INET):$(EPICS_IOC_LOG_PORT)",1)
caPutLogShow(2)
############################################################################
# print the time our boot was finished
date
############################################################################
