#!/bin/bash

set -euo pipefail

apt-get -y install python-setuptools
unzip /opt/trustgrid/pre-reg.zip -d /tmp/pre-reg
cd /tmp/pre-reg
/usr/local/trustgrid/ansible/tg-ansible --ansible-playbook ./pre-registration.yaml -e "tenant=${tenant} platform=${platform}" > /bootstrap.out
cd /usr/local/trustgrid && bin/register.sh
mv /usr/local/trustgrid/tg-apt.crt /etc/apt/ssl/tg-apt.crt
chown _apt:root /etc/apt/ssl
shutdown -r now