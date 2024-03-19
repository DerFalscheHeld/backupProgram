#!/usr/bin/bash

#Programmdateien erzeugen
function touchData {
  mkdir -p $programmDir
  if ! [ -s $backupFile ] ; then
    jo -p backup=$(jo -a $(jo ID= name= flag= dwmtokeep= source= destination= )) > $backupFile
  fi
  if ! [ -s $deactBackupFile ] ; then
    jo -p backup=$(jo -a $(jo ID= name= flag= dwmtokeep= source= destination= )) > $deactBackupFile
  fi
  if ! [ -s $trashBackupFile ] ; then
    jo -p backup=$(jo -a $(jo ID= name= flag= dwmtokeep= source= destination= )) > $trashBackupFile
  fi
  if ! test -s $backupPath ; then
    touch $backupPath
    echo /root/backup > $backupPath
  fi
  if ! [ -s $logs_with_errors ] ; then
    mkdir -p $logTempDir
    touch $logs_with_errors
  fi
}
