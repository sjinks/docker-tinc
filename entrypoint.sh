#!/bin/sh

: "${NETWORK_NAME:?"NETWORK_NAME environment variable is not set"}"

if [ ! -d "/etc/tinc/${NETWORK_NAME}" ]; then
    : "${NETWORK_ADDRESS:?"NETWORK_ADDRESS environment variable is not set"}"

    if [ -n "${SERVER:-}" ]; then
        /usr/sbin/tinc -n "${NETWORK_NAME}" init "${NODE_NAME:-$(hostname)}"
        cat > "/etc/tinc/${NETWORK_NAME}/invitation-created" <<'EOF'
#!/bin/sh

cat > "${INVITATION_FILE}" <<EOT
Name = ${NODE}
Netname = ${NETNAME}
ConnectTo = ${NAME}
#----------------#
EOT
/usr/sbin/tinc export-all >> "${INVITATION_FILE}"
EOF
        chmod +x "/etc/tinc/${NETWORK_NAME}/invitation-created"
    elif [ -n "${INVITE_URL:-}" ]; then
        /usr/sbin/tinc join "${INVITE_URL}"
    fi

    /usr/sbin/tinc -n "${NETWORK_NAME}" add subnet "${NETWORK_ADDRESS}"
    if [ -d "/etc/tinc/${NETWORK_NAME}" ]; then
        cat > "/etc/tinc/${NETWORK_NAME}/tinc-up" <<EOF
#!/bin/sh

/sbin/ip addr add ${NETWORK_ADDRESS}/${NETWORK_PREFIX:-24} dev \$INTERFACE
/sbin/ip link set \$INTERFACE up
EOF

        cat > "/etc/tinc/${NETWORK_NAME}/tinc-down" <<EOF
#!/bin/sh

/sbin/ip link set \$INTERFACE down
/sbin/ip addr del ${NETWORK_ADDRESS}/${NETWORK_PREFIX:-24} dev \$INTERFACE
EOF

        chmod +x "/etc/tinc/${NETWORK_NAME}/tinc-up" "/etc/tinc/${NETWORK_NAME}/tinc-down"
    fi
fi

exec /usr/sbin/tinc -n "${NETWORK_NAME}" "$@"
