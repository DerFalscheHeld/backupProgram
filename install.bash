#!/bin/bash

umask 0077

countLoad=1
length=${COLUMNS:-$(tput cols)}
length=$(($length-1))

function load {
  prozent=$(($length*$1/100))
  echo -e -n "\033[32m["
  while : ; do
    echo -e -n "\033[32m\033[7m#\033[0m"
    countLoad=$(($countLoad+1))
    if [[ $countLoad -eq $prozent ]] ; then
      while : ; do
       countLoad=$(($countLoad+1))
       if [[ $countLoad -gt $length ]] ; then
         break
       fi
       echo -e -n "\033[33m-"
      done
      echo -e -n "\033[32m]"
      echo -e -n "\r"
      countLoad=1
      break
    fi
  done
}

if [[ $UID != 0 ]] ; then
  echo -e "\n\033[31mError : \033[33mYou are not root!\n"
  exit
fi

mkdir -p '/usr/local/bin'
load 17
mkdir -p '/usr/local/etc/backup/temp'
load 34
path='/usr/local/etc/backup/temp/gitClonePath.temp'
touch $path
load 51
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
load 68
cp `cat $path` /usr/local/bin/backup
load 85
rm $path
load 100
echo -e "\033[32m[Successfully installed"
