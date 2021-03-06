#!/bin/bash

# For debugging purposes.
if test -z $ELOG; then
export ELOG=/dev/null
fi

# Truncate the error log.
>$ELOG

# Attempt to find the system reserved partition.
if test -z $SYS_RESERVED; then
export SYS_RESERVED=$(blkid 2>>$ELOG | grep -m1 'LABEL="SYSTEM RESERVED"' 2>>$ELOG | cut -d ':' -f1 2>>$ELOG)
fi

if test -z $SYS_RESERVED; then
export SYS_RESERVED=$(blkid 2>>$ELOG | grep -m1 'LABEL="SYSTEM"' 2>>$ELOG | cut -d ':' -f1 2>>$ELOG)
fi

# Prompt the user for the system reserved partition.
if test -z $SYS_RESERVED; then
echo "warning: system reserved partition not found.";
read -p "Please specify the path of the system reserved partition (e.g. /dev/sda1): " SYS_RESERVED
fi

# Check if the user told us anything about the partition.
if test -z $SYS_RESERVED; then
echo "error: system reserved partition not known."
exit 1
fi

# Attempt to mount the partition.
mkdir -p /media/SYSTEM_RESERVED 2>>$ELOG
mount $SYS_RESERVED /media/SYSTEM_RESERVED 2>>$ELOG
if [ $? -ne 0 ]; then
echo "error: unable to mount $SYS_RESERVED."
rmdir /media/SYSTEM_RESERVED 2>>$ELOG
exit 1
fi

# Ask GRUB for some necessary details to put into the menu entry.
export HINTS_STRING=$(grub-probe --target=hints_string /media/SYSTEM_RESERVED/bootmgr 2>>$ELOG)
export FS_UUID=$(grub-probe --target=fs_uuid /media/SYSTEM_RESERVED/bootmgr 2>>$ELOG)

# Make sure we have got those details.
if test -z "$HINTS_STRING" || test -z "$FS_UUID"; then
echo "error: is grub-probe installed?";
umount /media/SYSTEM_RESERVED 2>>$ELOG
rmdir /media/SYSTEM_RESERVED 2>>$ELOG
exit 1
fi

# Write the menu entry.
cat << __EOF__ >> /etc/grub.d/40_custom
menuentry "Microsoft Windows Vista/7/8/8.1" {
	insmod part_msdos
	insmod ntfs
	insmod search_fs_uuid
	insmod ntldr
	search --fs-uuid --set=root $HINTS_STRING $FS_UUID
	ntldr /bootmgr
}
__EOF__

# Clean up.
umount /media/SYSTEM_RESERVED 2>>$ELOG
rmdir /media/SYSTEM_RESERVED 2>>$ELOG

