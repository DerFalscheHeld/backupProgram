#!/usr/bin/bash

# version discription
# 1.0.2   1 - version of the program
#         0 - bugfix version of the program
#         2 - cosmetic change

version=experimantal-backup-0.0.0

sourcefiles=/home/simon/backupProgram/backup2Code/*
for sourcefile in $sourcefiles ; do
  source $sourcefile
done

umask 00177

if [[ $UID != 0 ]] ; then
  error "\033[31mError : \033[33mYou are not root!"
  exit_
fi
if [[ $# -eq 7 ]] ; then
  error "\033[31mError : \033[33mTo many arguments!"
  exit_
fi
if [[ "$1" = "" ]] ; then
  output "$(helpPage1)"
  output "$(helpPage2)"
  output "$(helpPage3)"
  exit_
fi

touchData

if ! [[ "$(echo $@ | grep '#')" = "" ]] ; then
  error "\033[31mError : \033[33mThe character '#' is not allowed!"
fi

case $1 in
  prog)   
          programmBackup "$2" "$3" "$4" "$5" "$6"
          ;;

  exec)   
          if execution > /dev/null 2>&1 ; then
            while read line ; do
              cat $line 1>&2
            done < $logs_with_errors
          fi
          rm -rf $logTempDir
          ;;

  execAll)
          execAllBackups=1
          execution >> /dev/null
          ;;


    path) 
        if [[ "$3" != "" ]] ; then
            error "\033[31mError : \033[33mTo many arguments for path."
            exit_
          fi

          if test -e $2 && test -d $2 ; then
            output "\033[36mMSG   : \033[32mChanging \033[0mstandard backup path to \033[33m$2"
            echo $2 > $backupPath
            output "\033[36mMSG   : \033[32mChanged \033[0mstandard backup path to \033[33m$2"
          else
            error "\033[31mError : \033[33mPath does not exist!"
          fi
          ;;

  deact)  if [[ "$3" != "" ]] ; then
            error "\033[31mError : \033[33mTo many arguments for deact."
            exit_
          fi
          if [[ "$2" = "0" || "$2" = "00" ]] ; then
            error "\033[31mError : \033[33mBackup with ID $2 does not exists!"
            exit_
          fi
          if [[ "$2" =~ ^[0-9][0-9]$ ]] || [[ "$2" =~ ^[0-9]$ ]] ; then

            deletedLine=`jq .backup[$(($2-1))].name $backupFile`

            if [[ "$deletedLine" = "null" ]] ; then
              error "\033[31mError : \033[33mBackup ID $2 does not exists!"
              exit_
            fi

            output "\n\033[36mMSG   : \033[0mDeactivating backup \033[0mID-$2 ..."

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

            output "\033[36mMSG   : \033[33mDeactivated backup ID-$2\033[0m\n"

            list $backupFile
            list $deactBackupFile

          else
            error "\033[31mError : \033[33m'$2' is not an argument for deact."
            exit_
          fi
          ;;

  react)  if [[ "$3" != "" ]] ; then
            error "\033[31mError : \033[33mTo many arguments for react."
            exit_
          fi
          if [[ "$2" = "0" || "$2" = "00" ]] ; then
            error "\033[31mError : \033[33mBackup ID $2 does not exists in deactivation list!"
            exit_
          fi
          if [[ "$2" =~ ^[0-9][0-9]$ ]] || [[ "$2" =~ ^[0-9]$ ]] ; then

            deletedLine=`jq .backup[$(($2-1))].name $deactBackupFile`

            if [[ "$deletedLine" = "null" ]] ; then
              error "\033[31mError : \033[33mBackup ID $2 does not exists in deactivation list."
              exit_
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
              output "\033[36mMSG   : \033[32mReactivated backup ID $2."
            else
              error "\033[31mError : \033[33mBackup ID $2 can't be reactivated!"
            fi
            list $backupFile
            list $deactBackupFile
          else
            error "\033[31mError : \033[33m'$2' is not an argument for react."
          fi
          break
          ;;


  rm)     if [[ "$3" != "" ]] ; then
            error "\033[31mError : \033[33mTo many arguments for rm."
            exit_
          fi

          if [[ "$2" = "trash" ]] ; then
            output -n "\033[35mQ & A?: \033[33mDo you really want to \033[31mdelete \033[33mthe trashbin? \033[0m[\033[32my\033[0m/\033[31mN\033[0m] : " ;
            read option
            case $option in
              yes|y|Yes|Y)  output "\n\033[36mMSG   : \033[33mDeleting trashbin..."
                            rm -f $trashBackupFile
                            output "\033[36mMSG   : \033[33mTrashbin deleted!"
                            ;;
              *)    output "\n\033[36mMSG   : \033[32mTrashbin not deleted!"
                    ;;
            esac
            exit_
          elif [[ "$2" = "deact" ]] ; then
            output -n "\033[35mQ & A?: \033[33mDo you really want to \033[31mdelete \033[33mthe deactivation list? \033[0m[\033[32my\033[0m/\033[31mN\033[0m] : " ;
            read option
            case $option in
              yes|y|Yes|Y)  output "\n\033[36mMSG   : \033[33mDeleting deactivation list..."
                            rm -f $deactBackupFile
                            output "\033[36mMSG   : \033[33mDeactivation list deleted!"
                            ;;
              *)    output "\n\033[36mMSG   : \033[32mDeactivation list not deleted!"
                    ;;
            esac
            exit_
          fi

          if [[ "$2" = "0" || "$2" = "00" ]] ; then
            error "\033[31mError : \033[33mBackup with ID $2 does not exists!"
            exit_
          fi

          if [[ "$2" =~ ^[0-9][0-9]$ ]] || [[ "$2" =~ ^[0-9]$ ]] ; then
            deletedLine=`jq .backup[$(($2-1))].name $backupFile`

            if [[ "$deletedLine" = "null" ]] ; then
              error "\033[31mError : \033[33mBackup ID $2 does not exists!"
              exit_
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

            output "\n\033[36mMSG   : \033[0mCopied backup \033[0mID-$2 to trashbin"

            array=".backup[$(($2-1))]"
            jq " $array.name=null | $array.flag=null | $array.dwmtokeep=null | $array.source=null | $array.destination=null " $backupFile > $handoverFile
            mv $handoverFile $backupFile

            output "\033[36mMSG   : \033[33mDeleted ID-$2\033[0m"

            list $backupFile
            list $trashBackupFile

          else
            error "\033[31mError : \033[33m'$2' is not an argument for rm."
            exit_
          fi
          ;;


  re)     if [[ "$3" != "" ]] ; then
            error "\033[31mError : \033[33mTo many arguments for re."
            exit_
          fi

          if [[ "$2" = "0" || "$2" = "00" ]] ; then
            error "\033[31mError : \033[33mBackup ID $2 does not exists in trashbin!"
            exit_
          fi

          if [[ "$2" =~ ^[0-9][0-9]$ ]] || [[ "$2" =~ ^[0-9]$ ]] ; then
            deletedLine=`jq .backup[$(($2-1))].name $trashBackupFile`

            if [[ "$deletedLine" = "null" ]] ; then
              error "\033[31mError : \033[33mBackup ID $2 does not exists in trashbin"
              exit_
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
              output "\033[36mMSG   : \033[32mRestored backup ID $2 from trashbin."
            else
              error "\033[31mError : \033[33mBackup ID $2 from trashbin can't be restored!"
            fi
            list $backupFile
            list $trashBackupFile
          else
            error "\033[31mError : \033[33m'$2' is not an argument for re."
          fi
          ;;

  ls)     if [[ "$3" != "" ]] ; then
            error "\033[31mError : \033[33mTo many arguments for ls."
            exit_
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
            error "\033[31mError : \033[33m'$2' is not an argument for ls"
          fi
          ;;

  log)    if [[ "$3" != "" ]] ; then
            error "\033[31mError : \033[33mTo many arguments for log."
            exit_
          fi
          if [[ "$2" = "0" || "$2" = "00" ]] ; then
            error "\033[31mError : \033[33mBackup with ID $2 does not exist!"
            exit_
          fi
          if [[ "$2" =~ ^[0-9][0-9]$ ]] || [[ "$2" =~ ^[0-9]$ ]] ; then
            logDest=`jq ".backup[$(($2-1))].destination" $backupFile`
            if [[ "$logDest" = "null" ]] ; then
              error "\033[31mError : \033[33mLog ID $2 does not exist!"
              exit_
            fi
            logDest=`jq -r ".backup[$(($2-1))].destination" $backupFile`
            if [[ "`echo $logDest | cut -b 1`" = "*" ]] ; then
              if cd "`cat $backupPath``echo $logDest | cut -b 2-`" >> /dev/null 2>&1 ; then
                cat * 2>> /dev/null | less
              else
                error "\033[31mError : \033[33mLogs for '$2' do not exist."
              fi
            else
              if cd $logDest >> /dev/null 2>&1 ; then
                cat * 2>> /dev/null | less
              else
                error "\033[31mError : \033[33mLogs for '$2' do not exist."
              fi
            fi
          else
            error "\033[31mError : \033[33m'$2' is not an argument for log."
          fi
          ;;

  -h|--help|help)
          if [[ "$3" != "" ]] ; then
            error "\033[31mError : \033[33mTo many arguments for --help."
            exit_
          fi
          # Browse help
          case $2 in
            "")
              output "`helpPage1` `helpPage2` `helpPage3`"
              ;;
            options|option)
              output "$(helpPage1)"
              ;;
            flags|flag)
              output "$(helpPage2)"
              ;;
            examples|example)
              output "$(helpPage3)"
              ;;
            *)
              error "\033[31mError : \033[33mHelp page "$2" doesn't exist."
              ;;
          esac
          ;;

  --restoreProgram)
          if [[ "$4" != "" ]] ; then
            error "\033[31mError : \033[33mTo many arguments for --restoreProgram"
            exit_
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
            output -n "\033[35mQ & A?: \033[33mDo you really want to \033[31mdelete \033[33mthe program files and restore from the file? \033[0m[\033[32my\033[0m/\033[31mN\033[0m] : " ;
            read option
            case $option in
              yes|y|Yes|Y)
                            if test -f $2 ; then
                              output "\n\033[36mMSG   : \033[33mDeleting program files..."
                              rm -rf $programmDir
                              output "\033[36mMSG   : \033[33mProgram files deleted!\n"
                              output "\033[36mMSG   : \033[33mRestore data from file..."
                              mkdir $programmDir
                              touchData
                              cp $2 $backupFile
                              output "\033[36mMSG   : \033[33mRestored!"
                            else
                              error "\033[31mError : \033[33mProgram can't be restored, $2 is not a file."
                            fi
                            ;;
              *)    output "\n\033[36mMSG   : \033[32mProgram files not deleted!\n"
                    ;;
            esac
          else
            error "\033[31mError : \033[33m'$3' is not an argument for --restoreProgram."
          fi
          ;;

  --deleteAllProgramFiles)
          if [[ "$3" != "" ]] ; then
            error "\033[31mError : \033[33mTo many arguments for --deleteAllProgramFiles."
            exit_
          fi
          if [[ "$2" = "--yes" ]] ; then
            rm -rf $programmDir
            exit_ 
          fi
          ouput -n "\033[35mQ & A?: \033[33mDo you really want to \033[31mdelete \033[33mthe programfiles? \033[0m[\033[32my\033[0m/\033[31mN\033[0m] : " ;
          read option
          case $option in
            yes|y|Yes|Y)  output "\n\033[36mMSG   : \033[33mDeleting programfiles..."
                          rm -rf $programmDir
                          output "\033[36mMSG   : \033[33mProgram files deleted!"
                          ;;
            *)    output "\n\033[36mMSG   : \033[32mProgram files not deleted!"
                  ;;
          esac
          ;;

  version|--version)
          output "$version"
          ;;

  *)      
          error "\033[31mError : \033[33mSyntax Error!!"
          output "\033[36mMSG   : \033[0mUse \"backup help\" to get usage infos."
          ;;
esac

if [[ "$1" != "exec" ]] ; then
  clearColor
fi
exit_
