# tinycloudinit #
Very Tiny cloud-init script for contextualization of small linux instances.

## Minimum requirements:
 - Linux core utils (awk, head, bash or ash, wget, sed, adduser, addgroup, base64, blkid). Busybox supported.

## Supported cloud-init features:
 - MIME Multipart
 - Base64 encode of userdata
 - OpenNebula datasource
 - OpenStack datasource
 - Amazon EC2 datasource
 - #!/bin/bash script run
 - #!/bin/sh script run
 - #cloud-config [limited support]

Regarding #cloud-config support, commands supported are:
 - users
   - sudo
   - ssh-authorized-keys
   - groups
   - passwd
   - gecos

## Installation:
### On TinyCoreLinux:
   - Install the software into the /opt/ directory, naming it tinycloudinit.sh
   - Add the software to the startup script
 echo /opt/tinycloudinit.sh >> /opt/bootlocal.sh
   - Save the changes to the opt folder
 filetool.sh -b
   - (optional) Load the coreutils package for base64 decoding support
 tce-load -wi coreutils
   - (optional) Load the bash package for running bash scripts (as default, ash will be used)
 tce-load -wi bash

### On RHEL/CentOS/Init:
   - Install the software as init.d script via
 
 wget -O /etc/init.d/tinycloudinit https://raw.githubusercontent.com/spinto/tinycloudinit/master/tinycloudinit.sh

   - Enable it at startup
 
 chkconfig --add tinycloudinit
 chkconfig tinycloudinit on
