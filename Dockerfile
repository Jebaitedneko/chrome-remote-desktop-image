FROM ubuntu:focal
ENV DEBIAN_FRONTEND=noninteractive
ARG USER=user
ENV PIN=000000
ENV CODE=4/xxx
ENV HOSTNAME=crd
COPY ["setup.sh", "/"]
RUN /setup.sh SETUP
USER $USER
WORKDIR /home/$USER
