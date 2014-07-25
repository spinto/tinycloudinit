Very Tiny cloud-init script for contextualization of small linux instances.

Minimum requirements:
 - Linux core utils (awk, bash, wget, sed, useradd, groupadd). Busybox supported.

Supported cloud-init features:
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
