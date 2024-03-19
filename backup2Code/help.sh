#!/usr/bin/bash

function helpPage1 {
echo "\033[0mbackup [option] [arguments...]
\033[32mOPTIONS\033[0m
  ls []                 >> Lists programmed backups
     [trash]            >> Lists trashbin
     [deact]            >> Lists deactivated backups
     [all]              >> Lists all
  rm [1-99]             >> Delete a programmed backup with ID [1-99]
     [trash]            >> Delete the trashbin
     [deact]            >> Delete the deactivation list
  re [1-99]             >> Restore backup from trashbin with ID [1-99]
  log [1-99]            >> Shows all logs from the ID [1-99] in less
  path [Path]           >> Change standard backup path
  deact [1-99]          >> Deactivate backup with ID [1-99]
  react [1-99]          >> Reactivate backup with ID [1-99]
  exec                  >> For daily execute use cron syntax
                           \033[36m0 0 * * * /usr/local/bin/backup exec \033[0m
  execAll               >> Execute all backups now
  prog                  >> Programming a new backup - See example and flag page
  version / --version   >> Shows the program version.
  help / -h / --help [] >> Shows all help pages.
               [option] >> Shows help page no.1 (options page)
               [ flag ] >> Shows help page no.2 (flas page)
              [example] >> Shows help page no.3 (examples page)
  --restoreProgram [file] []      >> Restore program from backup file
                          [--yes] >> ... and skip confirmation by auto-affirming restoration
  --deleteAllProgramFiles []      >> Delete all program Files
                          [--yes] >> ... and skip confirmation by auto-affirming deletion
"
}

function helpPage2 {
echo "\033[32mFLAGS\033[0m
  Arguments are seperated by \"/\"
  e.g.:   /flag1/flag2/flag3/....

  day     >>  daily backup
  m[1-31] >>  monthly backup
  w[0-6]  >>  weekly backup
              0  1  2  3  4  5  6
              Su Mo Tu We Th Fr Sa
  copy    >>  Supply source path argument
              and an optional destination argument
  bash    >>  The command will be executed in bash
              The command needs to be supplied with '
              Will be executed in exec-path
  img     >>  Save data as .img file
  zip     >>  Save data as .gz archive with gzip with single core
  tar     >>  Save data as .tar archive
  log     >>  Create log-file in destination folder
"
}

function helpPage3 {
echo "\033[32mUSAGE\033[0m
backup prog \033[33m[name] \033[36m[flag] \033[35m[d/w/m_to_keep] \033[34m[source/command] \033[0m[destination/exec-path]\033[0m
              |      |          |                |                    |
              |      |          |                |                    '->> destinaton / exec-path path from backup
              |      |          |                |                         If no destination path is supplied,
              |      |          |                |                         the standard path with \033[33m[name]\033[0m is used as destination / exec-path
              |      |          |                |
              |      |          |                '->>  \033[34msource path\033[0m for backup / \033[34mcommand\033[0m to be executed
              |      |          |
              |      |          '->> \033[35mNumber\033[0m of [days or weeks or months] to keep the old backups.
              |      |               Time unit determined by flag argument.
              |      |
              |      '->> \033[36mflags\033[0m (see help page No.2 \"flags\")
              |
              '->>  \033[33mname\033[0m of backup

\033[32mEXAMPLES\033[0m
\033[31m#\033[0m backup prog \033[33mbackup1 \033[36m/day/copy/img/ \033[35m20 \033[34m\"/source_path/\" \033[0m\"/destination/\"\033[0m
backup \"source_path\" every day as an .img file into \"/destination/${helpTime}/${helpDate}__start_00-00__end_00-01__name_backup1.img\" and keep the last \033[35m20\033[0m days.

\033[31m#\033[0m backup prog \033[33mbackup1 \033[36m/day/copy/tar/zip/ \033[35m7 \033[34m\"/source_path/\"\033[0m
backup \"source_path\" every day as an .tar.gz file into \"standard_backup_path/${helpTime}/${helpDate}__start_00-00__end_00-01__name_backup1.tar.gz\" and keep the last \033[35m7\033[0m days.

\033[31m#\033[0m backup prog \033[33mbackup2 \033[36m/w0/bash/ \033[35m3 \033[34m'dd if=/dev/sda1 of=/dev/sda2 bs=512'\033[0m
copy devcie sda1 onto sda2 with block size 512 every sunday. Excecute \033[35m\"\033[0m\033[31mroot@${HOSTNAME}\033[0m:\033[34m/standard_backup_path \033[31m#\033[0m dd if=/dev/sda1 of=/dev/sda2 bs=512\033[35m\"\033[0m. Keep the last \033[35m3\033[0m weeks.

\033[31m#\033[0m backup prog \033[33mworld1 \033[36m/w1/bash/log/ \033[35m18 \033[34m'/customskript.bash' \033[0m\"/game/gameservers/\"\033[0m
backup gameserver with name world1 via a custom skript executed in folder \"/game/gameservers/\".
Do it every Monday create a log file in the destination folder and keep the last \033[35m18\033[0m weeks.

"
}
