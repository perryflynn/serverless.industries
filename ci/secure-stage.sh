#!/bin/bash

#set -x

ssh ${sshopts} ${sshremote} stat ${remotedir}/.htpasswd \> /dev/null 2\>\&1
issecured=$?

stageuser="stage"
stagepass="$(pwgen -s 12 1)"

# create htpasswd
if [ "$secure" == "1" ] && ( [ ! "$issecured" == "0" ] || [ -f enforce-new-password ] )
then

    htpasswd -b -c newhtpasswd "$stageuser" "$stagepass"
    scp ${sshopts} newhtpasswd ${sshremote}:${remotedir}/.htpasswd
    rm newhtpasswd

    echo
    echo
    echo "New Username: $stageuser"
    echo "New Password: $stagepass"
    echo
    echo

elif [ "$secure" == "1" ]
then

    echo
    echo "Credencials already set. Create a 'enforce-new-password' file to override."
    echo

else
    echo "No authentication required."
fi

# extend htaccess
if [ "$secure" == "1" ]
then

    cat <<HTEOL >> dist-${distname}/.htaccess

AuthType Basic
AuthName "Stage ${CI_COMMIT_REF_SLUG}"
AuthUserFile ${remotedir}/.htpasswd
Require valid-user
HTEOL

echo
echo

cat dist-${distname}/.htaccess

fi

# EOF