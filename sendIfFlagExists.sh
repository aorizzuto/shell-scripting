#!/bin/bash

# SCRIPT to check if flag exists to send a file
# Parameters
# 1: Country
# 2: File_template
# 3: jump validation

##########################
# Functions

function logger {
    if [[ -z ${1} ]]
    then
        echo >>$LOG
    else
        echo "$(date +%Y%m%d-%H:%M:%S) - ${1}" >>$LOG
    fi
}

##########################
# Parameters

COUNTRY=${1}
F_TEMPLATE=${2}
JUMP=${3}

##########################
# Variables

DATE=$(date +%Y%m%d)
PFLAG=/transmissions/${COUNTRY}/flag
PFLAG_LOGDIR=${PFLAG}/logs
PFLAG_LOGFILE=flags_log_${COUNTRY}_${DATE}.log
LOG=${PFLAG_LOGDIR}/${PFLAG_LOGFILE}

##########################
# Main

if [[ ! -z ${JUMP} ]]
then
    exit 0
fi

test -d $PFLAG_LOGDIR || mkdir $PFLAG_LOGDIR; chmod 755 $PFLAG_LOGDIR 2>>/dev/null

AUX=$(ls ${PFLAG}/flag_${F_TEMPLATE}_${DATE}.* 2>/dev/null)

if [[ -z ${AUX} ]]
then
    logger "Flag ${PFLAG}/flag_${F_TEMPLATE}_${DATE}.* does not exist. Exiting ..."
    exit 1
fi

logger "Flag EXIST. Removing flag and continue with transmission."
rm ${PFLAG}/flag_${F_TEMPLATE}_${DATE}.*

exit 0