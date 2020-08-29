#!/bin/bash
#####################################################################################################################################################################
##
##	Script to backup LXD containers, tested on LXD 3.0.3 & 4.4 on Ubuntu 16.04, 18.04 & 20.04
##	Change backup retention. Destination provided as first positional parameter will be mounted to /backup
##	ex. /skrypty/lxdbackup.sh "mount.cifs //192.168.127.15/folder/subfolder /backup -o credentials=/root/backupsmb.cred,vers=2.0" >> /var/log/lxdbackup.log
##	author: krzysztof.szostak[AT]gmx.com
##
#####################################################################################################################################################################
#test
# how many daily backups to keep?
dbn=22
# how many weekly backups to keep?
wbn=12
# how many monthly backups to keep?
mbn=12

# function that do backup and manage retency
ctbac () {
	# $1 << container name          $2 << daily, weekly or  monthly

	# make directory for backups
	mkdir -p /backup/lxd/$1/$2

	# do backup only if todays backup don't exist
	while [ ! -f /backup/lxd/$1/$2/`date -I`-$1.tar.gz ]
	do
		# take snapshot until it exist
		echo `date +"%F %T   "` $1 "taking snapshot"
		while true
		do
			if lxc info $1 |grep -q "backup (taken at" ; then
				echo `date +"%F %T   "` $1 "snapshot taken"
				break
			else
				lxc snapshot $1 backup
			fi
		done

		# publish image from snapshot until it is published
		echo `date +"%F %T   "` $1 "publishing image"
		while true
		do
			imagels=`lxc image list -c l --format=csv | grep backup`
			if [[ $imagels = backup ]]
			then
				break
			fi
			pub=`lxc publish $1/backup --public --alias backup`
		done
		echo `date +"%F %T   "` $1 $pub

		# delete snapshot until it doesn't exist
		echo `date +"%F %T   "` $1 "deleting snapshot"
		while true
		do
			if lxc info $1 |grep -q "backup (taken at" ; then
				lxc delete $1/backup
			else
				echo `date +"%F %T   "` $1 "snapshot deleted"
				break
			fi
		done

		# export image until it is exported
		while [ ! -f /backup/lxd/$1/$2/`date -I`-$1.tar.gz ]
		do
			echo `date +"%F %T   "` $1 "can't find todays backup, exporting backup"
			expo=$(lxc image export backup /backup/lxd/$1/$2/`date -I`-$1)
			sleep 5
		done
		echo `date +"%F %T   "` $1 "image exported succesfully"

		# manage backup retency
		curedire=`pwd`
		cd /backup/lxd/$1/$2/
		oldest=`ls -1t | tail -n +$tbn`
		echo `date +"%F %T   "` $1 deleting oldest $2 backup: $oldest
		ls -1t | tail -n +$tbn | xargs rm -f
		cd $curedire

		# delete image created for backup
		echo `date +"%F %T   "` $1 "deleting image"
		lxc image list -c l --format=csv | grep backup | while read LINE
		do
			lxc image delete backup
			sleep 5
		done

	done
	echo `date +"%F %T   "` $1 $2 "backup has been created or already existed"
}


# get starting date in seconds
d1=`date +%s`

echo `date +"%F %T   "` "begining backup procedure..."

# decide if to do monthly, weekly or daily backup based on day of month
today=`date +%d`
case "$today" in
	"01")                   varly=monthly ; tbn="$mbn" ;;
	"07"|"14"|"21"|"28")    varly=weekly ; tbn="$wbn" ;;
	*)                      varly=daily ; tbn="$dbn"
esac


# mount backup target
umount /backup
echo `date +"%F %T   "` "mounting backup target"
mountstat=0
# read backup target from 1st position variable or mount default target
if [ -z "$1" ]
then
	mount [2001:db8::2:1]:/backup /backup/ || mountstat=1
else
	# read first position variable end execute it
	rempath="$1"
	bash -c "${rempath[@]}" || mountstat=1
fi
# exit with failure(1) if mount failed or proceed when succesfull
if [ $mountstat != 0 ]
then
	echo `date +"%F %T   "` "mount failed, backup failed, exiting"
	exit 1
else
	dfmounted=`df -h |grep /backup`
	echo `date +"%F %T   "` "mount succesfull" $dfmounted
fi


# get list of running containers
cts=`lxc list -c ns --format="csv" |grep ,RUNNING | sed 's/,RUNNING//g' | tr '\n' ' '`
echo `date +"%F %T   "` "getting list of containers to backup: " $cts

# do backup of only running containers by running "ctbac" function for evry line returned
lxc list -c ns --format="csv" |grep ,RUNNING | sed 's/,RUNNING//g' | while read line ; do ctbac $line $varly ; done

# umount backup target
echo `date +"%F %T   "` "umounting backup target"
umount /backup

# get ending date in seconds
d2=`date +%s`

# do math on starting end ending date to print elapsed time
d3=$((d2-d1))
dh=$((d3/3600))
dm=$(((d3-(3600*dh))/60))
ds=$(((d3-(3600*dh))-(dm*60)))
echo `date +"%F %T   "` backup script executed succesfully, time elapsed: $dh hours, $dm minutes, $ds seconds

exit 0
