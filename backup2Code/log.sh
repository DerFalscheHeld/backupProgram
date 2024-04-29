#!/usr/bin/bash

#log
logTempDir="/tmp/backup_log"
logsWithErrors="$logTempDir/errorlogfiles.txt"

function log {
  logfile=$1
  shift
  origin=$1
  eval echo "'"$@"'" > >(sed "s:^:$logStyleInfo[bash] :" | timestamp | tee -a $logfile) 2> >(sed -e "s:^:$logStyleError[bash] :" | timestamp | tee -a $logfile 1>&2) | cat  
  eval bash -c "'"$@"'" > >(sed "s:^:$logStyleInfo[$origin] :" | timestamp | tee -a $logfile) 2> >(sed -e "s:^:$logStyleError[$origin] :" | timestamp | tee -a $logfile 1>&2) | cat
  if cat $logfile | grep '\[ERROR\]' > /dev/null 2>&1 ; then
    if ! cat $logsWithErrors | grep "$logfile" ; then
      echo -e "$logfile" >> $logsWithErrors
    fi
    exit=1
    skipRotatingDelete=1
  fi
}

function logText {
  logfile=$1
  shift
  echo -e "$@" | sed "s:^:$logStyleInfo[echo] :" | timestamp | tee -a $logfile
}

function timestamp {
  if $outputJurnalctlReady ; then
    while read data; do
      echo "$data"
    done
  else
    while read data; do
      echo "[`date +"%Y-%m-%d %H:%M:%S"`] $data"
    done
  fi
}
