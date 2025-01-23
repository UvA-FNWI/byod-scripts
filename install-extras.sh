#!/usr/bin/env bash
TITLE="
Installation script
University of Amsterdam

Made by:
 - E.M. Kooistra
 - S.J.R. van Schaik
 - R. de Vries
 - B. Terwijn
 - L.A. van Hijfte
 - S.J.N. van den Broek
 - S.R.W. van Kampen
 - R.K. Slot

Source: https://github.com/UvA-FNWI/byod-scripts
Contact: laptops-fnwi@uva.nl
"
LOGFILE="install-extras.log"
APT_OPTIONS="-y -o DPkg::Lock::Timeout=3600"

set -e

function check_answer {
    while true; do
        read -p "$1 (Y/n) " answer
        case $answer in
            [Yy]* ) return 0;;
            [Nn]* ) return 1;;
            * ) echo "Please answer yes (y) or no (n)";;
        esac
    done
}

if [[ $EUID -ne 0 ]]; then
    sudo $0 $@
    exit $?
fi

if [[ -z $SUDO_USER ]]; then
    echo "This program must be run using sudo." 1>&2
    exit 1
fi

if [[ $SUDO_UID -eq 0 ]]; then
   echo "Please execute this script as a normal user using sudo." 1>&2
   exit 1
fi

if ! lsb_release -c | grep -q noble; then
    echo "This script is recommended to be executed on a machine running Ubuntu 24.04 LTS with the GNOME desktop environment."
    if ! check_answer "Do you wish to continue?"; then exit 1; fi
fi

# Sets colors if supported else they are empty.
if [ $(bc <<< "`(tput colors) 2>/dev/null || echo 0` >= 8") -eq 1 ]; then
    RED=$(tput setaf 1)
    GREEN=$(tput setaf 2)
    YELLOW=$(tput setaf 11)
    BLUE=$(tput setaf 4)
    BOLD=$(tput bold)
    RESET=$(tput sgr0)
fi

function on_exit {
    if [ $? != 0 ]; then
        echo
        echo
        echo "${RED}The script encountered an error."
        echo "It is likely caused by a network connection issue. Please try running the script again."
        if check_answer "Would you like to read the log file?"; then
            less ${LOGFILE}
        fi
    fi
    echo
}

trap on_exit EXIT

tput reset
echo -e "${TITLE}"
echo "Starting installation" > ${LOGFILE}

function run_step {
    step=$1
    index=$2
    total=$3
    echo -ne "${YELLOW}[$index/$total]${RESET} Running: ${step%;*}..."
    echo -e "\n\n\n#############################################
#############################################
RUNNING STEP: ${step%;*}
#############################################
#############################################\n" &>> ${LOGFILE}
    ${step#*;} &>> ${LOGFILE}
    # Spaces are required to fully overwrite the previous line
    echo -e "\r${YELLOW}[$index/$total] ${GREEN}Done: ${step%;*}${RESET}               "
}

function add_universe_repository {
    add-apt-repository -y universe
    apt-get $APT_OPTIONS update
}

function install_uvavpn {
    if [ -z "$(nmcli con | grep 'UvA')" ];
    then
        # Gnome settings adds "VPN" to the name, so while it is
        # called just "UvA" here it will show up as "UvA VPN"
        apt-get $APT_OPTIONS install network-manager-openconnect-gnome
        nmcli con add type vpn \
                con-name "UvA" \
                ifname "*" \
                vpn-type openconnect \
                -- \
                vpn.data "gateway=vpn.uva.nl,protocol=nc"
    else
        echo "UvA VPN already configured"
    fi
}

function install_eduvpn {
    sudo apt-get install -y apt-transport-https wget
    wget -O- https://app.eduvpn.org/linux/v4/deb/app+linux@eduvpn.org.asc | gpg --dearmor | sudo tee /usr/share/keyrings/eduvpn-v4.gpg >/dev/null
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/eduvpn-v4.gpg] https://app.eduvpn.org/linux/v4/deb/ $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/eduvpn-v4.list
    sudo apt-get update -y
    sudo apt-get install -y eduvpn-client
}

function install_ai_bashrc {
    su "$SUDO_USER" -c ' mkdir -p ~/bin;
if [ -z "`grep \"BscKI\" ~/.bashrc`" ]; then
    echo "" >> ~/.bashrc;
    echo "# byod BscKI settings" >> ~/.bashrc;
    echo "export PATH=\$PATH:~/bin" >> ~/.bashrc;
    echo "export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:/usr/local/lib" >> ~/.bashrc;
    echo "export EDITOR=/usr/bin/emacs" >> ~/.bashrc;
    echo "alias o=gnome-open" >> ~/.bashrc;
    echo "alias e=emacs" >> ~/.bashrc;
fi'
}

# Install functions
function install_prolog {
    apt-get $APT_OPTIONS install swi-prolog
    # emacs now has postfix as a recommended (transitive) dep.
    # i know emacs is an os, but that is a bit much (and it messes up our noninteractive install)
    apt-get $APT_OPTIONS install --no-install-recommends emacs emacs-goodies-extra-el

    su "$SUDO_USER" -c ' echo "(setq auto-mode-alist (cons (cons \"\\\\.pl\" '\''prolog-mode) auto-mode-alist))" >> ~/.emacs '
    su "$SUDO_USER" -c ' echo "(require '\''color-theme)" >> ~/.emacs '
    su "$SUDO_USER" -c ' echo "(eval-after-load \"color-theme\" '\''(progn (color-theme-initialize) (color-theme-dark-laptop)))" >> ~/.emacs '
    su "$SUDO_USER" -c ' echo "(show-paren-mode 1)" >> ~/.emacs '
}

function install_java {
    apt-get $APT_OPTIONS install openjdk-11-jre openjdk-11-jdk
}

function install_code {
    if dpkg -l code; then
        echo "Skipping, Visual Studio Code already installed"
    else
        apt-get $APT_OPTIONS install dbus-x11
        wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
        mv microsoft.gpg /etc/apt/trusted.gpg.d/microsoft.gpg
        sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main" > /etc/apt/sources.list.d/vscode.list'
        apt-get $APT_OPTIONS install apt-transport-https
        apt-get $APT_OPTIONS update
        apt-get $APT_OPTIONS install code # or code-insiders
        # add code to sidebar
        if command -v gsettings > /dev/null; then
            su "$SUDO_USER" -c $'gsettings set org.gnome.shell favorite-apps "[\'code.desktop\', $(gsettings get org.gnome.shell favorite-apps | sed s/^.//)"'
        else
            echo "gsettings not available, Ubuntu with different desktop environment?"
        fi
    fi
}

function install_python {
    apt-get $APT_OPTIONS install \
            python3 \
            python3-pip \
            python3-virtualenv
}

# disabled because it seems to be broken
# ERROR 1045 (28000): Access denied for user 'root'@'localhost' (using password: NO)
function install_sql {
    sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password password your_password'
    sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password your_password'
    sudo apt-get $APT_OPTIONS install mysql-server
    mysql -u root -e "DROP USER 'root'@'localhost';
                      CREATE USER 'root'@'localhost' IDENTIFIED BY '';
                      GRANT ALL PRIVILEGES ON *.* TO 'root'@'localhost';
                      FLUSH PRIVILEGES;"
    apt-get $APT_OPTIONS install sqlite libsqlite-dev mysql-client
}

function install_r {
    apt-get $APT_OPTIONS install r-base
}

function install_flatpak {
    apt-get install $APT_OPTIONS flatpak gnome-software-plugin-flatpak
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
}

function install_zoom {
    install_flatpak
    flatpak install -y us.zoom.Zoom
}

function install_teams {
    install_flatpak
    flatpak install -y com.microsoft.Teams
}

function install_protege {
    su "$SUDO_USER" -c "mkdir -p ~/programs;
                        cd ~/programs;
                        rm -rf ./Protege-5.2.0*;
                        wget http://sbt.science.uva.nl/boydki_software/Protege-5.2.0-linux.tar.gz;
                        tar -xf Protege-5.2.0-linux.tar.gz;
                        mkdir -p ~/bin
                        cd ~/bin;
                        echo \#\!/bin/bash > protege;
                        echo \"cd ~/programs/Protege-5.2.0\" >> protege;
                        echo \"./run.sh\" >> protege;
                        chmod +x protege;"
}

# function install_latex {
#     # A selection of TeX Live packages
#     # (texlive-fonts-recommended, texlive-latex-base, texlive-latex-recommended)
#     # Maybe also install the docs but we are somewhat time-constrained
#     #apt-get -y install texlive-latex-extra-doc
#     apt-get -y install texlive-latex-extra
# }

function install_sim_pl {
    # it's fine if this runs twice, add-apt-repository checks if already present in sources
    add-apt-repository -y ppa:uva-informatica/sim-pl
    apt-get $APT_OPTIONS install sim-pl
}

function install_vivado {
    add-apt-repository -y ppa:uva-informatica/meta-packages
    apt-get $APT_OPTIONS install 5062arco6y
}

function install_c_tools {
    apt-get $APT_OPTIONS install build-essential clang lldb expect clang-tools valgrind gcc
}

function install_git {
    apt-get $APT_OPTIONS install git
}

function install_chromium {
    sudo snap install chromium
}

function install_firefox_deb {
    # At least for now, the Firefox snap starts very slowly, even on powerful machines. On slower
    # laptops, with SSD, it can take nearly a minute. In addition, there are issues with browser
    # extensions that use native communication, like password managers.

    # Install upstream deb package from Mozilla:
    # https://support.mozilla.org/en-US/kb/install-firefox-linux#w_install-firefox-deb-package-for-debian-based-distributions
    if snap info firefox | grep -q "installed"; then
        apt-get $APT_OPTIONS install dbus-x11
        cat << EOF > /etc/apt/preferences.d/mozilla
Package: *
Pin: origin packages.mozilla.org
Pin-Priority: 1000
EOF
        apt-get $APT_OPTIONS remove firefox
        snap remove firefox
        killall firefox || true
        sudo install -d -m 0755 /etc/apt/keyrings
        wget -q https://packages.mozilla.org/apt/repo-signing-key.gpg -O- | sudo tee /etc/apt/keyrings/packages.mozilla.org.asc > /dev/null
        gpg -n -q --import --import-options import-show /etc/apt/keyrings/packages.mozilla.org.asc | awk '/pub/{getline; gsub(/^ +| +$/,""); if($0 == "35BAA0B33E9EB396F59CA838C0BA5CE6DC6315A3") print "\nThe key fingerprint matches ("$0").\n"; else print "\nVerification failed: the fingerprint ("$0") does not match the expected one.\n"}'
        echo "deb [signed-by=/etc/apt/keyrings/packages.mozilla.org.asc] https://packages.mozilla.org/apt mozilla main" | sudo tee -a /etc/apt/sources.list.d/mozilla.list > /dev/null
        apt-get $APT_OPTIONS update
        apt-get $APT_OPTIONS install firefox firefox-l10n-nl
        su "$SUDO_USER" -c $'
            # Attempt to move data if snap data exists
            if [ -d "~/snap/firefox/common/.mozilla/firefox/" ]; then
                # If data already exists, create a backup instead of overwriting
                if [ -d "~/.mozilla/firefox/" ]; then
                    RANDOM=$(shuf -er -n8  {A..Z} {a..z} {0..9} | tr -d \'\n\')
                    echo "Creating backup of existing Firefox data"
                    mv "~/.mozilla/firefox" "~/.mozilla/firefox.byod-backup-$RANDOM"
                fi
                mkdir -p ~/.mozilla/firefox/
                echo "Moving snap Firefox data"
                mv ~/snap/firefox/common/.mozilla/firefox/* ~/.mozilla/firefox/
            fi

            if command -v gsettings > /dev/null; then
                # Add to GNOME panel favorites
    gsettings set org.gnome.shell favorite-apps "[\'firefox.desktop\', $(gsettings get org.gnome.shell favorite-apps | sed s/^.//)"
            else
                echo "gsettings not available, Ubuntu with different desktop environment?"
            fi
        '
    else
        echo "Skipping, firefox snap not installed"
    fi
}

function install_vim {
    apt-get $APT_OPTIONS install vim
}

function install_arduino_ide {
    apt-get $APT_OPTIONS install libfuse2

    wget -q https://downloads.arduino.cc/arduino-ide/arduino-ide_2.3.2_Linux_64bit.AppImage -O /usr/local/bin/arduino-ide
    chmod a+x /usr/local/bin/arduino-ide

    # Workaround for namespace restrictions added in noble
    cat << EOF > /etc/apparmor.d/arduino-ide
abi <abi/4.0>,
include <tunables/global>

profile arduino-ide /usr/local/bin/arduino-ide flags=(unconfined) {
    userns,
    include if exists <local/arduino-ide>
}
EOF
    systemctl reload apparmor

    # So you can find it in the launcher
    cat <<EOF > /usr/share/applications/arduino-ide.desktop
[Desktop Entry]
Name=Arduino IDE
Exec=/usr/local/bin/arduino-ide
Type=Application
Terminal=false
EOF

    # User needs serial permissions; add them to dialout group
    usermod -aG dialout $SUDO_USER
}

# Note that the rye installation script requires curl, so this must be
# sequenced after installing curl.
function install_rye {
    su "$SUDO_USER" -c '
        curl -sSf https://rye.astral.sh/get | RYE_INSTALL_OPTION="--yes" bash
    '
}

function apt_upgrade {
    DEBIAN_FRONTEND=noninteractive apt-get $APT_OPTIONS upgrade
}

function apt_autoremove {
    DEBIAN_FRONTEND=noninteractive apt-get $APT_OPTIONS autoremove
}

echo "1) Informatica
2) Artificial Intelligence"
while true; do
    read -p "Which of the above listed items fits you the best? " answer
    case $answer in
        [1] ) # Set Informatica year 1&2 variables
            mandatory=(
                "Add Universe repository;add_universe_repository"
                "Install curl;apt-get $APT_OPTIONS install curl"
                "Install Vim;install_vim"
                "Install Git;install_git"
                "Install C build tools;install_c_tools"
                "Install eduVPN;install_eduvpn"
                # This does not install any extensions anymore; courses should use proper venvs or Poetry or rye.
                "Install Python;install_python"
                "Install Rye;install_rye"
                "Visual Studio Code;install_code"
                "Install SIM-PL;install_sim_pl"
                "Install Arduino IDE;install_arduino_ide"
                "Install Vivado;install_vivado"
                # "Upgrade packages;apt_upgrade"
                "Remove unneeded packages;apt_autoremove"
                "Replace Firefox snap with deb from Mozilla;install_firefox_deb"
            )
            optional=(
                # "install Chromium browser (open source base for Google Chrome);install_chromium"
                "install Zoom (flatpak);install_zoom"
                "install Microsoft Teams (flatpak);install_teams"
            ); break;;
        [2] ) # Set Artificial Intelligence year 1 variables
            mandatory=(
                "Add Universe repository;add_universe_repository"
                "Install curl;apt-get $APT_OPTIONS install curl"
                "Install Vim;install_vim"
                "Install Git;install_git"
                "Install C build tools;install_c_tools"
                "Install eduVPN;install_eduvpn"
                # This does not install any extensions anymore; courses should use proper venvs or Poetry or rye.
                "Install Python;install_python"
                "Install Rye;install_rye"
                "Add .bashrc configuration;install_ai_bashrc"
                "Install Prolog;install_prolog"
                # "Install SQL tools;install_sql"
                # "Install Protege;install_protege"
                "Install R;install_r"
                "Install Weka;apt-get $APT_OPTIONS install weka"
                "Install Visual Studio Code;install_code"
                "Install Flatpak;install_flatpak"
                # "Upgrade packages;apt_upgrade"
                "Remove unneeded packages;apt_autoremove"
                "Replace Firefox snap with deb from Mozilla;install_firefox_deb"
            )
            optional=(
                # "install Chromium browser (open source base for Google Chrome);install_chromium"
                "install Zoom (flatpak);install_zoom"
                # "install Microsoft Teams (flatpak);install_teams"
            ); break;;
        * ) echo "Please answer with 1 or 2";;
    esac
done

tput reset
echo -e "${TITLE}"

echo "Run 'tail -f install-extras.log' in a new terminal to monitor logs"

echo -e "\rStarting installation..."
echo

# Total number of steps
mandatory_steps=${#mandatory[@]}
optional_steps=${#optional[@]}
total_steps=$(( mandatory_steps + optional_steps ))

if [ "$1" = "optional" ]
then
    echo "Mandatory steps will be treated as optional steps"
    # Run mandatory steps like optional steps
    for i in "${!mandatory[@]}"; do
        step=${mandatory[$i]}
        description=${step%;*} # extract part before semicolon
        current_step_number=$(( 1 + i ))
        if check_answer "${YELLOW}[$current_step_number/$total_steps]${RESET} Would you like to: $description?"; then
            run_step "$step" $current_step_number $total_steps
        fi
    done
else
    # Run mandatory steps
    for i in "${!mandatory[@]}"; do
        step=${mandatory[$i]}
        current_step_number=$(( 1 + i ))
        run_step "$step" $current_step_number $total_steps
    done
fi

# Run optional steps
for i in "${!optional[@]}"; do
    step=${optional[$i]}
    description=${step%;*} # extract part before semicolon
    current_step_number=$(( 1 + mandatory_steps + i ))
    if check_answer "${YELLOW}[$current_step_number/$total_steps]${RESET} Optional: Would you like to $description?"; then
        run_step "$step" $current_step_number $total_steps
    fi
done

echo
echo "${GREEN}${BOLD}Finished!${RESET} If nothing went wrong, you can shut down your computer or start using it."
