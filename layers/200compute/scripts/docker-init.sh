#!/bin/bash

# Uninstall old versions
apt-get remove docker docker-engine docker.io containerd runc

# setup repo
apt-get update
apt-get -y install \
&&    apt-transport-https \
&&    ca-certificates \
&&    curl \
&&    gnupg-agent \
&&    software-properties-common

# Add Docker’s official GPG key:
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

# set up the stable repository
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

# install docker engine
apt-get install -y docker-ce docker-ce-cli containerd.io
