#!/bin/bash

### Functions ###
function logger {
    if [[ -z ${1} ]]
    then
        echo >>$LOG
    else
        echo "$(date +%Y%m%d-%H:%M:%S) - ${1}" >>$LOG
    fi
}

function checkConnectionString {
    if [[ -z ${CONN_STRING} ]]
    then
        logger "Connection string empty. Exiting ..."
        exit 1
    fi
}

function checkFile {
    arch=${1}
    if [[ -f ${arch} ]]
    then
        logger "File ${arch} already exists ... removing and creating a new one"
        rm -f ${arch}
    else
        logger "File ${arch} not exist"
    fi
}

function runExport {
    logger "### Export"
    
    ${DB_EXP} ${CONN_STRING} \
    file=${FILE} \
    log=${LOG}.exp \
    buffer=536870912 \
    recordlength=65535 \
    statistics=none \
    direct=n \
    ignore=y \
}

function moveExportLogToLog {
    if [[ -f ${LOG}.exp ]]
    then
        cat ${LOG}.exp >>${LOG}
        rm -f ${LOG}.exp
    fi
}

function compressFile {
    nohup ${COMPRESSSCRIPT} ${FILE} &
}

### Init ###
CONN_STRING="..."
BCK_DB="/home/backups/"
DB_EXP=exp
RUN_DATE=$(date +%Y%m%d)
FILE="/home/files/backup_${RUN_DATE}.bkp"
LOG="/home/log/backup_BBDD_${RUN_DATE}.log"
COMPRESSSCRIPT="/home/scripts/CompressFile.sh"

### MAIN ###
logger "### Backup_${RUN_DATE} begin ###"
logger

checkConnectionString

logger " * Backup dir =      ${BCK_DB}"
logger " * Export command =  ${DB_EXP}"
logger " * Run date =        ${RUN_DATE}"
logger " * File =            ${FILE}"
logger " * Log =             ${LOG}"
logger

checkFile ${FILE}
checkFile ${FILE}.Z

runExport

moveExportLogToLog

compressFile

exit 0