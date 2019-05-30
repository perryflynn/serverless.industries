#!/bin/bash

set -x

ssh ${sshopts} ${sshremote} stat ${remotedir}/.htaccess \> /dev/null 2\>\&1
issecured=$?
stageuser="stage"
stagepass="$(pwgen -s 12 1)"

if [ "$secure" == "1" ] && ( [ ! "$issecured" == "0" ] || [ -f enforce-new-password ] )
then

    htpasswd -b -c newhtpasswd "$stageuser" "$stagepass"
    scp ${sshopts} newhtpasswd ${sshremote}:${remotedir}/.htpasswd
    rm newhtpasswd

    cat >newhtaccess <<HTEOL
AuthType Basic
AuthName "Stage ${CI_COMMIT_REF_SLUG}"
AuthUserFile ${remotedir}/.htpasswd
Require valid-user
HTEOL

    scp ${sshopts} newhtaccess ${sshremote}:${remotedir}/.htaccess
    rm newhtaccess

    echo
    echo
    echo "New Username: $stageuser"
    echo "New Password: $stagepass"
    echo
    echo

elif [ "$secure" == "1" ]
then

    echo
    echo
    echo "Credencials already set. Create a 'enforce-new-password' to override."
    echo
    echo

fi

# EOF