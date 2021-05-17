#!/bin/bash

export TERM=xterm

##############################
# Styles

RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
RESET=$(tput sgr0)
BOLD=$(tput bold)
NORMAL=$(tput sgr0)

##############################
# Variables
DIR="/tmp"
USER=$(echo ${id} | sed 's/[()]/ /g' | cut -d" " -f2) # Take the user automatically
BCK_DB=/database/backups
DB_IMP=imp
RUN_DATE=$(date +%Y%m%d)
LOG_DIR=${DIR}Restore_BBDD_${RUN_DATE}.log
SERVERS="..."

##############################
# Functions
function remove_old_files(){
    rm -f $FILE
}

function impr(){
    printf "        ${1} "
    if [[ ! -z ${2} ]]
    then
        points ${2}
        printf ${3}
    fi
    printf "\n"
}

function wait_for_key(){
    listo=0
    key=0
    max=${1}
    while [[ listo -eq 0 ]]
    do
        read -r -s -n 1 key
        if [[ ${key} -gt 0 && ${key} -le ${max} ]] # key must be greater than 0 and lower than "max"
        then
            listo = 1
        fi
    done
}

function points(){
    iter=${1}
    for ((i=0 ; i<=${iter} ; i++))
    do
        printf "."
        sleep 0.07
    done
    printf " "
}

function title(){
    VERSION="1.0"
    echo
    echo " ${RED} "
    echo "  ____  ____  ____  ____    ____           _                  "
    echo " | __ )| __ )|  _ \|  _ \  |  _ \ ___  ___| |_ ___  _ __ ___  "
    echo " |  _ \|  _ \| | | | | | | | |_) / _ \/ __| __/ _ \| '__/ _ \ "
    echo " | |_) | |_) | |_| | |_| | |  _ <  __/\__ \ || (_) | | |  __/ "
    echo " |____/|____/|____/|____/  |_| \_\___||___/\__\___/|_|  \___| "
    echo "                                           Version: ${VERSION}"
    echo "${RESET}"
}

function show_title(){
    title
    echo
    read -n 1 -s -r -p "Press any key to continue ..."
}

function ask_for_env_parameters(){

    var_env=1
    while [[ ${var_env} == 1 ]]
    do
        clear
        echo
        echo "  --------------------------------------------------"
        echo "  |                   BBDD Restore                 |"
        echo "  --------------------------------------------------"
        echo "  |       Please choose an option according to     |"
        echo "  |            where the backup exist              |"
        echo "  --------------------------------------------------"
        echo "  |       [1]      |      QA Environment           |"
        echo "  |       [2]      |      PROD Environment         |"
        echo "  |       [3]      |      Other                    |"
        echo "  |       [4]      |      Show available servers   |"
        echo "  --------------------------------------------------"
        echo
        impr "Option:"
        wait_for_key 4
        echo
        impr "Checking option" 19 ${key}
        sleep 0.5

        ENV=""

        case ${key} in
        "1")
            SERVER="QA"
            ENV=${SERVER_QA}
            ;;
        "2")
            SERVER="PROD"
            ENV=${SERVER_PROD}
            ;;
        "3")
            SERVER="OTHER"
            echo "Enter another server: "
            read -r -n 15 serv
            echo
            impr "Checking option" 19 ${serv}
            sleep 1

            if [[ ${others} == *${serv}* ]]
            then
                ENV=${serv}
            else
                echo $RED
                impr "ERROR - Could not find the environment ${serv}."
                echo $RESET
            fi
            ;;
        "4")
            impr "Available servers:"
            echo $BOLD
            for line in $others; do echo "     *${line}"; done
            echo $RESET
            read -n 1-s -r -p "  Copy the server you want and press any key to go back ..."
            ;;
        esac

        if [[ ! -< $ENV ]]
        then
            echo $GREEN
            impr "Origin database" 19 $ENV
            echo
            impr "Is this ORIGIN database fine? [y/n]"

            echo $RESET
            
            read -s -r -n 1 ret

            ret=$(echo ${ret} | tr [a-z] [A-Z])

            if [[ ${ret} == 'Y' ]]
            then
                final_server=${SERVER}
                final_origin=${ENV}
                var_env=0
            fi
        fi
    done
}

function ask_for_date_parameter() {
    var_date=1
    while [[ ${var_date} == 1 ]]
    do
        clear
        echo
        echo "  --------------------------------------------------"
        echo "  |                   BBDD Restore                 |"
        echo "  --------------------------------------------------"
        echo "  |       Please choose an option according to     |"
        echo "  |               the date to restore              |"
        echo "  --------------------------------------------------"
        echo "  |       [1]      |      Last backup created      |"
        echo "  |       [2]      |      Show backup list         |"
        echo "  --------------------------------------------------"
        echo
        impr "Option:"
        wait_for_key 2
        echo
        impr "Checking option" 19 ${key}
        sleep 0.5
        echo
        impr "Getting information from server ..."
        echo

        case ${key} in
        "1")
            last_backup=$(ssh ${USER}@${final_origin} ls /database/backup/ | grep backup | tail -1 )
            echo $GREEN
            impr "Last Backup is" 19 $last_backup
            echo
            impr "Is this DATE fine? [y/n]"
            echo $RESET
            read -n 1-s -r DATE
            DATE=$(echo ${DATE} | tr [a-z] [A-Z])
            if [[ ${DATE} == 'Y' ]]
            then
                final_file=${last_backup}
                var_date=0
            fi
            ;;
        "2")
            listOfBackups=$(ssh ${USER}@${final_origin} ls /database/backup/ | grep backup )
            echo "List of backups ..."
            for line in ${listOfBackups}
            do
                echo " * ${line}"
            done

            echo 
            imprt "Please enter the DATE to restore (YYYYMMDD) ..."

            read -s -r -n 8 DATE
            final_file = ""

            for line in ${listOfBackups}
            do
                if [[ ${line} == *${DATE}* ]]
                then
                    final_file=${line}
                    break
                fi
            done

            if [[ ! = ${final_file} ]]
                then
                echo $GREEN
                impr "File with date \"${DATE}\" exist" 5 $final_file
                echo
                impr "Is this DATE fine? [y/n]"
                echo $RESET
                read -n 1 -s -r yn
                yn=$(echo ${yn} | tr [a-z] [A-Z])
                if [[ ${yn} == 'Y' ]]
                then
                    var_date=0
                fi
            else
                echo $RED
                impr "File with date \"${DATE}\" does not exist ..."
                sleep 1
                echo $RESET
            fi
            ;;
        esac
    done
}

function ask_for_final_database() {
    var_env=1
    while [[ ${var_env} == 1 ]]
    do
        clear
        echo
        echo "  --------------------------------------------------"
        echo "  |                   BBDD Restore                 |"
        echo "  --------------------------------------------------"
        echo "  |       Please choose an option according to     |"
        echo "  |         where the restore should be done       |"
        echo "  --------------------------------------------------"
        echo "  |       [1]      |      server1                  |"
        echo "  |       [2]      |      server2                  |"
        echo "  --------------------------------------------------"
        echo
        impr "Option:"
        wait_for_key 2
        echo
        impr "Checking option" 19 ${key}
        sleep 0.5

        BASE_DEST=${key}

        echo $GREEN
        impr "Final database" 19 $BASE_DEST
        echo
        impr "Is this final database fine? [y/n]"
        echo $RESET
        read -n 1 -s -r ret
        ret=$(echo ${ret} | tr [a-z] [A-Z])
        if [[ ${ret} == 'Y' ]]
        then
            final_final=${BASE_DEST}
            var_env=0
        fi
        
    done
}

function show_summary(){
    var_summary=1
    while [[ ${var_summary} == 1 ]]
    do
        clear
        echo
        echo "  --------------------------------------------------"
        echo "  |                   BBDD Restore                 |"
        echo "  --------------------------------------------------"
        echo "  |                      Summary                   |"
        echo "  --------------------------------------------------"
        echo "  |       Backup directory    |   ${BACKUP_DIR}    |"
        echo "  |       Date to restore     |   ${final_file}    |"
        echo "  |            From           |   ${final_origin}  |"
        echo "  |             To            |   ${final_final}   |"
        echo "  |             Log           |   ${LOG_DIR}       |"
        echo "  --------------------------------------------------"
        echo
        echo $GREEN
        impr "Is this fine? [y/n]"
        echo $RESET
        read -n 1 -s -r key

        echo
        impr "Checking option" 19 ${key}

        key=$(echo ${key} | tr [a-z] [A-Z])

        if [[ ${key} == 'Y' ]]
        then
            echo $GREEN
            impr "Summary has been confirmed ..."
            echo
            impr "Restore will continue ..."
            echo $RESET
            var_start=0
        else
            echo $RED
            impr "An option must be changed ..."
            echo
            impr "Restore is restarting ..."
            echo $RESET
            var_start=1
        fi

        var_summary=0
        sleep 3        
    done
}

function get_file_from_origin(){
    var_getfile=1
    while [[ ${var_getfile} == 1 ]]
    do
        clear
        echo
        echo "  --------------------------------------------------"
        echo "  |                   BBDD Restore                 |"
        echo "  --------------------------------------------------"
        echo "  |                      STEP 1                    |"
        echo "  --------------------------------------------------"
        echo "  |             Getting file from ${ENV}.          |"
        echo "  --------------------------------------------------"
        echo
        echo $BOLD
        impr "This step will finish automatically in some minutes"
        echo $RESET

        scp ${USER}@${ENV}:${BACKUP_DIR}/${FILE} ${DIR}

        if [[ -f ${DIR}/${FILE}]]
        then
            impr "File copied successfully ..."
            echo
            impr "From this point to the end, the restore will be perform automatic steps."
            var_getfile=0
        else
            echo $RED
            impr "File NOT copied, please try again ..."
            echo $RESET
        fi
        sleep 5
    done
}

function uncompress_file(){

    clear
    echo
    echo "  --------------------------------------------------"
    echo "  |                   BBDD Restore                 |"
    echo "  --------------------------------------------------"
    echo "  |                      STEP 2                    |"
    echo "  --------------------------------------------------"
    echo "  |                Uncompressing file              |"
    echo "  --------------------------------------------------"
    echo
    echo $BOLD
    impr "This step will finish automatically in some minutes"
    echo $RESET

    gunzip ${DIR}${FILE}

    if [[ $? -eq 0 ]]
    then
        impr "Uncompress has been finished successfully."
    else
        echo $RED
        impr "There was a problem while uncompressing."
        impr "Exiting" 5 ""
        echo $RESET
        exit 1
    fi
    sleep 3
}

function sql_truncate(){
    clear
    echo
    echo "  --------------------------------------------------"
    echo "  |                   BBDD Restore                 |"
    echo "  --------------------------------------------------"
    echo "  |                      STEP 3                    |"
    echo "  --------------------------------------------------"
    echo "  |  Truncate tables, views, packages, functions   |"
    echo "  --------------------------------------------------"
    echo
    echo $BOLD
    impr "This step will finish automatically in some minutes"
    echo $RESET

    sqlplus ${BBDD_DEST} @/scripts/truncateAll.sql

    if [[ $? -eq 0 ]]
    then
        impr "Truncate has been finished successfully."
    else
        echo $RED
        impr "There was a problem while Truncate."
        impr "Exiting" 5 ""
        echo $RESET
        exit 1
    fi
    sleep 3
}

function sql_import(){
    clear
    echo
    echo "  --------------------------------------------------"
    echo "  |                   BBDD Restore                 |"
    echo "  --------------------------------------------------"
    echo "  |                      STEP 4                    |"
    echo "  --------------------------------------------------"
    echo "  |                   Import data                  |"
    echo "  --------------------------------------------------"
    echo
    echo $BOLD
    impr "This step will finish automatically in some minutes"
    echo $RESET

    ${DB_IMP} ${BBDD_DEST} log=${LOG_DIR}.imp file=${DIR}${FILE} ignore=Y fromuser=${BASE_SOURCE} touser=${BASE_DEST} grants=no

    if [[ $? -eq 0 ]]
    then
        impr "Import has been finished successfully."
    else
        echo $RED
        impr "There was a problem while Import."
        impr "Exiting" 5 ""
        echo $RESET
        exit 1
    fi
    sleep 3
}

function sql_record() {
    SEARCH=${1}
    RECORDS=$(echo "${BBDD_DEST}
    set heading off
    set feedback off
    set pages 0
    SELECT
    LISTAGG(obj, ', ') WITHIN GROUP (order by obj) "result"
    FROM
    select object_name as obj
    from user_objects
    where object_type like '${SEARCH} and status='INVALID'
    )
    ;
    exit" | sqlplus -s)

    if [[ ! -z ${RECORDS} ]]
    then
        echo "There are INVALID records for ${SEARCH}:"
        echo "      ${RECORDS}"
    fi
}

function sql_check() {
    TABLAS=""

    clear
    echo
    echo "  --------------------------------------------------"
    echo "  |                   BBDD Restore                 |"
    echo "  --------------------------------------------------"
    echo "  |                      STEP 5                    |"
    echo "  --------------------------------------------------"
    echo "  |              Checking imported data            |"
    echo "  --------------------------------------------------"
    echo
    echo $BOLD
    impr "This step will finish automatically in some minutes"
    echo $RESET

    ERROR_LINE=0

    VAR=$(cat ${LOG_DIR}.imp | grep -i error | sort | uniq | grep "IMP-" | grep -v "00017" | awk '(print $0 echo "|")')
    NUM=$(cat ${LOG_DIR}.imp | grep -i error | sort | uniq | grep "IMP-" | grep -v "00017" | wc -l)

    for (( c=1;c<=$NUM;c++ ))
    do
        line=$(echo $VAR | cut -d"|" -f$c | cut -d":" -f2)
        lineNumber=$(grep -n "${line}" ${LOG_DIR}.imp | cut -d":" -f1)

        echo "Line, Execution, ${line}"
        echo
        for numero in $lineNumber
        do
            if [[ ${line} == *1031*]]
            then
                lin=$(sed -n $((numero - 2))p ${LOG_DIR}.imp)
            else
                lin=$(sed -n $((numero - 1))p ${LOG_DIR}.imp)
            fi
            
            if [[ ${line} == *904* ]]
            then
                TABLAS=${TABLAS}","$(echo $lin | cut -d"\"" -f2)
                ERROR_LINE=1
            fi

            lin=$(sed -n $((numero + 1))p ${LOG_DIR}.imp)
        done
    done

    if [[ ${ERROR_LINE} -ne 0 ]]
    then
        TABLAS="${TABLAS:1}"
        echo $RED
        impr "There are error lines. Please check ${LOG_DIR}."
        impr "Tables with different structure will be removed and imported again."
        echo 
        import "Tables:" 10 ${TABLAS}
        echo $RESET
        echo
    else
        impr "There are no structure errors. Restore will continue ..."
    fi
    sleep 3
}

function sql_import_failed_tables(){
    if [[ -z $TABLAS ]]
    then
        return
    fi

    clear
    echo
    echo "  --------------------------------------------------"
    echo "  |                   BBDD Restore                 |"
    echo "  --------------------------------------------------"
    echo "  |                      STEP 5-A                  |"
    echo "  --------------------------------------------------"
    echo "  |     Drop fail tablas and re-importing again    |"
    echo "  --------------------------------------------------"
    echo
    echo $BOLD
    impr "This step will finish automatically in some minutes"
    echo $RESET
    impr "Tables to remove" 10 ${TABLAS}

    tablesToDrop=$(echo ${TABLAS} | sed 's/,/ /g')

    for tab in $tablesToDrop
    do
        impr "* Droping table" 10 ${tab}

        echo "${BBDD_DEST}
        drop tabl ${tab} CASCADE CONSTRAINTS;
        commit;
        exit" | sqlplus -s
    done

    echo 
    impr "Importing tables dropped" 5

    ${DB_IMP} ${BBDD_DEST} log=${LOG_DIR}.imp file=${DIR}${FILE} ignore=Y tables=${TABLAS} fromuser=${BASE_SOURCE} touser=${BASE_DEST} grants=no

    if [[ $? -eq 0 ]]
    then
        impr "Import has been finished successfully."
    else
        echo $RED
        impr "There was a problem while Import."
        impr "Exiting" 5 ""
        echo $RESET
        exit 1
    fi
    sleep 3
}

function sql_compile(){
    clear
    echo
    echo "  --------------------------------------------------"
    echo "  |                   BBDD Restore                 |"
    echo "  --------------------------------------------------"
    echo "  |                      STEP 6                    |"
    echo "  --------------------------------------------------"
    echo "  |                 Compile Objects                |"
    echo "  --------------------------------------------------"
    echo
    echo $BOLD
    impr "This step will finish automatically in some minutes"
    echo $RESET

    sqlplus ${BBDD} @/scripts/CompileObjects.sql

    if [[ $? -eq 0 ]]
    then
        impr "Compile has been finished successfully."
    else
        echo $RED
        impr "There was a problem while Compile."
        impr "Exiting" 5 ""
        echo $RESET
        exit 1
    fi
    sleep 3
}

function sql_rec(){
    clear
    echo
    echo "  --------------------------------------------------"
    echo "  |                   BBDD Restore                 |"
    echo "  --------------------------------------------------"
    echo "  |                      STEP 7                    |"
    echo "  --------------------------------------------------"
    echo "  |                 Checking Objects               |"
    echo "  --------------------------------------------------"
    echo
    echo $BOLD
    impr "This step will finish automatically in some minutes"
    echo $RESET

    sql_record "FUNCTION"
    sql_record "VIEW"
    sql_record "PROCEDURE"
    sql_record "PACKAGE%"

    sleep 3
}

function sql_stats(){
    clear
    echo
    echo "  --------------------------------------------------"
    echo "  |                   BBDD Restore                 |"
    echo "  --------------------------------------------------"
    echo "  |                      STEP 8                    |"
    echo "  --------------------------------------------------"
    echo "  |                 Installing stats                |"
    echo "  --------------------------------------------------"
    echo
    echo $BOLD
    impr "This step will finish automatically in some minutes"
    echo $RESET

    sqlplus ${BBDD} @/scripts/InstallingStats.sql

    if [[ $? -eq 0 ]]
    then
        impr "Stats instalation has been finished successfully."
    else
        echo $RED
        impr "There was a problem while Stats instalation."
        impr "Exiting" 5 ""
        echo $RESET
        exit 1
    fi
    sleep 3
}

##############################
# MAIN

clear
show_title

var_start=1
while [[ var_start -eq 1]]
do
    ask_for_env_parameters
    ask_for_date_parameter
    ask_for_final_database
    show_summary
done

# Save final variables
ENV=${final_origin}
FILE=${final_file}
BASE_SOURCE="..."
BASE_DEST=${final_final}
BBDD_DEST=${BASE_DEST}/${BASE_DEST}@"..."

# Start restore
get_file_from_origin
uncompress_file
sql_truncate
sql_import
sql_check
sql_import_failed_tables
sql_compile
sql_rec
sql_stats

remove_old_files