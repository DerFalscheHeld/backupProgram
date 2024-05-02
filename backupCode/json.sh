#!/usr/bin/bash

backupJsonArray="backups"
deactJsonArray="deactivationlist"
trashJsonArray="trashbin"

createTempJsonFileForRead=0

function readFromArray {
  if [[ $createTempJsonFileForRead -eq 0 ]] ; then
    tempJsonFileForRead=$(cat $mainDataFile | jq -r . )
    createTempJsonFileForRead=1
  fi
  if [[ "$2" = "" ]] ; then
    echo $tempJsonFileForRead | jq -r .$1[].$3
  else
    echo $tempJsonFileForRead | jq -r .$1[$2].$3
  fi
}

# $1 [arrayName] $2 [name=$2] $3 [flag=$3] $4 [dwmtokeep=$4] $5 [source=$5] $6 [destination=$6]
function writeToArray {
  count=0
  while ! [[ "`jq .$1[$count].name $mainDataFile`" = "null" ]] ; do
    count=$(($count+1))
  done
  array=".$1[$count]"
  shift
  jsonFile=$(cat $mainDataFile)
  echo $jsonFile | jq "$array.name=\"$1\" | $array.flag=\"$2\" | $array.dwmtokeep=\"$3\" | $array.source=\"$4\" | $array.destination=\"$5\"" > $mainDataFile
}

# $1 [array] $2 [number from array]
# if $2 "" then delete the whole array
function deletefromArray {
  tempJsonFile=$(cat $mainDataFile)
  echo $tempJsonFile | jq ".$1[$2]=null" | jq "del(..|nulls)" > $mainDataFile
}

# $1 configname + configvalue separated by =
function writeConfig {
  if ! [[ "$(jq .config[0].$1 $mainDataFile)" = "null" ]] ; then
    tempJsonFile="$(cat $mainDataFile)"
    echo -e $tempJsonFile | jq .config[0].$1=\"$2\" > $mainDataFile
  else
    error "${red}Error : ${yellow}'$1=$2' is not a config option"
  fi
}

# $1 configname you want to read
# if $1 "" then read the whole array
function readConfig {
  if [[ "$1" = "" ]] ; then
    jq -r .config[] $mainDataFile
  else
    jq -r .config[0].$1 $mainDataFile
  fi
}


function createNewJsonFile {
  echo "{ \"$backupJsonArray\": [],\
          \"$deactJsonArray\": [],\
          \"$trashJsonArray\": [],\
          \"config\": [{\
            \"version\": \"\",\
            \"configFileVersion\": \"\",\
            \"output\": \"$defaultConfigError\",\
            \"zipProgram\": \"$defaultConfigZip\",\
            \"font\": \"$defaultConfigColor\",\
            \"backupPath\": \"$defaultConfigBackupPath\"\
            }]}" | jq . > $mainDataFile
}
