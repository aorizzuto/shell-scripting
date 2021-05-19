#!/bin/bash

##### Funciones
function logger {
    echo "$(date +%Y%m%d-%H:%M:%S) - ${1}" >>$LOG
}

function getProcessDate {
    echo "$CONN_STRING
    set heading off
    set feedback off
    set pages 0
    select getProcessDate('${1}') from dual;
    exit" | sqlplus -s
}

function sendEmail {
    ebolog "Sending email"
    TITLE="Process Monitor - $(date +%Y%m%d)"
    printf "DO NOT REPLY\n \
    This is an automated email\n\n \
    * Countries with status OK:   ${STATUS_OK}\n \
    * Countries with status FAIL:   ${STATUS_FAIL}\n\
    * Countries with status WAIT:   ${STATUS_WAIT}\n\n" | mailx -s "${TITLE}" "${EMAIL}"
}

##### Variables

EMAIL="alejandro...@gmail.com"
COUNTRIES="ES US FR"
LOG=/logs/checkProcessStatus_$(date +%Y%m%d).log
CONN_STRING="..."

##### MAIN #####

logger
logger "Check process - START"
logger

COUNTRIES_UP=$(echo ${COUNTRIES} | tr [:lower:] [:upper:])

logger "Countries to check: ${COUNTRIES}"

STATUS_OK=""
STATUS_FAIL=""
STATUS_WAIT=""

for COUNTRY in ${COUNTRIES}
do
    logger "Checking country: ${COUNTRY}"

    PROCESS_DATE=$(getProcessDate "${COUNTRY}")
    logger "Process Date: ${COUNTRY}"

    STATUS=$(echo $PROC_DATE | cut -d" " -f2)

    case $STATUS in
        0) # OK
        STATUS_OK=${STATUS_OK}' '${COUNTRY}
        ;;
        1) # FAIL
        STATUS_FAIL=${STATUS_FAIL}' '${COUNTRY}
        ;;
        2) # WAIT
        STATUS_WAIT=${STATUS_WAIT}' '${COUNTRY}
        ;;
        *)
        ;;
    esac
done

ebolog "Countries with status OK:   ${STATUS_OK}"
ebolog "Countries with status FAIL: ${STATUS_FAIL}"
ebolog "Countries with status WAIT: ${STATUS_WAIT}"

##### Email section #####

sendEmail

exit 0