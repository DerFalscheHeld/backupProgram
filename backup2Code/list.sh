#!/usr/bin/bash

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

  echo -e "\033[32mID#|#\033[33m[name]#\033[36m[flag]#\033[35m[d/w/m_to_keep]#\033[34m[source/command]#\033[0m[destination/exec-path]\n"

  for i in  $(seq 0 $(($(jq -r .backup[].name $1 | wc -l)-1))) ; do
    listName=$(jq .backup[$i].name $1)
    if ! [[ "$listName" = "null" ]] ; then
      info0=$(jq -r ".backup[$i].ID" $1)
      info1=$(jq -r ".backup[$i].name" $1)
      info2=$(jq -r ".backup[$i].flag" $1)
      info3=$(jq -r ".backup[$i].dwmtokeep" $1)
      info4=$(jq -r ".backup[$i].source" $1)
      info5=$(jq -r ".backup[$i].destination" $1)

      echo -e "\033[32m${info0}#|#\033[33m${info1}#\033[36m${info2}#\033[35m${info3}#\033[34m${info4}#\033[0m${info5}"

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
