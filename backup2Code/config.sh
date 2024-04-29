#!/usr/bin/bash

# default config
defaultConfigError="errorLogs"
defaultConfigColor="color"
defaultConfigZip="pigz"
defaultConfigBackupPath="/backup"

#config from JasonFile
function setConfigVar {
  outputFromExec="$(readConfig output)"
  if [[ "$outputFromExec" = "journalctlReady" ]] ; then
    outputJurnalctlReady=true
    logStyleError=""
    logStyleInfo=""
  else
    outputJurnalctlReady=false
    logStyleError="[ERROR] "
    logStyleInfo="[INFO ] "
  fi

  zipProgram="$(readConfig zipProgram)"
  case $zipProgram in
    pigz)
      zip="pigz -c -p$(cat /proc/cpuinfo | grep processor | wc -l) >"
      zipFileExtension=".gz"
      ;;
    gzip)
      zip="gzip -c >"
      zipFileExtension=".gz"
      ;;
    bzip2)
      zip="bzip2 -c >"
      zipFileExtension=".bz2"
      ;;
    zip)
      zip="zip "
      zipFileExtension=".zip"
      ;;
    xz)
      zip="xz -c -T$(cat /proc/cpuinfo | grep processor | wc -l) >"
      zipFileExtension=".xz"
      ;;

  esac

  font="$(readConfig font)"
  case $font in
    color)
      red="\033[31m"
      green="\033[32m"
      yellow="\033[33m"
      blue="\033[34m"
      magenta="\033[35m"
      cyan="\033[36m"
      lightRed="\033[1;31m"
      lightYellow="\033[1;33m"
      reverse="\033[7m"
      reset="\033[0m"
      resetEND="\033[0m"
      ;;
    cursiveColor)
      red="\033[31m\033[3m"
      green="\033[32m\033[3m"
      yellow="\033[33m\033[3m"
      blue="\033[34m\033[3m"
      magenta="\033[35m\033[3m"
      cyan="\033[36m\033[3m"
      lightRed="\033[7m\033[1;31m"
      lightYellow="\033[7m\033[1;33m"
      reverse="\033[7m\033[3m"
      reset="\033[0m\033[3m"
      resetEND="\033[0m"
      ;;
    cursive)
      red="\033[3m"
      green="\033[3m"
      yellow="\033[3m"
      blue="\033[3m"
      magenta="\033[3m"
      cyan="\033[3m"
      lightRed="\033[3m"
      lightYellow="\033[3m"
      reverse="\033[3m"
      reset="\033[0m\033[3m"
      resetEND="\033[0m"
      ;;
    unicorn)
      red="\033[37m\033[$(($RANDOM%6+41))}m"
      green="\033[30m\033[$(($RANDOM%6+41))m"
      yellow="\033[30m\033[$(($RANDOM%6+41))m"
      blue="\033[37m\033[$(($RANDOM%6+41))m"
      magenta="\033[37m\033[$(($RANDOM%6+41))m"
      cyan="\033[30m\033[$(($RANDOM%6+41))m"
      lightRed=""
      lightYellow=""
      reverse=""
      reset="\033[0m\033[30m\033[$(($RANDOM%6+41))m"
      resetEND="\033[0m"
      ;;
    *|normal)
      red=""
      green=""
      yellow=""
      blue=""
      magenta=""
      cyan=""
      lightRed=""
      lightYellow=""
      reverse=""
      reset=""
      resetEND=""
      ;;
  esac  
  backupPath="$(readConfig backupPath)"
}