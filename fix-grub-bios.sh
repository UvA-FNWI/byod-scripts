if test -z $SYS_RESERVED; then
export SYS_RESERVED=$(blkid 2>/dev/null | grep -m1 'LABEL="SYSTEM RESERVED"' 2>/dev/null | cut -d ':' -f1 2>/dev/null);
fi

if test -z $SYS_RESERVED; then
export SYS_RESERVED=$(blkid 2>/dev/null | grep -m1 'LABEL="SYSTEM"' 2>/dev/null | cut -d ':' -f1 2>/dev/null);
fi

if test -z $SYS_RESERVED; then
echo "error: system reserved not found.";
read -p "Please specify the path of the system reserved partition (e.g. /dev/sda1): " SYS_RESERVED
fi

mkdir -p /media/SYSTEM_RESERVED
mount $SYS_RESERVED /media/SYSTEM_RESERVED
cat << __EOF__ >> /etc/grub.d/40_custom
menuentry "Microsoft Windows Vista/7/8/8.1" {
	insmod part_msdos
	insmod ntfs
	insmod search_fs_uuid
	insmod ntldr
	search --fs-uuid --set=root $(grub-probe --target=hints_string /media/SYSTEM_RESERVED/bootmgr) $(grub-probe --target=fs_uuid /media/SYSTEM_RESERVED/bootmgr)
	ntldr /bootmgr
}
__EOF__
#update-grub
umount /media/SYSTEM_RESERVED
rmdir /media/SYSTEM_RESERVED

