#!/bin/sh
mkdir -p /etc/nginx/certs
if [ ! -f /etc/nginx/certs/server.key ]; then
    echo "Generating self-signed certificate..."
    apk add --no-cache openssl
    openssl req -x509 -nodes -days 3650 -newkey rsa:2048 \
    -keyout /etc/nginx/certs/server.key \
    -out /etc/nginx/certs/server.crt \
    -subj "/C=DE/ST=Berlin/L=Berlin/O=LemueSec/CN=sec.lemue.org"
fi
exec nginx -g "daemon off;"
