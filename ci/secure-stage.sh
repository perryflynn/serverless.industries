#!/bin/bash

#set -x

ssh ${sshopts} ${sshremote} stat ${remotedir}/.htpasswd \> /dev/null 2\>\&1
issecured=$?

echo
echo "<DEBUG BEGIN>"
echo
echo "sshopts = $sshopts"
echo "remotedir = $remotedir"
echo "issecured = $issecured"
echo "distname = $distname"
echo
echo "</DEBUG>"
echo

stageuser="stage"
stagepass="$(pwgen -s 12 1)"

# create htpasswd
if [ "$secure" == "1" ] && [ ! -f enforce-insecure ] && ( [ ! "$issecured" == "0" ] || [ -f enforce-new-password ] )
then

    htpasswd -b -c dist-${distname}/newhtpasswd "$stageuser" "$stagepass"
    #scp ${sshopts} newhtpasswd ${sshremote}:${remotedir}/.htpasswd
    #rm dist-${distname}/newhtpasswd

    echo
    echo
    echo "New Username: $stageuser"
    echo "New Password: $stagepass"
    echo
    echo "If you dont want a password protection, create a 'enforce-insecure' file"
    echo
    echo

elif [ -f enforce-insecure ]
then

    ssh ${sshopts} ${sshremote} rm -f ${remotedir}/.htpasswd

    echo
    echo "'enforce-insecure' file exists, so no password protection created."
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
if [ "$secure" == "1" ] && [ ! -f enforce-insecure ]
then

    cat <<HTEOL >> dist-${distname}/.htaccess

AuthType Basic
AuthName "Stage ${CI_COMMIT_REF_SLUG}"
AuthUserFile ${remotedir}/.htpasswd
Require valid-user
HTEOL

fi

# EOF