#! /bin/bash
# @marcgc ASIX M06 2019-2020
# startup.sh
# -------------------------------------

/opt/docker/install.sh && echo "Install Ok"
# Configuració ldap
/sbin/nscd && echo "nscd Ok"
/sbin/nslcd && echo "nslcd  Ok"

# Configuració samba
/usr/sbin/smbd && echo "smb Ok"
bash /opt/docker/ldapusers.sh
/usr/sbin/nmbd -F


