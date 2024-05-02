#!/bin/bash

umask 0177

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
  echo -e "\033[31mError : \033[33mYou are not root!"
  exit
fi
load 10
path="${0%/*}/program_backup.sh"
codePath="${0%/*}/backupCode/*"
load 30
cp $path /usr/local/bin/backup
chmod 755 /usr/local/bin/backup
load 50
mkdir -p /usr/local/etc/backup/code
cp $codePath /usr/local/etc/backup/code/
chmod 755 -R /usr/local/etc/backup/code
chmod 755 /usr/local/etc/backup
load 100
echo -e "\033[32m[\033[7mSuccessfully installed\033[0m"