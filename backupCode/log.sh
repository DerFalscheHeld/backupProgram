#!/usr/bin/bash

#log
logTempDir="/tmp/backup_log_$BASHPID"
logsWithErrors="$logTempDir/errorlogfiles.txt"

out_fifo=$logTempDir/out_fifo
err_fifo=$logTempDir/err_fifo


function log {
  logfile=$1
  shift
  origin=$1
  mkfifo $out_fifo $err_fifo

  eval echo '"'$@'"' | sed -u "s:^:$logStyleInfo[bash] :" | timestamp | tee -a $logfile

  ( cat $out_fifo | sed -u "s:^:$logStyleInfo[$origin] :" | timestamp | tee -a $logfile )&
  ( cat $err_fifo | sed -u "s:^:$logStyleError[$origin] :" | timestamp | tee -a $logfile 1>&2 )&
  eval bash -c '"'$@'"' 1>$out_fifo 2>$err_fifo
  wait
  
  rm $out_fifo $err_fifo

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
