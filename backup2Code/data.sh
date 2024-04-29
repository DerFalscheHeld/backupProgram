#!/usr/bin/bash

#Programmdateien erzeugen
function touchData {
  mkdir -p $programmDir
  if ! [ -s $backupFile ] ; then
    mkdir -p $configDir
    createNewJsonFile
  fi
}

function touchLogData {
  if ! [ -s $logsWithErrors ] ; then
    mkdir -p $logTempDir
    touch $logsWithErrors
  fi
}
