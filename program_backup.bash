#!/bin/bash

#backup [option] [name] [Flags] [days/months - to keep] [Source] [Destinantion]

#Flags:

#  /
#   m01-31 : monatliches Backup
#   w0-6   : wöchentliches Backup
#   day    : dayly Backup
#   bash   : bash befehl ausführen    ## bach -c "<string>"
#   copy   : cp befehl
#   img    : partition / device zu img datei machen
#   zip    : gzip
#   tar    : tar
#   log    : logging

############################################################
# Frankensteins Monster      echo $[test$x=2] >> /dev/null #
############################################################

version=backup-1.0.0

umask 00177

programmDir=/usr/local/etc/backup

backupFile=$programmDir/backup.json
backupPath=$programmDir/backup.path

# deactivation files
deactBackupFile=$programmDir/backupDeact.json

# trashbin files
trashBackupFile=$programmDir/backupTrash.json

#tempDir
tempDir=/tmp

#allgemeine val
count=1
separator=\#

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
}

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

#Variable zum unterbrechen der readFlag() funktion
breakval=0
flagcheck=0
flagCheckDay=0
flagCheckWeek=0
flagCheckMonth=0
flagTimeMany=0
flagTimeLess=0

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

standardBackuppath=""

function renderListHeader {
  echo -e "\n\033[0mstandard backup path : `cat $backupPath`\n * in destination/exec-path means standard backup path"
  if [[ "$1" = "$trashBackupFile" ]] ; then
    echo -e -n "\n\033[2m\033[33m\033[7m#-#-#-#-#- TRASHBIN -#-#-#-#-#\n\033[0m"
  elif [[ "$1" = "$deactBackupFile" ]] ; then
    echo -e -n "\n\033[2m\033[31m\033[7m#-#-#-#-#- DEACTIVATED -#-#-#-#-#\n\033[0m"
  else
    echo -e ""
  fi
}

function renderListTemp {

  echo -e "\033[32mID#|#\033[33m[name]#\033[36m[flag]#\033[35m[d/w/m_to_keep]#\033[34m[source/command]#\033[37m[destination/exec-path]\n"

  for i in  $(seq 0 $(($(jq -r .backup[].name $1 | wc -l)-1))) ; do
    listName=$(jq .backup[$i].name $1)
    if ! [[ "$listName" = "null" ]] ; then
      
      info0=$(jq -r ".backup[$i].ID" $1)
      info1=$(jq -r ".backup[$i].name" $1)
      info2=$(jq -r ".backup[$i].flag" $1)
      info3=$(jq -r ".backup[$i].dwmtokeep" $1)
      info4=$(jq -r ".backup[$i].source" $1)
      info5=$(jq -r ".backup[$i].destination" $1)

      echo -e "\033[32m${info0}#|#\033[33m${info1}#\033[36m${info2}#\033[35m${info3}#\033[34m${info4}#\033[37m${info5}"

    fi
  done
}

function list {
  renderTemp1=/dev/shm/.backupRender1.temp
  renderTemp2=/dev/shm/.backupRender2.temp
  renderTemp3=/dev/shm/.backupRender3.temp
  renderListTemp $1 > $renderTemp1
  column $renderTemp1 -t -s "#" > $renderTemp2
  cat $renderTemp2 > $renderTemp1
  sed -i "2,130d" $renderTemp1
  sed -i "1d" $renderTemp2

  renderListHeader $1 > $renderTemp3
  cat $renderTemp1 >> $renderTemp3
  allColumnsWidth="$((`cat $renderTemp1 | wc -m`-30))"
  echo -e -n "\033[31m" >> $renderTemp3
  for (( i = 0 ; i <= $allColumnsWidth ; i++ )) ; do
    printf "-" >> $renderTemp3
  done
  echo >> $renderTemp3
  cat $renderTemp2 >> $renderTemp3
  echo >> $renderTemp3
  cat $renderTemp3
  rm -rf $renderTemp1 $renderTemp2 $renderTemp3
}

function helpPage1 {

  echo -e "\033[37m
  backup [option] [arguments.....]

  \033[33m-------------
  \033[33m|  OPTIONS  |
  \033[33m-------------\033[37m
    ls []       >> Lists programmed backups
       [trash]  >> Lists trashbin
       [deact]  >> Lists deactivated backups
       [all]    >> Lists all 

    rm [1-99]   >> Delete a programmed backup with ID [1-99]
       [trash]  >> Delete the trashbin
       [deact]  >> Delete the deactivation list

    re [1-99]   >> Restore backup from trashbin with ID [1-99]

    log [1-99]   >> Shows all logs from the ID [1-99] in less

    path [Path]   >> Change standard backup path

    deact [1-99]   >> Deactivate backup with ID [1-99]

    react [1-99]   >> Reactivate backup with ID [1-99]

    exec           >> For daily execute use cron syntax | \033[36m0 0 * * * /usr/local/bin/backup exec \033[37m

    execAll        >> Execute all backups now

    prog           >> Programming a new backup - See example and flag page

    version / --version          >> Shows the program version.
    
    help / -h / --help []         >> Shows all help pages.
                       [options]  >> Shows help page no.1 (options page)
                       [flags]    >> Shows help page no.2 (flas page)
                       [examples] >> Shows help page no.3 (examples page)

    --restoreProgram [file] []      >> Restore program from backup file
                            [--yes] >> ... and skip confirmation by auto-affirming restoration

    --deleteAllProgramFiles []      >> Delete all program Files
                            [--yes] >> ... and skip confirmation by auto-affirming deletion
  "
}

function helpPage2 {

  echo -e "
  \033[33m-----------
  \033[33m|  FLAGS  |
  \033[33m-----------\033[37m
    Arguments are seperated by \"/\"
    e.g.:   /flag1/flag2/flag3/....

    day     >>  daily backup

    m[1-31] >>  monthly backup

    w[0-6]  >>  weekly backup
                0  1  2  3  4  5  6
                Su Mo Tu We Th Fr Sa

    copy    >>  Supply source path argument
                and an optional destination argument

                If no destination path is supplied,
                the standard path with [name] is used as destination

    bash    >>  The command will be executed in bash
                The command needs to be supplied with '
                Will be executed in exec-path

    img     >>  Save data as .img file

    zip     >>  Save data as .gz archive with gzip with single core

    tar     >>  Save data as .tar archive

    log     >>  Create log-file in destination folder
  "
}

function helpPage3 {
  helpTime=`date +"%Y-%m-%d--%H-%M"`
  helpDate=`date +"%Y-%m-%d"`

  echo -e "
  \033[33m-----------
  \033[33m|  USAGE  |
  \033[33m-----------\033[37m
  backup prog \033[33m[name] \033[36m[flag] \033[35m[d/w/m_to_keep] \033[34m[source/command] \033[37m[destination/exec-path]\033[37m
                |      |          |                |                    |
                |      |          |                |                    '->> destinaton path from backup
                |      |          |                |
                |      |          |                '->>  source path for backup / command to be executed
                |      |          |
                |      |          '->> Number of [days or weeks or months] to keep the old backups. Time unit determined by flag argument.
                |      |
                |      '->> flags (see help page No.2 \"flags\")
                |
                '->>  name of backup
  
  \033[33m--------------
  \033[33m|  EXAMPLES  |
  \033[33m--------------\033[37m
  
  \033[31m#\033[37m backup prog \033[33mbackup1 \033[36m/day/copy/img/ \033[35m20 \033[34m\"/source_path/\" \033[37m\"/destination/\"\033[37m
  backup \"source_path\" every day as an .img file into \"/destination/${helpTime}/${helpDate}__start_00-00__end_00-01__name_backup1.img\" and keep the last \033[35m20\033[37m days. 
  
  \033[31m#\033[37m backup prog \033[33mbackup1 \033[36m/day/copy/tar/zip/ \033[35m7 \033[34m\"/source_path/\"\033[37m
  backup \"source_path\" every day as an .tar.gz file into \"standard_backup_path/${helpTime}/${helpDate}__start_00-00__end_00-01__name_backup1.tar.gz\" and keep the last \033[35m7\033[37m days.
  
  \033[31m#\033[37m backup prog \033[33mbackup2 \033[36m/w0/bash/ \033[35m3 \033[34m'dd if=/dev/sda1 of=/dev/sda2 bs=512'\033[37m
  copy devcie sda1 onto sda2 with block size 512 every sunday. Excecute \033[35m\"\033[37m\033[31mroot@${HOSTNAME}\033[37m:\033[34m/standard_backup_path \033[31m#\033[37m dd if=/dev/sda1 of=/dev/sda2 bs=512\033[35m\"\033[37m. Keep the last \033[35m3\033[37m weeks.
  
  \033[31m#\033[37m backup prog \033[33mworld1 \033[36m/w1/bash/log/ \033[35m18 \033[34m'/customskript.bash' \033[37m\"/game/gameservers/\"\033[37m
  backup gameserver with name world1 via a custom skript executed in folder \"/game/gameservers/\". 
  Do it every Monday create a log file in the destination folder and keep the last \033[35m18\033[37m weeks.
  
  "
}

#vom re zum checken ob programiert wurde
reProgram=0

function programmBackup {
  name=0
  namelength=0
  flag=0
  flagsyntax=0
  number=0
  dest=0
  destsyntax=0

  if [[ "`cat $backupFile`" = "" ]] ; then
    name=1
    dest=1
  fi

  #Namen nicht doppelt erlauben
  for i in  $(seq 0 $(($(jq -r .backup[].name $backupFile | wc -l)-1))) ; do
    namecut=$(jq .backup[$i].name $backupFile)
    if [[ "$namecut" != "\"$1\"" ]] ; then
      name=1
    else
      name=0
      break
    fi
  done

  stringlength=`echo $1 | wc -m`
  if [[ $stringlength -gt 25 ]] ; then
    name=0
    namelength=1
  fi

  #Flag checken
  Flag=`echo $2 | cut -b 1`
  if [[ "$Flag" = "/" ]] ; then
    while : ; do
      count=$(($count+1))
      Flag=`echo $2 | cut -d"/" -f$count`
      if [[ "$Flag" = "" ]] ; then
        flag=1
        break
      fi
      readFlag $Flag
      if [[ $flagcheck -eq 1 ]] ; then
        flag=0
        break
      fi
    done
  else
    flagsyntax=1
  fi
  
  if [[ $flagCheckDay -eq 1 && $flagCheckWeek -eq 1 ]] ; then
    flagTimeMany=1
  elif [[ $flagCheckDay -eq 1 && $flagCheckMonth -eq 1 ]] ; then
    flagTimeMany=1
  elif [[ $flagCheckWeek -eq 1 && $flagCheckMonth -eq 1 ]] ; then
    flagTimeMany=1
  elif [[ $flagCheckDay -eq 0 && $flagCheckWeek -eq 0 && $flagCheckMonth -eq 0 ]] ; then
    flagTimeLess=1
  fi
  count=1

  #nicht tar bash copy und img zusammen erlauben
  if [[ $flagError -gt 1 ]] ; then
    flagError=1
  else
    flagError=0
  fi

  #day and month o keep muss eine Nummer sein
  if [[ "$3" =~ ^[0-9]$ ]] || [[ "$3" =~ ^[0-9][0-9]$ ]] ; then
    number=1
  else
    number=0
  fi


  # source check
  if [[ "bash" = "$flagBash" ]] || [[ "img" = "$flagImg" ]] ; then
    sour=1
  else
    if test -e $4 && test -d $4 ; then
      sour=1
    else
      sour=0
    fi
    if [[ "$4" = "" ]] ; then
      sour=0
    fi
  fi

  # destination path nicht doppelt erlauben
  for i in  $(seq 0 $(($(jq -r .backup[].destination $backupFile | wc -l)-1))) ; do
    destination=$(jq -r .backup[$i].destination $backupFile)
    if [[ "$5" = "" ]] ; then
      if [[ "$destination" != "*/$1" ]] ; then
        dest=1
      else
        dest=0
        break
      fi
    else
      if [[ "`echo $5 | cut -b 1`" = "/" ]] ; then
        if [[ "$destination" != "$5" ]] ; then
          dest=1
        else
          dest=0
          break
        fi
      else
        if [[ "$destination" != "$5" ]] && [[ "$destination" != "*/$5" ]] ; then
          dest=1
        else
          dest=0
          break
        fi
      fi
    fi
  done
  
  while : ; do
    if [[ "`echo $5 | cut -b $count`" = "/" && "`echo $5 | cut -b $(($count+1))`" = "/" ]] ; then
      destsyntax=1
      break
    fi
    if [[ "`echo $5 | cut -b $(($count))`" = "*" ]] ; then
      if ! [[ $count -eq 1 && "`echo $5 | cut -b 2`" = "/" ]] ; then
        destsyntax=1
        break
      fi
    fi
    if [[ "`echo $5 | cut -b $count`" = "" ]] ; then
      break
    fi
    count=$(($count+1))
  done
  count=1


  #Errors ausgeben
  if [[ $name -eq 0 && $namelength -eq 1 ]] ; then
    echo -e "\033[31mError : \033[33mName to long only 1-24 chars!"
  elif [[ $name -eq 0 && $namelength -eq 0 ]] ; then
    echo -e "\033[31mError : \033[33mName exist!"
  else
    echo -e "\033[36mMSG   : \033[37mName        \033[32mo.k."
  fi

  if [[ $flag -eq 0 && $flagsyntax -eq 1 ]] ; then
    echo -e "\033[31mError : \033[33mFlag : Syntax Error!"
  elif [[ $flagTimeLess -eq 0 && $flagTimeMany -eq 0 && $flagError -eq 0 ]] ; then
    if [[ $flag -eq 0 && $flagsyntax -eq 0 ]] ; then
      echo -e "\033[31mError : \033[33mFlag '$Flag' does not exist!"
    else
      echo -e "\033[36mMSG   : \033[37mFlags       \033[32mo.k."
    fi
  elif [[ $flagTimeLess -eq 1 ]] ; then
    echo -e "\033[31mError : \033[33mFlag \"Backup has no time specification for execution!\""
  elif [[ $flagTimeMany -eq 1 ]] ; then
    echo -e "\033[31mError : \033[33mFlag \"Backup has to many time specifications for execution!\""
  elif [[ $flagError -eq 1 ]] ; then
    echo -e "\033[31mError : \033[33mFlags \"bash, img, tar, copy\" are exclusive."
  fi

  if [[ $number -eq 0 ]] ; then
    echo -e "\033[31mError : \033[33m[d/w/m too keep] needs to be a Number between 0-99!"
  else
    echo -e "\033[36mMSG   : \033[37mNumber      \033[32mo.k."
  fi
  if [[ $sour -eq 0 ]] ; then
    echo -e "\033[31mError : \033[33mSource path does not exist!"
  else
    echo -e "\033[36mMSG   : \033[37mSource      \033[32mo.k."
  fi

  if [[ $dest -eq 0 && $destsyntax -eq 1 ]] ; then
    echo -e "\033[31mError : \033[33mInvalid destination path!"
  elif [[ $dest -eq 0 && $destsyntax -eq 0 ]] ; then
    echo -e "\033[31mError : \033[33mDestination path exist!"
  elif [[ $dest -eq 1 && $destsyntax -eq 1 ]] ; then
    echo -e "\033[31mError : \033[33mInvalid destination path!"
  else
    echo -e "\033[36mMSG   : \033[37mDestination \033[32mo.k."
  fi

  if [[ "$4" != "" ]] || [[ "$5" != "" ]] ; then
    if [[ $name -eq 1 && $namelength -eq 0 && $flag -eq 1 && $flagsyntax -eq 0 && $flagTimeLess -eq 0 && $flagTimeMany -eq 0 && $flagError -eq 0 && $number -eq 1 && $sour -eq 1 && $dest -eq 1 && $destsyntax -eq 0 ]] ; then
      reProgram=1
      count=0
      handoverFile=/dev/shm/.backupHandover1.temp
	  echo #newline after msg and error
      echo -e "\033[36mMSG   : \033[33msaving..."
      while ! [[ "`jq .backup[$count].name $backupFile`" = "null" ]] ; do
        count=$(($count+1))
      done
      array=".backup[$count]"
      if [[ "$5" = "" ]] ; then
        jq " $array.ID=$(($count+1)) | $array.name=\"$1\" | $array.flag=\"$2\" | $array.dwmtokeep=\"$3\" | $array.source=\"$4\" | $array.destination=\"*/$1\"" $backupFile > $handoverFile
      else
        if [[ "`echo $5 | cut -b 1`" = "/" ]] ; then
          jq " $array.ID=$(($count+1)) | $array.name=\"$1\" | $array.flag=\"$2\" | $array.dwmtokeep=\"$3\" | $array.source=\"$4\" | $array.destination=\"$5\"" $backupFile > $handoverFile
        elif [[ "`echo $5 | cut -b 1-2`" = "*/" ]] ; then
          jq " $array.ID=$(($count+1)) | $array.name=\"$1\" | $array.flag=\"$2\" | $array.dwmtokeep=\"$3\" | $array.source=\"$4\" | $array.destination=\"$5\"" $backupFile > $handoverFile
        else
          jq " $array.ID=$(($count+1)) | $array.name=\"$1\" | $array.flag=\"$2\" | $array.dwmtokeep=\"$3\" | $array.source=\"$4\" | $array.destination=\"*/$5\"" $backupFile > $handoverFile
        fi
      fi
      mv $handoverFile $backupFile
      echo -e "\033[36mMSG   : \033[32msaved"
    fi
  else
    echo -e "\033[31mError : \033[33mTo few arguments"
  fi
}

execAllBackups=0

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
        bash -c "$execSource" >> $execLogfile
      elif [[ "$flagImg" = "img" ]] && [[ "$flagZip" = "" ]]  ; then
        echo "[`date +"%Y-%m-%d %H:%M"`] [dd] : " >> $execLogfile
        dd if=$execSource of=${date}__start_${execStartTime}__name_${execName}.img.part 2>> $execLogfile
        execEndTime=`date +"%H-%M"`
        echo -n "[`date +"%Y-%m-%d %H:%M"`] [mv] : " >> $execLogfile
        mv -v ${date}__start_${execStartTime}__name_${execName}.img.part ${date}_${execStartTime}/${date}__start_${execStartTime}__end_${execEndTime}__name_${execName}.img >> $execLogfile
      elif [[ "$flagImg" = "img" ]] && [[ "$flagZip" = "zip" ]]  ; then
        echo "[`date +"%Y-%m-%d %H:%M"`] [dd and gzip] : " >> $execLogfile
        (
          dd if=$execSource | gzip -c > ${date}__start_${execStartTime}__name_${execName}.img.gz.part
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
        echo "[`date +"%Y-%m-%d %H:%M"`] [tar and gzip] :" >> $execLogfile
        ( 
          cd $execSource
          execSourceEmpty=$(echo *) # "*" then its empty
          if [[ "$execSourceEmpty" != "*" ]] ; then
            tar czf "$execPath/${date}_${execStartTime}/${date}__start_${execStartTime}__name_${execName}.tar.gz.part" *
            execEndTime=`date +"%H-%M"`
            echo "[`date +"%Y-%m-%d %H:%M"`] [tar and gzip] : END"
            echo -n "[`date +"%Y-%m-%d %H:%M"`] [mv] : "
            mv -v "$execPath/${date}_${execStartTime}/${date}__start_${execStartTime}__name_${execName}.tar.gz.part" "$execPath/${date}_${execStartTime}/${date}__start_${execStartTime}__end_${execEndTime}__name_${execName}.tar.gz" >> $execLogfile
          else
            echo "[`date +"%Y-%m-%d %H:%M"`] [tar and gzip] : Directory empty, no data to save!"
            echo "[`date +"%Y-%m-%d %H:%M"`] [tar and gzip] : END"
            echo "[`date +"%Y-%m-%d %H:%M"`] [rmdir] : Delete empty folder $execPath/${date}_${execStartTime}"
            rmdir $execPath/${date}_${execStartTime}
          fi
        ) >> $execLogfile
      elif [[ "$flagZip" = "zip" ]] && [[ "$flagTar" = "" ]] && [[ "$flagImg" = "" ]] ; then
        echo "[`date +"%Y-%m-%d %H:%M"`] [gzip] :" >> $execLogfile
        execSourceEmpty=$(echo *)
        if [[ "$execSourceEmpty" != "*" ]] ; then
          gzip -r * 2>> $execLogfile
        else
          echo "[`date +"%Y-%m-%d %H:%M"`] [gzip] : Directory empty, no data to save!" >> $execLogfile
          echo "[`date +"%Y-%m-%d %H:%M"`] [rmdir] : Delete empty folder $execPath/${date}_${execStartTime}"
          rmdir $execPath/${date}_${execStartTime}
        fi
        echo "[`date +"%Y-%m-%d %H:%M"`] [gzip] : END" >> $execLogfile
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

while : ; do
  if [[ $UID != 0 ]] ; then
    echo -e "\033[31mError : \033[33mYou are not root!"
    break
  fi
  touchData
  if [[ $# -eq 7 ]] ; then
    echo -e "\033[31mError : \033[33mTo many arguments!"
    break
  fi
  if [[ "$1" = "" ]] ; then
    helpPage1
    helpPage2
    helpPage3
    break
  fi

  while : ; do
    if [[ "`echo $2 | cut -b $count`" = "#" ]] || [[ "`echo $3 | cut -b $count`" = "#" ]] || [[ "`echo $4 | cut -b $count`" = "#" ]] || [[ "`echo $5 | cut -b $count`" = "#" ]] || [[ "`echo $6 | cut -b $count`" = "#" ]] ; then
      echo -e "\033[31mError : \033[33mThe character '#' is not allowed!"
      breakval=1
      break
    fi
    if [[ "`echo $2 | cut -b $count`" = "" ]] && [[ "`echo $3 | cut -b $count`" = "" ]] && [[ "`echo $4 | cut -b $count`" = "" ]] && [[ "`echo $5 | cut -b $count`" = "" ]] && [[ "`echo $6 | cut -b $count`" = "" ]] ; then  
      break
    fi
    count=$(($count+1))
  done
  count=1
  if [[ breakval -eq 1 ]] ; then
    break
  fi
  case $1 in

    prog)   programmBackup "$2" "$3" "$4" "$5" "$6"
            break
            ;;
    exec)   execution >> /dev/null
            break
            ;;

    execAll)
            execAllBackups=1
            execution >> /dev/null
            break
            ;;


    path)   if [[ "$3" != "" ]] ; then
              echo -e "\033[31mError : \033[33mTo many arguments for path."
              break
            fi

            if test -e $2 && test -d $2 ; then
              echo -e "\033[36mMSG   : \033[32mChanging \033[37mstandard backup path to \033[33m$2"
              echo $2 > $backupPath
              echo -e "\033[36mMSG   : \033[32mChanged \033[37mstandard backup path to \033[33m$2"
            else
              echo -e "\033[31mError : \033[33mPath does not exist!"
            fi
            break
            ;;

    deact)  if [[ "$3" != "" ]] ; then
              echo -e "\033[31mError : \033[33mTo many arguments for deact."
              break
            fi
            if [[ "$2" = "0" || "$2" = "00" ]] ; then
              echo -e "\033[31mError : \033[33mBackup with ID $2 does not exists!"
              break
            fi
            if [[ "$2" =~ ^[0-9][0-9]$ ]] || [[ "$2" =~ ^[0-9]$ ]] ; then

              deletedLine=`jq .backup[$(($2-1))].name $backupFile`

              if [[ "$deletedLine" = "null" ]] ; then
                echo -e "\033[31mError : \033[33mBackup ID $2 does not exists!"
                break
              fi

              echo -e "\n\033[36mMSG   : \033[37mDeactivating backup \033[37mID-$2 ..."

              handoverFile=/dev/shm/.backupHandover1.temp
              count=0
              while ! [[ "`jq .backup[$count].name $deactBackupFile`" = "null" ]] ; do
                count=$(($count+1))
              done

              deactName=$(jq ".backup[$(($2-1))].name" $backupFile)
              deactFlag=$(jq ".backup[$(($2-1))].flag" $backupFile)
              deactNumber=$(jq ".backup[$(($2-1))].dwmtokeep" $backupFile)
              deactSource=$(jq ".backup[$(($2-1))].source" $backupFile)
              deactDestination=$(jq ".backup[$(($2-1))].destination" $backupFile)

              array=".backup[$count]"
              jq "$array.ID=$(($count+1)) | $array.name=$deactName | $array.flag=$deactFlag | $array.dwmtokeep=$deactNumber | $array.source=$deactSource | $array.destination=$deactDestination " $deactBackupFile > $handoverFile
              mv $handoverFile $deactBackupFile

              array=".backup[$(($2-1))]"
              jq " $array.name=null | $array.flag=null | $array.dwmtokeep=null | $array.source=null | $array.destination=null " $backupFile > $handoverFile
              mv $handoverFile $backupFile

              echo -e "\033[36mMSG   : \033[33mDeactivated backup ID-$2\033[37m\n"

              list $backupFile
              list $deactBackupFile

            else
              echo -e "\033[31mError : \033[33m'$2' is not an argument for deact."
              break
            fi
            break
            ;;

    react)  if [[ "$3" != "" ]] ; then
              echo -e "\033[31mError : \033[33mTo many arguments for react."
              break
            fi
            if [[ "$2" = "0" || "$2" = "00" ]] ; then
              echo -e "\033[31mError : \033[33mBackup ID $2 does not exists in deactivation list!"
              break
            fi
            if [[ "$2" =~ ^[0-9][0-9]$ ]] || [[ "$2" =~ ^[0-9]$ ]] ; then

              deletedLine=`jq .backup[$(($2-1))].name $deactBackupFile`

              if [[ "$deletedLine" = "null" ]] ; then
                echo -e "\033[31mError : \033[33mBackup ID $2 does not exists in deactivation list."
                break
              fi

              handoverFile=/dev/shm/.backupHandover1.temp
              reactName=$(jq -r ".backup[$(($2-1))].name" $deactBackupFile)
              reactFlag=$(jq -r ".backup[$(($2-1))].flag" $deactBackupFile)
              reactNumber=$(jq -r ".backup[$(($2-1))].dwmtokeep" $deactBackupFile)
              reactSource=$(jq -r ".backup[$(($2-1))].source" $deactBackupFile)
              reactDestination=$(jq -r ".backup[$(($2-1))].destination" $deactBackupFile)

              programmBackup "$reactName" "$reactFlag" "$reactNumber" "$reactSource" "$reactDestination"

              if [[ $reProgram = 1 ]] ; then
                array=".backup[$(($2-1))]"
                jq " $array.name=null | $array.flag=null | $array.dwmtokeep=null | $array.source=null | $array.destination=null " $deactBackupFile > $handoverFile
                mv $handoverFile $deactBackupFile
                echo -e "\033[36mMSG   : \033[32mReactivated backup ID $2."
              else
                echo -e "\033[31mError : \033[33mBackup ID $2 can't be reactivated!"
              fi
              list $backupFile
              list $deactBackupFile
            else
              echo -e "\033[31mError : \033[33m'$2' is not an argument for react."
            fi
            break
            ;;


    rm)     if [[ "$3" != "" ]] ; then
              echo -e "\033[31mError : \033[33mTo many arguments for rm."
              break
            fi

            if [[ "$2" = "trash" ]] ; then
              echo -e -n "\033[35mQ & A?: \033[33mDo you really want to \033[31mdelete \033[33mthe trashbin? \033[37m[\033[32my\033[37m/\033[31mN\033[37m] : " ; 
              read option
              case $option in
                yes|y|Yes|Y)  echo -e "\n\033[36mMSG   : \033[33mDeleting trashbin..."
                              rm -f $trashBackupFile
                              echo -e "\033[36mMSG   : \033[33mTrashbin deleted!\n"
                              ;;
                *)    echo -e "\n\033[36mMSG   : \033[32mTrashbin not deleted!\n"
                      ;;
              esac
              break
            elif [[ "$2" = "deact" ]] ; then
              echo -e -n "\033[35mQ & A?: \033[33mDo you really want to \033[31mdelete \033[33mthe deactivation list? \033[37m[\033[32my\033[37m/\033[31mN\033[37m] : " ; 
              read option
              case $option in
                yes|y|Yes|Y)  echo -e "\n\033[36mMSG   : \033[33mDeleting deactivation list..."
                              rm -f $deactBackupFile
                              echo -e "\033[36mMSG   : \033[33mDeactivation list deleted!\n"
                              ;;
                *)    echo -e "\n\033[36mMSG   : \033[32mDeactivation list not deleted!\n"
                      ;;
              esac
              break
            fi

            if [[ "$2" = "0" || "$2" = "00" ]] ; then
              echo -e "\033[31mError : \033[33mBackup with ID $2 does not exists!"
              break
            fi

            if [[ "$2" =~ ^[0-9][0-9]$ ]] || [[ "$2" =~ ^[0-9]$ ]] ; then
              deletedLine=`jq .backup[$(($2-1))].name $backupFile`

              if [[ "$deletedLine" = "null" ]] ; then
                echo -e "\033[31mError : \033[33mBackup ID $2 does not exists!"
                break
              fi

              handoverFile=/dev/shm/.backupHandover1.temp
              count=0
              while ! [[ "`jq .backup[$count].name $trashBackupFile`" = "null" ]] ; do
                count=$(($count+1))
              done

              deactName=$(jq ".backup[$(($2-1))].name" $backupFile)
              deactFlag=$(jq ".backup[$(($2-1))].flag" $backupFile)
              deactNumber=$(jq ".backup[$(($2-1))].dwmtokeep" $backupFile)
              deactSource=$(jq ".backup[$(($2-1))].source" $backupFile)
              deactDestination=$(jq ".backup[$(($2-1))].destination" $backupFile)

              array=".backup[$count]"
              jq " $array.ID=$(($count+1)) | $array.name=$deactName | $array.flag=$deactFlag | $array.dwmtokeep=$deactNumber | $array.source=$deactSource | $array.destination=$deactDestination " $trashBackupFile > $handoverFile
              mv $handoverFile $trashBackupFile

              echo -e "\n\033[36mMSG   : \033[37mCopied backup \033[37mID-$2 to trashbin"

              array=".backup[$(($2-1))]"
              jq " $array.name=null | $array.flag=null | $array.dwmtokeep=null | $array.source=null | $array.destination=null " $backupFile > $handoverFile
              mv $handoverFile $backupFile

              echo -e "\033[36mMSG   : \033[33mDeleted ID-$2\033[37m"

              list $backupFile
              list $trashBackupFile

            else
              echo -e "\033[31mError : \033[33m'$2' is not an argument for rm."
              break
            fi
            break
            ;;


    re)     if [[ "$3" != "" ]] ; then
              echo -e "\033[31mError : \033[33mTo many arguments for re."
              break
            fi

            if [[ "$2" = "0" || "$2" = "00" ]] ; then
              echo -e "\033[31mError : \033[33mBackup ID $2 does not exists in trashbin!"
              break
            fi

            if [[ "$2" =~ ^[0-9][0-9]$ ]] || [[ "$2" =~ ^[0-9]$ ]] ; then
              deletedLine=`jq .backup[$(($2-1))].name $trashBackupFile`

              if [[ "$deletedLine" = "null" ]] ; then
                echo -e "\033[31mError : \033[33mBackup ID $2 does not exists in trashbin"
                break
              fi

              handoverFile=/dev/shm/.backupHandover1.temp
              reName=$(jq -r ".backup[$(($2-1))].name" $trashBackupFile)
              reFlag=$(jq -r ".backup[$(($2-1))].flag" $trashBackupFile)
              reNumber=$(jq -r ".backup[$(($2-1))].dwmtokeep" $trashBackupFile)
              reSource=$(jq -r ".backup[$(($2-1))].source" $trashBackupFile)
              reDestination=$(jq -r ".backup[$(($2-1))].destination" $trashBackupFile)

              programmBackup "$reName" "$reFlag" "$reNumber" "$reSource" "$reDestination"

              if [[ $reProgram = 1 ]] ; then
                array=".backup[$(($2-1))]"
                jq " $array.name=null | $array.flag=null | $array.dwmtokeep=null | $array.source=null | $array.destination=null " $trashBackupFile > $handoverFile
                mv $handoverFile $trashBackupFile
                echo -e "\033[36mMSG   : \033[32mRestored backup ID $2 from trashbin."
              else
                echo -e "\033[31mError : \033[33mBackup ID $2 from trashbin can't be restored!"
              fi
              list $backupFile
              list $trashBackupFile
            else
              echo -e "\033[31mError : \033[33m'$2' is not an argument for re."
            fi
            break
            ;;
    ls)     if [[ "$3" != "" ]] ; then
              echo -e "\033[31mError : \033[33mTo many arguments for ls."
              break
            fi
            if [[ "$2" = "" ]] ; then
              list $backupFile
            elif [[ "$2"  = "all" ]] ; then
              list $backupFile
              list $deactBackupFile
              list $trashBackupFile
            elif [[ "$2" = "trash" ]] ; then
              list $trashBackupFile
            elif [[ "$2" = "deact" ]] ; then
              list $deactBackupFile
            else
              echo -e "\033[31mError : \033[33m'$2' is not an argument for ls"
            fi
            break
            ;;

    log)    if [[ "$3" != "" ]] ; then
              echo -e "\033[31mError : \033[33mTo many arguments for log."
              break
            fi
            if [[ "$2" = "0" || "$2" = "00" ]] ; then
              echo -e "\033[31mError : \033[33mBackup with ID $2 does not exist!"
              break
            fi
            if [[ "$2" =~ ^[0-9][0-9]$ ]] || [[ "$2" =~ ^[0-9]$ ]] ; then
              logDest=`jq ".backup[$(($2-1))].destination" $backupFile`
              if [[ "$logDest" = "null" ]] ; then
                echo -e "\033[31mError : \033[33mLog ID $2 does not exist!"
                break
              fi
              logDest=`jq -r ".backup[$(($2-1))].destination" $backupFile`
              if [[ "`echo $logDest | cut -b 1`" = "*" ]] ; then
                if cd "`cat $backupPath``echo $logDest | cut -b 2-`" >> /dev/null 2>&1 ; then
                  cat * 2>> /dev/null | less
                else  
                  echo -e "\033[31mError : \033[33mLogs for '$2' do not exist."
                fi
              else
                if cd $logDest >> /dev/null 2>&1 ; then
                  cat * 2>> /dev/null | less
                else  
                  echo -e "\033[31mError : \033[33mLogs for '$2' do not exist."
                fi
              fi
            else
              echo -e "\033[31mError : \033[33m'$2' is not an argument for log."
            fi
            break
            ;;

    -h|--help|help)
            if [[ "$3" != "" ]] ; then
              echo -e "\033[31mError : \033[33mTo many arguments for --help."
              break
            fi
            # Browse help
            if [[ "$2" = "" ]] ; then
              echo "`helpPage1` `helpPage2` `helpPage3`" | less -R
              break
            elif [[ "$2" = "options" ]] ; then
              echo -e "----------------- Help Page No.1 [options] -----------------"
              helpPage1
              break
            elif [[ "$2" = "flags" ]] ; then
              echo -e "----------------- Help Page No.2 [ flags ] -----------------"
              helpPage2
              break
            elif [[ "$2" = "examples" ]] ; then
              echo -e "----------------- Help Page No.3 [examples] -----------------"
              helpPage3
              break
            else
              echo -e "\033[31mError : \033[33mHelp page "$2" doesn't exist."
              break
            fi
            ;;

    --restoreProgram)
            if [[ "$4" != "" ]] ; then
              echo -e "\033[31mError : \033[33mTo many arguments for --restoreProgram"
              break
            fi
            if [[ "$3" = "--yes" ]] ; then
              if test -e $2 ; then
                rm -rf $programmDir
                mkdir $programmDir
                touchData
                cp $2 $backupFile
              fi
              break
            fi
            if [[ "$3" = "" ]] ; then
              echo -e -n "\033[35mQ & A?: \033[33mDo you really want to \033[31mdelete \033[33mthe program files and restore from the file? \033[37m[\033[32my\033[37m/\033[31mN\033[37m] : " ; 
              read option
              case $option in
                yes|y|Yes|Y)
                              if test -f $2 ; then
                                echo -e "\n\033[36mMSG   : \033[33mDeleting program files..."
                                rm -rf $programmDir
                                echo -e "\033[36mMSG   : \033[33mProgram files deleted!\n"
                                echo -e "\033[36mMSG   : \033[33mRestore data from file..."
                                mkdir $programmDir
                                touchData
                                cp $2 $backupFile
                                echo -e "\033[36mMSG   : \033[33mRestored!"
                              else
                                echo -e "\033[31mError : \033[33mProgram can't be restored, $2 is not a file."
                              fi
                              ;;
                *)    echo -e "\n\033[36mMSG   : \033[32mProgram files not deleted!\n"
                      ;;
              esac
            else
              echo -e "\033[31mError : \033[33m'$3' is not an argument for --restoreProgram."
            fi
            break
            ;;

    --deleteAllProgramFiles)
            if [[ "$3" != "" ]] ; then
              echo -e "\033[31mError : \033[33mTo many arguments for --deleteAllProgramFiles."
              break
            fi
            if [[ "$2" = "--yes" ]] ; then
              rm -rf $programmDir
              break
            fi
            echo -e -n "\033[35mQ & A?: \033[33mDo you really want to \033[31mdelete \033[33mthe programfiles? \033[37m[\033[32my\033[37m/\033[31mN\033[37m] : " ; 
            read option
            case $option in
              yes|y|Yes|Y)  echo -e "\n\033[36mMSG   : \033[33mDeleting programfiles..."
                            rm -rf $programmDir
                            echo -e "\033[36mMSG   : \033[33mProgram files deleted!"
                            ;;
              *)    echo -e "\n\033[36mMSG   : \033[32mProgram files not deleted!"
                    ;;
            esac
            break
            ;;
    
    version|--version)
            echo -e "$version"
            break
            ;;

    *)      echo -e "\033[31mError : \033[33mSyntax Error!!"
            echo -e "\033[36mMSG   : \033[0mUse \"backup help\" to get usage infos."
            break
            ;;
  esac
done
if [[ "$1" != "exec" ]] ; then
  echo -e -n "\033[0m"
fi

