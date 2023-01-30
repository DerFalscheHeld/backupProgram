#!/bin/bash

if [[ $UID != 0 ]] ; then
  echo -e "\033[31mERROR :\033[33m You are not root!\033[0m" >&2
  exit 1
fi

umask 0177

usbBackupPath=/usr/local/etc/usb_backup
usbBackupFile=$usbBackupPath/usb_backup.json
count=1

mkdir -p $usbBackupPath
if ! [ -s $usbBackupFile ] ; then
  jo -p usbBackup=$(jo -a $(jo ID= timeout= dir= uuid= exclude= )) > $usbBackupFile
fi

function help {
  backupTime=`date +"%Y-%m-%d--%H-%M"`
  mntPath=$usbBackupPath/mount/$backupTime
  echo -e "
  usbbackup [option] [arguments.....]

  options:

    ls []            >> lists all usbBackups

    rm [1-99]        >> delete a usbBackup with that ID [1-99]

    exec []          >> for every minute execute use cron syntax | \033[36m* * * * * /usr/local/bin/usbbackup exec \033[37m
         [<command>] >> insert bash command in <command>, this command executes before disk will be mounted
         [<start cmd>] [<end cmd>] >> command <start cmd> executes before disk will be mounted, command <end cmd> executes after disk is unmounted

    prog [DIR] [UUID] [EXCLUDE] >> prog uses this command

    resetTimer [1-99] >> reset timer so that this usbbackup will be executed with the next `usbbackup exec` call

    Structure
      /data1/data2
      /data1/data3
      /data1/test.txt
      /data1/hello world.txt

    EXAMPLE >> usbbackup prog 68EE9C02EE9BC72A /data1
    EXECUTES rsync\033[35m --archive --copy-links --stats --chown=root:root --chmod=D777,F777 --delete --inplace --whole-file \033[36m/data1 \033[37m $mntPath/$HOSTNAME/data1

    EXAMPLE >> usbbackup prog 68EE9C02EE9BC72A /data1/ \033[32m# preferable, else rsync will create folder $HOSTNAME/data1/data1\033[37m
    EXECUTES rsync\033[35m --archive --copy-links --stats --chown=root:root --chmod=D777,F777 --delete --inplace --whole-file \033[36m/data1/ \033[37m $mntPath/$HOSTNAME/data1

    EXAMPLE >> usbbackup prog 68EE9C02EE9BC72A /data1/ \"'data2'\"
    EXECUTES rsync\033[35m --archive --copy-links --stats --chown=root:root --chmod=D777,F777 --delete --inplace --whole-file --exclude=\033[32m{\033[36m'data2'\033[32m}\033[37m \033[36m/data1/ \033[37m $mntPath/$HOSTNAME/data1

    EXAMPLE >> usbbackup prog 68EE9C02EE9BC72A /data1/ \"'data2','test.txt'\"
    EXECUTES rsync\033[35m --archive --copy-links --stats --chown=root:root --chmod=D777,F777 --delete --inplace --whole-file --exclude=\033[32m{\033[36m'data2','test.txt'\033[32m}\033[37m \033[36m/data1/ \033[37m $mntPath/$HOSTNAME/data1

    EXAMPLE >> usbbackup prog 68EE9C02EE9BC72A /data1/ \"'data2','data3','hello world.txt'\"
    EXECUTES rsync\033[35m --archive --copy-links --stats --chown=root:root --chmod=D777,F777 --delete --inplace --whole-file --exclude=\033[32m{\033[36m'data2','data3','hello world.txt'\033[32m}\033[37m \033[36m/data1/ \033[37m $mntPath/$HOSTNAME/data1
\033[0m"
}

# $1: start command
# $2: end command
function execution {
  time=`date +"%H:%M"`
  for i in  $(seq 0 $(( $(jq -r .usbBackup[].ID $usbBackupFile | wc -l)-1))) ; do
    ID=`jq -r .usbBackup[$i].ID $usbBackupFile`
    execDir=`jq -r .usbBackup[$i].dir $usbBackupFile`
    execUUID=`jq -r .usbBackup[$i].uuid $usbBackupFile`
    execExclude=`jq -r .usbBackup[$i].exclude $usbBackupFile`
    timeout=`jq -r .usbBackup[$i].timeout $usbBackupFile`

    if [[ "$timeout" = "$time" ]] ; then
      handover=$(mktemp)
      jq ".usbBackup[$i].timeout=\"0\"" $usbBackupFile > $handover
      mv $handover $usbBackupFile
    fi
    if lsblk /dev/disk/by-uuid/$execUUID >> /dev/null 2>&1 && [[ "$timeout" = "0" ]] ; then
      if [[ "$1" != "" ]] ; then
        echo -e "\nexecute start command:"
        bash -c "$1"
        echo
      fi

      handover=$(mktemp)
      jq ".usbBackup[$i].timeout=\"currently_executing\"" $usbBackupFile > $handover
      mv $handover $usbBackupFile

      umask 0000
      backupTime=`date +"%Y-%m-%d--%H-%M"`
      mntPath=$usbBackupPath/mount/${backupTime}_ID-$ID
      mntPathrm=$usbBackupPath/mount/*
      mkdir -p $mntPath

      # mount drive
      echo -e "mount /dev/disk/by-uuid/$execUUID $mntPath\n"
      if ! mount -v /dev/disk/by-uuid/$execUUID $mntPath ; then
        echo "mount failed!" >&2

        handover=$(mktemp)
        jq ".usbBackup[$i].timeout=\"0\"" $usbBackupFile > $handover
        mv $handover $usbBackupFile

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
          rsyncExclude=$(echo -n "$execExclude" | sed -e "s/'\([^']*\)',*/--exclude='\1' /g")
          echo $rsyncExclude
          eval echo rsync --archive --copy-links --stats --chown=root:root --chmod=D777,F777 --delete --inplace --whole-file $rsyncExclude $execDir $rsyncPath
          eval rsync --archive --copy-links --stats --chown=root:root --chmod=D777,F777 --delete --inplace --whole-file $rsyncExclude $execDir $rsyncPath | tee -a $mntPath/$HOSTNAME/backuptime_$rsyncDir.txt
        fi

        # write end time to drive
        echo "[`date +"%Y-%m-%d %H:%M"`] [END USB-Backup]" | tee -a $mntPath/$HOSTNAME/backuptime_$rsyncDir.txt

        # unmount drive
        echo "umount $mntPath"
        # try 5 times to unmount with 2s pause in between
        for x in {1..5} ; do
          umount $mntPath && break
          echo "Failed to unmount drive, retry in 2s.."
          sleep 2 ; false #retur error code to echo "Failed 5 times. Skipping unount." >&2
        done || echo "Failed 5 times. Skipping unount." >&2
        time2=`date +"%H:%M"`

        handover=$(mktemp)
        jq ".usbBackup[$i].timeout=\"$time2\"" $usbBackupFile > $handover
        mv $handover $usbBackupFile
      fi
      rmdir -p $mntPathrm 2> /dev/null

      if [[ "$2" != "" ]] ; then
        echo -e "\nexecute end command:"
        bash -c "$2"
        echo
      fi

      echo -e "\n/-/-/  USB-Backup complete!  /-/-/\n"
    fi
    count=$(($count+1))
  done
}

if [[ "$1" = "" ]] ; then
  help
  exit
fi

case $1 in
  exec) execution "$2" "$3"
        ;;

  prog) echo -e -n "\033[33m"
        if [[ -d "$2" ]] && [[ `lsblk /dev/disk/by-uuid/$3` ]] ; then
        count=0
        handover=$(mktemp)
        while ! [[ "`jq .usbBackup[$count].dir $usbBackupFile`" = "null" ]] ; do
          count=$(($count+1))
        done

          #jo -p usbBackup=$(jo -a $(jo ID= timeout= dir= uuid= exclude= )) > $usbBackupFile
          array=".usbBackup[$count]"
          jq " $array.ID=$(($count+1)) | $array.timeout=\"0\" | $array.dir=\"$2\" | $array.uuid=\"$3\" | $array.exclude=\"$4\" " $usbBackupFile > $handover
          mv $handover $usbBackupFile
          echo -e "\033[36mMSG   :\033[32m Saved!\033[0m"
        else
          echo -e "\033[31mERROR :\033[33m Error DIR or UUID does not exsist!\033[0m" >&2
        fi
        ;;

    ls) lsblk -f
        handover=$(mktemp)
        echo -e "\033[36m"
        echo -e "ID#TIMEOUT#DIR#UUID#EXCLUDE\n" > $handover

        for i in  $(seq 0 $(($(jq -r .usbBackup[].dir $usbBackupFile | wc -l)-1))) ; do
          listDir=$(jq .usbBackup[$i].dir $usbBackupFile)
          if ! [[ "$listDir" = "null" ]] ; then

            ID=$(jq -r ".usbBackup[$i].ID" $usbBackupFile)
            timeout=$(jq -r ".usbBackup[$i].timeout" $usbBackupFile)
            dir=$(jq -r ".usbBackup[$i].dir" $usbBackupFile)
            uuid=$(jq -r ".usbBackup[$i].uuid" $usbBackupFile)
            exclude=$(jq -r ".usbBackup[$i].exclude" $usbBackupFile)

            echo -e "${ID}#${timeout}#${dir}#${uuid}#${exclude}" >> $handover
          fi
        done

        column $handover -t -s "#"
        echo -e "\033[0m"
        ;;

    rm) if [[ $2 = [0-9][0-9] ]] || [[ $2 = [0-9] ]] ; then
          handover=$(mktemp)
          array=".usbBackup[$(($2-1))]"
          jq " $array.timeout=null | $array.dir=null | $array.uuid=null | $array.exclude=null " $usbBackupFile > $handover
          mv $handover $usbBackupFile
        else
          echo -e "\033[31mERROR :\033[33m '$2 is no argumet for rm'\033[0m" >&2
        fi
        ;;

    resetTimer) if [[ $2 = [0-9][0-9] ]] || [[ $2 = [0-9] ]] ; then
            json_data=$(cat $usbBackupFile)
            echo $json_data | jq ".usbBackup[$(($2-1))].timeout = \"0\"" > $usbBackupFile
        else
          echo -e "\033[31mERROR :\033[33m '$2 is no argumet for resetTimer '\033[0m" >&2
        fi
        ;;

    -h|--help|help)
        help
        ;;

     *) echo -e "\033[31mERROR :\033[33m Syntax Error!\033[0m" >&2
        ;;
esac
