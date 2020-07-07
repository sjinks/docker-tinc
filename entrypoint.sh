#!/bin/sh

if [ ! -d /etc/tinc/vpn ]; then
    if [ -z "${NETWORK_ADDRESS}" ]; then
        echo Please set NETWORK_ADDRESS environment variable
        exit 1
    fi

    if [ -n "${SERVER}" ]; then
        /usr/sbin/tinc -n vpn init "${NODE_NAME:-$(hostname)}"
        cat > /etc/tinc/vpn/invitation-created <<'EOF'
#!/bin/sh

cat > $INVITATION_FILE <<EOT
Name = $NODE
Netname = $NETNAME
ConnectTo = $NAME
#----------------#
EOT
/usr/sbin/tinc export-all >> $INVITATION_FILE
EOF
        chmod +x /etc/tinc/vpn/invitation-created
    elif [ -n "${INVITE_URL}" ]; then
        /usr/sbin/tinc join "${INVITE_URL}"
    fi

    /usr/sbin/tinc -n vpn add subnet ${NETWORK_ADDRESS}
    if [ -d /etc/tinc/vpn ]; then
        cat > /etc/tinc/vpn/tinc-up <<EOF
#!/bin/sh

/sbin/ip addr add ${NETWORK_ADDRESS}/${NETWORK_MASK:-24} dev \$INTERFACE
/sbin/ip link set \$INTERFACE up
EOF

        cat > /etc/tinc/vpn/tinc-down <<EOF
#!/bin/sh

/sbin/ip link set \$INTERFACE down
/sbin/ip addr del ${NETWORK_ADDRESS}/${NETWORK_MASK:-24} dev \$INTERFACE
EOF

        chmod +x /etc/tinc/vpn/tinc-up /etc/tinc/vpn/tinc-down
    fi
fi

exec /usr/sbin/tinc $@
