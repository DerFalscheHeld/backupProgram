#!/usr/bin/bash

function resetFlags {
  breakval=0
  flagError=0

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
    m[0-9][0-9])    flagCheckMonth=1
                    if [[ "`date +'%d'`" = "`echo $1 | cut -b 2-3`" ]] || [[ $execAllBackups -eq 1 ]] ; then
                      flagMonth="m"
                    else
                      breakval=1
                    fi
                    if [[ "`echo $1 | cut -b 2-3`" = "00" ]] ; then
                      flagcheck=1
                      flagCheckMonth=0
                    elif [[ "`echo $1 | cut -b 2-3`" -gt "31" ]] ; then
                      flagcheck=1
                      flagCheckMonth=0
                    fi
                    ;;

    w[0-6])         flagCheckWeek=1
                    if [[ "`date +'%w'`" = "`echo $1 | cut -b 2`" ]] || [[ $execAllBackups -eq 1 ]] ; then
                      flagWeek="w"
                    else
                      breakval=1
                    fi
                    if [[ "`echo $1 | cut -b 2`" -gt "6" ]] ; then
                      flagcheck=1
                      flagCheckWeek=0
                    fi
                    ;;

    day)            flagCheckDay=1
                    flagDay="d"
                    ;;
    copy)           flagCopy="copy"
                    flagError=$(($flagError+1))
                    ;;
    bash)           flagBash="bash"
                    flagError=$(($flagError+1))
                    ;;
    img)            flagImg="img"
                    flagError=$(($flagError+1))
                    ;;
    zip)            flagZip="zip"
                    ;;
    tar)            flagTar="tar"
                    flagError=$(($flagError+1))
                    ;;
    log)            flagLog="log"
                    ;;
    *)              breakval=1
                    flagcheck=1
                    ;;
  esac
}