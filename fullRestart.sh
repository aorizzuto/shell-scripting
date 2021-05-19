#!/bin/bash

##### FUNCTIONS #####
function logger {
    echo "$(date +%Y%m%d-%H:%M:%S) - ${1}" >>$LOG
}

function checkReturnCode {
    RC=${1}
    if [[ $RC -ne 0 ]]
    then
        logger "ERROR: ${2}Process has finished with errors. (Code: ${RC})"
        logger "Full restart END"
        exit 1
    fi
}

##### VARIABLES #####
DATE=$(date +%Y%m%d)
LOG=/logs/fullRestart_${DATE}.log
STOPPROCESS=/scripts/StopProcess.sh
STARTPROCESS=/scripts/StartProcess.sh

##### MAIN #####
logger
logger "Full restart START"
logger

# STOP
${STOPPROCESS}
checkReturnCode $? Stop

# START
${STARTPROCESS}
checkReturnCode $? Start

logger "Process succesfully restarted."
logger "Full restart END"
exit 0