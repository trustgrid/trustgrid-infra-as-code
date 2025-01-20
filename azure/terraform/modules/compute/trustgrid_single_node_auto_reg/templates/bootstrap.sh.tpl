#!/bin/bash

set -euo pipefail


unzip /opt/trustgrid/pre-reg.zip -d /tmp/pre-reg
/usr/local/trustgrid/ansible/tg-ansible --ansible-playbook ./user_data_ami.yaml -e "enroll_endpoint=${enroll_endpoint}" > /bootstrap.out
cd /usr/local/trustgrid && bin/register.sh
mv /usr/local/trustgrid/tg-apt.crt /etc/apt/ssl/tg-apt.crt
chown _apt:root /etc/apt/ssl
shutdown -r now