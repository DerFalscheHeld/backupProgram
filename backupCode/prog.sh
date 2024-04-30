#!/usr/bin/bash

#vom re zum checken ob programiert wurde
reProgram=0

function programmBackup {
  nameExistError=0
  nameEmptyError=0
  flagTimeNumberError=0
  flagSyntaxError=0
  flagTimeLessError=0
  flagTimeManyError=0
  flagToLessTaskError=0
  flagToManyTaskError=0
  flagZipError=0
  numberIsNotANumberError=0
  sourceIsNotAFileOrDirError=0
  sourceEmptyError=0
  sourceBashError=0
  sourceImageError=0
  destinationExistError=0
  destinationSyntaxError=0
  destinationEmptyError=0

  #Namen nicht doppelt erlauben
  
  for i in $(seq 0 $(($(readFromArray $backupJsonArray "" name | wc -l) -1))) ; do
    if [[ $(readFromArray $backupJsonArray $i name) = $1 ]] ; then
      nameExistError=1
      break
    fi
  done
  if [[ "$1" = "" ]] ; then
    nameEmptyError=1
  fi

  #Flag checken
  Flag=`echo $2 | cut -b 1`
  count=1
  if [[ "$Flag" = "/" ]] ; then
    while : ; do
      count=$(($count+1))
      Flag=`echo $2 | cut -d"/" -f$count`
      if [[ "$Flag" = "" ]] ; then
        break
      fi
      readFlag $Flag
      if [[ $flagTimeNumberError -eq 1 ]] ; then
        break
      fi
    done
  else
    flagSyntaxError=1
  fi

  if [[ $flagCheckDay -eq 1 && $flagCheckWeek -eq 1 ]] ; then
    flagTimeManyError=1
  elif [[ $flagCheckDay -eq 1 && $flagCheckMonth -eq 1 ]] ; then
    flagTimeManyError=1
  elif [[ $flagCheckWeek -eq 1 && $flagCheckMonth -eq 1 ]] ; then
    flagTimeManyError=1
  elif [[ $flagCheckDay -eq 0 && $flagCheckWeek -eq 0 && $flagCheckMonth -eq 0 ]] ; then
    flagTimeLessError=1
  fi

  #nicht tar bash copy und img zusammen erlauben
  if [[ $flagToManyTaskError -gt 1 ]] ; then
    flagToManyTaskError=1
  elif [[ $flagToManyTaskError -eq 0 ]] ; then
    flagToLessTaskError=1
  else
    if [[ "$flagZip" = "zip" ]] && ! [[ $flagZipCheck -eq 1 ]] ; then
      flagZipError=1
    fi
    flagToManyTaskError=0
  fi

  #day and month o keep muss eine Nummer sein
  if ! [[ $3 =~ ^[0-9]$ || $3 =~ ^[0-9][0-9]$ ]] ; then
    numberIsNotANumberError=1
  fi

  # source check
  if [[ "bash" = "$flagBash" ]] ; then
    if ! [ -s $4 ] ; then
      sourceBashError=1
    fi
  elif [[ "img" = "$flagImg" ]] ; then
    if ! [ -b $4 ] ; then
      sourceImageError=1
    fi
  elif ! [ -e $4 ] ; then
    sourceIsNotAFileOrDirError=1
  fi
  if [[ "$4" = "" ]] ; then
    sourceEmptyError=1
  fi


  # destination path nicht doppelt erlauben
  for i in  $(seq 0 $(($(readFromArray $backupJsonArray "" destination | wc -l)-1))) ; do
    progDestination=$(readFromArray $backupJsonArray $i destination)
    if [[ "$5" = "" ]] ; then
      if ! [[ "$progDestination" != "*/$1" ]] ; then
        destinationExistError=1
        break
      fi
      if [[ $nameEmptyError -eq 1 ]] ; then
        destinationEmptyError=1
      fi
    else
      if [[ "`echo $5 | cut -b 1`" = "/" ]] ; then
        if ! [[ "$progDestination" != "$5" ]] ; then
          destinationExistError=1
          break
        fi
      else
        if ! [[ "$progDestination" != "$5" ]] && [[ "$progDestination" != "*/$5" ]] ; then
          destinationExistError=1
          break
        fi
      fi
    fi
  done
  
  count=1
  while : ; do
    if [[ "`echo $5 | cut -b $count`" = "/" && "`echo $5 | cut -b $(($count+1))`" = "/" ]] ; then
      destinationSyntaxError=1
      break
    fi
    if [[ "`echo $5 | cut -b $(($count))`" = "*" ]] ; then
      if ! [[ $count -eq 1 && "`echo $5 | cut -b 2`" = "/" ]] ; then
        destinationSyntaxError=1
        break
      fi
    fi
    if [[ "`echo $5 | cut -b $count`" = "" ]] ; then
      break
    fi
    count=$(($count+1))
  done

  #Error output

  #name errors
  if [[ $nameExistError -eq 1 ]] ; then
    error "${red}Error : ${yellow}Name exist!"
  elif [[ $nameEmptyError -eq 1 ]] ; then
    error "${red}Error : ${yellow}Name input is empty!"
  else
    output "${cyan}MSG   : ${reset}Name        ${green}o.k."
  fi

  #flag errors
  if [[ $flagTimeNumberError -eq 1 && $flagSyntaxError -eq 1 ]] ; then
    error "${red}Error : ${yellow}Flag : Syntax Error!"
  elif [[ $flagTimeNumberError -eq 1 && $flagSyntaxError -eq 0 ]] ; then
    error "${red}Error : ${yellow}Flag '$Flag' does not exist!"
  elif [[ $flagZipError -eq 1 ]] ; then 
    error "${red}Error : ${yellow}Flag zip can only be used with img or tar!"
  elif [[ $flagTimeLessError -eq 1 ]] ; then
    error "${red}Error : ${yellow}Flag \"Backup has no time specification for execution!\""
  elif [[ $flagTimeManyError -eq 1 ]] ; then
    error "${red}Error : ${yellow}Flag \"Backup has to many time specifications for execution!\""
  elif [[ $flagToManyTaskError -eq 1 ]] ; then
    error "${red}Error : ${yellow}Flags \"bash, img, tar\" are exclusive."
  elif [[ $flagToLessTaskError -eq 1 ]] ; then
    error "${red}Error : ${yellow}Backup has no task to do!."
  else 
    output "${cyan}MSG   : ${reset}Flags       ${green}o.k."
  fi

  # number errors
  if [[ $numberIsNotANumberError -eq 1 ]] ; then
    error "${red}Error : ${yellow}[d/w/m too keep] needs to be a number between 0-99!"
  else
    output "${cyan}MSG   : ${reset}Number      ${green}o.k."
  fi

  # source errors
  if [[ $sourceIsNotAFileOrDirError -eq 1 ]] ; then
    error "${red}Error : ${yellow}Source path does not exist!"
  elif [[ $sourceBashError -eq 1 ]] ; then
    error "${red}Error : ${yellow}Bash script does not exist!"
  elif [[ $sourceImageError -eq 1 ]] ; then
    error "${red}Error : ${yellow}'$4' is not a block device!"
  elif [[ $sourceEmptyError -eq 1 ]] ; then
    error "${red}Error : ${yellow}Source input is empty!"
  else
    output "${cyan}MSG   : ${reset}Source      ${green}o.k."
  fi

  # destination errors
  if [[ $destinationExistError -eq 1 && $destinationSyntaxError -eq 1 ]] ; then
    error "${red}Error : ${yellow}Invalid destination path!"
  elif [[ $destinationExistError -eq 1 && $destinationSyntaxError -eq 0 ]] ; then
    error "${red}Error : ${yellow}Destination path exist!"
  elif [[ $destinationExistError -eq 0 && $destinationSyntaxError -eq 1 ]] ; then
    error "${red}Error : ${yellow}Invalid destination path!"
  else
    if [[ $destinationEmptyError -eq 1 ]] ; then
      error "${red}Error : ${yellow}Destination input is empty!"
    else
      output "${cyan}MSG   : ${reset}Destination ${green}o.k."
    fi
  fi

  if [[ "$4" != "" ]] || [[ "$5" != "" ]] ; then
    if [[ $nameExistError -eq 0 && $nameEmptyError -eq 0 && $flagTimeNumberError -eq 0 && $flagSyntaxError -eq 0 && $flagTimeLessError -eq 0 && $flagTimeManyError -eq 0 && $flagToManyTaskError -eq 0 && $flagToLessTaskError -eq 0 && $flagZipError -eq 0 && $numberIsNotANumberError -eq 0 && $sourceIsNotAFileOrDirError -eq 0 && $sourceEmptyError -eq 0 && $sourceBashError -eq 0 && $sourceImageError -eq 0 && $destinationExistError -eq 0 && $destinationSyntaxError -eq 0 && $destinationEmptyError -eq 0 ]] ; then
      reProgram=1
      count=1
      output "${cyan}MSG   : ${yellow}saving..."
      if [[ "$5" = "" ]] ; then
        writeToArray $backupJsonArray "$1" "$2" "$3" "$4" "*/$1"
      else
        if [[ "`echo $5 | cut -b 1`" = "/" ]] ; then
          writeToArray $backupJsonArray "$1" "$2" "$3" "$4" "$5"
        elif [[ "`echo $5 | cut -b 1-2`" = "*/" ]] ; then
          writeToArray $backupJsonArray "$1" "$2" "$3" "$4" "$5"
        else
          writeToArray $backupJsonArray "$1" "$2" "$3" "$4" "*/$5"
        fi
      fi
      output "${cyan}MSG   : ${green}saved"
    fi
  else
    error "${red}Error : ${yellow}To few arguments"
  fi
  return $progExit
}
