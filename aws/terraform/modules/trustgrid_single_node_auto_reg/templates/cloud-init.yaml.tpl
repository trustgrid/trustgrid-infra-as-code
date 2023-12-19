#cloud-config

write_files:
  - content: ${license}
    path: /usr/local/trustgrid/license.txt
    permissions: "000644"
    owner: root:root
