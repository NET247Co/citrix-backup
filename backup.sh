#!/bin/bash

# Set the destination of backups
DESTPATH=/mnt/storage

# The storage repository (TODO: Get dynamically)
SSUID=c76e7e20-8cd5-a6b5-f297-a6e36fee907d

# The suffix for backups - get creative to have the script auto-replace older backups
SUFFIX=`date '+%u'`

# Do not edit below this line.

DATE=`date +%d%B%y`
XSNAME=`echo $HOSTNAME`
VM_DUR=0
VMUUIDFILE=/tmp/vmuuids.txt
POOL=`xe pool-list | grep name-label | cut -d":" -f2 | xargs`
HOSTUUID=`xe host-list name-label=$XSNAME | grep uuid | cut -d":" -f2 | xargs`

if [ ! -d $DESTPATH ]
then
        echo "Destination Storage Not Found/Connected"
        exit
fi

# Get a list of all available Virtual Machines on the Citrix Host Server
xe vm-list is-control-domain=false is-a-snapshot=false resident-on=$HOSTUUID | grep uuid | cut -d":" -f2 > $VMUUIDFILE

# Loop over each VM and create a backup
while read VMUUID
do
        # Start Timer
        VM_START=`date +%s`

        # Get the VM Name
        VMNAME=`xe vm-list uuid=$VMUUID | grep name-label | cut -d":" -f2 | sed 's/^ *//g'`
        VMFILE=$DESTPATH/$VMNAME.B$SUFFIX.xva

        echo "Creating backup $SUFFIX of $VMNAME virtual machine "

        # Check for Existing Snapshot
        if [ -f "$VMFILE" ]
        then
                echo "Deleting existing snapshot from destination storage"
                rm "$VMFILE"
        fi

        # Check for Existing Archive
        if [ -f "$VMFILE.gz" ]
        then
                echo "Deleting existing archive from destination storage"
                rm "$VMFILE.gz"
        fi

        # Todo: Check if there is enough space to perform the backup
        
        # Create a snapshot and save the snapshot UUID
        echo "Creating snapshot"
        SNAPUUID=`xe vm-snapshot uuid=$VMUUID new-name-label="SNAPSHOT-$VMUUID-$DATE"`

        # Set flags on the snapshot
        echo "Chaning Flags"
        xe template-param-set is-a-template=false ha-always-run=false uuid=$SNAPUUID

        # Export the snapshot
        echo "Exporting to $VMFILE.gz"
        xe vm-export vm=$SNAPUUID filename= |pigz -c >$VMFILE.gz

        # Delete the snapshot
        echo "Deleting snapshot from storage repository"
        xe snapshot-uninstall snapshot-uuid=$SNAPUUID force=true

        # Backup Timer Calculations
        VM_END=`date +%s`
        VM_DUR=$((VM_START-VM_END))
        VM_TOT=$((VM_TOT+VM_DUR))

        echo "Backup of $VMNAME virtual machine completed in $VM_DUR Seconds"
        
        # Optionally run a cleanup if you are low on space on the storage repo (Todo: Detect if we should run this)
        /opt/xensource/sm/cleanup.py -u $SSUID -g

done < $VMUUIDFILE

echo "Backup Script Completed in $VM_TOT seconds."
