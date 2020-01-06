# Samba

Samba és un protocol de compartiment de directoris en xarxa, prové del protocol smb de Windows, actualment **cifs** (d'aquí el nom).

Té dos dimonis: `smbd` i `nmbd`.

* `smbd`: shares, files, print...

* `nmbd`: resolució de noms (dns).

* Els ports que fa servir són:
  
  ```bash
  139/tcp open  netbios-ssn
  445/tcp open  microsoft-ds
  ```

* Quan és un server Linux, simula ser un dispositiu Windows.

## Diferents rols

* `stand alone`: No depèn de ningú, van a la seva. El host pot montar directoris remots i s'administra ell mateix.

* `servidor`: Ofereix algún servei a algún altre dispositiu. És un *stand alone* que ofereix un servei especial.

* `controlador de domini`: Pot ser `PDC` (*Primary Domain Controler*) o `DC`(*Domain Controler*).

## Tipologia de xarxa

* `P2P`: **Peer to peer**, una xarxa entre iguals.

* `Client/Server`: Administració centralitzada.

## Organització

* `workgroup`: Van al seu aire però pertanyen a un grup.

* `domini`: Pertanyen a un domini que ha de donar autorització.

//server/recurs -> Es denomina UNC (únic)

`$` al final del recurs indica que és un recurs **ocult**.

## Linux amb Samba

* `Client de samba`: per conectar a un servidor samba windows.

* `Servidor samba`: per compartir un recurs.

* Pot fer de controlador de domini.

## Ordres Samba

* `testparm`: Test de configuració de samba, ens permet veure què estem compartint.

* `smbtree`: Funciona per **broadcast** i mostra els equips que estàn compartint a la xarxa.

```bash
smbtree
# Veure el domini
smbtree -D
# Veure el server
smbtree -S
```

* `smbclient`: És la ordre client que fem servir per conectar a un recurs.

```bash
# Conectar al recurs manpages (per defecte conectem amb l'user actual)
smbclient //samba/manpages
# Conectar amb user anònim
smbclient -N //samba/manpages
# Conectem amb l'user ramon (ens demanarà password)
smbclient //samba/manpages -U ramon
# Conectem amb l'user ramon especificant la password després de %
smbclient //samba/manpages -U ramon%tururu
# Debug amb rang de 1-9
smbclient -d1 //samba/public
# Un cop conectats podem pujar/baixar entre altres ordres
smb: \> get file nounom
smb: \> put file nounom
```

* `smbget`: Descarrega directament el que volem, similar a `wget`.

```bash
smbget smb://samba/documentation/xz/file
# Podem especificar copiar una carpeta de forma recursiva
smbget -R smb://samba/documentation/
```

* `nmblookup`: Mostra el estat del servidor

```bash
# Per IP
nmblookup -A 172.18.0.2
# Per nom de server
nmblookup -S samba
```

* `smbclient` i `smbget` fan resolució per `nmb`.

* `mount`, al contrari, fa servir el `dns`. Degut que són diferents no sabrà fer la resolució de nom. Per això, o fem servir la IP del servidor o editem `/etc/hosts`. Hem d'especificar el tipus `-t` i l'user `-o`.

```bash
mount -t cifs -o guest //172.18.0.2/public /mnt
```

## Accés gràfic

També podem accedir, des de l'explorador d'arxius, a un recurs.

```bash
smb://samba/public
```

## Recursos del servidor samba

* `/etc/samba/lmhosts` equival a `/etc/hosts`

* `/etc/samba/smb.conf` és la configuració de samba.

## Usuaris

Samba té els **seus propis** usuaris, però es recolza amb usuaris unixs **existents**.

```bash
useradd lila # En cas de que no estigui ja creat
smbpasswd -a lila # Afegim l'user a samba
```

* `pdbedit`: Edita o llista els usuaris samba

```bash
# Llista els usuaris de samba
pdbedit -L
    lila:1003:
    roc:1005:
    patipla:1004:
    pla:1006:
```

## Configuració del servidor samba

El fitxer de configuració de samba es troba a `/etc/samba/smb.conf/` i és on es defineixen els shares, recursos compartits i configuració global.

* Per defecte sortirem com samba, si volem canviar el nom del servidor ho fem amb la directiva `netbios name`. Aixi, `netbios name = marc`, el nostre servidor es dirà *marc*.

### Estructura dels recursos

Els recursos s'especifiquen entre [] i a sota les opcions que necessiti/volguem

```bash
[public]
        comment = Share de contingut public
        path = /var/lib/samba/public
        public = yes
        browseable = yes
        writable = yes
        guest ok = yes
```

### Opcions dels shares

Tenim les següents opcions:

```bash
path = /dir1/dir2/share # La direcció del que compartim
comment = share description # Comentari del que compartim
volume = share name
browseable = yes/no # Si ho mostrem o no quan fem un smbtree
max connections = num # Nombre màxim de connexions que admetem
public = yes/no # Si permetem que sigui public o no, és a dir, tant anònims com users o sol users.
guest ok = yes/no # Si permetem l'accés a anònim. És equivalent a public
guest account = unix-useraccount # El compte d'anònim
guest only = yes/no # Si permetem que NOMÉS hi pugui accedir guest
valid users = user1 user2 @group1 @group2 ... # Users vàlids. Poden ser user específics o grups
invalid users = user1 user2 @group1 @group2 ... # Users invàlids
auto services = user1 user2 @group1 @group2 ...
admin users = user1 user2 @group1 @group2 ... # Té permisos per escriure com a root
writable = yes/no # Si es pot escriure o no. És equivalent al contrari de read only
read only = yes/no # Si és només lectura o no. És equivalent al contrari de writable
write list = user1 user2 @group1 @group2 ... # Users vàlids per escriure
read list = user1 user2 @group1 @group2 ... # Users vàlids per llegir el directori
create mode = 0660 # Si creem algún fitxer, es crearà amb aquests permisos
directory mode = 0770 # Si creem algún directori, es crearà amb aquests permisos
```

### Permisos

#### Accés anònim

`guest ok = yes` és equivalent a `public = yes` i permet l'accés al user anònim guest, que al sistema linux es transforma com a `nobody`.

Si ambes opcions es troben especificades, prevaleix la última que llegeix.

```bash
[public]
        comment = Share de contingut public
        path = /var/lib/samba/public
        public = yes
        browseable = yes
        writable = yes
        guest ok = yes
```

#### Sol anònim

`guest only = yes` permet únicament l'accés a usuaris anònims. Si intentem accedir com un altre user automàticament farà un mapping a l'usuari anònim.

```bash
[public]
        comment = Share de contingut public
        path = /var/lib/samba/public
        public = yes
        browseable = yes
        writable = yes
        guest only = yes
```

#### Llista d'usuaris vàlids

`valid users = user1 user2 @grup1 @grup2` permet l'accés al recurs als usuaris especificats a la llista. Anònim tampoc podrà accedir tot i que estigui indicat al `guesto ok = yes`.

```bash
[public]
        comment = Share de contingut public
        path = /var/lib/samba/public
        public = yes
        browseable = yes
        writable = yes
        guest ok = yes
        valid users = lila patipla
```

#### Llista d'usuaris restringits

`invalid users = user1 user2 userN` indica els usuaris que **NO** poden accedir al recurs. Anònim dependrà de `guest ok`.

```bash
[public]
        comment = Share de contingut public
        path = /var/lib/samba/public
        public = yes
        browseable = yes
        writable = yes
        guest ok = yes
        invalid users = lila patipla
```

#### Admin

`admin users = user` permet definir usuaris que seràn convertits al sistema com a root. És a dir, l'user samba tindrà permisos com a root al sistema.

```bash
[public]
      comment = Share de contingut public
      path = /var/lib/samba/public
      writable = yes
      guest ok = yes
      admin users = lila
```

### Escriptura i lectura

`read only` i `writeable` són equivalents al contrari. És a dir, el *yes* d'un equival al *no* de l'altre.

En el cas de que ambes estiguin especificades, prevaleix la última que llegeix.

#### Sol lectura

`read only = yes` o `writeable = no` són equivalents. Ambes opcions volen dir que sol es pot llegir.

```bash
[public]
        comment = Share de contingut public
        path = /var/lib/samba/public
        public = yes
        browseable = yes
        writable = no
        guest ok = yes
```

#### Lectura i escriptura

`read only = no` o `writable = yes` són equivalents.

```bash
[public]
        comment = Share de contingut public
        path = /var/lib/samba/public
        public = yes
        browseable = yes
        read only = no
        guest ok = yes
```

#### Llista d'usuaris de lectura

`read list = user1 user2...` llista d'usuaris que **sol** poden llegir. És a dir, els usuaris que es trobin aquí **només** podràn llegir.

```bash
[public]
        comment = Share de contingut public
        path = /var/lib/samba/public
        public = yes
        browseable = yes
        writable = yes
        read list = rock
        guest ok = yes
```

#### Llista d'usuaris d'escriptura

`write list = user1...` llista d'usuaris que podràn escriure en el recurs. S'utilitza en recursos que són sol de lectura.

```bash
[public]
        comment = Share de contingut public
        path = /var/lib/samba/public
        public = yes
        browseable = yes
        writable = no
        write list = rock
        guest ok = yes
```

#### Modes de creació de directoris i fitxers

`create mask = 0600` fa referència a la creació de fitxers, que es crearàn amb aquests permisos.

`directory mask = 0700` fa referència a la creació de directoris, que es crearà amb aquests permisos.

```bash
[public]
        comment = Share de contingut public
        path = /var/lib/samba/public
        public = yes
        browseable = yes
        read only = no
        guest ok = yes
        create mask = 0600
        directory mask = 0700
```

### Homes

Per defecte a la configuració del samba ja ve un share per la exportació del home dels usuaris.

```bash
smbclient //samba/lila -U lila%lila
#
```
