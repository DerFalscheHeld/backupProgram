#!/bin/bash

#usbbackup [DIR] [UUID] [EXCLUDE]

#config

#   timeout#ordner#uuid#exclude

# rsync -a --info=progress2 --delete --inplace --whole-file --exclude */0_Papierkorb /data/ /mnt

if [[ $UID != 0 ]] ; then
  echo -e "\033[31mERROR :\033[33m You are not root!\033[0m"
  exit
fi

umask 0177

time=`date +"%H%M"`

usbBackupPath=/usr/local/etc/usb_backup
usbBackupFile=$usbBackupPath/usb_backup.conf
usbBackup_ls=$usbBackupPath/usb_backup.ls
count=1

mkdir -p $usbBackupPath
touch $usbBackupFile
touch $usbBackup_ls

function help {
  backupTime=`date +"%Y-%m-%d--%H-%M"`
  mntPath=$usbBackupPath/mount/$backupTime
  echo -e "
  usbbackup [option] [arguments.....]

  options:

    ls []       >> lists all usbBackups

    rm [1-99]   >> delete a usbBackup with that ID [1-99]

    exec        >> for every minute execute use cron syntax | \033[36m* * * * * /usr/local/bin/usbbackup exec \033[37m

    prog [DIR] [UUID] [EXCLUDE] >> prog uses this command

         rsync \033[35m-a --stats --chown=root:root --chmod=D777,F777 --delete --inplace --whole-file --exclude=\033{37m\"\033[32m[\033[36m'EXCLUDE1','EXCLUDE2'\033[32m}\033[37m\" \033[32m[\033[36mDIR\033[32m] \033[37m $mntPath

  \033[0m"
}

function execution {
  while read line ; do
    execDir=`echo $line | cut -d'#' -f 2`
    execUUID=`echo $line | cut -d'#' -f 3`
    execExclude=`echo $line | cut -d'#' -f 4`
    timeout=`echo $line | cut -d'#' -f 1`
    if [[ "$timeout" = "$time" ]] ; then
      sed -i -e ${count}c"0#$execDir#$execUUID#$execExclude" $usbBackupFile
    fi
    if [[ `lsblk /dev/disk/by-uuid/$execUUID 2> /dev/null` ]] && [[ "$timeout" = "0" ]] ; then
      sed -i -e ${count}c"$time#$execDir#$execUUID#$execExclude" $usbBackupFile
      umask 0000
      backupTime=`date +"%Y-%m-%d--%H-%M"`
      mntPath=$usbBackupPath/mount/$backupTime
      mkdir -p $mntPath
      mount /dev/disk/by-uuid/$execUUID $mntPath
      count2=2
      while : ; do
        if [[ "`echo $execDir | cut -d"/" -f $count2`" = "" ]] || [[ $count2 -eq 100 ]] ; then
          rsyncDir=`echo $execDir | cut -d"/" -f $(($count2-1))`
          break
        fi
        count2=$(($count2+1))
      done
      rsyncPath=$mntPath/$rsyncDir
      if [[ "`$execExclude`" = "" ]] ; then
        rsync -a --stats --chown=root:root --chmod=D777,F777 --delete --inplace --whole-file $execDir $rsyncPath
      else
        rsync -a --stats --chown=root:root --chmod=D777,F777 --delete --inplace --whole-file --exclude={$execExclude} $execDir $rsyncPath
      fi
      echo -e "\n/-/-/  USB-Backup complete!  /-/-/\n"
      umount $mntPath
      rmdir -p $mntPath 2> /dev/null
      umask 0177
    fi
    count=$(($count+1))
  done < $usbBackupFile
}

if [[ "$1" = "" ]] ; then
  help
  exit
fi

case $1 in
  exec) execution
        ;;

  prog) echo -e -n "\033[33m"
        if [[ -d "$2" ]] && [[ `lsblk /dev/disk/by-uuid/$3` ]] ; then
          echo "0#$2#$3#$4" >> $usbBackupFile
          echo -e "\033[36mMSG   :\033[32m Saved!\033[0m"
        else
          echo -e "\033[31mERROR :\033[33m Error DIR or UUID does not exsist!\033[0m"
        fi
        ;;

    ls) lsblk -f
        echo -e "\033[36m"
        echo -e "ID#DIR#UUID#EXCLUDE\n" > $usbBackup_ls
        while read line ; do
          echo "$count#`echo $line | cut -d'#' -f 2`#`echo $line | cut -d'#' -f 3`#`echo $line | cut -d'#' -f 4`" >> $usbBackup_ls
          count=$(($count+1))
        done < $usbBackupFile
        column $usbBackup_ls -t -s "#"
        echo -e "\033[0m"
        ;;

    rm) if [[ $2 = [0-9][0-9] ]] || [[ $2 = [0-9] ]] ; then
          sed -i "$2d" $usbBackupFile
        else
          echo -e "\033[31mERROR :\033[33m '$2 is no argumet for rm'\033[0m"
        fi
        ;;

    -h|--help|help)
        help
        ;;

     *) echo -e "\033[31mERROR :\033[33m Syntax Error!\033[0m"
        ;;
esac
