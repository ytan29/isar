#!/usr/bin/env sh

echo -n "SSH server is "
if systemctl is-enabled ssh; then
    SSHD_ENABLED="true"
    systemctl disable --no-reload ssh
fi

echo "Removing keys ..."
nhkeys=$( find /etc/ssh/ -iname "ssh_host_*key*" -printf '.' | wc -c )

if [ "${nhkeys}" -eq "0" ]; then
    echo "Regenerating keys ..."
    dpkg-reconfigure openssh-server
fi

if test -n $SSHD_ENABLED; then
    echo "Reenabling ssh server ..."
    systemctl enable --no-reload ssh
fi
