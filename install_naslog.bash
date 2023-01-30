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
  echo -e "\n\033[31mError : \033[33mYou are not root!\n"
  exit
fi
load 10
path=""
count=1
while : ; do
  pathPart=`echo $0 | cut -d'/' -f $count`
  if [[ $count -eq 1 ]] ; then
    path="${path}${pathPart}"
  else
    if [[ "`echo $0 | cut -d'/' -f $(($count+1))`" = "" ]] ; then
      path="${path}/program_naslog.bash"
      break
    else
      path="${path}/${pathPart}"
    fi
  fi
  count=$(($count+1))
done
load 50
cp $path /usr/local/bin/naslog
chmod 755 /usr/local/bin/naslog
load 100
echo -e "\033[32m[\033[7mSuccessfully installed\033[0m"
