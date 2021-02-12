#!/bin/bash

function shell_log(){
    echo "$(date +%Y%m%d-%H:%M:%S) - ${1}"
}

HOME=/home/alejandro

#source /home/alejandro/anaconda3/bin/activate
export DISPLAY=":0"

export PATH=${HOME}:/usr/bin:/home/alejandro/anaconda3/bin:/home/alejandro/anaconda3/condabin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin

log=${HOME}/logs/Check_disk_free.log

disk='/dev/sda2' 
line=$(df -h --output=source,pcent | grep ${disk})
percent=$(echo ${line} | sed -e 's/\t/ /g' | cut -d" " -f2 | sed -e 's/%//g')
maximo=80
HOME_PYTHON=${HOME}/python_scripting

if [[ $((${percent})) > ${maximo} ]]
then
    shell_log "ATENCION! El valor fue de ${percent}. Se superó el máximo de ${maximo}%." >>$log
    python ${HOME_PYTHON}/Disk_free.py ${percent} ${maximo} &
else
	shell_log "El valor fue de ${percent}% (Máx.: ${maximo}). Sin problemas." >>$log
fi

sleep 5

exit 0
