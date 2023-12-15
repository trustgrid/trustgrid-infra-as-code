#!/bin/bash

set -euo pipefail

apt-get -y install python-setuptools
unzip /home/ubuntu/amisetup.zip -d /home/ubuntu/
ansible-playbook /home/ubuntu/user_data_ami.yaml -e "enroll_endpoint=${enroll_endpoint}" > /bootstrap.out
cd /usr/local/trustgrid && bin/register.sh
rm -rf /home/ubuntu/*
mv /usr/local/trustgrid/tg-apt.crt /etc/apt/ssl/tg-apt.crt
chown _apt:root /etc/apt/ssl
shutdown -r now