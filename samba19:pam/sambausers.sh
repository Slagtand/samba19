for user in lila patipla roc pla
do
    useradd $user
    echo -e "$user\n$user" | smbpasswd -a $user
done