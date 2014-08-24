#!/usr/bin/env bash

if [[ $EUID -ne 0 ]]; then
    echo "This program must be run as root, try: sudo ./install-extras.sh" 1>&2
    exit 1
fi

if [[ -z $SUDO_USER ]]; then
    echo "This program must be run using sudo." 1>&2
    exit 1
fi

if [[ $SUDO_UID -eq 0 ]]; then
   echo "Please execute this script as a normal user using sudo." 1>&2
   exit 1
fi

echo "University of Amsterdam - S.J.R. van Schaik - R. de Vries"

# Install gnome-flashback-session
apt-get -y install gnome-session-flashback
gsettings set org.gnome.desktop.wm.keybindings panel-run-dialog "['<Alt>F2']"
gsettings set org.gnome.desktop.wm.preferences button-layout :minimize,maximize,close

# Set gnome-session-flashback as default
sed -i 's/user-session=ubuntu/user-session=gnome-fallback/g' /usr/share/lightdm/lightdm.conf.d/50-ubuntu.conf
sed -i 's/XSession=ubuntu/Xsession=gnome-fallback/g' /var/lib/AccountsService/users/$SUDO_USER

# Install oracle java and UvAvpn
add-apt-repository -y ppa:webupd8team/java ppa:uva-informatica/uvavpn
apt-get update
echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | sudo /usr/bin/debconf-set-selections
apt-get -y install oracle-java8-installer oracle-java8-set-default  uvavpn

# Install development tools
apt-get -y install build-essential git vim valgrind flex bison

# Programming languages for the programming-languages course
apt-get -y install lua5.2 liblua5.2-dev swi-prolog erlang ghc

# Install several python packages
apt-get -y install python-scipy python3-scipy

# Install Chromium
apt-get -y install chromium-browser

# Install LaTeX
apt-get -y install texlive-full

# Finish and reboot!
reboot
