#!/bin/bash

#usbbackup [DIR] [UUID] [EXCLUDE]

#config
#   timeout#ordner#uuid#exclude

# rsync -a --info=progress2 --delete --inplace --whole-file --exclude */0_Papierkorb /data/ /mnt

if [[ $UID != 0 ]] ; then
  echo -e "\033[31mERROR :\033[33m You are not root!\033[0m" >&2
  exit 1
fi

umask 0177

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

    EXAMPLE >> usbbackup prog /data1
    EXECUTES rsync\033[35m --archive --copy-links --stats --chown=root:root --chmod=D777,F777 --delete --inplace --whole-file \033[36m/data1 \033[37m $mntPath

    EXAMPLE >> usbbackup prog /data1 \"'/data2','data3','test.txt'\"
    EXECUTES rsync\033[35m --archive --copy-links --stats --chown=root:root --chmod=D777,F777 --delete --inplace --whole-file --exclude=\033[32m{\033[36m'data2','data3','test.txt'\033[32m}\033[37m \033[36m/data1 \033[37m $mntPath

    EXAMPLE >> usbbackup prog /data1 \"'/data2'\"
    EXECUTES rsync\033[35m --archive --copy-links --stats --chown=root:root --chmod=D777,F777 --delete --inplace --whole-file --exclude=\033[32m{\033[36m'data2'\033[32m}\033[37m \033[36m/data1 \033[37m $mntPath
  \033[0m"
}

function execution {
  while read line ; do
    time=`date +"%H%M"`
    execDir=`echo $line | cut -d'#' -f 2`
    execUUID=`echo $line | cut -d'#' -f 3`
    execExclude=`echo $line | cut -d'#' -f 4`
    timeout=`echo $line | cut -d'#' -f 1`
    if [[ "$timeout" = "$time" ]] ; then
      sed -i -e ${count}c"0#$execDir#$execUUID#$execExclude" $usbBackupFile
    fi
    if lsblk /dev/disk/by-uuid/$execUUID >> /dev/null 2>&1 && [[ "$timeout" = "0" ]] ; then
      sed -i -e ${count}c"currently_executing#$execDir#$execUUID#$execExclude" $usbBackupFile
      umask 0000
      backupTime=`date +"%Y-%m-%d--%H-%M"`
      mntPath=$usbBackupPath/mount/$backupTime
      mntPathrm=$usbBackupPath/mount/*
      mkdir -p $mntPath

      # mount drive
      echo -e "mount /dev/disk/by-uuid/$execUUID $mntPath\n"
      if ! mount -v /dev/disk/by-uuid/$execUUID $mntPath ; then
        echo "mount failed!" >&2
        sed -i -e ${count}c"0#$execDir#$execUUID#$execExclude" $usbBackupFile
      else

        # calculate $rsyncPath (path to copy to)
        count2=2
        while : ; do
          if [[ "`echo $execDir | cut -d"/" -f $count2`" = "" ]] || [[ $count2 -eq 100 ]] ; then
            rsyncDir=`echo $execDir | cut -d"/" -f $(($count2-1))`
            break
          fi
          count2=$(($count2+1))
        done
        rsyncPath=$mntPath/$HOSTNAME/$rsyncDir
        mkdir -p $rsyncPath

        # write start time to drive
        touch $mntPath/$HOSTNAME/backuptime_$rsyncDir.txt
        echo "[`date +"%Y-%m-%d %H:%M"`] [START USB-Backup]" | tee -a $mntPath/$HOSTNAME/backuptime_$rsyncDir.txt

        # run rsync
        if [[ "$execExclude" = "" ]] ; then
          echo "rsync --archive --copy-links --stats --chown=root:root --chmod=D777,F777 --delete --inplace --whole-file $execDir $rsyncPath"
          rsync --archive --copy-links --stats --chown=root:root --chmod=D777,F777 --delete --inplace --whole-file $execDir $rsyncPath | tee -a $mntPath/$HOSTNAME/backuptime_$rsyncDir.txt
        else
          echo "rsync --archive --copy-links --stats --chown=root:root --chmod=D777,F777 --delete --inplace --whole-file --exclude={$execExclude} $execDir $rsyncPath"
          rsync --archive --copy-links --stats --chown=root:root --chmod=D777,F777 --delete --inplace --whole-file --exclude={$execExclude} $execDir $rsyncPath | tee -a $mntPath/$HOSTNAME/backuptime_$rsyncDir.txt
        fi

        # write end time to drive
        echo "[`date +"%Y-%m-%d %H:%M"`] [END USB-Backup]" | tee -a $mntPath/$HOSTNAME/backuptime_$rsyncDir.txt

        # unmount drive
        echo "umount $mntPath"
        # try 5 times to unmount with 2s pause in between
        for i in {1..5} ; do
          umount $mntPath && break
          echo "Failed to unmount drive, retry in 2s.."
          sleep 2
        done || echo "Failed 5 times. Skipping unount." >&2

        sed -i -e ${count}c"$time#$execDir#$execUUID#$execExclude" $usbBackupFile
      fi
      rmdir -p $mntPathrm 2> /dev/null
      echo -e "\n/-/-/  USB-Backup complete!  /-/-/\n"
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
          echo -e "\033[31mERROR :\033[33m Error DIR or UUID does not exsist!\033[0m" >&2
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
          echo -e "\033[31mERROR :\033[33m '$2 is no argumet for rm'\033[0m" >&2
        fi
        ;;

    -h|--help|help)
        help
        ;;

     *) echo -e "\033[31mERROR :\033[33m Syntax Error!\033[0m" >&2
        ;;
esac
