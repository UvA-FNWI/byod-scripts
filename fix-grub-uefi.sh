if test -z $EFI_SYS; then
export EFI_SYS=$(blkid | grep -m1 'PARTLABEL="EFI system partition"' | cut -d
':' -f1);
fi

if test -z $EFI_SYS; then
echo "error: EFI system partition not found.";
exit 1
fi

mkdir -p /media/EFI_SYS
mount $esp /media/EFI_SYS
cat << __EOF__ >> /etc/grub.d/40_custom
if [ "${grub_platform}" == "pc" ]; then
	menuentry "Microsoft Windows Vista/7/8/8.1" {
		insmod part_gpt
		insmod fat
		insmod search_fs_uuid
		insmod chain
		search --fs-uuid --set=root $(grub-probe --target=hints_string /media/EFI_SYS/EFI/Microsoft/Boot/bootmgfw.efi) $(grub-probe --target=fs_uuid /media/EFI_SYS/EFI/Microsoft/Boot/bootmgfw.efi)
		chainloader /EFI/Microsoft/Boot/bootmgfw.efi
	}
fi
__EOF__
update-grub
umount /media/EFI_SYS
rmdir /media/EFI_SYS

