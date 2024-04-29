#!/usr/bin/bash

#Variable zum unterbrechen der readFlag() funktion
breakval=0
flagcheck=0
flagCheckDay=0
flagCheckWeek=0
flagCheckMonth=0
flagTimeManyError=0
flagTimeLessError=0

#flagsyntax vals
flagMonth=""
flagWeek=""
flagDay=""
flagCopy=""
flagBash=""
flagZip=""
flagTar=""
flagLog=""
flagImg=""

function resetFlags {
  breakval=0
  flagCheckWeek=0
  flagCheckMonth=0
  flagCheckDay=0
  flagBash=""
  flagMonth=""
  flagWeek=""
  flagDay=""
  flagZip=""
  flagTar=""
  flagLog=""
  flagImg=""
  flagCopy=""
}

function readFlag {
  case $1 in
    m[0-9][0-9])    
      flagCheckMonth=1
      if [[ "`date +'%d'`" = "`echo $1 | cut -b 2-3`" ]] || [[ $execAllBackups -eq 1 ]] ; then
        flagMonth="m"
      else
        breakval=1
      fi
      if [[ "`echo $1 | cut -b 2-3`" = "00" ]] ; then
        flagTimeNumberError=1
        flagCheckMonth=0
      elif [[ "`echo $1 | cut -b 2-3`" -gt "31" ]] ; then
        flagTimeNumberError=1
        flagCheckMonth=0
      fi
      ;;

    w[0-6])         
      flagCheckWeek=1
      if [[ "`date +'%w'`" = "`echo $1 | cut -b 2`" ]] || [[ $execAllBackups -eq 1 ]] ; then
        flagWeek="w"
      else
        breakval=1
      fi
      if [[ "`echo $1 | cut -b 2`" -gt "6" ]] ; then
        flagTimeNumberError=1
        flagCheckWeek=0
      fi
      ;;

    day)            
      flagCheckDay=1
      flagDay="d"
      ;;
    bash)           
      flagBash="bash"
      flagToManyTaskError=$(($flagToManyTaskError+1))
      ;;
    img)            
      flagImg="img"
      flagZipCheck=1
      flagToManyTaskError=$(($flagToManyTaskError+1))
      ;;
    tar)            
      flagTar="tar"
      flagZipCheck=1
      flagToManyTaskError=$(($flagToManyTaskError+1))
      ;;
    zip)            
      flagZip="zip"
      ;;
    log)            
      flagLog="log"
      ;;
    *)              
      breakval=1
      flagTimeNumberError=1
      ;;
  esac
}
