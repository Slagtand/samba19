for user in local1 local2 local3
do
    useradd $user
    echo -e "$user" | passwd --stdin $user
done