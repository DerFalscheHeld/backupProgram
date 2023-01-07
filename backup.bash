#!/bin/bash

#backup [option] [name] [Flags] [days/months - to keep] [Source] [Destinantion]

#Flags:

#  /
#   m01-31 : monatliches Backup
#   w1-7   : wöchentliches Backup
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

######später entfernen
#cp /srv/dev-disk-by-uuid-3c6b8ad9-35ca-4dcf-9039-0158b5532353/raid1/00__Backup/backup-programm/backup.sh /usr/local/bin/backup

umask 0022

programmDir=/usr/local/etc/backup
tempDir=$programmDir/temp

backupFileDir=data
backupFile=$programmDir/$backupFileDir/backup
backupPath=$programmDir/$backupFileDir/backupPath
backupList=$programmDir/$backupFileDir/backup_ls

# deactivation files
deactDir=deact
deactBackupFile=$programmDir/$deactDir/deactBackup
deactBackupList=$programmDir/$deactDir/deactBackup_ls

# help files
helpDir=help
helpScreen=$programmDir/$helpDir/help_ls

# trashbin files
trashDir=trashbin
trashBackupFile=$programmDir/$trashDir/trashFile
trashBackupList=$programmDir/$trashDir/trashFile_ls

#allgemeine val
count=1
separator=\#

#Programmdateien erzeugen
function touchData {
  mkdir -p {$tempDir,$programmDir/$backupFileDir,$programmDir/$deactDir,$programmDir/$helpDir,$programmDir/$trashDir}
  touch $backupFile
  touch $backupList
  if ! test -e $backupPath ; then
    touch $backupPath
    echo /root/backup > $backupPath
    renderAll
  fi
  touch $deactBackupFile
  touch $deactBackupList
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
                    if [[ `date +"%d"` -eq `echo $1 | cut -b 2-3` ]] || [[ $execAllBackups -eq 1 ]] ; then
                      flagMonth="m"
                    else
                      breakval=1
                    fi
                    if [[ `echo $1 | cut -b 2-3` -eq 00 ]] ; then
                      flagcheck=1
                      flagCheckMonth=0
                    elif [[ `echo $1 | cut -b 2-3` -gt 31 ]] ; then
                      flagcheck=1
                      flagCheckMonth=0
                    fi
                    ;;

    w[0-9])         flagCheckWeek=1
                    if [[ `date +"%w"` -eq `echo $1 | cut -b 2` ]] || [[ $execAllBackups -eq 1 ]] ; then
                      flagWeek="w"
                    else
                      breakval=1
                    fi
                    if [[ `echo $1 | cut -b 2` -eq 0 ]] ; then
                      flagcheck=1
                      flagCheckWeek=0
                    elif [[ `echo $1 | cut -b 2` -gt 7 ]] ; then
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
  echo -e "\n\033[0mstandard backup path : `cat $backupPath`\n * means standard backup path"
  if [[ "$1" = "trash" ]] ; then
    echo -e -n "\n\033[2m\033[33m\033[7m#-#-#-#-#- TRASHBIN -#-#-#-#-#\n\033[0m"
  elif [[ "$1" = "deact" ]] ; then
    echo -e -n "\n\033[2m\033[31m\033[7m#-#-#-#-#- DEACTIVATED -#-#-#-#-#\n\033[0m"
  else
    echo -e ""
  fi
}

function renderListTemp {

  echo -e "\033[32mID#|#\033[33m[name]#\033[36m[flag]#\033[35m[d/m/w_to_keep]#\033[34m[source/command]#\033[37m[destination/exec-path]\n"

  while read line; do
    info1=`echo $line | cut -d"$separator" -f1`
    info2=`echo $line | cut -d"$separator" -f2`
    info3=`echo $line | cut -d"$separator" -f3`
    info4=`echo $line | cut -d"$separator" -f4`
    info5=`echo $line | cut -d"$separator" -f5`

    echo -e "\033[32m${count}#|#\033[33m${info1}#\033[36m${info2}#\033[35m${info3}#\033[34m${info4}#\033[37m${info5}"

    count=$(($count+1))
  done < $1
}

function renderList {

  renderListTemp $1 > $tempDir/.renderList.temp.1
  column $tempDir/.renderList.temp.1 -t -s "#" > $tempDir/.renderList.temp.2
  cat $tempDir/.renderList.temp.2 > $tempDir/.renderList.temp.1
  sed -i "2,130d" $tempDir/.renderList.temp.1
  sed -i "1d" $tempDir/.renderList.temp.2

  renderListHeader $3 > $2
  cat $tempDir/.renderList.temp.1 >> $2
  allColumnsWidth="$((`cat $tempDir/.renderList.temp.1 | wc -m`-30))"
  echo -e -n "\033[31m" >> $2
  for (( i = 0 ; i <= $allColumnsWidth ; i++ )) ; do
    printf "-" >> $2
  done
  echo >> $2 
  cat $tempDir/.renderList.temp.2 >> $2
  echo >> $2
  rm -rf $tempDir/.renderList.temp.1 $tempDir/.renderList.temp.2
}

function renderHelp {

  rm -rf $helpScreen ########################################################## DBUG

  if ! test -e $helpScreen ; then
    echo -e "
  backup [option] [arguments.....]

  options:
    ls []       >> lists all reProgram backups
       [trash]  >> lists trashbin
       [deact]  >> lists all deactivated backups
       [all]    >> lists all 

    rm [1-99]   >> delete a reProgram Backup with that ID [1-99]
       [trash]  >> delete the trashbin
       [deact]  >> delete the deactivation list

    re [1-99]   >> Restore backup from trashbin with ID [1-99]
       
    log [1-99]   >> shows all logs from the ID [1-99] in less

    path [Path]   >> Change standard backup path

    deact [1-99]   >> Deactivate backup with ID [1-99]
    
    react [1-99]   >> Reactivate backup with ID [1-99]

    exec           >> for daily execute use cron syntax | \033[36m0 0 * * * /usr/local/bin/backup exec  \033[37m
    
    execAll        >> execute all backups now

    prog           >> programming a new backup

    help / -h / --help      >> shows this screen

    --restoreProgram [file] []      >> Restore program from backup file
                            [--yes] >> ... and skip confirmation by auto-affirming restoration

    --deleteAllProgramFiles []      >> delete all program Files
                            [--yes] >> ... and skip confirmation by auto-affirming deletion

  example:
  backup prog \033[33m[name] \033[36m[flag] \033[35m[d/w/m_to_keep] \033[34m[source/command] \033[37m[destination/exec-path]
                |      |          |                |                    |
                |      |          |                |                    '->> destinaton path from backup
                |      |          |                |
                |      |          |                '->>  source path for backup / command to be executed
                |      |          |
                |      |          '->> Number of [days or weeks or months] to keep the old backups
                |      |
                |      '->> flags (see below)
                |
                '->>  name of backup
                

        flags:
                arguments are seperated by \"/\"
                e.g.:   /arg1/arg2/arg3/
                
                m[1-31] >>  monthly backup
                
                w[1-7]  >>  weekly backup
        
                day     >>  daily backup

                copy    >>  Supply source path arg
                            and an optional destination arg
                       
                            If no destination path is supplied,
                            the standard path with [name] is used as destination
                       
                            copy <source path> <destination path>
              
                bash    >>  Argument after bash will executed in bash
                            Needs to be supplied with '
                            Will be executed in exec-path
                            
                            bash 'command'
              
                img     >>  Save backup as .img file
              
                zip     >>  Save backup as .gz archive
              
                tar     >>  Save backup as .tar archive
              
                log     >>  Create log-file in destination folder                
  
    
  " > $helpScreen
  fi
}

function renderAll {
  if test -e $backupList ; then
    renderList $backupFile $backupList
  fi
  if test -e $deactBackupList ; then
    renderList $deactBackupFile $deactBackupList deact
  fi
  if test -e $trashBackupList ; then
    renderList $trashBackupFile $trashBackupList trash
  fi
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
  while read line; do
    namecut=`echo "$line" | cut -d"$separator" -f1`
    if [[ "$namecut" != "$1" ]] ; then
      name=1
    else
      name=0
      break
    fi
  done < "$backupFile"

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
  if [[ "$5" = "" ]] ; then
      while read line; do
        destination=`echo "$line" | cut -d"$separator" -f5`
        if [[ "$destination" != `echo "*/$1"` ]] ; then
          dest=1
        else
          dest=0
          break
        fi
    done < "$backupFile"

  else
    while read line; do
      destination=`echo "$line" | cut -d"$separator" -f5`
      if [[ "`echo $5 | cut -b 1`" = "/" ]] ; then
        if [[ "$destination" != `echo "$5"` ]] ; then
          dest=1
        else
          dest=0
          break
        fi
      else
        if [[ "$destination" != `echo "$5"` ]] && [[ "$destination" != `echo "*/$5"` ]] ; then
          dest=1
        else
          dest=0
          break
        fi
      fi
    done < "$backupFile"
  fi

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
    echo -e "\n\033[31mError : \033[33mName to long only 1-24 chars!"
  elif [[ $name -eq 0 && $namelength -eq 0 ]] ; then
    echo -e "\n\033[31mError : \033[33mName exist!"
  else
    echo -e "\n\033[36mMSG   : \033[37mName        \033[32mo.k."
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
    echo -e "\033[31mError : \033[33mFlag \"You can only use one of 'bash, img, tar, copy, '\""
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
  echo #newline after msg and error

  if [[ "$5" = "" ]] ; then
    standardBackuppath="*"
  fi

  if [[ "$4" != "" ]] || [[ "$5" != "" ]] ; then
    if [[ $name -eq 1 && $namelength -eq 0 && $flag -eq 1 && $flagsyntax -eq 0 && $flagTimeLess -eq 0 && $flagTimeMany -eq 0 && $flagError -eq 0 && $number -eq 1 && $sour -eq 1 && $dest -eq 1 && $destsyntax -eq 0 ]] ; then
      reProgram=1
      if [[ "$standardBackuppath" = "*" ]] ; then
        echo -e "\033[36mMSG   : \033[33msaving..."
        echo -e "$1#$2#$3#$4#*/$1" >> $backupFile
        renderList $backupFile $backupList
        echo -e "\033[36mMSG   : \033[32msaved"
      else
        if [[ "`echo $5 | cut -b 1`" = "/" ]] ; then
          echo -e "\033[36mMSG   : \033[33msaving..."
          echo -e "$1#$2#$3#$4#$5" >> $backupFile
          renderList $backupFile $backupList
          echo -e "\033[36mMSG   : \033[32msaved"
        elif [[ "`echo $5 | cut -b 1-2`" = "*/" ]] ; then
          echo -e "\033[36mMSG   : \033[33msaving..."
          echo -e "$1#$2#$3#$4#$5" >> $backupFile
          renderList $backupFile $backupList
          echo -e "\033[36mMSG   : \033[32msaved"
        else
          echo -e "\033[36mMSG   : \033[33msaving..."
          echo -e "$1#$2#$3#$4#*/$5" >> $backupFile
          renderList $backupFile $backupList
          echo -e "\033[36mMSG   : \033[32msaved"
        fi
      fi
      echo #newline after saving
    fi
  else
    echo -e "\033[31mError : \033[33mTo few arguments\n"
  fi
}

execAllBackups=0

function execution {
  umask 0000
  ID=1
  while read line; do
    Flag=`echo $line | cut -d"$separator" -f2 | cut -b 1`
    if [[ "$Flag" = "/" ]] ; then
      count=1
      while : ; do
        count=$(($count+1))
        Flag=`echo $line | cut -d"$separator" -f2 | cut -d"/" -f$count`
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
    
    if [[ $breakval -eq 0 ]] || [[ $execAllBackups -eq 1 ]] ; then

      date=`date +"%Y-%m-%d"`
      execStartTime=`date +"%H-%M"`
      execName="`echo $line | cut -d"$separator" -f1`"
      execNumber="`echo $line | cut -d"$separator" -f3`"
      execSource="`echo $line | cut -d"$separator" -f4`"
      execPath="`echo $line | cut -d"$separator" -f5`"
      execLogfile="$tempDir/${date}__start_${execStartTime}__name_$execName.log.temp"
 
      echo -e "Logfile: $execLogFile\n" > $execLogfile
      
      #cd *
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
        echo Hallo : $execSourceEmpty
        if [[ "$execSourceEmpty" != "*" ]] ; then
          gzip * 2>> $execLogfile
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
    ID=$(($ID+1))
    resetFlags
  done < $backupFile
}

while : ; do
  if [[ $UID != 0 ]] ; then
    echo -e "\n\033[31mError : \033[33mYou are not root!\n"
    break
  fi
  touchData
  if [[ $# -eq 7 ]] ; then
    echo -e "\n\033[31mError : \033[33mTo many arguments!\n"
    break
  fi
  if [[ "$1" = "" ]] ; then
    renderHelp
    cat $helpScreen
    break
  fi

  while : ; do
    if [[ "`echo $2 | cut -b $count`" = "#" ]] || [[ "`echo $3 | cut -b $count`" = "#" ]] || [[ "`echo $4 | cut -b $count`" = "#" ]] || [[ "`echo $5 | cut -b $count`" = "#" ]] || [[ "`echo $6 | cut -b $count`" = "#" ]] ; then
      echo -e "\n\033[31mError : \033[33mThe character '#' is not allowed!\n\033[0m"
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
              echo -e "\n\033[31mError : \033[33mTo many arguments for path.\n"
              break
            fi
            
            if test -e $2 && test -d $2 ; then
              echo -e "\n\033[36mMSG   : \033[32mChanging \033[37mstandart backup path to \033[33m$2"
              echo $2 > $backupPath
              renderAll
              echo -e "\033[36mMSG   : \033[32mchanged \033[37mstandart backup path to \033[33m$2\n"
            else
              echo -e "\n\033[31mError : \033[33mPath does not exist!\n"
            fi
            break
            ;;

    deact)  if [[ "$3" != "" ]] ; then
              echo -e "\n\033[31mError : \033[33mTo many arguments for deact.\n"
              break
            fi

            if [[ "$2" =~ ^[0-9][0-9]$ ]] || [[ "$2" =~ ^[0-9]$ ]] ; then
              
              ID=1
              while read line; do
                if [[ $ID -eq $2 ]] ; then
                  deletedLine=$line
                  break
                fi
                ID=$(($ID+1))
              done < $backupFile

              if [[ $deletedLine = "" ]] ; then
                echo -e "\n\033[31mError : \033[33mBackup ID $2 does not exsist!\n"
                break
              fi

              echo "$deletedLine" >> $deactBackupFile
              echo -e "\n\033[36mMSG   : \033[37mDeactivating backup \033[37mID-$2 ..."
              sed -i "$2d" $backupFile
              count=1
              renderList $backupFile $backupList
              count=1
              renderList $deactBackupFile $deactBackupList deact
              echo -e "\033[36mMSG   : \033[33mDeactivated backup ID-$2\033[37m\n"

              cat $backupList
              cat $deactBackupList
              
            else
              echo -e "\n\033[31mError : \033[33m'$2' is not an argument for deact\n"
              break
            fi
            break
            ;; 
         
    react)  if [[ "$3" != "" ]] ; then
              echo -e "\n\033[31mError : \033[33mTo many arguments for react.\n"
              break
            fi
            if [[ "$2" =~ ^[0-9][0-9]$ ]] || [[ "$2" =~ ^[0-9]$ ]] ; then

              ID=1
              while read line; do
                if [[ $ID -eq $2 ]] ; then
                  deletedLine=$line
                  break
                fi
                ID=$(($ID+1))
              done < $deactBackupFile
              
              if [[ "$deletedLine" = "" ]] ; then
                echo -e "\n\033[31mError : \033[33mBackup ID $2 does not exsist in deactivation list\n"
                break
              fi

              one=`echo "$deletedLine" | cut -d"$separator" -f1`
              two=`echo "$deletedLine" | cut -d"$separator" -f2`
              three=`echo "$deletedLine" | cut -d"$separator" -f3`
              four=`echo "$deletedLine" | cut -d"$separator" -f4`
              five=`echo "$deletedLine" | cut -d"$separator" -f5`

              programmBackup "$one" "$two" "$three" "$four" "$five"

              if [[ $reProgram = 1 ]] ; then
                sed -i "$2d" $deactBackupFile
                count=1
                renderList $deactBackupFile $deactBackupList deact
                echo -e "\033[36mMSG   : \033[32mReactivated backup ID $2."
              else
                echo -e "\033[31mError : \033[33mBackup ID $2 can't be reactivated!"
              fi
              cat $backupList
              cat $deactBackupList
            else
              echo -e "\n\033[31mError : \033[33m'$2' is not an argument for react\n"
            fi
            break  
            ;;
         

    rm)     if [[ "$3" != "" ]] ; then
              echo -e "\n\033[31mError : \033[33mTo many arguments for rm.\n"
              break
            fi

            if [[ "$2" = "trash" ]] ; then
              echo -e -n "\n\033[35mQ & A?: \033[33mDo you really want to \033[31mdelete \033[33mthe trashbin? \033[37m[\033[32my\033[37m/\033[31mN\033[37m] : " ; 
              read option
              case $option in
                yes|y|Yes|Y)  echo -e "\n\033[36mMSG   : \033[33mDeleting trashbin..."
                              rm -f $trashBackupList 
                              rm -f $trashBackupFile 
                              echo -e "\033[36mMSG   : \033[33mTrashbin deleted!\n"
                              ;;
                *)    echo -e "\n\033[36mMSG   : \033[32mTrashbin not deleted!\n"
                      ;;
              esac
              break
            elif [[ "$2" = "deact" ]] ; then
              echo -e -n "\n\033[35mQ & A?: \033[33mDo you really want to \033[31mdelete \033[33mthe deactivation list? \033[37m[\033[32my\033[37m/\033[31mN\033[37m] : " ; 
              read option
              case $option in
                yes|y|Yes|Y)  echo -e "\n\033[36mMSG   : \033[33mDeleting deactivation list..."
                              rm -f $deactBackupFile
                              rm -f $deactBackupList 
                              echo -e "\033[36mMSG   : \033[33mDeactivation list deleted!\n"
                              ;;
                *)    echo -e "\n\033[36mMSG   : \033[32mDeactivation list not deleted!\n"
                      ;;
              esac
              break
            fi

            if [[ "$2" =~ ^[0-9][0-9]$ ]] || [[ "$2" =~ ^[0-9]$ ]] ; then
              
              ID=1
              while read line; do
                if [[ $ID -eq $2 ]] ; then
                  deletedLine=$line
                  break
                fi
                ID=$(($ID+1))
              done < $backupFile

              if [[ $deletedLine = "" ]] ; then
                echo -e "\n\033[31mError : \033[33mBackup ID $2 does not exsist!\n"
                break
              fi

              echo "$deletedLine" >> $trashBackupFile
              echo -e "\n\033[36mMSG   : \033[37mCopied backup \033[37mID-$2 to trashbin"
              sed -i "$2d" $backupFile
              count=1
              renderList $backupFile $backupList
              count=1
              renderList $trashBackupFile $trashBackupList trash
              echo -e "\033[36mMSG   : \033[33mDeleted ID-$2\033[37m"

              cat $backupList
              cat $trashBackupList

            else
              echo -e "\n\033[31mError : \033[33m'$2' is not an argument for rm\n"
              break
            fi
            break
            ;;


    re)     if [[ "$3" != "" ]] ; then
              echo -e "\n\033[31mError : \033[33mTo many arguments for re.\n"
              break
            fi
            #if [[ "$2" = "0" || "$2" = "00" ]] ; then
            #  echo -e "\n\033[31mError : \033[33mBackup ID $2 does not exsist in trashbin!\n"
            #  break
            #fi
            
            if [[ "$2" =~ ^[0-9][0-9]$ ]] || [[ "$2" =~ ^[0-9]$ ]] ; then

              ID=1
              while read line; do
                if [[ $ID -eq $2 ]] ; then
                  deletedLine=$line
                  break
                fi
                ID=$(($ID+1))
              done < $trashBackupFile
              
              if [[ "$deletedLine" = "" ]] ; then
                echo -e "\n\033[31mError : \033[33mBackup ID $2 does not exsist in trashbin\n"
                break
              fi

              one=`echo "$deletedLine" | cut -d"$separator" -f1`
              two=`echo "$deletedLine" | cut -d"$separator" -f2`
              three=`echo "$deletedLine" | cut -d"$separator" -f3`
              four=`echo "$deletedLine" | cut -d"$separator" -f4`
              five=`echo "$deletedLine" | cut -d"$separator" -f5`

              programmBackup "$one" "$two" "$three" "$four" "$five"

              if [[ $reProgram = 1 ]] ; then
                sed -i "$2d" $trashBackupFile
                count=1
                renderList $trashBackupFile $trashBackupList trash
                echo -e "\033[36mMSG   : \033[32mRestored backup ID $2 from trashbin."
              else
                echo -e "\033[31mError : \033[33mBackup ID $2 from trashbin can't be restored!\n"
              fi
              cat $backupList
              cat $trashBackupList
            else
              echo -e "\n\033[31mError : \033[33m'$2' is not an argument for re\n"
            fi
            break
            ;;
    ls)     if [[ "$3" != "" ]] ; then
              echo -e "\n\033[31mError : \033[33mTo many arguments for ls.\n"
              break
            fi
            if [[ "$2" = "" ]] ; then
              cat $backupList
            elif [[ "$2"  = "all" ]] ; then
              cat $backupList
              if test -s $deactBackupList ; then
                cat $deactBackupList
              else
                echo -e "\n\033[36mMSG   : \033[33mDeactivation list is empty!\n"
              fi
              if test -s $trashBackupList ; then
                cat $trashBackupList
              else
                echo -e "\n\033[36mMSG   : \033[33mTrashbin is empty!\n"
              fi
            elif [[ "$2" = "trash" ]] ; then
              if test -s $trashBackupList ; then
                cat $trashBackupList
              else
                echo -e "\n\033[36mMSG   : \033[33mTrashbin is empty!\n"
              fi
            elif [[ "$2" = "deact" ]] ; then
              if test -s $deactBackupList ; then
                cat $deactBackupList
              else
                echo -e "\n\033[36mMSG   : \033[33mDeactivation list is empty!\n"
              fi
            else
              echo -e "\n\033[31mError : \033[33m'$2' is not an argument for ls\n"
            fi
            break
            ;;

    log)    if [[ "$3" != "" ]] ; then
              echo -e "\n\033[31mError : \033[33mTo many arguments for log.\n"
              break
            fi
            if [[ "$2" =~ ^[0-9][0-9]$ ]] || [[ "$2" =~ ^[0-9]$ ]] ; then
              ID=1
              while read line; do
                if [[ $ID -eq $2 ]] ; then
                  deletedLine=$line
                  break
                fi
                ID=$(($ID+1))
              done < $backupFile
              if [[ "$deletedLine" = "" ]] ; then
                echo -e "\n\033[31mError : \033[33mLOG ID $2 does not exsist!\n"
                break
              fi
              logDest=`echo $deletedLine | cut -d"$separator" -f5`
              if [[ "`echo $logDest | cut -b 1`" = "*" ]] ; then
                cd "`cat $backupPath``echo $logDest | cut -b 2-`"
              else
                cd $logDest
              fi
              #cd /usr/local/etc/backup
              cat * 2>> /dev/null | less
            else
              echo -e "\n\033[31mError : \033[33m'$2' is not an argument for log\n"
            fi
            break
            ;;

    -h|--help|help)     
            if [[ "$2" != "" ]] ; then
              echo -e "\n\033[31mError : \033[33mTo many arguments for --help.\n"
              break
            fi
            renderHelp
            cat $helpScreen
            break
            ;;

    --restoreProgram)
            if [[ "$4" != "" ]] ; then
              echo -e "\n\033[31mError : \033[33mTo many arguments for --restoreProgram\n"
              break
            fi
            if [[ "$3" = "--yes" ]] ; then
              if test -e $2 ; then
                rm -rf /usr/local/etc/backup
                touchData
                cp $2 $programmDir/$backupFileDir/$backupFile
                renderAll
              fi
              break
            fi
            if [[ "$3" = "" ]] ; then
              echo -e -n "\n\033[35mQ & A?: \033[33mDo you really want to \033[31mdelete \033[33mthe program files and restore from the file? \033[37m[\033[32my\033[37m/\033[31mN\033[37m] : " ; 
              read option
              case $option in
                yes|y|Yes|Y)  
                              if test -f $2 ; then
                                echo -e "\n\033[36mMSG   : \033[33mDeleting program files..."
                                rm -rf /usr/local/etc/backup
                                echo -e "\033[36mMSG   : \033[33mProgram files deleted!\n"
                                echo -e "\n\033[36mMSG   : \033[33mRestore data from file..."
                                touchData
                                cp $2 $programmDir/$backupFileDir/
                                renderAll
                                echo -e "\033[36mMSG   : \033[33mRestored!\n"
                              else
                                echo -e "\n\033[31mError : \033[33mProgram can't be restored, $2 is not a file\n"
                              fi
                              ;;
                *)    echo -e "\n\033[36mMSG   : \033[32mProgram files not deleted!\n"
                      ;;
              esac
            else
              echo -e "\n\033[31mError : \033[33m'$3' is not an argument for --restoreProgram\n"
            fi            
            break
            ;;
            
    --deleteAllProgramFiles)
            if [[ "$3" != "" ]] ; then
              echo -e "\n\033[31mError : \033[33mTo many arguments for --deleteAllProgramFiles.\n"
              break
            fi
            if [[ "$2" = "--yes" ]] ; then
              rm -rf /usr/local/etc/backup
              break
            fi
            echo -e -n "\n\033[35mQ & A?: \033[33mDo you really want to \033[31mdelete \033[33mthe programfiles? \033[37m[\033[32my\033[37m/\033[31mN\033[37m] : " ; 
            read option
            case $option in
              yes|y|Yes|Y)  echo -e "\n\033[36mMSG   : \033[33mDeleting programfiles..."
                            rm -rf /usr/local/etc/backup
                            echo -e "\033[36mMSG   : \033[33mProgram files deleted!\n"
                            ;;
              *)    echo -e "\n\033[36mMSG   : \033[32mProgram files not deleted!\n"
                    ;;
            esac
            break
            ;;

    *)      echo -e "\n\033[31mError : \033[33mSyntax Error!!\n"
            break
            ;;
  esac
done
echo -e -n "\033[0m"


