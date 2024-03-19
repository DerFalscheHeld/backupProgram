#!/usr/bin/bash

function execution {
  for i in  $(seq 0 $(( $(jq -r .backup[].ID $backupFile | wc -l)-1))) ; do
    Flagcut=$(jq -r .backup[$i].flag $backupFile)
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

    if [[ $(jq -r .backup[$i].flag $backupFile) = "null" ]] ; then
      breakval=1
    fi

    if [[ $breakval -eq 0 ]] || [[ $execAllBackups -eq 1 ]] && [[ $breakval -eq 0 ]] ; then

      execName=$(jq -r .backup[$i].name $backupFile)
      execNumber=$(jq -r .backup[$i].dwmtokeep $backupFile)
      execSource=$(jq -r .backup[$i].source $backupFile)
      execPath=$(jq -r .backup[$i].destination $backupFile)

      date=`date +"%Y-%m-%d"`
      execStartTime=`date +"%H-%M"`
      execLogFile="$logTempDir/${date}__start_${execStartTime}__name_$execName.log.temp"
      
      logText $execLogFile "Logfile: $execLogFile\n"

      if [[ "`echo "$execPath" | cut -b 1`" = "*" ]] ; then
        execPath=`cat $backupPath``echo "$execPath" | cut -b 2-`
      fi
      
      log $execLogFile mkdir -pv $execPath
      log $execLogFile cd $execPath
      log $execLogFile mkdir -pv "${date}_${execStartTime}"
      log $execLogFile cd "${date}_${execStartTime}"

      logText $execLogFile "START"
      if [[ "$flagBash" = "bash" ]] ; then
        log $execLogFile "$execSource"
      elif [[ "$flagImg" = "img" ]] && [[ "$flagZip" = "" ]]  ; then
        log $execLogFile dd if=$execSource of=${date}__start_${execStartTime}__name_${execName}.img.part
        execEndTime=`date +"%H-%M"`
        log $execLogFile mv -v ${date}__start_${execStartTime}__name_${execName}.img.part ${date}_${execStartTime}/${date}__start_${execStartTime}__end_${execEndTime}__name_${execName}.img
      elif [[ "$flagImg" = "img" ]] && [[ "$flagZip" = "zip" ]]  ; then
        log $execLogFile dd if=$execSource | $zip -c > ${date}__start_${execStartTime}__name_${execName}.img.gz.part
        execEndTime=`date +"%H-%M"`
        log $execLogFile mv -v ${date}__start_${execStartTime}__name_${execName}.img.gz.part ${date}__start_${execStartTime}__end_${execEndTime}__name_${execName}.img.gz

      elif [[ "$flagCopy" = "copy" ]] ; then
        log $execLogFile cp -r "$execSource" .
      fi

      ##  TAR und ZIP  ##

      if [[ "$flagZip" = "zip" ]] && [[ "$flagTar" = "tar" ]] ; then
        echo "[tar and $zipProg] :" | log $execLogFile
        (
          cd $execSource
          execSourceEmpty=$(echo *) # "*" then its empty
          if [[ "$execSourceEmpty" != "*" ]] ; then
            tar c * | $zip -c > "$execPath/${date}_${execStartTime}/${date}__start_${execStartTime}__name_${execName}.tar.gz.part"
            execEndTime=`date +"%H-%M"`
            echo "[tar and $zipProg] : END"
            echo -n "[mv] : "
            mv -v "$execPath/${date}_${execStartTime}/${date}__start_${execStartTime}__name_${execName}.tar.gz.part" "$execPath/${date}_${execStartTime}/${date}__start_${execStartTime}__end_${execEndTime}__name_${execName}.tar.gz" | log $execLogFile
          else
            echo "[tar and $zipProg] : Directory empty, no data to save!"
            echo "[tar and $zipProg] : END"
            echo "[rmdir] : Delete empty folder $execPath/${date}_${execStartTime}"
            rmdir $execPath/${date}_${execStartTime}
          fi
        ) | log $execLogFile
      elif [[ "$flagZip" = "zip" ]] && [[ "$flagTar" = "" ]] && [[ "$flagImg" = "" ]] ; then
        echo "[$zipProg] :" | log $execLogFile
        execSourceEmpty=$(echo *)
        if [[ "$execSourceEmpty" != "*" ]] ; then
          $zip -r * | log $execLogFile
        else
          echo "[$zipProg] : Directory empty, no data to save!" | log $execLogFile
          echo "[rmdir] : Delete empty folder $execPath/${date}_${execStartTime}"
          rmdir $execPath/${date}_${execStartTime}
        fi
        echo "[$zipProg] : END" | log $execLogFile
      elif [[ "$flagZip" = "" ]] && [[ "$flagTar" = "tar" ]] ; then
        echo "[tar] :" | log $execLogFile
        (
          cd $execSource
          execSourceEmpty=$(echo *) # "*" then its empty
          echo "execSourceEmpty : $execSourceEmpty"
          if [[ "$execSourceEmpty" != "*" ]] ; then
            tar cf "$execPath/${date}_${execStartTime}/${date}__start_${execStartTime}__name_${execName}.tar.part" *
            echo "[tar] : END"
            execEndTime=`date +"%H-%M"`
            echo -n "[mv] : "
            mv -v "$execPath/${date}_${execStartTime}/${date}__start_${execStartTime}__name_${execName}.tar.part" "$execPath/${date}_${execStartTime}/${date}__start_${execStartTime}__name_${execName}.tar" | log $execLogFile

          else
            echo "[tar] : Directory empty, no data to save!" | log $execLogFile
            echo "[tar] : END"
            echo "[rmdir] : Delete empty folder $execPath/${date}_${execStartTime}"
            rmdir $execPath/${date}_${execStartTime}
          fi
        ) | log $execLogFile
      fi

      logText $execLogFile "END \n"

      ##  rotating delete  ##

      
      if [[ $exit -eq 0 ]] ; then
        logText $execLogFile "[Backup] : check for old backups"
        cd ..
        for f in * ; do
          if [[ $f =~ ^[0-9][0-9][0-9][0-9]\-[0-9][0-9]\-[0-9][0-9].*$ ]] ; then
            today_seconds=$(date -d ${date:0:10} +%s)
            file_seconds=$(date -d ${f:0:10} +%s)
            if [[ "$flagDay" = "d" ]] ; then
              day=$((24*60*60))
              if [[ $(($today_seconds - $execNumber * $day)) -ge $file_seconds ]] ; then
                logText $execLogFile "[Backup] : delete old backup: $f"
                log $execLogFile rm -rf "$f"
              fi
            elif [[ "$flagWeek" = "w" ]] ; then
              week=$((24*60*60*7))
              if [[ $(($today_seconds - $execNumber * $week)) -ge $file_seconds ]] ; then
                logText $execLogFile "[Backup] : delete old backup: $f"
                log $execLogFile rm -rf "$f"
              fi
            elif [[ "$flagMonth" = "m" ]] ; then
              month=$((24*60*60*31))
              if [[ $(($today_seconds - $execNumber * $month)) -ge $file_seconds ]] ; then
                logText $execLogFile "[Backup] : delete old backup: $f"
                log $execLogFile rm -rf "$f"
              fi
            fi
          fi
        done
      fi

      ##  LOG or NOT  ##

      if [[ "$flagLog" = "log" ]] ; then
        execEndTime=`date +"%H-%M"`
        execLogName="${date}__start_${execStartTime}__end_${execEndTime}__name_${execName}.log"
        logText $execLogFile "END Logfile: ${execLogName}\n"
        sed -i -e 1c"[`date +"%Y-%m-%d %H:%M"`] [INFO ] [backup] Logfile: ${execLogName}" $execLogFile
        echo >> $execLogFile
        cp $execLogFile $execPath/"${execLogName}"
      fi
    fi
    resetFlags
  done
}