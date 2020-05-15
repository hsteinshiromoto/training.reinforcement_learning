#!/bin/bash
set -e

# If "-e uid={custom/local user id}" flag is not set for "docker run" command, use 9999 as default
CURRENT_UID=${uid:-9999}

# If "-e docker_user={custom/local user id}" flag is not set for "docker run" command, use docker_user as default
CONTAINER_USERNAME=${DOCKER_USER:-"docker_user"}

# Create user called "docker" with selected UID
useradd --shell /bin/bash -p $(openssl passwd -1 $CONTAINER_PASSWORD) -u $CURRENT_UID --no-create-home $CONTAINER_USERNAME

# Start SSH Server
service ssh start

# Execute process
exec gosu $CONTAINER_USERNAME "$@"