#!/bin/bash
set -x
# INSTALL SOURCES FOR CHROME REMOTE DESKTOP
function SETUP() {
    apt-get update -y -qq && apt-get upgrade -y -qq
    apt-get install --install-recommends --fix-missing --fix-broken curl gpg wget p7zip-full -y -qq
    wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | apt-key add -
    echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list
    # INSTALL WINE AND WINETRICKS + DOTNET + VCRUNTIMES
    dpkg --add-architecture i386
    mkdir -pm755 /etc/apt/keyrings
    wget -q -O /etc/apt/keyrings/winehq-archive.key https://dl.winehq.org/wine-builds/winehq.key
    wget -q -NP /etc/apt/sources.list.d/ https://dl.winehq.org/wine-builds/ubuntu/dists/bionic/winehq-bionic.sources
    apt-get update -y -qq && apt-get upgrade -y -qq
    apt-get install --install-recommends --fix-missing --fix-broken winehq-staging -y -qq
    apt-get install --install-recommends --fix-missing --fix-broken winetricks -y -qq
    winetricks -q --force dotnet48 gdiplus # vcrun2003 vcrun2005 vcrun2008 vcrun2010 vcrun2012 vcrun2013 vcrun2015
    # wget -q https://github.com/abbodi1406/vcredist/releases/download/v0.64.0/VisualCppRedist_AIO_x86_x64_64.zip
    # 7za x VisualCppRedist_AIO_x86_x64_64.zip
    # wine "VisualCppRedist_AIO_x86_x64.exe /aiA /nogui"
    # or alternative below
    # 7za x VisualCppRedist_AIO_x86_x64.exe -ovcredist
    # sed -i '80d;81d' $(realpath vcredist/Installer.cmd)
    # sed -i 's/choice \/c YRN.*/goto :proceed/g' $(realpath vcredist/Installer.cmd)
    # wine cmd < $(realpath vcredist/Installer.cmd)
    # SOME XTERM AND KEYRING STUFF
    apt-get install --install-recommends --fix-missing --fix-broken xterm libdbus-1-3 libglib2.0-0 -y -qq
    wget -q http://security.ubuntu.com/ubuntu/pool/main/g/glibc/multiarch-support_2.27-3ubuntu1.5_amd64.deb
    wget -q http://mirrors.edge.kernel.org/ubuntu/pool/universe/libg/libgnome-keyring/libgnome-keyring0_3.12.0-1build1_amd64.deb
    wget -q http://mirrors.edge.kernel.org/ubuntu/pool/universe/libg/libgnome-keyring/libgnome-keyring-common_3.12.0-1build1_all.deb
    dpkg -i multiarch-support_2.27-3ubuntu1.5_amd64.deb
    dpkg -i libgnome-keyring-common_3.12.0-1build1_all.deb
    dpkg -i libgnome-keyring0_3.12.0-1build1_amd64.deb
    # INSTALL XFCE DESKTOP AND DEPENDENCIES
    apt-get update -y -qq && apt-get upgrade -y -qq
    apt-get install --install-recommends --fix-missing --fix-broken sudo apt-utils xvfb xfce4 xbase-clients \
        desktop-base vim xscreensaver google-chrome-stable python-psutil psmisc python3-psutil xserver-xorg-video-dummy -y -qq
    apt-get install --install-recommends --fix-missing --fix-broken libutempter0 -y -qq
    wget https://dl.google.com/linux/direct/chrome-remote-desktop_current_amd64.deb
    dpkg -i chrome-remote-desktop_current_amd64.deb
    apt-get install --install-recommends --fix-missing --fix-broken -y -qq
    echo "exec /etc/X11/Xsession /usr/bin/xfce4-session" > /etc/chrome-remote-desktop-session
    # INSTALL FIREFOX
    apt-get install --install-recommends --fix-missing --fix-broken firefox -y -qq
    # ADD USER TO THE SPECIFIED GROUPS
    adduser --disabled-password --gecos '' $USER
    mkhomedir_helper $USER
    adduser $USER sudo
    echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
    usermod -aG chrome-remote-desktop $USER
    mkdir -p .config/chrome-remote-desktop
    chown "$USER:$USER" .config/chrome-remote-desktop
    chmod a+rx .config/chrome-remote-desktop
    touch .config/chrome-remote-desktop/host.json
    apt-get autoremove -y -qq && apt-get clean autoclean && rm -rf /var/lib/apt/lists/*
    rm -rf ./*.deb
}
function CRD() {
   DISPLAY= /opt/google/chrome-remote-desktop/start-host --code=$CODE --redirect-url="https://remotedesktop.google.com/_/oauthredirect" --name=$HOSTNAME --pin=$PIN && \
   HOST_HASH=$(echo -n $HOSTNAME | md5sum | cut -c -32) && \
   FILENAME=.config/chrome-remote-desktop/host#${HOST_HASH}.json && echo $FILENAME && \
   cp .config/chrome-remote-desktop/host#*.json $FILENAME && \
   sudo service chrome-remote-desktop stop && \
   sudo service chrome-remote-desktop start && \
   echo $HOSTNAME && \
   sleep infinity & wait
}
[[ $* =~ "SETUP" ]] && SETUP
[[ $* =~ "CRD" ]] && CRD
set +x