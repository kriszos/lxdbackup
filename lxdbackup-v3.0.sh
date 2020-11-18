#!/bin/bash
#################################################################################################################################
##	version 3.0.0
##
##	THIS SCRIPT DON'T WORK ON LXD LOWER THAN 3.1 see README.md
##	Script to backup LXD containers, tested with snap LXD 4.4, 4.5, 4.6, 4.7, 4.8 on Ubuntu 16.04 and 20.04
##	Change backup retention. Destination provided as first positional parameter MUST be mounted to /backup
##	Exaples in README.md
##	author: krzysztof.szostak[AT]gmx.com
##
#################################################################################################################################

# how many daily backups to keep
dbn=22
# how many weekly backups to keep
wbn=12
# how many monthly backups to keep
mbn=12


# get todays date for file name
namedate=`date -I`

# functions to manage continuity
contweek1 (){
	shouldname=`date +%Y-%m-01`
	shouldexist=`ls /backup/lxd/$1/monthly/ |grep $shouldname`
	if [ -z "$shouldexist" ]
	then
		echo `date +"%F %T   "` $1 "moving today's daily backup to complete monthly backup"
		mv /backup/lxd/$1/daily/`date -I`* /backup/lxd/$1/monthly/`date +%Y-%m-01`-from-$today-$1.tar.gz
		echo `date +"%F %T   "` $1 "new monthly name:" `date +%Y-%m-01`"-from-"$today"-"$1".tar.gz"
	fi
}

contweek2 (){
	shouldname=`date +%Y-%m-07`
	shouldexist=`ls /backup/lxd/$1/weekly/ |grep $shouldname`
	if [ -z "$shouldexist" ]
	then
		echo `date +"%F %T   "` $1 "moving today's daily backup to complete weekly backup"
		mv /backup/lxd/$1/daily/`date -I`* /backup/lxd/$1/weekly/`date +%Y-%m-07`-from-$today-$1.tar.gz
		echo `date +"%F %T   "` $1 "new weekly name:" `date +%Y-%m-07`"-from-"$today"-"$1".tar.gz"
	fi
}

contweek3 (){
	shouldname=`date +%Y-%m-14`
	shouldexist=`ls /backup/lxd/$1/weekly/ |grep $shouldname`
	if [ -z "$shouldexist" ]
	then
		echo `date +"%F %T   "` $1 "moving today's daily backup to complete weekly backup"
		mv /backup/lxd/$1/daily/`date -I`* /backup/lxd/$1/weekly/`date +%Y-%m-14`-from-$today-$1.tar.gz
		echo `date +"%F %T   "` $1 "new weekly name:" `date +%Y-%m-14`"-from-"$today"-"$1".tar.gz"
	fi
}

contweek4 (){
	shouldname=`date +%Y-%m-21`
	shouldexist=`ls /backup/lxd/$1/weekly/ |grep $shouldname`
	if [ -z "$shouldexist" ]
	then
		echo `date +"%F %T   "` $1 "moving today's daily backup to complete weekly backup"
		mv /backup/lxd/$1/daily/`date -I`* /backup/lxd/$1/weekly/`date +%Y-%m-21`-from-$today-$1.tar.gz
		echo `date +"%F %T   "` $1 "new weekly name:" `date +%Y-%m-21`"-from-"$today"-"$1".tar.gz"
 	fi
}

contweek5 (){
	shouldname=`date +%Y-%m-28`
	shouldexist=`ls /backup/lxd/$1/weekly/ |grep $shouldname`
	if [ -z "$shouldexist" ]
	then
		echo `date +"%F %T   "` $1 "moving today's daily backup to complete weekly backup"
		mv /backup/lxd/$1/daily/`date -I`* /backup/lxd/$1/weekly/`date +%Y-%m-28`-from-$today-$1.tar.gz
		echo `date +"%F %T   "` $1 "new weekly name:" `date +%Y-%m-28`"-from-"$today"-"$1".tar.gz"
	fi
}

# function that do backup and manage retency
ctbac () {
	# $1 << container name 		$2 << daily, weekly or  monthly
	echo `date +"%F %T   "` $1
	# make directory for backups
	mkdir -p /backup/lxd/$1/daily
	mkdir -p /backup/lxd/$1/weekly
	mkdir -p /backup/lxd/$1/monthly

	# export backup until it is exported
	while [ ! -f /backup/lxd/$1/$2/$namedate-$1.tar.gz ]
	do
		echo `date +"%F %T   "` $1 "can't find todays backup, exporting backup"
		# export container backup without snapshots (--instance-only)
		expo=$(lxc export $1 /backup/lxd/$1/$2/$namedate-$1.tar.gz --instance-only)
		echo `date +"%F %T   "` $1 "container backup exported succesfully"
	done

	# print backup name and size
	bacsizename=`ls -sh /backup/lxd/$1/$2/ |grep $namedate`
	echo `date +"%F %T   "` $1 "today's backup:" $bacsizename

	#manage backup continuity by calling function contweekN
	case "$week" in
		"1")	contweek1 $1 ;;
		"2")	contweek2 $1 ;;
		"3")	contweek3 $1 ;;
		"4")	contweek4 $1 ;;
		"5")	contweek5 $1 ;;
		*)	echo `date +"%F %T   "` "'Something is not YES' invalid week $1 or today is weekly/monthly backup"
	esac

	# manage backup retency
	curedire=`pwd`
	cd /backup/lxd/$1/$2/
	oldest=`ls -1t | tail -n +$tbn`
	if [ ! -z "$oldest" ]
	then
		echo `date +"%F %T   "` $1 deleting oldest $2 backup: $oldest
		ls -1t | tail -n +$tbn | xargs rm -f
	else
		echo `date +"%F %T   "` $1 "oldest" $2 "backup not deleted"
	fi
	cd $curedire
	echo `date +"%F %T   "` $1 $2 "backup has been created or already existed"
}

#
# get starting date in seconds
d1=`date +%s`
echo `date +"%F %T   "` "____________________________________________________"
echo `date +"%F %T   "` "begining backup procedure..."

# mount backup target
umount /backup
echo `date +"%F %T   "` "mounting backup target"
mountstat=0
# read backup target from 1st position variable or mount default target
if [ -z "$1" ]
then
	mount.cifs //192.168.125.32/folder/subfolder /backup -o credentials=/root/backupsmb.cred,vers=2.0
	#mount [2001:db8::2:1]:/backup /backup
else
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

# decide if to do monthly, weekly or daily backup based on day of month,
# set $week number for later calling contweekN function
today=`date +%d`
case "$today" in
	"01")				varly=monthly ; tbn="$mbn" ;;
	"02"|"03"|"04"|"05"|"06")	varly=daily ; week=1 ; tbn="$dbn" ;;
	"07"|"14"|"21"|"28")		varly=weekly ; tbn="$wbn" ;;
	"08"|"09"|"10"|"11"|"12"|"13")	varly=daily ; week=2 ; tbn="$dbn" ;;
	"15"|"16"|"17"|"18"|"19"|"20")	varly=daily ; week=3 ; tbn="$dbn" ;;
	"22"|"23"|"24"|"25"|"26"|"27")	varly=daily ; week=4 ; tbn="$dbn" ;;
	"29"|"30"|"31")			varly=daily ; week=5 ; tbn="$dbn" ;;
	*) varly=daily ; tbn="$dbn" ; echo `date +"%F %T   "` "'Something is not YES' invalid day $today"
esac

# get list of RUNNING containers
cts=`lxc list -c ns --format="csv" |grep ,RUNNING | sed 's/,RUNNING//g'`
echo `date +"%F %T   "` "getting list of containers to backup: " $cts
# do backup of only RUNNING containers by calling function ctbac
echo "$cts" | while read line
do
	ctbac $line $varly
done


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
