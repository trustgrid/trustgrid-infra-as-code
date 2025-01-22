#!/bin/bash

set -euo pipefail

# Install necessary dependencies
apt-get -y install python-setuptools

# Extract the setup files
unzip /home/ubuntu/amisetup.zip -d /home/ubuntu/

# Run the Ansible playbook
ansible-playbook /home/ubuntu/user_data_ami.yaml -e "enroll_endpoint=${enroll_endpoint}" > /bootstrap.out

# Attempt node registration until successful
while ! (cd /usr/local/trustgrid && bin/register.sh); do
  echo "Registration failed. Retrying in 60 seconds..."
  sleep 60
done

# Perform cleanup
rm -rf /home/ubuntu/*

# Move the tg-apt certificate and set permissions
mv /usr/local/trustgrid/tg-apt.crt /etc/apt/ssl/tg-apt.crt
chown _apt:root /etc/apt/ssl

# Reboot the instance
shutdown -r now
