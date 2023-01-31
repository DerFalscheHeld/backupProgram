#!/bin/bash

if [[ "$1" = "--help" ]] || [[ "$1" = "-h" ]] || [[ "$1" = "help" ]] || [[ "$1" = "" ]] ; then
  echo -e " Usage : $0 [OPTION]
            options
              [install] >> installs the mail service
              [DEBUG]   >> installs the mail service in DEBUG Mode"
  exit
fi

declare -A osInfo;
osInfo[/etc/debian_version]="apt install -y msmtp-mta"
osInfo[/etc/alpine-release]="apk --update add"
osInfo[/etc/centos-release]="yum install -y"
osInfo[/etc/fedora-release]="dnf install -y"

for f in ${!osInfo[@]}
do
    if [[ -f $f ]];then
        package_manager=${osInfo[$f]}
    fi
done

package="msmtp mailutils"
${package_manager} ${package}


home=$HOME
path=""
count=1
while : ; do
  pathPart=`echo $0 | cut -d'/' -f $count`
  if [[ $count -eq 1 ]] ; then
    path="${path}${pathPart}"
  else
    if [[ "`echo $0 | cut -d'/' -f $(($count+1))`" = "" ]] ; then
      path="${path}/"
      break
    else
      path="${path}/${pathPart}"
    fi
  fi
  count=$(($count+1))
done

configDir=config_cronmail_service
cp -f $path$configDir/msmtprc.conf $home/.msmtprc

chmod 600 $home/.msmtprc
sudo cp -f $home/.msmtprc /etc/msmtprc
sudo cp -f $home/.msmtprc ~/.msmtprc
sudo cp -f $path$configDir/aliases.conf /etc/aliases

sudo rm /usr/sbin/sendmail

if [[ "$1" = "DEBUG" ]] ; then
  sudo cp -f $path$configDir/mail.rc.debug /etc/mail.rc
  sudo cp $path$configDir/sendmail.conf.debug /usr/sbin/sendmail
else
  sudo cp -f $path$configDir/mail.rc /etc/mail.rc
  sudo cp $path$configDir/sendmail.conf /usr/sbin/sendmail
fi

sudo chmod 600 /etc/msmtprc
sudo chmod 600 ~/.msmtprc
sudo chmod 777 /usr/sbin/sendmail

echo -e "\033[36mMSG  :\033[33m Please reboot your system to activate the mailservice!\033[0m"
