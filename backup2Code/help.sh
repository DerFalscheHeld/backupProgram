#!/usr/bin/bash

helpTime=`date +"%Y-%m-%d--%H-%M"`
helpDate=`date +"%Y-%m-%d"`

function helpPageOptions {
echo "backup [option] [arguments...]
${green}OPTIONS${reset}
  ls    []              >> Lists programmed backups
        [trash]         >> Lists trashbin
        [deact]         >> Lists deactivated backups
        [all]           >> Lists all
  rm    [1-99]          >> Delete a programmed backup with ID [1-99]
        [trash]         >> Delete the trashbin
        [deact]         >> Delete the deactivation list
  re    [1-99]          >> Restore backup from trashbin with ID [1-99]
  log   [1-99]          >> Shows all logs from the ID [1-99] in less
  deact [1-99]          >> Deactivate backup with ID [1-99]
  react [1-99]          >> Reactivate backup with ID [1-99]
  exec                  >> For daily execute use cron syntax
                           ${cyan}0 0 * * * /usr/local/bin/backup exec ${reset}
  execAll               >> Execute all backups now
  prog                  >> Programming a new backup - See example and flag page
  ****cofig****
  version / --version   >> Shows the program version.
  help / -h / --help [] >> Shows options help pages
               [option] >> Shows options help page
                 [flag] >> Shows flags help page
              [example] >> Shows usage and examples help page 
                  [all] >> Shows all help pages at the same time
  --restoreConfig [file] []      >> Restore config from backup file
                         [--yes] >> ... and skip confirmation by auto-affirming restoration
  --deleteConfigFile     []      >> Delete all config Files
                         [--yes] >> ... and skip confirmation by auto-affirming deletion
"
}

function helpPageFlags {
echo "${green}FLAGS${reset}
  Arguments are seperated by \"/\"
  e.g.:   /flag1/flag2/flag3/....

  day     >>  daily backup
  m[1-31] >>  monthly backup
  w[0-6]  >>  weekly backup
              0  1  2  3  4  5  6
              Su Mo Tu We Th Fr Sa
  bash    >>  a bash script
              will be executed in exec-path
  img     >>  Save a block device as .img file
  tar     >>  Save data as .tar archive
  zip     >>  Save data as an archive
  log     >>  Create log-file in destination folder
"
}

function helpPageExamlpes {
echo "${green}USAGE${reset}
backup prog ${yellow}[name] ${cyan}[flag] ${magenta}[d/w/m_to_keep] ${blue}[source/command] ${reset}[destination/exec-path]${reset}
              |      |          |                |                    |
              |      |          |                |                    '->> destinaton / exec-path path from backup
              |      |          |                |                         If no destination path is supplied,
              |      |          |                |                         the standard path with ${yellow}[name]${reset} is used as destination / exec-path
              |      |          |                |
              |      |          |                '->>  ${blue}source path${reset} for backup / ${blue}command${reset} to be executed
              |      |          |
              |      |          '->> ${magenta}Number${reset} of [days or weeks or months] to keep the old backups.
              |      |               Time unit determined by flag argument.
              |      |
              |      '->> ${cyan}flags${reset} (see help page No.2 \"flags\")
              |
              '->>  ${yellow}name${reset} of backup

${green}EXAMPLES${reset}
${red}#${reset} backup prog ${yellow}backup1 ${cyan}/day/copy/img/ ${magenta}20 ${blue}\"/source_path/\" ${reset}\"/destination/\"${reset}
backup \"source_path\" every day as an .img file into \"/destination/${helpTime}/${helpDate}__start_00-00__end_00-01__name_backup1.img\" and keep the last ${magenta}20${reset} days.

${red}#${reset} backup prog ${yellow}backup1 ${cyan}/day/copy/tar/zip/ ${magenta}7 ${blue}\"/source_path/\"${reset}
backup \"source_path\" every day as an .tar.gz file into \"standard_backup_path/${helpTime}/${helpDate}__start_00-00__end_00-01__name_backup1.tar.gz\" and keep the last ${magenta}7${reset} days.

${red}#${reset} backup prog ${yellow}backup2 ${cyan}/w0/bash/ ${magenta}3 ${blue}'dd if=/dev/sda1 of=/dev/sda2 bs=512'${reset}
copy devcie sda1 onto sda2 with block size 512 every sunday. Excecute ${magenta}\"${reset}${red}root@${HOSTNAME}${reset}:${blue}/standard_backup_path ${red}#${reset} dd if=/dev/sda1 of=/dev/sda2 bs=512${magenta}\"${reset}. Keep the last ${magenta}3${reset} weeks.

${red}#${reset} backup prog ${yellow}world1 ${cyan}/w1/bash/log/ ${magenta}18 ${blue}'/customskript.bash' ${reset}\"/game/gameservers/\"${reset}
backup gameserver with name world1 via a custom skript executed in folder \"/game/gameservers/\".
Do it every Monday create a log file in the destination folder and keep the last ${magenta}18${reset} weeks.

"
}
