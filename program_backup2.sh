#!/usr/bin/bash
# version discription
# 1.0.2   1 - version of the program
#         0 - bugfix version of the program
#         2 - cosmetic change

version="backup-2.0.0"
configFileVersion="1.0.0"

programmDir="/usr/local/etc/backup"
#codeDir="$programmDir/code"
codeDir="/home/simon/backupProgram/backup2Code"
configDir="$programmDir/config"
backupFile="$configDir/backup.json"

#global count
count=1

for sourcefile in $codeDir/* ; do
  source $sourcefile
done

umask 00177

if [[ $UID != 0 ]] ; then
  error "backup: You are not root!       Permission denied"
  error "backup: Config can't be loaded! Permission denied"
  exit_
else
  touchData
  update_1
  setConfigVar
fi
if [[ $# -ge 7 ]] ; then
  error "${red}Error : ${yellow}To many arguments!"
  exit_
fi
if [[ "$1" = "" ]] ; then
  output "$(helpPageOptions)"
  exit_
fi
if ! [[ "$(echo $@ | grep '#')" = "" ]] ; then
  error "${red}Error : ${yellow}The character '#' is not allowed!"
  exit_
fi

case $1 in
  prog)   
    programmBackup "$2" "$3" "$4" "$5" "$6"
    ;;

  exec|execAll)
    if [[ "$1" = "execAll" ]] ; then
      execAllBackups=1
    fi
    case $outputFromExec in
      errorOnly)
        execution > /dev/null
        ;;
      errorLogs)
        execution > /dev/null 2>&1
        if [[ $exit = 1 ]] ; then
          while read line ; do
            cat $line 1>&2
          done < $logsWithErrors
        fi
        ;;
      journalctlReady|all|*)
        execution
        ;;
    esac
    rm -rf $logTempDir
    ;;

  deact)  
    if [[ $# -ge 3 ]] ; then
      error "${red}Error : ${yellow}To many arguments for deact."
      exit_
    fi
    if [[ "$2" = "0" || "$2" = "00" ]] ; then
      error "${red}Error : ${yellow}Backup with ID $2 does not exists!"
      exit_
    fi
    if [[ "$2" =~ ^[0-9][0-9]$ ]] || [[ "$2" =~ ^[0-9]$ ]] ; then

      deletedLine=$(readFromArray $backupJsonArray $(($2-1)) name)

      if [[ "$deletedLine" = "null" ]] ; then
        error "${red}Error : ${yellow}Backup ID $2 does not exists!"
        exit_
      fi

      output "${cyan}MSG   : ${reset}Deactivating backup ${reset}ID-$2 ..."
      deactName=$(readFromArray $backupJsonArray $(($2-1)) name)
      deactFlag=$(readFromArray $backupJsonArray $(($2-1)) flag)
      deactNumber=$(readFromArray $backupJsonArray $(($2-1)) dwmtokeep)
      deactSource=$(readFromArray $backupJsonArray $(($2-1)) source)
      deactDestination=$(readFromArray $backupJsonArray $(($2-1)) destination)

      writeToArray $deactJsonArray "$deactName" "$deactFlag" "$deactNumber" "$deactSource" "$deactDestination"
      deletefromArray $backupJsonArray $(($2-1))

      output "${cyan}MSG   : ${yellow}Deactivated backup ID-$2${reset}\n"
      list $backupJsonArray
      list $deactJsonArray noHeader
    else
      error "${red}Error : ${yellow}'$2' is not an argument for deact."
      exit_
    fi
    ;;

  react)  
    if [[ $# -ge 3 ]] ; then
      error "${red}Error : ${yellow}To many arguments for react."
      exit_
    fi
    if [[ "$2" = "0" || "$2" = "00" ]] ; then
      error "${red}Error : ${yellow}Backup ID $2 does not exists in deactivation list!"
      exit_
    fi
    if [[ "$2" =~ ^[0-9][0-9]$ ]] || [[ "$2" =~ ^[0-9]$ ]] ; then

      deletedLine=$(readFromArray $deactJsonArray $(($2-1)) name)

      if [[ "$deletedLine" = "null" ]] ; then
        error "${red}Error : ${yellow}Backup ID $2 does not exists in deactivation list."
        exit_
      fi

      reactName=$(readFromArray $deactJsonArray $(($2-1)) name)
      reactFlag=$(readFromArray $deactJsonArray $(($2-1)) flag)
      reactNumber=$(readFromArray $deactJsonArray $(($2-1)) dwmtokeep)
      reactSource=$(readFromArray $deactJsonArray $(($2-1)) source)
      reactDestination=$(readFromArray $deactJsonArray $(($2-1)) destination)
      
      programmBackup "$reactName" "$reactFlag" "$reactNumber" "$reactSource" "$reactDestination"

      if [[ $reProgram = 1 ]] ; then
        deletefromArray $deactJsonArray $(($2-1))
        output "${cyan}MSG   : ${green}Reactivated backup ID $2."
      else
        error "${red}Error : ${yellow}Backup ID $2 can't be reactivated!\n"
      fi
      list $backupJsonArray
      list $deactJsonArray noHeader
    else
      error "${red}Error : ${yellow}'$2' is not an argument for react."
    fi
    ;;


  rm)     
    if [[ $# -ge 3 ]] ; then
      error "${red}Error : ${yellow}To many arguments for rm."
      exit_
    fi

    if [[ "$2" = "trash" ]] ; then
      output -n "${magenta}Q & A?: ${yellow}Do you really want to ${red}delete ${yellow}the trashbin? ${reset}[${green}y${reset}/${red}N${reset}] : " ;
      read option
      case $option in
        yes|y|Yes|Y)  
          output "${cyan}MSG   : ${yellow}Deleting trashbin..."
          deletefromArray $trashJsonArray ""
          output "${cyan}MSG   : ${yellow}Trashbin deleted!"
          ;;
        *)    
          output "${cyan}MSG   : ${green}Trashbin not deleted!"
          ;;
      esac
      exit_
    elif [[ "$2" = "deact" ]] ; then
      output -n "${magenta}Q & A?: ${yellow}Do you really want to ${red}delete ${yellow}the deactivation list? ${reset}[${green}y${reset}/${red}N${reset}] : " ;
      read option
      case $option in
        yes|y|Yes|Y)
          output "\n${cyan}MSG   : ${yellow}Deleting deactivation list..."
          deletefromArray $deactJsonArray ""
          output "${cyan}MSG   : ${yellow}Deactivation list deleted!"
          ;;
        *)
          output "\n${cyan}MSG   : ${green}Deactivation list not deleted!"
          ;;
      esac
      exit_
    fi

    if [[ "$2" = "0" || "$2" = "00" ]] ; then
      error "${red}Error : ${yellow}Backup with ID $2 does not exists!"
      exit_
    fi

    if [[ "$2" =~ ^[0-9][0-9]$ ]] || [[ "$2" =~ ^[0-9]$ ]] ; then
      if [[ "$(readFromArray $backupJsonArray $(($2-1)) name)" = "null" ]] ; then
        error "${red}Error : ${yellow}Backup ID $2 does not exists!"
        exit_
      fi

      rmName=$(readFromArray $backupJsonArray $(($2-1)) name)
      rmFlag=$(readFromArray $backupJsonArray $(($2-1)) flag)
      rmNumber=$(readFromArray $backupJsonArray $(($2-1)) dwmtokeep)
      rmSource=$(readFromArray $backupJsonArray $(($2-1)) source)
      rmDestination=$(readFromArray $backupJsonArray $(($2-1)) destination)

      writeToArray $trashJsonArray "$rmName" "$rmFlag" "$rmNumber" "$rmSource" "$rmDestination"
      output "${cyan}MSG   : ${reset}Copied backup ${reset}ID-$2 to trashbin"
      deletefromArray $backupJsonArray $(($2-1))

      output "${cyan}MSG   : ${yellow}Deleted ID-$2${reset}"
      list $backupJsonArray
      list $trashJsonArray noHeader
    else
      error "${red}Error : ${yellow}'$2' is not an argument for rm."
      exit_
    fi
    ;;


  re)     
    if [[ $# -ge 3 ]] ; then
      error "${red}Error : ${yellow}To many arguments for re."
      exit_
    fi

    if [[ "$2" = "0" || "$2" = "00" ]] ; then
      error "${red}Error : ${yellow}Backup ID $2 does not exists in trashbin!"
      exit_
    fi

    if [[ "$2" =~ ^[0-9][0-9]$ ]] || [[ "$2" =~ ^[0-9]$ ]] ; then
      if [[ "$(readFromArray $trashJsonArray $(($2-1)) name)" = "null" ]] ; then
        error "${red}Error : ${yellow}Backup ID $2 does not exists in trashbin"
        exit_
      fi

      reName=$(readFromArray $trashJsonArray $(($2-1)) name)
      reFlag=$(readFromArray $trashJsonArray $(($2-1)) flag)
      reNumber=$(readFromArray $trashJsonArray $(($2-1)) dwmtokeep)
      reSource=$(readFromArray $trashJsonArray $(($2-1)) source)
      reDestination=$(readFromArray $trashJsonArray $(($2-1)) destination)

      programmBackup "$reName" "$reFlag" "$reNumber" "$reSource" "$reDestination"

      if [[ $reProgram = 1 ]] ; then
        deletefromArray $trashJsonArray $(($2-1))
        output "${cyan}MSG   : ${green}Restored backup ID $2 from trashbin."
      else
        error "${red}Error : ${yellow}Backup ID $2 from trashbin can't be restored!"
      fi
      list $backupJsonArray
      list $trashJsonArray noHeader
    else
      error "${red}Error : ${yellow}'$2' is not an argument for re."
    fi
    ;;

  ls)     
    if [[ $# -ge 3 ]] ; then
      error "${red}Error : ${yellow}To many arguments for ls."
      exit_
    fi
    if [[ "$2" = "" ]] ; then
      list $backupJsonArray
    elif [[ "$2"  = "all" ]] ; then
      list $backupJsonArray
      list $deactJsonArray noHeader
      list $trashJsonArray noHeader
    elif [[ "$2" = "trash" ]] ; then
      list $trashJsonArray
    elif [[ "$2" = "deact" ]] ; then
      list $deactJsonArray
    else
      error "${red}Error : ${yellow}'$2' is not an argument for ls"
    fi
    ;;

  log)
    if [[ $# -ge 3 ]] ; then
      error "${red}Error : ${yellow}To many arguments for log."
      exit_
    fi
    if [[ "$2" = "0" || "$2" = "00" ]] ; then
      error "${red}Error : ${yellow}Backup with ID $2 does not exist!"
      exit_
    fi
    if [[ "$2" =~ ^[0-9][0-9]$ ]] || [[ "$2" =~ ^[0-9]$ ]] ; then
      logColorRed=$(echo ${red} | sed -e 's/\\/\\\\/g' | sed -e 's/\[/\\\[/g')
      logColorGreen=$(echo ${green} | sed -e 's/\\/\\\\/g' | sed -e 's/\[/\\\[/g')
      logColorReset=$(echo ${reset} | sed -e 's/\\/\\\\/g' | sed -e 's/\[/\\\[/g')
      logDest=`readFromArray $backupJsonArray $(($2-1)) destination`
      if [[ "$logDest" = "null" ]] ; then
        error "${red}Error : ${yellow}Log ID $2 does not exist!"
        exit_
      fi
      if [[ "`echo $logDest | cut -b 1`" = "*" ]] ; then
        if cd "$backupPath`echo $logDest | cut -b 2-`" >> /dev/null 2>&1 ; then
          cat * 2>> /dev/null | echo -e "$(sed -e "s/\(\[\INFO ]\)/${logColorGreen}\1${logColorReset}/g" | sed -e "s/\(\[\ERROR]\)/${logColorRed}\1${logColorReset}/g")" | less -R +G
        else
          error "${red}Error : ${yellow}Logs for '$2' do not exist."
        fi
      else
        if cd $logDest >> /dev/null 2>&1 ; then
          cat * 2>> /dev/null | echo -e "$(sed -e "s/\(\[\INFO ]\)/${logColorGreen}\1${logColorReset}/g" | sed -e "s/\(\[\ERROR]\)/${logColorRed}\1${logColorReset}/g")" | less -R +G
        else
          error "${red}Error : ${yellow}Logs for '$2' do not exist."
        fi
      fi
    else
      error "${red}Error : ${yellow}'$2' is not an argument for log."
    fi
    ;;

  -h|--help|help)
    if [[ $# -ge 3 ]] ; then
      error "${red}Error : ${yellow}To many arguments for --help."
      exit_
    fi
    # Browse help
    case $2 in
      ""|options|option)
        output "$(helpPageOptions)"
        ;;
      flags|flag)
        output "$(helpPageFlags)"
        ;;
      examples|example)
        output "$(helpPageExamlpes)"
        ;;
      all)
        output "$(helpPageOptions)\n\n$(helpPageFlags)\n\n$(helpPageExamlpes)"
        ;;
      *)
        error "${red}Error : ${yellow}Help page "$2" doesn't exist."
        ;;
    esac
    ;;

  config)
    if [[ $# -ge 3 ]] ; then
      error "${red}Error : ${yellow}To many arguments for config."
      exit_
    fi
    if [[ "$2" = "" ]] || [[ "$2" = "ls" ]] ; then
      output "$(readConfig | sed -e '/{/d' -e '/}/d' -e 's/^ *//g' -e 's/,$//g' -e 's/:/:=:/g' | column -t -s ':')"
    elif echo "$2" | grep '=' > /dev/null 2>&1 ; then
      key=$(echo $2 | cut -d"=" -f1)
      value=$(echo $2 | cut -d"=" -f2)
      falseKey=0
      trueValue=0
      case $key in 
        output)
          case $value in
            all)             trueValue=1 ;;
            errorOnly)       trueValue=1 ;;
            errorLogs)       trueValue=1 ;;
            journalctlReady) trueValue=1 ;;
            *)               trueValue=0 ;;
          esac
          ;;        
        zipProgram)
          case $value in          
            gzip)  trueValue=1 ;;
            pigz)  trueValue=1 ;;
            bzip2) trueValue=1 ;;
            zip)   trueValue=1 ;;
            xz)    trueValue=1 ;;
            *)     trueValue=0 ;;
          esac
          ;;
        font)
          case $value in
            color)        trueValue=1 ;;
            cursiveColor) trueValue=1 ;;
            cursive)      trueValue=1 ;;
            unicorn)      trueValue=1 ;;
            normal)       trueValue=1 ;;
            *)            trueValue=0 ;;
          esac
          ;;
        backupPath)
          if [[ -d $value ]] ; then
            trueValue=1
          else
            trueValue=0
          fi
          ;;
        *)
          falseKey=1
          ;;
      esac
        
      if [[ $trueValue -eq 1 && $falseKey = 0 ]] ; then
        writeConfig $key $value
      else
        error "${red}Error : ${yellow}Config '$2' does not exist!${reset}"
      fi          
    else
      if [[ "$(readConfig $2)" != "null" ]] ; then
        output "$2 = $(readConfig $2)"
      else
        error "${red}Error : ${yellow}Config '$2' does not exist!${reset}"
      fi
    fi
    ;;

  --restoreConfig)
    if [[ $# -ge 4 ]] ; then
      error "${red}Error : ${yellow}To many arguments for --restoreProgram"
      exit_
    fi
    if [[ "$3" = "--yes" ]] ; then
      if test -e $2 ; then
        rm -rf $backupFile
        touchData
        cp $2 $backupFile
      fi
      break
    elif [[ "$3" = "" ]] ; then
      output -n "${magenta}Q & A?: ${yellow}Do you really want to ${red}delete ${yellow}the program files and restore from the file? ${reset}[${green}y${reset}/${red}N${reset}] : " ;
      read option
      case $option in
        yes|y|Yes|Y)
          if test -f $2 ; then
            output "\n${cyan}MSG   : ${yellow}Deleting program files..."
            rm -rf $backupFile
            output "${cyan}MSG   : ${yellow}Program files deleted!\n"
            output "${cyan}MSG   : ${yellow}Restore data from file..."
            touchData
            cp $2 $backupFile
            output "${cyan}MSG   : ${yellow}Restored!"
          else
            error "${red}Error : ${yellow}Program can't be restored, $2 is not a file."
          fi
          ;;
        *)    
          output "\n${cyan}MSG   : ${green}Program files not deleted!\n"
          ;;
      esac
    else
      error "${red}Error : ${yellow}'$3' is not an argument for --restoreProgram."
    fi
    ;;

  --deleteConfigFiles)
    if [[ $# -ge 3 ]] ; then
      error "${red}Error : ${yellow}To many arguments for --deleteAllProgramFiles."
      exit_
    fi
    if [[ "$2" = "--yes" ]] ; then
      rm -rf $programmDir
      exit_ 
    fi
    ouput -n "${magenta}Q & A?: ${yellow}Do you really want to ${red}delete ${yellow}the programfiles? ${reset}[${green}y${reset}/${red}N${reset}] : " ;
    read option
    case $option in
      yes|y|Yes|Y)  output "\n${cyan}MSG   : ${yellow}Deleting programfiles..."
                    rm -rf $programmDir
                    output "${cyan}MSG   : ${yellow}Program files deleted!"
                    ;;
      *)    output "\n${cyan}MSG   : ${green}Program files not deleted!"
            ;;
    esac
    ;;

  version|--version)
    output "$(readConfig version)"
    ;;

  *)      
    error "${red}Error : ${yellow}Syntax Error!!${reset}"
    output "$(helpPageOptions)"
    ;;
esac

if [[ "$1" = "exec" ]] || [[ "$1" = "execAll" ]] ; then
  exit $exit
fi
exit_
