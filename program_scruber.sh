#!/usr/bin/bash
if [[ $UID != 0 ]] ; then
  echo "You are not root! Permission denied"
  exit 1
fi

function help {
echo "scruber [option] [arguments...]
OPTIONS
  exec [btrfs] >> scrub all btrfs volumes
       [zpool] >> scrub all zpool volumes
       [all]   >> scrub all btrfs and zpool volumes
  help|--help  >> shows this help page

EXAMPLE CRON SYNTAX
  0 0 1 * * /usr/local/bin/scruber exec all (recommended)
  executes a scrub at the first of mounth at 00:00 for btrfs and zpool

  0 3 15 * * /usr/local/bin/scruber exec zpool
  executes a scrub at the 15. day of every mounth at 03:00 for zpool volumes
"
}

function zpool_scrub {
  while read line ; do
    zpool scrub -w $line
  done < <(zpool list | cut -d' ' -f1 | sed -e '1d')
}

function btrfs_scrub {
  while read line ; do
    if ! [[ $(findmnt $line | sed -e '1d' | cut -d' ' -f1 | cut -d'/' -f-5 ) = "/usr/local/etc/usbbackup" ]] ; then
      btrfs scrub start -B -d $(findmnt $line | sed -e '1d' | cut -d' ' -f1 )
    fi
  done < <(df -l --output | grep btrfs | cut -d' ' -f1 )
}

case $1 in
  exec)
    case $2 in
      btrfs)
        btrfs_scrub
        ;;
      zpool)
        zpool_scrub
        ;;
      all)
        btrfs_scrub
        zpool_scrub
        ;;
      *)
        echo "'$2' is not an option for exec!" 1>&2
        exit 1
        ;;
    esac
    ;;
  help|--help)
    help
    ;; 
  *)      
    echo "Syntax Error!!" 1>&2
    help
    exit 1
    ;;
esac
