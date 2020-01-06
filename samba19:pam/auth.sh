#! /bin/bash
# @marcgc ASIX M06 2019-2020
# startup.sh
# -------------------------------------

authconfig --enableshadow --enablelocauthorize \
 --enableldap \
 --enableldapauth \
 --ldapserver='ldapserver' \
 --ldapbase='dc=edt,dc=org' \
 --enablemkhomedir \
 --updateall