#!/bin/bash

set -euo pipefail

apt-get -y install python-setuptools
cd /opt/trustgrid
unzip /home/ubuntu/amisetup.zip -d /home/ubuntu/
RANDFILE=/tmp/.rnd ansible-playbook /home/ubuntu/user_data_ami.yaml -e "enroll_endpoint=${enroll_endpoint}" > /bootstrap.out
rm -rf /opt/trustgrid
cd /usr/local/trustgrid && bin/register.sh
rm -rf /home/ubuntu/*
mv /usr/local/trustgrid/tg-apt.crt /etc/apt/ssl/tg-apt.crt
chown _apt:root /etc/apt/ssl
shutdown -r now