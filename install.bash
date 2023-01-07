#!/bin/bash

if [[ $UID != 0 ]] ; then
  echo -e "\n\033[31mError : \033[33mYou are not root!\n"
  exit
fi

mkdir -p '/usr/local/bin'
mkdir -p '/usr/local/etc/backup/temp'
path='/usr/local/etc/backup/temp/gitClonePath.temp'
touch $path
count=1
while : ; do
  pathPart=`echo $0 | cut -d'/' -f $count`
  if [[ $count -eq 1 ]] ; then
    echo -n $pathPart >> $path
  else
    if [[ "`echo $0 | cut -d'/' -f $(($count+1))`" = "" ]] ; then
      echo -n /backup.bash >> $path
      break
    else
      echo -n /$pathPart >> $path
    fi
  fi
  count=$(($count+1))
done
cp `cat $path` /usr/local/bin/backup
rm $path
