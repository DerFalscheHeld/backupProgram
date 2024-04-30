#!/usr/bin/bash
function update_version {
  writeConfig version $version
  writeConfig configFileVersion $configFileVersion
}

function update_1 {
  if [[ $(jq -r .config[0].configFileVersion /usr/local/etc/backup/config/main.json) = "" ]] ; then
    output "${cyan}MSG   : ${green}Updating the old config..."
    
    update_1_file="/usr/local/etc/backup/backup.json"
    for i in $(seq 0 $(($(jq ".backup[].name" $update_1_file | wc -l)-1))) ; do
      if [[ $(jq .backup[$i].name $update_1_file) != null ]] ; then
        update_1_name=$(jq -r .backup[$i].name $update_1_file)
        update_1_flag=$(jq -r .backup[$i].flag $update_1_file)
        update_1_dwm=$(jq -r .backup[$i].dwmtokeep $update_1_file)
        update_1_source=$(jq -r .backup[$i].source $update_1_file)
        update_1_destination=$(jq -r .backup[$i].destination $update_1_file)

        output "${cyan}MSG   : ${reset}backup prog $update_1_name $update_1_flag $update_1_dwm $update_1_source $update_1_destination"

        if ! programmBackup "$update_1_name" "$update_1_flag" "$update_1_dwm" "$update_1_source" "$update_1_destination" ; then
          error "\033[31mError : backup prog $update_1_name $update_1_flag $update_1_dwm $update_1_source $update_1_destination\033[0m"
          error "\033[31mError : This needs to be revised, it is no longer compatible!\033[0m"
          error "\033[31mError : It is in the deactivation list for now!\033[0m"
          writeToArray $deactJsonArray "$update_1_name" "$update_1_flag" "$update_1_dwm" "$update_1_source" "$update_1_destination"
        fi
        resetFlags
        progExit=0
      fi
    done
    output "${cyan}MSG   : ${green}Backups of the old config are in the new config${reset}"
    
    update_1_deactfile="/usr/local/etc/backup/backupDeact.json"
    for i in $(seq 0 $(($(jq ".backup[].name" $update_1_deactfile | wc -l)-1))) ; do
      if [[ $(jq .backup[$i].name $update_1_deactfile) != null ]] ; then
        update_1_deactName=$(jq -r .backup[$i].name $update_1_deactfile)
        update_1_deactFlag=$(jq -r .backup[$i].flag $update_1_deactfile)
        update_1_deactdwm=$(jq -r .backup[$i].dwmtokeep $update_1_deactfile)
        update_1_deactSource=$(jq -r .backup[$i].source $update_1_deactfile)
        update_1_deactDestination=$(jq -r .backup[$i].destination $update_1_deactfile)
        writeToArray $deactJsonArray "$update_1_deactName" "$update_1_deactFlag" "$update_1_deactdwm" "$update_1_deactSource" "$update_1_deactDestination"
      fi
    done
    output "${cyan}MSG   : ${green}Backups of the deactivation list are in the new config${reset}"

    update_1_trashbinfile="/usr/local/etc/backup/backupTrash.json"
    for i in $(seq 0 $(($(jq ".backup[].name" $update_1_trashbinfile | wc -l)-1))) ; do
      if [[ $(jq .backup[$i].name $update_1_trashbinfile) != null ]] ; then
        update_1_trashbinName=$(jq -r .backup[$i].name $update_1_trashbinfile)
        update_1_trashbinFlag=$(jq -r .backup[$i].flag $update_1_trashbinfile)
        update_1_trashbindwm=$(jq -r .backup[$i].dwmtokeep $update_1_trashbinfile)
        update_1_trashbinSource=$(jq -r .backup[$i].source $update_1_trashbinfile)
        update_1_trashbinDestination=$(jq -r .backup[$i].destination $update_1_trashbinfile)
        writeToArray $trashJsonArray "$update_1_trashbinName" "$update_1_trashbinFlag" "$update_1_trashbindwm" "$update_1_trashbinSource" "$update_1_trashbinDestination"
      fi
    done
    output "${cyan}MSG   : ${green}Backups of the trashbin are in the new config${reset}"

    update_1_pathfile="/usr/local/etc/backup/backup.path"
    update_1_path=$(cat $update_1_pathfile)
    if [[ -d $update_1_path ]] ; then
      update_1_pathLength=$(echo $update_1_path | wc -L)
      if [[ ${update_1_path:$(($update_1_pathLength-1)):$(($update_1_pathLength-1))} = "/" ]] ; then
        update_1_path=$(echo ${update_1_path:0:$(($y-2))})
      fi
    fi
    writeConfig backupPath $update_1_path
    output "${cyan}MSG   : ${green}The backup path is in the new config${reset}"
  
    rm $update_1_file $update_1_deactfile $update_1_trashbinfile $update_1_pathfile
    writeConfig version "backup-2.0.0"
    writeConfig configFileVersion "1.0.0"
    return 0
  else
    return 1
  fi
}