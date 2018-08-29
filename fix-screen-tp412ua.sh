#
# To add local entries, create a new file
#   /etc/udev/hwdb.d/61-sensor-local.hwdb
# and add your rules there. To load the new rules execute (as root):
#   systemd-hwdb update
#   udevadm trigger -v -p DEVNAME=/dev/iio:deviceXXX
# where /dev/iio:deviceXXX is the device in question.

if [[ $EUID -ne 0 ]]; then
    sudo $0
    exit $?
fi

cat > /etc/udev/hwdb.d/61-sensor-local.hwdb <<- EOF
sensor:modalias:acpi:BOSC0200*:dmi:*svn*ASUSTeK*:*pn*TP412UA*
 ACCEL_MOUNT_MATRIX=0, -1, 0; 1, 0, 0; 0, 0, 1
EOF

systemd-hwdb update
