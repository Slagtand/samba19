#! /bin/bash
# @edt ASIX M06 2019-2020
# instal.lacio
# -------------------------------------
mkdir /var/lib/samba/public
chmod 777 /var/lib/samba/public
cp /opt/docker/* /var/lib/samba/public/.

mkdir /var/lib/samba/privat
#chmod 777 /var/lib/samba/privat
cp /opt/docker/*.md /var/lib/samba/privat/.

cp /opt/docker/smb.conf /etc/samba/smb.conf

useradd lila
useradd patipla
useradd roc
useradd pla

echo -e "lila\nlila" | smbpasswd -a lila
echo -e "patipla\npatipla" | smpasswd -a patipla
echo -e "roc\nroc" | smbpasswd -a roc
echo -e "pla\npla" | smbpasswd -a pla