if test -z $SYS_RESERVED; then
export SYS_RESERVED=$(blkid | grep -m1 'LABEL="SYSTEM RESERVED"' | cut -d
':' -f1);
fi

if test -z $SYS_RESERVED; then
export SYS_RESERVED=$(blkid | grep -m1 'LABEL="SYSTEM"' | cut -d ':' -f1);
fi

if test -z $SYS_RESERVED; then
echo "error: system reserved not found.";
exit 1
fi

mkdir -p /media/SYSTEM_RESERVED
mount $SYS_RESERVED /media/SYSTEM_RESERVED
cat << __EOF__ >> /etc/grub.d/40_custom
if [ "${grub_platform}" == "pc" ]; then
	menuentry "Microsoft Windows Vista/7/8/8.1" {
		insmod part_msdos
		insmod ntfs
		insmod search_fs_uuid
		insmod ntldr
		search --fs-uuid --set=root $(grub-probe --target=hints_string /media/SYSTEM_RESERVED/bootmgr) $(grub-probe --target=fs_uuid /media/SYSTEM_RESERVED/bootmgr)
		ntldr /bootmgr
	}
fi
__EOF__
#update-grub
umount /media/SYSTEM_RESERVED
rmdir /media/SYSTEM_RESERVED

