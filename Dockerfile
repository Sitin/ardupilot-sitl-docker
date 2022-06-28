###############################################################################
# Docker image for ArduPilot SITL
# Inspired by https://hub.docker.com/r/radarku/ardupilot-sitl
###############################################################################

#------------------------------------------------------------------------------
# Check out code for a specific tag
#------------------------------------------------------------------------------
FROM ubuntu:focal

ENV DEBIAN_FRONTEND noninteractive
ENV DEBCONF_NONINTERACTIVE_SEEN true

# Code fetch dependencies
RUN echo "UTC" > /etc/timezone && \
    apt-get update && apt-get install -y \
    git \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# Create a user
ARG USER=ardupilot
RUN adduser --disabled-password --gecos '' ${USER} && \
    adduser ${USER} sudo && \
    echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# Get a particular version of ArduPilot from GitHub
ARG ARDUPILOT_TAG=Copter-4.2.1
RUN git clone https://github.com/ArduPilot/ardupilot.git -b ${ARDUPILOT_TAG} --single-branch /ardupilot && \
    chown -R ${USER}:${USER} /ardupilot

# Set working directory
WORKDIR /ardupilot
# Switch to the default user
USER ${USER}

# Update submodules
RUN git submodule update --init --recursive

#------------------------------------------------------------------------------
# Build ArduPilot and SITL
#------------------------------------------------------------------------------

# Install build dependencies
USER root
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    lsb-release \
    tzdata \
    && rm -rf /var/lib/apt/lists/*
USER ${USER}

# Install all build prerequisites
RUN USER=${USER} Tools/environment_install/install-prereqs-ubuntu.sh -y

# Build according to https://github.com/ArduPilot/ardupilot/blob/master/BUILD.md
RUN ./waf distclean
RUN ./waf configure --board sitl
RUN ./waf copter
RUN ./waf rover
RUN ./waf plane
RUN ./waf sub

#------------------------------------------------------------------------------
# Package SITL
#------------------------------------------------------------------------------

# Install xecution dependencies
USER root
RUN apt-get update && apt-get install -y \
    socat \
    ncat \
    && rm -rf /var/lib/apt/lists/*
USER ${USER}

# Allow UDP broadcasting
RUN sudo sysctl net.ipv4.icmp_echo_ignore_broadcasts=0

# Entry point script
COPY sitl-start.sh /ardupilot/sitl-start.sh
RUN sudo chmod +x /ardupilot/sitl-start.sh

# Default communication channel
EXPOSE 5760/tcp
# FlightGear updates
EXPOSE 5503/udp

# Execution configuration
ENTRYPOINT [ "/ardupilot/sitl-start.sh" ]
CMD [ ]
