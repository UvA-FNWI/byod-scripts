# Attempt to find the EFI system partition.
if test -z $EFI_SYS; then
export EFI_SYS=$(blkid 2>/dev/null | grep -m1 'PARTLABEL="EFI system partition"' 2>/dev/null | cut -d ':' -f1 2>/dev/null);
fi

# Prompt the user for the EFI system partition.
if test -z $EFI_SYS; then
echo "warning: EFI system partition not found.";
read -p "Please specify the path of the EFI system partition (e.g. /dev/sda1): " EFI_SYS;
fi

# Check if the user told us anything about the partition.
if test -z $EFI_SYS; then
echo "error: EFI system partition not known."
exit 1;
fi

# Attempt to mount the partition.
mkdir -p /media/EFI_SYS 2>/dev/null
mount $EFI_SYS /media/EFI_SYS 2>/dev/null
if [ $? -ne 0 ]; then
echo "error: unable to mount $EFI_SYS.";
rmdir /media/EFI_SYS;
exit 1;
fi

# Ask GRUB for some necessary details to put into the menu entry.
export HINTS_STRING=$(grub-probe --target=hints_string /media/EFI_SYS/EFI/Microsoft/Boot/bootmgfw.efi 2>/dev/null)
export FS_UUID= $(grub-probe --target=fs_uuid /media/EFI_SYS/EFI/Microsoft/Boot/bootmgfw.efi 2>/dev/null)

# Make sure we have got those details.
if test -z $HINTS_STRING || test -z $FS_UUID; then
echo "error: is grub-probe installed?";
umount /media/SYSTEM_RESERVED
rmdir /media/SYSTEM_RESERVED
exit 1;
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
umount /media/EFI_SYS
rmdir /media/EFI_SYS

