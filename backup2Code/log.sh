#!/usr/bin/bash

function log {
  logfile=$1
  shift
  origin=$1
  comand=$@
  #echo "comand=$comand"
  eval "$comand" > >(sed "s:^:[INFO ] [$origin] :" | timestamp ) 2> >(sed -e "s:^:[ERROR] [$origin] :" | timestamp | tee -a $logfile 1>&2) | cat | tee -a $logfile
  if cat $logfile | grep '\[ERROR\]' > /dev/null 2>&1 ; then
    echo -e "$logfile" >> $logs_with_errors
    exit=1
  fi
}

function logText {
  logfile=$1
  shift
  echo -e "$@" | sed "s:^:[INFO ] [backup] :" | timestamp | tee -a $logfile
}

function timestamp {
  while read data; do
    echo "[`date +"%Y-%m-%d %H:%M"`] $data"
  done
}