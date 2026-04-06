#!/bin/bash

# version discription
# 1.0.2   1 - version of the program
#         0 - bugfix version of the program
#         2 - cosmetic change

version=usbbackup-1.5.0

if [[ $UID != 0 ]] ; then
  echo -e "\033[31mERROR :\033[33m You are not root!\033[0m" >&2
  exit 1
fi

set -euo pipefail

umask 00177

usbBackupPath=/usr/local/etc/usbbackup
usbBackupConfigPath=$usbBackupPath/config
usbBackupFile=$usbBackupConfigPath/usbbackup.json
count=1

mkdir -p $usbBackupPath
mkdir -p $usbBackupConfigPath

#update from 1.2.3 -> 1.3.3
if [ -s /usr/local/etc/usb_backup/usb_backup.json ] ; then
  cp /usr/local/etc/usb_backup/usb_backup.json $usbBackupFile
  rm -rf /usr/local/etc/usb_backup
fi


if ! [ -s $usbBackupFile ] ; then
  echo "{\"usbBackup\": [] }" | jq > $usbBackupFile
fi

# JSON file location:
#   /usr/local/etc/usbbackup/config/usbbackup.json
#
# JSON structure (example of one configured backup job)
# {
#   "usbBackup": [{
#     "timeout": "ready",
#     "dir": "/data/backups/usb_backup/",
#     "uuid": "42066FAB066F9F23",
#     "exclude": "'*/0_Papierkorb'",
#     "last_error": "",
#     "active_boot_id": "",
#     "active_mount_path": ""
#   }]
# }
# timeout meaning:
#   ready                -> run on the next matching usbbackup exec
#   currently_executing  -> backup is running right now
#   failed               -> last run ended with an error, resetTimer required
#   HH:MM                -> scheduled retry time

function help {
  backupTime=`date +"%Y-%m-%d--%H-%M"`
  mntPath=$usbBackupPath/mount/${backupTime}_ID1
  echo -e "\033[0m
  usbbackup [option] [arguments.....]

  options:

    ls []            >> lists all usbBackups

    rm [1-99]        >> delete a usbBackup with that ID [1-99]

    exec []          >> for every minute execute use cron syntax | \033[36m* * * * * /usr/local/bin/usbbackup exec \033[0m
         [<command>] >> insert bash command in <command>, this command executes before disk will be mounted
         [<start cmd>] [<end cmd>] >> command <start cmd> executes before disk will be mounted, command <end cmd> executes after disk is unmounted

    prog [UUID] [DIR] [EXCLUDE] >> uses this to program a new usbbackup

    resetTimer [1-99] >> reset failed/currently_executing state so that this usbbackup will be executed with the next \`usbbackup exec\` call

    version / --version >> Shows the program version.

  ------------
  | EXAMPLES |
  ------------

    Structure
      /data1/data2
      /data1/data3
      /data1/test.txt
      /data1/hello world.txt

    EXAMPLE >> $ usbbackup prog 68EE9C02EE9BC72A /data1
    EXECUTES $ rsync\033[35m --archive --copy-links --stats --chown=root:root --chmod=D777,F777 --delete --inplace --whole-file \033[36m/data1 \033[0m $mntPath/$HOSTNAME/data1

    EXAMPLE >> $ usbbackup prog 68EE9C02EE9BC72A /data1/ \033[32m# preferable, else rsync will create folder $HOSTNAME/data1/data1\033[0m
    EXECUTES $ rsync\033[35m --archive --copy-links --stats --chown=root:root --chmod=D777,F777 --delete --inplace --whole-file \033[36m/data1/ \033[0m $mntPath/$HOSTNAME/data1

    EXAMPLE >> $ usbbackup prog 68EE9C02EE9BC72A /data1/ \"'data2'\"
    EXECUTES $ rsync\033[35m --archive --copy-links --stats --chown=root:root --chmod=D777,F777 --delete --inplace --whole-file --exclude=\033[32m{\033[36m'data2'\033[32m}\033[0m \033[36m/data1/ \033[0m $mntPath/$HOSTNAME/data1

    EXAMPLE >> $ usbbackup prog 68EE9C02EE9BC72A /data1/ \"'data2','test.txt'\"
    EXECUTES $ rsync\033[35m --archive --copy-links --stats --chown=root:root --chmod=D777,F777 --delete --inplace --whole-file --exclude=\033[32m{\033[36m'data2','test.txt'\033[32m}\033[0m \033[36m/data1/ \033[0m $mntPath/$HOSTNAME/data1

    EXAMPLE >> $ usbbackup prog 68EE9C02EE9BC72A /data1/ \"'data2','data3','hello world.txt'\"
    EXECUTES $ rsync\033[35m --archive --copy-links --stats --chown=root:root --chmod=D777,F777 --delete --inplace --whole-file --exclude=\033[32m{\033[36m'data2','data3','hello world.txt'\033[32m}\033[0m \033[36m/data1/ \033[0m $mntPath/$HOSTNAME/data1
\033[0m"
}

# $1: variable containing start command, e.g. '$start_cmd'
# $2: variable containing end   command, e.g. '$end_cmd'
function execution {
  time=`date +"%H:%M"`
  for i in  $(seq 0 $(( $(jq -r .usbBackup[].timeout $usbBackupFile | wc -l)-1))) ; do
    ID=$(($i+1))
    execDir=`jq -r .usbBackup[$i].dir $usbBackupFile`
    execUUID=`jq -r .usbBackup[$i].uuid $usbBackupFile`
    execExclude=`jq -r .usbBackup[$i].exclude $usbBackupFile`
    timeout=`jq -r .usbBackup[$i].timeout $usbBackupFile`
    activeBootId=`jq -r ".usbBackup[$i].active_boot_id // empty" $usbBackupFile`
    activeMountPath=`jq -r ".usbBackup[$i].active_mount_path // empty" $usbBackupFile`
    currentBootId=`cat /proc/sys/kernel/random/boot_id`

    if [[ "$timeout" = "currently_executing" ]] ; then
      if [[ "$activeBootId" != "" ]] && [[ "$activeBootId" != "$currentBootId" ]] ; then
        failureMessage="Previous usbbackup run was interrupted by a reboot or power outage."
      elif [[ "$activeMountPath" != "" ]] && ! findmnt -rn --target "$activeMountPath" > /dev/null 2>&1 ; then
        failureMessage="Previous usbbackup run was interrupted. Expected mount path is no longer mounted: $activeMountPath"
      else
        devicePath=`readlink -f /dev/disk/by-uuid/$execUUID 2> /dev/null || true`
        if [[ "$activeMountPath" = "" ]] && [[ "$devicePath" != "" ]] && ! findmnt -rn --source "$devicePath" > /dev/null 2>&1 ; then
          failureMessage="Previous usbbackup run is marked as currently_executing, but the backup disk is not mounted anymore."
        else
          failureMessage=""
        fi
      fi

      if [[ "$failureMessage" != "" ]] ; then
        echo -e "\033[31mERROR :\033[33m $failureMessage\033[0m" >&2
        handover=/dev/shm/.usbbackupHandover.temp
        jq --arg errorMessage "$failureMessage" ".usbBackup[$i].timeout=\"failed\" | .usbBackup[$i].last_error=\$errorMessage | .usbBackup[$i].active_boot_id=null | .usbBackup[$i].active_mount_path=null" $usbBackupFile > $handover
        mv $handover $usbBackupFile
        timeout="failed"
      fi
    fi

                                     # compatile to older versions
    if [[ "$timeout" = "$time" ]] || [[ "$timeout" = "0" ]] ; then
      handover=/dev/shm/.usbbackupHandover.temp
      jq ".usbBackup[$i].timeout=\"ready\" | .usbBackup[$i].last_error=\"\" | .usbBackup[$i].active_boot_id=null | .usbBackup[$i].active_mount_path=null" $usbBackupFile > $handover
      mv $handover $usbBackupFile
      timeout="ready"
    fi
    if lsblk /dev/disk/by-uuid/$execUUID >> /dev/null 2>&1 && [[ "$timeout" = "ready" ]] ; then
      if [[ "$1" != "" ]] ; then
        echo -e "\nexecute start command: $(eval echo $1)"
        # double eval: first eval expands '$start_cmd' to real command string, second eval evaluates command
        if ! eval eval $1 ; then
          errorMessage="Start command failed for usbbackup ID $ID."
          echo -e "\033[31mERROR :\033[33m $errorMessage\033[0m" >&2
          handover=/dev/shm/.usbbackupHandover.temp
          jq --arg errorMessage "$errorMessage" ".usbBackup[$i].timeout=\"failed\" | .usbBackup[$i].last_error=\$errorMessage | .usbBackup[$i].active_boot_id=null | .usbBackup[$i].active_mount_path=null" $usbBackupFile > $handover
          mv $handover $usbBackupFile
          return 1
        fi
        echo
      fi

      handover=/dev/shm/.usbbackupHandover.temp
      umask 00077
      backupTime=`date +"%Y-%m-%d--%H-%M"`
      mntPath=$usbBackupPath/mount/${backupTime}_ID-$ID
      mntPathrm=$usbBackupPath/mount/*
      mkdir -p $mntPath
      jq --arg bootId "$currentBootId" --arg mountPath "$mntPath" ".usbBackup[$i].timeout=\"currently_executing\" | .usbBackup[$i].last_error=\"\" | .usbBackup[$i].active_boot_id=\$bootId | .usbBackup[$i].active_mount_path=\$mountPath" $usbBackupFile > $handover
      mv $handover $usbBackupFile

      # mount drive
      echo -e "mount /dev/disk/by-uuid/$execUUID $mntPath\n"
      if ! mount -v /dev/disk/by-uuid/$execUUID $mntPath ; then
        errorMessage="Mount failed for backup disk UUID $execUUID."
        echo -e "\033[31mERROR :\033[33m $errorMessage\033[0m" >&2

        handover=/dev/shm/.usbbackupHandover.temp
        jq --arg errorMessage "$errorMessage" ".usbBackup[$i].timeout=\"failed\" | .usbBackup[$i].last_error=\$errorMessage | .usbBackup[$i].active_boot_id=null | .usbBackup[$i].active_mount_path=null" $usbBackupFile > $handover
        mv $handover $usbBackupFile
        rmdir -p $mntPathrm 2> /dev/null
        return 1

      else
        echo
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
        rsyncExitCode=0
        if [[ "$execExclude" = "" ]] ; then
          echo "rsync --archive --copy-links --stats --chown=root:root --chmod=D777,F777 --delete --inplace --whole-file $execDir $rsyncPath"
          if ! rsync --archive --copy-links --stats --chown=root:root --chmod=D777,F777 --delete --inplace --whole-file $execDir $rsyncPath | tee -a $mntPath/$HOSTNAME/backuptime_$rsyncDir.txt ; then
            rsyncExitCode=${PIPESTATUS[0]}
          fi
        else
          rsyncExclude=$(echo -n "$execExclude" | sed -e "s/'\([^']*\)',*/--exclude='\1' /g")
          echo $rsyncExclude
          eval echo rsync --archive --copy-links --stats --chown=root:root --chmod=D777,F777 --delete --inplace --whole-file $rsyncExclude $execDir $rsyncPath
          if ! eval rsync --archive --copy-links --stats --chown=root:root --chmod=D777,F777 --delete --inplace --whole-file $rsyncExclude $execDir $rsyncPath | tee -a $mntPath/$HOSTNAME/backuptime_$rsyncDir.txt ; then
            rsyncExitCode=${PIPESTATUS[0]}
          fi
        fi

        if [[ $rsyncExitCode -ne 0 ]] ; then
          errorMessage="rsync failed for usbbackup ID $ID with exit code $rsyncExitCode."
          echo -e "\033[31mERROR :\033[33m $errorMessage\033[0m" >&2
          echo "[`date +"%Y-%m-%d %H:%M"`] [FAILED USB-Backup] rsync exit code $rsyncExitCode" | tee -a $mntPath/$HOSTNAME/backuptime_$rsyncDir.txt

          echo "umount $mntPath"
          for x in {1..5} ; do
            umount $mntPath && break
            echo "Failed to unmount drive, retry in 2s.."
            sleep 2 ; false
          done || errorMessage="$errorMessage Cleanup could not unmount $mntPath."

          handover=/dev/shm/.usbbackupHandover.temp
          jq --arg errorMessage "$errorMessage" ".usbBackup[$i].timeout=\"failed\" | .usbBackup[$i].last_error=\$errorMessage | .usbBackup[$i].active_boot_id=null | .usbBackup[$i].active_mount_path=null" $usbBackupFile > $handover
          mv $handover $usbBackupFile
          rmdir -p $mntPathrm 2> /dev/null
          return 1
        fi

        # write end time to drive
        echo "[`date +"%Y-%m-%d %H:%M"`] [END USB-Backup]" | tee -a $mntPath/$HOSTNAME/backuptime_$rsyncDir.txt

        # scrub a btrfs backup
        if df --output=fstype $mntPath | grep btrfs > /dev/null 2>&1 ; then
          echo -e "\nFile system is btrfs performing a scrub!"
          if ! btrfs scrub start -B -d $mntPath ; then
            errorMessage="btrfs scrub failed for mount path $mntPath."
            echo -e "\033[31mERROR :\033[33m $errorMessage\033[0m" >&2

            echo "umount $mntPath"
            for x in {1..5} ; do
              umount $mntPath && break
              echo "Failed to unmount drive, retry in 2s.."
              sleep 2 ; false
            done || errorMessage="$errorMessage Cleanup could not unmount $mntPath."

            handover=/dev/shm/.usbbackupHandover.temp
            jq --arg errorMessage "$errorMessage" ".usbBackup[$i].timeout=\"failed\" | .usbBackup[$i].last_error=\$errorMessage | .usbBackup[$i].active_boot_id=null | .usbBackup[$i].active_mount_path=null" $usbBackupFile > $handover
            mv $handover $usbBackupFile
            rmdir -p $mntPathrm 2> /dev/null
            return 1
          fi
          echo
        fi

        # unmount drive
        echo "umount $mntPath"

        # try 5 times to unmount with 2s pause in between
        unmountFailed=1
        for x in {1..5} ; do
          if umount $mntPath ; then
            unmountFailed=0
            break
          fi
          echo "Failed to unmount drive, retry in 2s.."
          sleep 2
        done

        if [[ $unmountFailed -ne 0 ]] ; then
          errorMessage="Unmount failed for mount path $mntPath."
          echo -e "\033[31mERROR :\033[33m $errorMessage\033[0m" >&2

          handover=/dev/shm/.usbbackupHandover.temp
          jq --arg errorMessage "$errorMessage" ".usbBackup[$i].timeout=\"failed\" | .usbBackup[$i].last_error=\$errorMessage | .usbBackup[$i].active_boot_id=null | .usbBackup[$i].active_mount_path=null" $usbBackupFile > $handover
          mv $handover $usbBackupFile
          rmdir -p $mntPathrm 2> /dev/null
          return 1
        fi

        H=`date +"%_H"`
        M=$((`date +"%_M"`-1))
        if [[ $M -eq -1 ]] ; then
          H=$(($H-1))
          M=59
          if [[ $H -eq -1 ]] ; then
            H=23
          fi
        fi

        timeAfterBackup=`date -d $H:$M +"%H:%M"`

        handover=/dev/shm/.usbbackupHandover.temp
        jq ".usbBackup[$i].timeout=\"$timeAfterBackup\" | .usbBackup[$i].last_error=\"\" | .usbBackup[$i].active_boot_id=null | .usbBackup[$i].active_mount_path=null" $usbBackupFile > $handover
        mv $handover $usbBackupFile
      fi
      rmdir -p $mntPathrm 2> /dev/null

      if [[ "$2" != "" ]] ; then
        echo -e "\nexecute end command: $(eval echo $2)"
        # double eval: first eval expands '$start_cmd' to real command string, second eval evaluates command
        if ! eval eval $2 ; then
          errorMessage="End command failed for usbbackup ID $ID after a successful backup."
          echo -e "\033[31mERROR :\033[33m $errorMessage\033[0m" >&2
          return 1
        fi
        echo
      fi

      echo -e "\n/-/-/  USB-Backup complete!  /-/-/\n"
    fi
    count=$(($count+1))
  done
}

if [[ "${1:-}" = "" ]] ; then
  help
  exit
fi

case ${1:-} in
  exec) start_cmd=${2:-}
        end_cmd=${3:-}
        execution '$start_cmd' '$end_cmd'
        ;;

  prog) echo -e -n "\033[33m"
        if [[ -d "${3:-}" ]] && lsblk /dev/disk/by-uuid/${2:-} > /dev/null 2>&1 ; then
          count=0
          handover=/dev/shm/.usbbackupHandover.temp
          while ! [[ "`jq .usbBackup[$count].dir $usbBackupFile`" = "null" ]] ; do
            count=$(($count+1))
          done

          array=".usbBackup[$count]"
          jq " $array.timeout=\"ready\" | $array.uuid=\"${2:-}\" | $array.dir=\"${3:-}\" | $array.exclude=\"${4:-}\" | $array.last_error=\"\" | $array.active_boot_id=null | $array.active_mount_path=null " $usbBackupFile > $handover
          mv $handover $usbBackupFile
          echo -e "\033[36mMSG   :\033[32m Saved!\033[0m"
        else
          echo -e "\033[31mERROR :\033[33m Error DIR or UUID does not exsist!\033[0m" >&2
        fi
        ;;

    ls) #lsblk -f
        handover=/dev/shm/.usbbackupHandover.temp
        echo -e -n "\033[36m"
        echo -e "ID#TIMEOUT#UUID#DIR#EXCLUDE#LAST_ERROR\n" > $handover

        for i in  $(seq 0 $(($(jq -r .usbBackup[].dir $usbBackupFile | wc -l)-1))) ; do
          listDir=$(jq .usbBackup[$i].dir $usbBackupFile)
          if ! [[ "$listDir" = "null" ]] ; then
            ID=$(($i+1))
            timeout=$(jq -r ".usbBackup[$i].timeout" $usbBackupFile)
            uuid=$(jq -r ".usbBackup[$i].uuid" $usbBackupFile)
            dir=$(jq -r ".usbBackup[$i].dir" $usbBackupFile)
            exclude=$(jq -r ".usbBackup[$i].exclude" $usbBackupFile)
            lastError=$(jq -r ".usbBackup[$i].last_error // \"\"" $usbBackupFile)

            echo -e "${ID}#${timeout}#${uuid}#${dir}#${exclude}#${lastError}" >> $handover
          fi
        done

        column $handover -t -s "#"
        rm $handover
        echo -e -n "\033[0m"
        ;;

    rm) if [[ ${2:-} = [0-9][0-9] ]] || [[ ${2:-} = [0-9] ]] ; then
          handover=/dev/shm/.usbbackupHandover.temp
          array=".usbBackup[$((${2:-0}-1))]"
          jq "$array=null" $usbBackupFile > $handover
          mv $handover $usbBackupFile
        else
          echo -e "\033[31mERROR :\033[33m '${2:-}' is no argumet for rm\033[0m" >&2
        fi
        ;;

    resetTimer) if [[ ${2:-} = [0-9][0-9] ]] || [[ ${2:-} = [0-9] ]] ; then
            handover=/dev/shm/.usbbackupHandover.temp
            jq ".usbBackup[$((${2:-0}-1))].timeout = \"ready\" | .usbBackup[$((${2:-0}-1))].last_error = \"\" | .usbBackup[$((${2:-0}-1))].active_boot_id = null | .usbBackup[$((${2:-0}-1))].active_mount_path = null" $usbBackupFile > $handover
            mv $handover $usbBackupFile
        else
          echo -e "\033[31mERROR :\033[33m '${2:-}' is no argument for resetTimer \033[0m" >&2
        fi
        ;;

    -h|--help|help)
        help
        ;;

    version|--version)
        echo -e "$version"
        ;;

    *)  echo -e "\033[31mERROR :\033[33m Syntax Error!\033[0m" >&2
        ;;
esac
