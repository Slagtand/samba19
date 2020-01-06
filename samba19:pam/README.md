# SAMBA19:PAM

## Explicació

El que volem aconseguir amb aquesta pràctica és tindre tres contàiners (*ldapserver, samba i pam*) a la mateixa xarxa (*ldapnet*) i que, junt amb el volum *homes*, monti els homes dels usuaris ldap a pam.

## Containers a engegar (si està tot creat)

```bash
docker run --rm --name ldapserver -h ldapserver --net ldapnet -d marcgc/ldapserver19

docker run --rm --name samba -h samba --net ldapnet -p 139:139 -p 445:445 -v homes:/tmp/home --privileged -d marcgc/samba19:pam

docker run --rm --name ldapserver -h ldapserver --net ldapnet --privileged -p 445:445 -p 139:139 -v homes:/tmp/home -it marcgc/samba19:pam /bin/bash

docker run --rm --name hostpam -h hostpam --privileged --network ldapnet -it marcgc/hostpam19:samba /bin/bash
```

## Instal·lació

* Ja que volem fer servir un volum de docker primer l'hauriem de crear (si no està creat).

```bash
docker volume create homes
```

* També hem de ficar els containers a la mateixa xarxa per a que es reconeguin. La creem si no està creada ja.

```bash
docker network create ldapnet
```

### Creació des de 0

* Instal·lem els paquets necessaris:
  
  ```bash
  dnf -y install vim procps samba samba-client cifs-utils authconfig nss-pam-ldapd passwd
  ```

* Configurem els fitxers necessaris directament amb authconfig per a que funcioni el getent:
  
  ```bash
  authconfig --enableshadow --enablelocauthorize \
   --enableldap \
   --enableldapauth \
   --ldapserver='ldapserver' \
   --ldapbase='dc=edt,dc=org' \
   --enablemkhomedir \
   --updateall
  ```

* Engegem els serveis:
  
  ```bash
  /sbin/nscd
  /sbin/nslcd
  # Comprovem amb getent que està contactant amb el server ldap
  getent passwd
  # Si ens retorna els usuaris ldap funciona correctament. Si no hauriem de mirar que el servidor ldap funcionés bé, o que estigués engegat.
  ```

* Ara el que toca és, per a cada user de ldap, crear el seu home si no el tenen. Agafarem els usuaris i extraurem les seves dades:
  
  ```bash
  for num in {01..08}
  do
      # Afegim els usuaris per a que siguin users samba
      echo -e "jupiter\njupiter" | smbpasswd -a user$num
      line=$(getent passwd user$num)
      uid=$(echo $line | cut -d ":" -f 3)
      gid=$(echo $line | cut -d ":" -f 4)
      homedir=$(echo $line | cut -d ":" -f 6)
      # Comprovem si el home existeix, si no el crea
      if [ ! -d $homedir ]; then
          mkdir -p $homedir
          cp -ra /etc/skel/. $homedir/.
          # Canviem els permisos del directori al de l'user:grup,         perque si no serien els de root
          chown $uid:$gid $homedir
      fi
  done
  ```

* Copiem la següent configuració de samba per a poguer tindre els homes dels user accessibles. El samba sap quin és el home del user perque quan intenta accedir fa un *getent* de l'usuari
  
  ```bash
  cp /opt/docker/smb.conf /etc/samba/smb.conf
  # Contingut smb.conf
  [global]
          workgroup = MYGROUP
          server string = Samba Server Version %v
          log file = /var/log/samba/log.%m
          max log size = 50
          security = user
          passdb backend = tdbsam
          load printers = yes
          cups options = raw
  [homes]
          comment = Home Directories
          browseable = no
          writable = yes
  ;       valid users = %S
  ;       valid users = MYDOMAIN\%S
  [printers]
          comment = All Printers
          path = /var/spool/samba
          browseable = no
          guest ok = no
          writable = no
          printable = yes
  [documentation]
          comment = Documentació doc del container
          path = /usr/share/doc
          public = yes
          browseable = yes
          writable = no
          printable = no
          guest ok = yes
  [manpages]
          comment = Documentació man  del container
          path = /usr/share/man
          public = yes
          browseable = yes
          writable = no
          printable = no
          guest ok = yes
  [public]
          comment = Share de contingut public
          path = /var/lib/samba/public
          public = yes
          browseable = yes
          writable = yes
          printable = no
          guest ok = yes
  [privat]
          comment = Share d'accés privat
          path = /var/lib/samba/privat
          public = no
          browseable = no
          writable = yes
          printable = no
          guest ok = yes
  ```

* Engegem el servei de samba
  
  ```bash
  /sbin/nmbd
  /sbin/smbd
  # Podem comprovar que funciona o bé amb smbtree o intentar conectar amb smbclient
  # Pot ser que smbtree ho tinguem que fer uns quants cops fins que respongui
  [root@samba /]# smbtree
  SAMBA
      \\SAMBA                  Samba 4.7.10
          \\SAMBA\IPC$               IPC Service (Samba 4.7.10)
          \\SAMBA\print$             Printer Drivers
  # També podem comprovar que es monta des del local si hem mapejat els ports del container amb els del local
  mount -t cifs -o user="user08",pass="jupiter" //172.18.0.3/user08 /mnt
  ls -la /mnt/
  total 3076
  drwxr-xr-x.  2 root root    0 Aug 21  2018 .
  dr-xr-xr-x. 18 root root 4096 Sep 25 09:13 ..
  -rwxr-xr-x.  1 root root   18 Jun 18  2018 .bash_logout
  -rwxr-xr-x.  1 root root  193 Jun 18  2018 .bash_profile
  -rwxr-xr-x.  1 root root  231 Jun 18  2018 .bashrc
  ```

# HOSTPAM19:SAMBA

* Instal·lem els paquets necessaris:
  
  ```bash
  dnf -y install vim samba-client cifs-utils authconfig nss-pam-ldapd passwd pam_mount
  ```

* Instal·lem els usuaris locals (pas 2)

* Configurem els fitxers necessaris:
  
  ```bash
  authconfig --enableshadow --enablelocauthorize \
   --enableldap \
   --enableldapauth \
   --ldapserver='ldapserver' \
   --ldapbase='dc=edt,dc=org' \
   --enablemkhomedir \
   --updateall
  ```

* Afegim el mòdul *pam_mount.so* a `/etc/pam.d/system-auth`:
  
  ```bash
  #%PAM-1.0
  # This file is auto-generated.
  # User changes will be destroyed the next time authconfig is run.
  auth        required      pam_env.so
  auth        optional      pam_mount.so
  auth        sufficient    pam_unix.so try_first_pass nullok
  auth        sufficient    pam_ldap.so
  auth        required      pam_deny.so
  
  account     sufficient    pam_unix.so
  account     sufficient    pam_ldap.so
  account     required      pam_deny.so
  
  password    requisite     pam_pwquality.so try_first_pass local_users_only retry=3 authtok_type=
  password    sufficient    pam_unix.so try_first_pass use_authtok nullok sha512 shadow
  password    sufficient    pam_ldap.so
  password    required      pam_deny.so
  
  session     optional      pam_keyinit.so revoke
  session     required      pam_limits.so
  -session     optional      pam_systemd.so
  session     [success=1 default=ignore] pam_succeed_if.so service in crond quiet use_uid
  session     required      pam_mkhomedir.so
  session     optional      pam_mount.so
  session     sufficient    pam_unix.so
  session     sufficient    pam_ldap.so
  ```

* Afegim l'entrada necessària per que ens monti el home de l'user al fitxer `/etc/security/pam_mount.conf.xml`:
  
  ```bash
  <volume user="user08" fstype="cifs" server="samba" path="%(USER)"
  mountpoint="~/%(USER)" options="user=%(USER)" />
  ```
  
  * Amb `server` especifiquem quin és el servidor. En aquest cas és **samba** perque el nostre container s'anomena aixi.
  
  * Amb `path` indiquem on es troba el recurs al que volem accedir. En aquest cas volem accedir al recurs de l'usuari que es logueja.
  
  * Amb `mountpoint` indiquem on volem que es monti aquest recurs. En aquest cas és el home de l'usuari.
  
  * A `options` li indiquem les opcions que farà servir, en aquest cas li estem indicant l'user.

* Iniciem els serveis:
  
  ```bash
  /sbin/nscd
  /sbin/nslcd
  # Comprovem amb getent que està contactant amb el server ldap
  getent passwd
  # Si ens retorna els usuaris ldap funciona correctament. Si no hauriem de mirar que el servidor ldap funcionés bé, o que estigués engegat.
  ```
