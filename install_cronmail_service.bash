#!/bin/bash
if [[ "$1" = "--help" ]] || [[ "$1" = "-h" ]] || [[ "$1" = "help" ]] || [[ "$1" = "" ]] ; then
  echo -e " Usage : $0 [OPTION] [DISTRO]
            options
              [install] >> installs the mail service
              [DEBUG]   >> installs the mail service in DEBUG Mode
            distros
              [debian]  >> installs the debian Based pagages"
  exit
fi
if [[ "$2" = "debian" ]] ; then
  sudo apt remove msmtp msmtp-mta mailutils --yes
  sudo apt purge msmtp msmtp-mta mailutils --yes
  sudo apt install msmtp msmtp-mta mailutils
fi

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

#cat msmtprc.conf > $home/.msmtprc

#chmod 600 $home/.msmtprc
#sudo cp $home/.msmtprc /etc/msmtprc
#sudo cp $home/.msmtprc ~/.msmtprc
#sudo chmod 600 /etc/msmtprc
#sudo chmod 600 ~/.msmtprc

bash -c'
cat /aliases.conf > /etc/aliases ;
if [[ "$1" = "DEBUG" ]] ; then
  echo "set sendmail=\"/usr/bin/msmtp -t -d\"" > /etc/mail.rc ;
else
  echo "set sendmail=\"/usr/bin/msmtp -t\"" > /etc/mail.rc ;
fi ;
rm /usr/sbin/sendmail ;
echo -e "#!/bin/bash\nsed -e 1c\"FROM: \(Cron Daemon\) \<${mail}\>\" | /usr/bin/msmtp -t -d" >> /usr/sbin/sendmail ;
sudo chmod 777 /usr/sbin/sendmail' ;
