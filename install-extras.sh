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


if ! `lsb_release -c | grep -q trusty`; then
    echo "This script can only be executed on a machine running Ubuntu 14.04 LTS"
    exit 1
fi

echo "University of Amsterdam - E.M. Kooistra - S.J.R. van Schaik - R. de Vries"

# Install gnome-flashback-session
echo "[1/9] Installing gnome-flashback-session"
apt-get -y install gnome-session-flashback  &>> install_extras_log
gsettings set org.gnome.desktop.wm.keybindings panel-run-dialog "['<Alt>F2']"
gsettings set org.gnome.desktop.wm.preferences button-layout :minimize,maximize,close

# Set gnome-session-flashback as default
echo "[2/9] Setting gnome-session-flashback as default"
sed -i 's/user-session=ubuntu/user-session=gnome-fallback/g' /usr/share/lightdm/lightdm.conf.d/50-ubuntu.conf
sed -i 's/XSession=ubuntu/Xsession=gnome-fallback/g' /var/lib/AccountsService/users/$SUDO_USER

# Install oracle java and UvAvpn
echo "[3/9] Installing Java / UvA-VPN"
add-apt-repository -y ppa:webupd8team/java &>> install_extras_log
add-apt-repository -y ppa:uva-informatica/uvavpn &>> install_extras_log
apt-get -y update &>> install_extras_log
echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | sudo /usr/bin/debconf-set-selections
apt-get -y install oracle-java8-installer oracle-java8-set-default uvavpn &>> install_extras_log

# Install development tools
echo "[4/9] Installing development tools"
apt-get -y install build-essential git vim valgrind flex bison gnuplot gnuplot-qt graphviz &>> install_extras_log

# Programming languages for the programming-languages course
echo "[5/9] Installing Prolog, Erlang, Go and Haskell"
apt-get -y install swi-prolog erlang ghc golang haskell-platform &>> install_extras_log

# Install several python packages
echo "[6/9] Installing several Python packages"
apt-get -y install python-scipy python-numpy python-matplotlib python3-scipy python3-numpy python3-matplotlib &>> install_extras_log

# Install Chromium
echo "[7/9] Installing Chromium webbrowser"
apt-get -y install chromium-browser &>> install_extras_log

# Install LaTeX
echo "[8/9] Installing LaTeX (this can take up to 45 minutes)"
apt-get -y install texlive-full &>> install_extras_log

#check for updates
echo "[9/9] Updating packages"
apt-get -y upgrade &>> install_extras_log

# Finish and reboot!
echo "Reboot your computer now"
