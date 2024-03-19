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
      execLogfile="$tempDir/${date}__start_${execStartTime}__name_$execName.log.temp"

      echo -e "Logfile: $execLogFile\n" > $execLogfile

      echo "[`date +"%Y-%m-%d %H:%M"`] [mkdir] :" >> $execLogfile
      if [[ "`echo "$execPath" | cut -b 1`" = "*" ]] ; then
        mkdir -pv `cat $backupPath``echo "$execPath" | cut -b 2-` >> $execLogfile
        cd `cat $backupPath``echo "$execPath" | cut -b 2-` >> $execLogfile
        execPath=`cat $backupPath``echo "$execPath" | cut -b 2-`
      else
        mkdir -pv $execPath >> $execLogfile
        cd $execPath >> $execLogfile
        execPath=$execPath
      fi
      mkdir -pv "${date}_${execStartTime}" >> $execLogfile
      cd "${date}_${execStartTime}" >> $execLogfile


      echo "[`date +"%Y-%m-%d %H:%M"`] [Backup] : START" >> $execLogfile
      if [[ "$flagBash" = "bash" ]] ; then
        echo "[`date +"%Y-%m-%d %H:%M"`] [bash] : " >> $execLogfile
        bash -c "$execSource" >(tee -a $execLogfile) 2>(tee -a $execLogfile >&2)
      elif [[ "$flagImg" = "img" ]] && [[ "$flagZip" = "" ]]  ; then
        echo "[`date +"%Y-%m-%d %H:%M"`] [dd] : " >> $execLogfile
        dd if=$execSource of=${date}__start_${execStartTime}__name_${execName}.img.part 2>> $execLogfile
        execEndTime=`date +"%H-%M"`
        echo -n "[`date +"%Y-%m-%d %H:%M"`] [mv] : " >> $execLogfile
        mv -v ${date}__start_${execStartTime}__name_${execName}.img.part ${date}_${execStartTime}/${date}__start_${execStartTime}__end_${execEndTime}__name_${execName}.img >> $execLogfile
      elif [[ "$flagImg" = "img" ]] && [[ "$flagZip" = "zip" ]]  ; then
        echo "[`date +"%Y-%m-%d %H:%M"`] [dd and $zipProg] : " >> $execLogfile
        (
          dd if=$execSource | $zip -c > ${date}__start_${execStartTime}__name_${execName}.img.gz.part
        ) 2>> $execLogfile
        execEndTime=`date +"%H-%M"`
        echo -n "[`date +"%Y-%m-%d %H:%M"`] [mv] : " >> $execLogfile
        mv -v ${date}__start_${execStartTime}__name_${execName}.img.gz.part ${date}__start_${execStartTime}__end_${execEndTime}__name_${execName}.img.gz >> $execLogfile

      elif [[ "$flagCopy" = "copy" ]] ; then
        echo "[`date +"%Y-%m-%d %H:%M"`] [cp] : " >> $execLogfile
        cp -r "$execSource" . >> $execLogfile
      fi

      ##  TAR und ZIP  ##

      if [[ "$flagZip" = "zip" ]] && [[ "$flagTar" = "tar" ]] ; then
        echo "[`date +"%Y-%m-%d %H:%M"`] [tar and $zipProg] :" >> $execLogfile
        (
          cd $execSource
          execSourceEmpty=$(echo *) # "*" then its empty
          if [[ "$execSourceEmpty" != "*" ]] ; then
            tar c * | $zip -c > "$execPath/${date}_${execStartTime}/${date}__start_${execStartTime}__name_${execName}.tar.gz.part"
            execEndTime=`date +"%H-%M"`
            echo "[`date +"%Y-%m-%d %H:%M"`] [tar and $zipProg] : END"
            echo -n "[`date +"%Y-%m-%d %H:%M"`] [mv] : "
            mv -v "$execPath/${date}_${execStartTime}/${date}__start_${execStartTime}__name_${execName}.tar.gz.part" "$execPath/${date}_${execStartTime}/${date}__start_${execStartTime}__end_${execEndTime}__name_${execName}.tar.gz" >> $execLogfile
          else
            echo "[`date +"%Y-%m-%d %H:%M"`] [tar and $zipProg] : Directory empty, no data to save!"
            echo "[`date +"%Y-%m-%d %H:%M"`] [tar and $zipProg] : END"
            echo "[`date +"%Y-%m-%d %H:%M"`] [rmdir] : Delete empty folder $execPath/${date}_${execStartTime}"
            rmdir $execPath/${date}_${execStartTime}
          fi
        ) >> $execLogfile
      elif [[ "$flagZip" = "zip" ]] && [[ "$flagTar" = "" ]] && [[ "$flagImg" = "" ]] ; then
        echo "[`date +"%Y-%m-%d %H:%M"`] [$zipProg] :" >> $execLogfile
        execSourceEmpty=$(echo *)
        if [[ "$execSourceEmpty" != "*" ]] ; then
          $zip -r * 2>> $execLogfile
        else
          echo "[`date +"%Y-%m-%d %H:%M"`] [$zipProg] : Directory empty, no data to save!" >> $execLogfile
          echo "[`date +"%Y-%m-%d %H:%M"`] [rmdir] : Delete empty folder $execPath/${date}_${execStartTime}"
          rmdir $execPath/${date}_${execStartTime}
        fi
        echo "[`date +"%Y-%m-%d %H:%M"`] [$zipProg] : END" >> $execLogfile
      elif [[ "$flagZip" = "" ]] && [[ "$flagTar" = "tar" ]] ; then
        echo "[`date +"%Y-%m-%d %H:%M"`] [tar] :" >> $execLogfile
        (
          cd $execSource
          execSourceEmpty=$(echo *) # "*" then its empty
          echo "execSourceEmpty : $execSourceEmpty"
          if [[ "$execSourceEmpty" != "*" ]] ; then
            tar cf "$execPath/${date}_${execStartTime}/${date}__start_${execStartTime}__name_${execName}.tar.part" *
            echo "[`date +"%Y-%m-%d %H:%M"`] [tar] : END"
            execEndTime=`date +"%H-%M"`
            echo -n "[`date +"%Y-%m-%d %H:%M"`] [mv] : "
            mv -v "$execPath/${date}_${execStartTime}/${date}__start_${execStartTime}__name_${execName}.tar.part" "$execPath/${date}_${execStartTime}/${date}__start_${execStartTime}__name_${execName}.tar" >> $execLogfile

          else
            echo "[`date +"%Y-%m-%d %H:%M"`] [tar] : Directory empty, no data to save!" >> $execLogfile
            echo "[`date +"%Y-%m-%d %H:%M"`] [tar] : END"
            echo "[`date +"%Y-%m-%d %H:%M"`] [rmdir] : Delete empty folder $execPath/${date}_${execStartTime}"
            rmdir $execPath/${date}_${execStartTime}
          fi
        ) >> $execLogfile
      fi

      echo -e "[`date +"%Y-%m-%d %H:%M"`] [Backup] : END \n" >> $execLogfile

      ##  rotating delete  ##

      echo -e "[`date +"%Y-%m-%d %H:%M"`] [Backup] : check for old backups" >> $execLogfile
      cd ..
      for f in * ; do
        if [[ $f =~ ^[0-9][0-9][0-9][0-9]\-[0-9][0-9]\-[0-9][0-9].*$ ]] ; then
          today_seconds=$(date -d ${date:0:10} +%s)
          file_seconds=$(date -d ${f:0:10} +%s)
          if [[ "$flagDay" = "d" ]] ; then
            day=$((24*60*60))
            if [[ $(($today_seconds - $execNumber * $day)) -ge $file_seconds ]] ; then
              echo "[`date +"%Y-%m-%d %H:%M"`] [Backup] : delete old backup: $f" >> $execLogfile
              rm -rf "$f" >> $execLogfile
            fi
          elif [[ "$flagWeek" = "w" ]] ; then
            week=$((24*60*60*7))
            if [[ $(($today_seconds - $execNumber * $week)) -ge $file_seconds ]] ; then
              echo "[`date +"%Y-%m-%d %H:%M"`] [Backup] : delete old backup: $f" >> $execLogfile
              rm -rf "$f" >> $execLogfile
            fi
          elif [[ "$flagMonth" = "m" ]] ; then
            month=$((24*60*60*31))
            if [[ $(($today_seconds - $execNumber * $month)) -ge $file_seconds ]] ; then
              echo "[`date +"%Y-%m-%d %H:%M"`] [Backup] : delete old backup: $f" >> $execLogfile
              rm -rf "$f" >> $execLogfile
            fi
          fi
        fi
      done

      ##  LOG or NOT  ##

      if [[ "$flagLog" = "log" ]] ; then
        execEndTime=`date +"%H-%M"`
        execLogName="${date}__start_${execStartTime}__end_${execEndTime}__name_${execName}.log"
        echo -e "\n#-#-#   END Logfile: ${execLogName}   #-#-#\n\n" >> $execLogfile
        sed -i -e 1c"Logfile: ${execLogName}" $execLogfile
        mv $execLogfile $execPath/"${execLogName}"
      else
        rm -f $execLogfile
      fi
    fi
    resetFlags
  done
}