FROM ubuntu:latest
# ENABLE NONINTERACTIVE MODE
ENV DEBIAN_FRONTEND=noninteractive
# INSTALL SOURCES FOR CHROME REMOTE DESKTOP
RUN apt update && apt upgrade -y
RUN apt -y install curl gpg wget
RUN wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | apt-key add -
RUN sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list'
# INSTALL WINE AND WINETRICKS + DOTNET + VCRUNTIMES
RUN dpkg --add-architecture i386
RUN mkdir -pm755 /etc/apt/keyrings
RUN wget -O /etc/apt/keyrings/winehq-archive.key https://dl.winehq.org/wine-builds/winehq.key
RUN wget -NP /etc/apt/sources.list.d/ https://dl.winehq.org/wine-builds/ubuntu/dists/bionic/winehq-bionic.sources
RUN apt update && apt upgrade -y
RUN apt install --install-recommends winehq-staging -y
RUN apt install winetricks -y
RUN winetricks -q --force dotnet48 vcrun2003 vcrun2005 vcrun2008 vcrun2010 vcrun2012 vcrun2013 vcrun2015
# SOME XTERM AND KEYRING STUFF
RUN apt install xterm -y
RUN wget http://mirrors.edge.kernel.org/ubuntu/pool/universe/libg/libgnome-keyring/libgnome-keyring0_3.12.0-1build1_amd64.deb
RUN wget http://mirrors.edge.kernel.org/ubuntu/pool/universe/libg/libgnome-keyring/libgnome-keyring-common_3.12.0-1build1_all.deb
RUN dpkg --ignore-depends=multiarch-support -i libgnome-keyring-common_3.12.0-1build1_all.deb
RUN dpkg --ignore-depends=multiarch-support -i libgnome-keyring0_3.12.0-1build1_amd64.deb
# INSTALL XFCE DESKTOP AND DEPENDENCIES
RUN apt update && apt upgrade -y
RUN apt install -y --fix-missing sudo wget apt-utils xvfb xfce4 xbase-clients \
    desktop-base vim xscreensaver google-chrome-stable python-psutil psmisc python3-psutil
RUN apt install libutempter0
RUN wget https://dl.google.com/linux/direct/chrome-remote-desktop_current_amd64.deb
RUN dpkg -i chrome-remote-desktop_current_amd64.deb
RUN apt install -y --fix-broken
RUN bash -c 'echo "exec /etc/X11/Xsession /usr/bin/xfce4-session" > /etc/chrome-remote-desktop-session'
# INSTALL FIREFOX
RUN apt install -y firefox
# SPECIFY VARIABLES FOR SETTING UP CHROME REMOTE DESKTOP
ARG USER=user
ENV PIN=123456
ENV CODE=4/xxx
ENV HOSTNAME=crd
# ADD USER TO THE SPECIFIED GROUPS
RUN adduser --disabled-password --gecos '' $USER
RUN mkhomedir_helper $USER
RUN adduser $USER sudo
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
RUN usermod -aG chrome-remote-desktop $USER
USER $USER
WORKDIR /home/$USER
RUN mkdir -p .config/chrome-remote-desktop
RUN chown "$USER:$USER" .config/chrome-remote-desktop
RUN chmod a+rx .config/chrome-remote-desktop
RUN touch .config/chrome-remote-desktop/host.json
# RUN CRD
CMD \
   DISPLAY= /opt/google/chrome-remote-desktop/start-host --code=$CODE --redirect-url="https://remotedesktop.google.com/_/oauthredirect" --name=$HOSTNAME --pin=$PIN && \
   HOST_HASH=$(echo -n $HOSTNAME | md5sum | cut -c -32) && \
   FILENAME=.config/chrome-remote-desktop/host#${HOST_HASH}.json && echo $FILENAME && \
   cp .config/chrome-remote-desktop/host#*.json $FILENAME && \
   sudo service chrome-remote-desktop stop && \
   sudo service chrome-remote-desktop start && \
   echo $HOSTNAME && \
   sleep infinity & wait