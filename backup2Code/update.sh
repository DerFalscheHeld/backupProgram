#!/usr/bin/bash
function update_1 {
  if [[ $(jq -r .config[0].configFileVersion /usr/local/etc/backup/config/backup.json) = "" ]] ; then
    output "${cyan}MSG   : ${green}Update the old config..."
    
    update_1_file="/usr/local/etc/backup/backup.json"
    for i in $(seq 0 $(($(jq ".backup[].name" $update_1_file | wc -l)-1))) ; do
      if [[ $(jq .backup[$i].name $update_1_file) != null ]] ; then
        update_1_name=$(jq -r .backup[$i].name $update_1_file)
        update_1_flag=$(jq -r .backup[$i].flag $update_1_file)
        update_1_dwm=$(jq -r .backup[$i].dwmtokeep $update_1_file)
        update_1_source=$(jq -r .backup[$i].source $update_1_file)
        update_1_destination=$(jq -r .backup[$i].destination $update_1_file)

         output "MSG   : backup prog $update_1_name $update_1_flag $update_1_dwm $update_1_source $update_1_destination"
        if ! programmBackup "$update_1_name" "$update_1_flag" "$update_1_dwm" "$update_1_source" "$update_1_destination" ; then
          error "Error : backup prog $update_1_name $update_1_flag $update_1_dwm $update_1_source $update_1_destination"
          error "Error : This needs to be revised, it is no longer compatible!"
        fi
        resetFlags
        progExit=0
      fi
    done
    output "${cyan}MSG   : ${green}Backups of the old config are in the new config"
    
    #update_1_deactfile="/usr/local/etc/backup/backupDeact.json"
    #for i in $(seq 0 $(($(jq ".backup[].name" $update_1_file | wc -l)-1))) ; do
    #  if [[ $(jq .backup[$i].name $update_1_file) != null ]] ; then
    #    update_1_name=$(jq .backup[$i].name $update_1_file)
    #    update_1_flag=$(jq .backup[$i].flag $update_1_file)
    #    update_1_dwm=$(jq .backup[$i].dwmtokeep $update_1_file)
    #    update_1_source=$(jq .backup[$i].source $update_1_file)
     #   update_1_destination=$(jq .backup[$i].destination $update_1_file)
     #   programmBackup "$update_1_name" "$update_1_flag" "$update_1_dwm" "$update_1_source" "$update_1_destination"
     # fi
    #done
    #output "${cyan}MSG   : ${green}Backups of th deactivation list are in the new config"







  fi
}