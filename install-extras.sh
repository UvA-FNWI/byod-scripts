#!/usr/bin/env bash
TITLE="\n
Installation script\n
University of Amsterdam\n
\n
Made by:\n
 - E.M. Kooistra\n
 - S.J.R. van Schaik\n
 - R. de Vries\n
 - B. Terwijn\n
 - L.A. van Hijfte\n
 - S.J.N. van den Broek\n
 "
LOGFILE="install_extras.log"

function check_answer {
    while true; do
        read -p "$1 (Y/n) " answer
        case $answer in
            [Yy]* ) return 0;;
            [Nn]* ) return 1;;
            * ) echo "Pleases answer yes (y) or no (n)";;
        esac
    done
}

if [[ $EUID -ne 0 ]]; then
    sudo $0
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

if ! `lsb_release -c | grep -q bionic`; then
    echo "This script is recommended to be executed on a machine running Ubuntu 18.04 LTS"
    if ! check_answer "Do you wish to continue?"; then exit 1; fi
fi

# Sets colors if supported else they are empty.
if [ $(bc <<< "`(tput colors) 2>/dev/null || echo 0` >= 8") -eq 1 ]; then
    RED=`tput setaf 1`
    GREEN=`tput setaf 2`
    YELLOW=`tput setaf 3`
    BLUE=`tput setaf 4`
    BOLD=`tput bold`
    RESET=`tput sgr0`
fi

tput reset
echo -e ${TITLE}
> ${LOGFILE}

function install_app {
    app=$1
    echo -ne "$2 Installing ${app%;*}..."
    echo -e "\n\n\n#############################################
#############################################
INSTALLING ${app%;*}
#############################################
#############################################\n" &>> ${LOGFILE}
    ${app#*;} &>> ${LOGFILE}
    if [[ $? -ne 0 ]]; then
        echo -e "\r$2 ${RED}Something went wrong when installing ${app%;*}.${RESET}"
        if check_answer "Would you like to read the log file?"; then
            less ${LOGFILE}
        fi
    else
        echo -e "\r$2 ${GREEN}Installed ${app%;*}${RESET}    "
    fi
}

function initialize_informatica {
    # Add repositories
    sudo apt-add-repository universe &&
    add-apt-repository -y ppa:uva-informatica/meta-packages &&
    add-apt-repository -y ppa:uva-informatica/sim-pl &&
    # Load repositories
    apt -y update
}

function initialize_AI1 {

    su $SUDO_USER -c ' mkdir -p ~/bin;
                       if [ -z "`grep \"BscKI\" ~/.bashrc`" ]; then
                         echo "" >> ~/.bashrc;
                         echo "# boyd BscKI settings" >> ~/.bashrc;
                         echo "export PATH=\$PATH:~/bin" >> ~/.bashrc;
                         echo "export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:/usr/local/lib" >> ~/.bashrc;
                         echo "export EDITOR=/usr/bin/emacs" >> ~/.bashrc;
                         echo "alias o=gnome-open" >> ~/.bashrc;
                         echo "alias e=emacs" >> ~/.bashrc;
                       fi' &&

   sudo apt-add-repository universe
}

# Install functions
function install_prolog {
    apt -y install swi-prolog emacs emacs-goodies-extra-el

    su $SUDO_USER -c ' echo "(setq auto-mode-alist (cons (cons \"\\\\.pl\" '\''prolog-mode) auto-mode-alist))" >> ~/.emacs '
    su $SUDO_USER -c ' echo "(require '\''color-theme)" >> ~/.emacs '
    su $SUDO_USER -c ' echo "(eval-after-load \"color-theme\" '\''(progn (color-theme-initialize) (color-theme-dark-laptop)))" >> ~/.emacs '
    su $SUDO_USER -c ' echo "(show-paren-mode 1)" >> ~/.emacs '
}

function install_java {
    apt -y install openjdk-11-jdk
}

function install_code {
	curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
	mv microsoft.gpg /etc/apt/trusted.gpg.d/microsoft.gpg
	sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main" > /etc/apt/sources.list.d/vscode.list'
	apt -y install apt-transport-https
	apt -y update
	apt -y install code # or code-insiders
	
}

function install_python {
    apt -y install python  python-pip  python-virtualenv
    apt -y install python3 python3-pip python3-virtualenv
	apt -y install jupyter python3-nltk
	
}

function install_python_extra {
    apt -y install python  python-pip  python-virtualenv
    apt -y install python3 python3-pip python3-virtualenv
	apt -y install  python3-numpy
	apt -y install  python3-scipy
	apt -y install  python3-matplotlib
	apt -y install  python3-willow
}


function install_sql {
    sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password password your_password'
    sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password your_password'
    sudo apt-get -y install mysql-server
    mysql -u root -e "DROP USER 'root'@'localhost';
                      CREATE USER 'root'@'localhost' IDENTIFIED BY '';
                      GRANT ALL PRIVILEGES ON *.* TO 'root'@'localhost';
                      FLUSH PRIVILEGES;"
    apt -y install sqlite libsqlite-dev mysql-client
}

function install_r {
    apt -y install r-base
}

function install_protege {
    su $SUDO_USER -c "mkdir -p ~/programs;
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

echo "1) Informatica
2) Artificial Intelligence
while true; do
    read -p "Which of the above listed items fits you the best? " answer
    case $answer in
        [1] ) # Set Informatica year 1&2 variables
            initialize="initialize_informatica"
            mandatory=(
                "build-essential;apt -y install build-essential clang lldb expect"
                "Java;install_java"
                "SIM-PL;apt -y install sim-pl"
                "UvA-VPN;apt -y install openconnect"
                "UvA packages;apt -y install informatica-common informatica-jaar-1"
                "Python;install_python"
                "Python libraries;install_python_extra",
				"Visual studio Code;install_code"
                "LaTeX;apt -y install texlive-full"
			)
            optional=(
                "Chromium;apt -y install chromium-browser"
            ); break;;
        [2] ) # Set Artificial Intelligence year 1 variables
            initialize="initialize_AI1"
            mandatory=(
                "git;apt -y install git"
                # "UvA-VPN;apt -y install openconnect"
                "Prolog;install_prolog"
                "Python;install_python"
                "Atom;install_atom"
                "LaTeX;apt -y install texlive-full"
                "C essentials;apt -y install build-essential gcc valgrind"
                "Python libraries;install_python_extra"
                "SQL;install_sql"
                "Java;install_java"
                "R;install_r"
                "Weka;apt -y install weka"
                "MySQL workbench;apt -y install mysql-workbench"
                "Protege;install_protege"
				
            )
            optional=(
                "Chromium;apt -y install chromium-browser"
            ); break;;
        * ) echo "Pleases answer with 1 or 2";;
    esac
done
tput reset
echo -e ${TITLE}

echo -ne "Initializing..."
$initialize &>> ${LOGFILE}
echo -e "\rInstalling packages:"

total=$(( ${#mandatory[@]} + ${#optional[@]} + 1 ))
for ((i=0; i < ${#mandatory[@]}; i++)) do
    install_app "${mandatory[$i]}" "[$((i + 1))/$total]"
done
for ((i=0; i < ${#optional[@]}; i++)) do
    tag=[$((i + ${#mandatory[@]} + ${#recommended[@]} + 1))/$total]
    if check_answer "$tag Would you like to install ${optional[$i]%;*} (optional)?"; then
        install_app "${optional[$i]}" "$tag"
    fi
done

echo -n "[${total}/${total}] Upgrading packages"
apt -y upgrade &>> ${LOGFILE}
echo -e "\r[${total}/${total}] ${GREEN}Packages upgraded ${RESET}"
echo "${GREEN}Finished!${RESET} If nothing went wrong, you can reboot your computer."
