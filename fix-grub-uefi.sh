#!/bin/bash

# For debugging purposes.
if test -z $ELOG; then
export ELOG=/dev/null
fi

# Truncate the error log.
>$ELOG

# Attempt to find the EFI system partition.
if test -z $EFI_SYS; then
export EFI_SYS=$(blkid 2>>$ELOG | grep -m1 'PARTLABEL="EFI system partition"' 2>>$ELOG | cut -d ':' -f1 2>>$ELOG)
fi

# Prompt the user for the EFI system partition.
if test -z $EFI_SYS; then
echo "warning: EFI system partition not found."
read -p "Please specify the path of the EFI system partition (e.g. /dev/sda1): " EFI_SYS
fi

# Check if the user told us anything about the partition.
if test -z $EFI_SYS; then
echo "error: EFI system partition not known."
exit 1;
fi

# Attempt to mount the partition.
mkdir -p /boot/efi 2>>$ELOG
mount $EFI_SYS /boot/efi 2>>$ELOG
if [ $? -ne 0 ]; then
echo "error: unable to mount $EFI_SYS."
rmdir /boot/efi 2>>$ELOG
exit 1
fi

# Ask GRUB for some necessary details to put into the menu entry.
export HINTS_STRING=$(grub-probe --target=hints_string /boot/efi/EFI/Microsoft/Boot/bootmgfw.efi 2>>$ELOG)
export FS_UUID=$(grub-probe --target=fs_uuid /boot/efi/EFI/Microsoft/Boot/bootmgfw.efi 2>>$ELOG)

# Make sure we have got those details.
if test -z "$HINTS_STRING" || test -z "$FS_UUID"; then
echo "error: is grub-probe installed?"
umount /boot/efi 2>>$ELOG
rmdir /boot/efi 2>>$ELOG
exit 1
fi

# Write the menu entry.
cat << __EOF__ >> /etc/grub.d/40_custom
menuentry "Microsoft Windows Vista/7/8/8.1" {
	insmod part_gpt
	insmod fat
	insmod search_fs_uuid
	insmod chain
	search --fs-uuid --set=root $HINTS_STRING $FS_UUID
	chainloader /EFI/Microsoft/Boot/bootmgfw.efi
}
__EOF__

# Clean up.
umount /boot/efi 2>>$ELOG
rmdir /boot/efi 2>>$ELOG

