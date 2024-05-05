#!/usr/bin/bash

execAllBackups=0

function execution {
  touchLogData
  for i in  $(seq 0 $(( $(readFromArray $backupJsonArray "" name | wc -l)-1))) ; do
    Flagcut=$(readFromArray $backupJsonArray $i flag)
    Flag=`echo $Flagcut | cut -b 1`
    if [[ "$Flag" = "/" ]] ; then
      count=1
      while : ; do
        count=$(($count+1))
        Flag=`echo $Flagcut | cut -d"/" -f$count`
        if [[ "$Flag" = "" ]] ; then
          break
        elif [[ $flagcheck -eq 1 ]] && [[ $execAllBackups -eq 0 ]] ; then
          break
        elif [[ $breakval -eq 1 ]] && [[ $execAllBackups -eq 0 ]] ; then
          break
        fi
        readFlag $Flag
      done
    fi

    if [[ $(readFromArray $backupJsonArray $i flag) = "null" ]] ; then
      breakval=1
    fi

    if [[ $breakval -eq 0 ]] || [[ $execAllBackups -eq 1 ]] && [[ $breakval -eq 0 ]] ; then

      execName=$(readFromArray $backupJsonArray $i name)
      execNumber=$(readFromArray $backupJsonArray $i dwmtokeep)
      execSource=$(readFromArray $backupJsonArray $i source)
      execPath=$(readFromArray $backupJsonArray $i destination)

      date=`date +"%Y-%m-%d"`
      execStartTime=`date +"%H-%M"`
      execLogFile="$logTempDir/${date}__start_${execStartTime}__name_$execName.log.temp"

      logText $execLogFile "Logfile: $execLogFile\n"

      if [[ "`echo "$execPath" | cut -b 1`" = "*" ]] ; then
        execPath="$backupPath$(echo "$execPath" | cut -b 2-)"
      fi

      log $execLogFile mkdir -pv "$execPath"
      log $execLogFile cd "$execPath"
      cd "$execPath"
      log $execLogFile mkdir -pv "${date}_${execStartTime}"
      log $execLogFile cd "${date}_${execStartTime}"
      cd "${date}_${execStartTime}"

      if [[ "$flagBash" = "bash" ]] ; then
        log $execLogFile "${execSource}"
      elif [[ "$flagImg" = "img" ]] && [[ "$flagZip" = "" ]]  ; then
        log $execLogFile dd status=none if=$execSource of=${date}__start_${execStartTime}__name_${execName}.img.part
        execEndTime=`date +"%H-%M"`
        log $execLogFile mv -v ${date}__start_${execStartTime}__name_${execName}.img.part ${date}_${execStartTime}/${date}__start_${execStartTime}__end_${execEndTime}__name_${execName}.img
      elif [[ "$flagImg" = "img" ]] && [[ "$flagZip" = "zip" ]]  ; then
        log $execLogFile "dd status=none if=$execSource | $zip ${date}__start_${execStartTime}__name_${execName}.img${zipFileExtension}.part"
        execEndTime=`date +"%H-%M"`
        log $execLogFile mv -v ${date}__start_${execStartTime}__name_${execName}.img${zipFileExtension}.part ${date}__start_${execStartTime}__end_${execEndTime}__name_${execName}.img${zipFileExtension}
      fi

      ##  TAR und ZIP  ##

      if [[ "$flagZip" = "zip" ]] && [[ "$flagTar" = "tar" ]] ; then
        log $execLogFile cd $execSource
        cd $execSource
        execSourceEmpty=$(echo *) # "*" then its empty
        if [[ "$execSourceEmpty" != "*" ]] ; then
          log $execLogFile "tar c * | $zip \"$execPath/${date}_${execStartTime}/${date}__start_${execStartTime}__name_${execName}.tar${zipFileExtension}.part\""
          execEndTime=`date +"%H-%M"`
          log $execLogFile mv -v "$execPath/${date}_${execStartTime}/${date}__start_${execStartTime}__name_${execName}.tar${zipFileExtension}.part" "$execPath/${date}_${execStartTime}/${date}__start_${execStartTime}__end_${execEndTime}__name_${execName}.tar${zipFileExtension}"
        else
          logText $execLogFile "tar: Directory empty, no data to save!"
          log $execLogFile rmdir $execPath/${date}_${execStartTime}
        fi
      elif [[ "$flagZip" = "" ]] && [[ "$flagTar" = "tar" ]] ; then
        log $execLogFile cd $execSource
        cd $execSource
        execSourceEmpty=$(echo *) # "*" then its empty
        if [[ "$execSourceEmpty" != "*" ]] ; then
          log $execLogFile "tar cf \"$execPath/${date}_${execStartTime}/${date}__start_${execStartTime}__name_${execName}.tar.part\" *"
          execEndTime=`date +"%H-%M"`
          log $execLogFile mv -v "$execPath/${date}_${execStartTime}/${date}__start_${execStartTime}__name_${execName}.tar.part" "$execPath/${date}_${execStartTime}/${date}__start_${execStartTime}__name_${execName}.tar"
        else
          logText $execLogFile "Directory empty, no data to save!"
          log $execLogFile rmdir $execPath/${date}_${execStartTime}
        fi
      fi

      ##  rotating delete  ##
      if [[ $skipRotatingDelete -eq 0 ]] ; then
        logText $execLogFile ""
        log $execLogFile cd $execPath
        cd $execPath
        logText $execLogFile "Check for old backups"
        for f in * ; do
          if [[ $f =~ ^[0-9][0-9][0-9][0-9]\-[0-9][0-9]\-[0-9][0-9].*$ ]] ; then
            today_seconds=$(date -d ${date:0:10} +%s)
            file_seconds=$(date -d ${f:0:10} +%s)
            if [[ "$flagDay" = "d" ]] ; then
              day=$((24*60*60))
              if [[ $(($today_seconds - $execNumber * $day)) -ge $file_seconds ]] ; then
                logText $execLogFile "Delete old backup: $f"
                log $execLogFile rm -rf "$f"
              fi
            elif [[ "$flagWeek" = "w" ]] ; then
              week=$((24*60*60*7))
              if [[ $(($today_seconds - $execNumber * $week)) -ge $file_seconds ]] ; then
                logText $execLogFile "Delete old backup: $f"
                log $execLogFile rm -rf "$f"
              fi
            elif [[ "$flagMonth" = "m" ]] ; then
              month=$((24*60*60*31))
              if [[ $(($today_seconds - $execNumber * $month)) -ge $file_seconds ]] ; then
                logText $execLogFile "Delete old backup: $f"
                log $execLogFile rm -rf "$f"
              fi
            fi
          fi
        done
        logText $execLogFile ""
      else
        skipRotatingDelete=0
      fi

      ##  LOG or NOT  ##

      if [[ "$flagLog" = "log" ]] ; then
        execEndTime=`date +"%H-%M"`
        execLogName="${date}__start_${execStartTime}__end_${execEndTime}__name_${execName}.log"
        logText $execLogFile "END Logfile: ${execLogName}"
        execLogNameToWriteInTheFirstLine=$(cat $execLogFile | grep "$execLogFile" | sed -e "s:$execLogFile:$execLogName:g")
        sed -i -e 1c"$execLogNameToWriteInTheFirstLine" $execLogFile
        echo >> $execLogFile
        cp $execLogFile $execPath/"${execLogName}"
      fi
    fi
    resetFlags
  done
}
