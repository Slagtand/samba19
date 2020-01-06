#! /bin/bash
# @edt ASIX M06 2019-2020
# instal.lacio
# -------------------------------------
# Creació usuaris
bash /opt/docker/localusers.sh
bash /opt/docker/sambausers.sh

# Configuració client autenticació ldap
bash /opt/docker/auth.sh

# Configuració shares samba
mkdir /var/lib/samba/public
chmod 777 /var/lib/samba/public
cp /opt/docker/* /var/lib/samba/public/.
mkdir /var/lib/samba/privat
#chmod 777 /var/lib/samba/privat
cp /opt/docker/*.md /var/lib/samba/privat/.
cp /opt/docker/smb.conf /etc/samba/smb.conf

# Creació comptes samba i directoris dels usuaris ldap
# Un cop els serveis estàn actius
#bash /opt/docker/ldapusers.sh