#!/usr/bin/bash

programmDir=/usr/local/etc/backup

backupFile=$programmDir/backup2.json
backupPath=$programmDir/backup.path

# deactivation files
deactBackupFile=$programmDir/backupDeact.json

# trashbin files
trashBackupFile=$programmDir/backupTrash.json

#zipprogram
zip="pigz -p$(cat /proc/cpuinfo | grep processor | wc -l)"
zipProg="pigz"
#tempDir
tempDir=/tmp

#allgemeine val
count=1
separator=\#

#error
exit=0

#help
helpTime=`date +"%Y-%m-%d--%H-%M"`
helpDate=`date +"%Y-%m-%d"`

#Variable zum unterbrechen der readFlag() funktion
breakval=0
flagcheck=0
flagCheckDay=0
flagCheckWeek=0
flagCheckMonth=0
flagTimeMany=0
flagTimeLess=0

#flagsyntax vals
flagMonth=""
flagWeek=""
flagDay=""
flagCopy=""
flagBash=""
flagZip=""
flagTar=""
flagLog=""
flagImg=""

standardBackuppath=""

#vom re zum checken ob programiert wurde
reProgram=0

execAllBackups=0
