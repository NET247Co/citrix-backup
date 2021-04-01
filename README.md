# citrix-backup
Simple bash script to handle regular backups of VMs

This script is based off https://andrewsarver.com/xenserver-vm-backup-to-nfs-script/ 

## Prerequisites
* Citrix XenServer
* PIGZ Package for inline compression of snapshots

## Installation
Drop it into any folder on your server and setup a cron job to call it as often as required.

## Todo
Clean it up and add some arguments to the script to remove the need for hardcoded values.
