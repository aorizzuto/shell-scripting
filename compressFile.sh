#!/bin/bash

if [[ $# -ne 1 ]]
then
    exit 0
fi

FILE=$1
chmod ugo+w ${FILE}
gzip ${FILE}
chmod ugo+w "${FILE}.*"

if [[ -f ${FILE} && -f ${FILE}.Z ]] # If exist file and compress file, remove file
then
    rm -f ${FILE}
fi

exit 0