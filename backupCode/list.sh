#!/usr/bin/bash

function renderListTemp {

  echo -e "${green}ID#|#${yellow}[name]#${cyan}[flag]#${magenta}[d/w/m to keep]#${blue}[source/command]#${reset}[destination/exec-path]\n"
  if readFromArray $1 "" name > /dev/null 2>&1 ; then
    for i in $(seq 0 $(($(readFromArray $1 "" name | wc -l)-1))) ; do
      listName=$(readFromArray $1 $i name)
      if ! [[ "$listName" = "null" ]] ; then
        info0=$(($i+1))
        info1="$listName"
        info2=$(readFromArray $1 $i flag)
        info3=$(readFromArray $1 $i dwmtokeep)
        info4=$(readFromArray $1 $i source)
        info5=$(readFromArray $1 $i destination)
        echo -e "${green}${info0}#|#${yellow}${info1}#${cyan}${info2}#${magenta}${info3}#${blue}${info4}#${reset}${info5}"

      fi &
    done
    wait
  fi
}

# $1 [Arrayname] $2 [noHeader ("" means heder would be printet,
#                              "noHeader" prins the list without header)]
# this function returns a list from that Array
function list {
  renderList="$(renderListTemp $1 | column -t -s "#")"
  if ! [[ "$2" = "noHeader" ]] ; then
    echo -e "${reset}standard backup path : ${cyan}${backupPath}${reset}\n * in destination/exec-path means standard backup path\n"
  fi
  if [[ "$1" = "$trashJsonArray" ]] ; then
    echo -e "${lightYellow}${reverse}#-#-#-#-#- TRASHBIN -#-#-#-#-#${reset}"
  elif [[ "$1" = "$deactJsonArray" ]] ; then
    echo -e "${lightRed}${reverse}#-#-#-#-#- DEACTIVATED -#-#-#-#-#${reset}"
  else
    echo -e -n ""
  fi
  echo "$renderList" | sed "2,130d"
  allColumnsWidth="$(($(echo "$renderList" | sed "2,130d" | wc -m)-30))"
  echo -e -n "$red"
  for (( i = 0 ; i <= $allColumnsWidth ; i++ )) ; do
    echo -e -n "-"
  done
  echo -e "$reset"
  echo "$renderList" | sed "1d"
  echo
}
