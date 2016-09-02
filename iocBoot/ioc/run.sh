#!/bin/sh
chmod +x st.cmd
procServ --allow -n "VERIFY-SETTINGS" -p pid.txt -L log.txt --logstamp -i ^D^C 2004 ../../bin/$EPICS_HOST_ARCH/runControl st.cmd