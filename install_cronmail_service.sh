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
osInfo[/etc/arch-releaes]="pacman -Sy msmtp-mta"
osInfo[/etc/manjaro-release]="pacman -Sy"

for f in ${!osInfo[@]}
do
    if [[ -f $f ]];then
        package_manager=${osInfo[$f]}
    fi
done

package="msmtp mailutils"
sudo ${package_manager} ${package}


home=$HOME
homeroot=`sudo bash -c "echo ~"`
path="${0%/*}/"
configDir=config_cronmail_service

cp -f $path$configDir/msmtprc.conf $home/.msmtprc

chmod 600 $home/.msmtprc
sudo cp -f $home/.msmtprc /etc/msmtprc
sudo cp -f $home/.msmtprc $homeroot/.msmtprc
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
sudo chmod 600 $homeroot/.msmtprc
sudo chmod 777 /usr/sbin/sendmail

echo -e "\033[36mMSG  :\033[33m Please reboot your system to activate the mailservice!\033[0m"
