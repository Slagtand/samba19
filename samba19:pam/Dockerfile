# Version: 0.0.1
# @edt M06 2019-2020
# samba
# -------------------------------------
FROM fedora:27
LABEL author="@marcgc"
LABEL description="Samba:pam server 19-20"
RUN dnf -y install vim procps samba samba-client cifs-utils authconfig nss-pam-ldapd passwd
RUN mkdir /opt/docker
COPY * /opt/docker/
RUN chmod +x /opt/docker/install.sh /opt/docker/startup.sh
WORKDIR /opt/docker
CMD ["/opt/docker/startup.sh"]

