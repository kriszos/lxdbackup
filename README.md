# lxdbackup
Bash script to make a backup of RUNNING LXD containers to a remote mount specified on 1st positional variable.
Type of remote storage is up to You. I am using SMB and NFS

Script is expected to mount remote destination ALWAYS to /backup, 
so make it immutable to avoid writing to this folder without mount:
```bash
chattr -i /backup
```
Directory structure like bellow:
```bash
/backup/
└── lxd
    ├── CT10
    │   ├── daily
    │   │   └── 2020-08-29-CT10.tar.gz
    │   ├── monthly
    │   │   └── 2020-05-01-CT10.tar.gz
    │   └── weekly
    │       └── 2020-08-14-CT10.tar.gz
    └── CT20
        ├── daily
        │   └── 2020-08-29-CT20.tar.gz
        ├── monthly
        │   └── 2020-08-01-from-06-CT20.tar.gz
        └── weekly
            └── 2020-08-28-CT20.tar.gz
```

Oldest backups are removed when number of files in daily/weekly/monthly directory exceed retency variables.

Script print what it is doing to STDOUT, you can forward it to a log file like on examples at the bottom.

Script verion 2.0 is approximately 2x faster than 1.0,
due to new 'lxc export' command, but works only on LXD 3.1 and above.
I tested it only on LXD 4.4 

If You miss weekly or monthly backup script will correct it by moving daily backup as monthly or weekly,
up to 5 day afterward.
Example above on directory structure tree in /backup/lxd/CT20/monthly (works only in script version 2.0 and above)

At the end Script will print how much time it take to make a backup.

If You're using LXD from snap and running this script via crontab,
remember to add PATH of SNAP binaries /snap/bin to crontab file, like that:
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/snap/bin

If You find any bugs please report to krzysztof.szostak [ at ] gmx.com

Examples:
```bash
# backup to NFS share whit log to file
bash lxdbackup.sh "mount [2001:db8::2:1]:/backup /backup/" >> /var/log/lxdbackup.log

# backup to SAMBA share with log to STDOUT
bash lxdbackup.sh "mount.cifs //192.168.127.15/folder/subfolder /backup -o credentials=/root/backupsmb.cred,vers=2.0"

# backup to default destination specified in script with log to STDOUT
bash lxdbackup.sh
```
