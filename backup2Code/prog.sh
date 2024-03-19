#!/usr/bin/bash


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
    error "\033[31mError : \033[33mName to long only 1-24 chars!"
  elif [[ $name -eq 0 && $namelength -eq 0 ]] ; then
    error "\033[31mError : \033[33mName exist!"
  else
    output "\033[36mMSG   : \033[0mName        \033[32mo.k."
  fi

  if [[ $flag -eq 0 && $flagsyntax -eq 1 ]] ; then
    error "\033[31mError : \033[33mFlag : Syntax Error!"
  elif [[ $flagTimeLess -eq 0 && $flagTimeMany -eq 0 && $flagError -eq 0 ]] ; then
    if [[ $flag -eq 0 && $flagsyntax -eq 0 ]] ; then
      error "\033[31mError : \033[33mFlag '$Flag' does not exist!"
    else
      output "\033[36mMSG   : \033[0mFlags       \033[32mo.k."
    fi
  elif [[ $flagTimeLess -eq 1 ]] ; then
    error "\033[31mError : \033[33mFlag \"Backup has no time specification for execution!\""
  elif [[ $flagTimeMany -eq 1 ]] ; then
    error "\033[31mError : \033[33mFlag \"Backup has to many time specifications for execution!\""
  elif [[ $flagError -eq 1 ]] ; then
    error "\033[31mError : \033[33mFlags \"bash, img, tar, copy\" are exclusive."
  fi

  if [[ $number -eq 0 ]] ; then
    error "\033[31mError : \033[33m[d/w/m too keep] needs to be a Number between 0-99!"
  else
    output "\033[36mMSG   : \033[0mNumber      \033[32mo.k."
  fi
  if [[ $sour -eq 0 ]] ; then
    error "\033[31mError : \033[33mSource path does not exist!"
  else
    output "\033[36mMSG   : \033[0mSource      \033[32mo.k."
  fi

  if [[ $dest -eq 0 && $destsyntax -eq 1 ]] ; then
    error "\033[31mError : \033[33mInvalid destination path!"
  elif [[ $dest -eq 0 && $destsyntax -eq 0 ]] ; then
    error "\033[31mError : \033[33mDestination path exist!"
  elif [[ $dest -eq 1 && $destsyntax -eq 1 ]] ; then
    error "\033[31mError : \033[33mInvalid destination path!"
  else
    output "\033[36mMSG   : \033[0mDestination \033[32mo.k."
  fi

  if [[ "$4" != "" ]] || [[ "$5" != "" ]] ; then
    if [[ $name -eq 1 && $namelength -eq 0 && $flag -eq 1 && $flagsyntax -eq 0 && $flagTimeLess -eq 0 && $flagTimeMany -eq 0 && $flagError -eq 0 && $number -eq 1 && $sour -eq 1 && $dest -eq 1 && $destsyntax -eq 0 ]] ; then
      reProgram=1
      count=0
      handoverFile=/dev/shm/.backupHandover1.temp
	  echo #newline after msg and error
      output "\033[36mMSG   : \033[33msaving..."
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
      output "\033[36mMSG   : \033[32msaved"
    fi
  else
    error "\033[31mError : \033[33mTo few arguments"
  fi
}
