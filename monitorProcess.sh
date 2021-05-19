#!/bin/bash

##### FUNCTIONS #####
function logger {
    echo "$(date +%Y%m%d-%H:%M:%S) - ${1}" >>$LOG
}

function getStatus {
    processName=${1}
    echo $(ps -ef | grep -i ${processName} | wc -l)
}

function completeEmailBody {
    if [[ ${processStatus} -eq 1 ]]
    then
        BODY="OK - ${PROCESS} running."
    else
        BODY="ERROR - ${PROCESS} IS NOT RUNNING."
    fi
}

function sendEmail {
    logger "Sending email to ${EMAIL}..."
    if [[ ${processStatus} -eq 1 ]]
    then
        TITLE="[[OK]] - "${TITLE}
    else
        TITLE="[[ERROR]] - "${TITLE}
    fi

    printf "DO NOT REPLY\n \
    This is an automated email\n\n \
    ${BODY}" | mailx -s "${TITLE}" "${EMAIL}"
}

##### VARIABLES #####
DATE=$(date +%Y%m%d)
LOG=/logs/MonitorProcess_${DATE}.log
PROCESS=${1}

EMAIL="..."
TITLE="Monitor of ${PROCESS} - ${DATE}"

##### MAIN #####
logger
logger "Monitor Process START"
logger

logger "Checking existence of ${PROCESS}"
processStatus=$(getStatus ${PROCESS})
logger "Status: ${processStatus}"

completeEmailBody

sendEmail

logger
logger "Monitor ProcessEND"
logger

exit 0