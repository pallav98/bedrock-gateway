#!/bin/bash

DOCKER_SOCK="/var/run/docker.sock"
EXPECTED_GROUP="video"

CURRENT_GROUP=$(stat -c "%G" "$DOCKER_SOCK")

if [ "$CURRENT_GROUP" != "$EXPECTED_GROUP" ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Fixing permission of docker.sock" >> /var/log/fix_docker_sock.log
    chown root:"$EXPECTED_GROUP" "$DOCKER_SOCK"
    chmod 660 "$DOCKER_SOCK"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Changed group to $EXPECTED_GROUP" >> /var/log/fix_docker_sock.log
else
    echo "$(date '+%Y-%m-%d %H:%M:%S') - No changes needed, group is already $EXPECTED_GROUP" >> /var/log/fix_docker_sock.log
fi
