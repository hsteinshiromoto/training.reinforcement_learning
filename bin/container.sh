#!/usr/bin/env bash

# ---
# Functions
# ---

# Documentation
display_help() {
    echo "Usage: [variable=value] $0" >&2
    echo
    echo "   -d, --deploy               deploy container"
    echo "   -h, --help                 display help"
    echo "   -j, --jupyter_notebook     launch container with jupyter notebook"
    echo
    # echo some stuff here for the -a or --add-options
    exit 1
}

# Start jupyter server
jupyter() {
    echo "Starting Jupyter Notebook"
    make_variables

    # Use existing jupyter images instead of creating new
    DOCKER_IMAGE=jupyter/scipy-notebook
    DOCKER_USER=jovyan
    DOCKER_IMAGE_TAG=${DOCKER_IMAGE}:latest

    # Check if the container has existed and remove it
    EXITED_ID=$(docker ps -aqf "name=${PROJECT_NAME}" -f "status=exited" | awk '{ print $1}')

    if [[ -n "${EXITED_ID}" ]]; then
        docker rm ${EXITED_ID}

    else
        CONTAINER_ID=$(docker ps -aqf "name=${PROJECT_NAME}" | awk '{ print $1}')

    fi

    # Run new container and install the requirements
    if [[ -z "${CONTAINER_ID}" ]]; then
      echo "Creating Container from image ${DOCKER_IMAGE_TAG} ..."
      docker run --name ${PROJECT_NAME} -d -P -v $(pwd):/home/${DOCKER_USER}/work -t ${DOCKER_IMAGE_TAG} $1 >/dev/null >&1
      CONTAINER_ID=$(docker ps -aqf "name=${PROJECT_NAME}" | awk '{ print $1}')

      echo "Installing requirements"
     
      docker exec -u root -i ${CONTAINER_ID} /bin/bash -c "cp /home/${DOCKER_USER}/work/bin/setup.py /usr/local/bin"
      docker exec -u root -i ${CONTAINER_ID} /bin/bash -c "cp /home/${DOCKER_USER}/work/requirements.txt /usr/local/requirements.txt"
      docker exec -u root -i ${CONTAINER_ID} /bin/bash -c "bash /home/${DOCKER_USER}/work/bin/run_python.sh requirements"
      docker exec -u root -i ${CONTAINER_ID} /bin/bash -c "bash /home/${DOCKER_USER}/work/bin/run_python.sh jupyter_extensions"

      sleep 5

    else
      echo "Container already running"

    fi

	  JUPYTER_PORT=$(docker ps -f "name=${PROJECT_NAME}" | grep -o "0.0.0.0:[0-9]*->8888" | cut -d ":" -f 2 | head -n 1)

    echo -e "Container ID: ${BLUE}${CONTAINER_ID}${NC}"

    echo -e "Port mapping: ${JUPYTER_PORT}"

    JUPYTER_TOKEN=$(docker exec -u ${DOCKER_USER} -i ${CONTAINER_ID} sh -c "jupyter notebook list" | tac | grep -o "token=[a-z0-9]*" | sed -n 1p | cut -d "=" -f 2)
    echo -e "Jupyter token: ${GREEN}${JUPYTER_TOKEN}${NC}"

    JUPYTER_ADDRESS=$(docker ps | grep ${DOCKER_IMAGE_TAG} | grep -o "0.0.0.0:[0-9]*")
    echo -e "Jupyter Address: ${BLUE}http://${JUPYTER_ADDRESS}/?token=${JUPYTER_TOKEN}${NC}"

}

# Get container id
get_container_id() {
    echo "Getting container id for image ${DOCKER_IMAGE_TAG} ..."

    CONTAINER_ID=$(docker ps | grep "${DOCKER_IMAGE_TAG}" | awk '{ print $1}')

    if [[ -z "${CONTAINER_ID}" ]]; then
        echo "No container id found"

    else
        echo "Container id: ${bold}${CONTAINER_ID}${normal}"

    fi
}

# Get container id
deploy_container() {
    make_variables

    echo "Pushing image ${DOCKER_IMAGE_TAG}"
    docker push ${DOCKER_IMAGE_TAG}
}

registry_login() {
    # Todo: Not working. Need to fix this!
    make_variables
    GITHUB_PAT=$(cat .env | grep GITHUB_PAT | awk -F'=' '{print $2}') 
    echo ${DOCKER_REGISTRY}
    echo ${REGISTRY_USER}
    $(echo ${GITHUB_PAT} | docker login ${DOCKER_REGISTRY} -u ${REGISTRY_USER} --password-stdin)
}

make_variables() {
    # Get Variables From make_variables.sh
    # IFS='|| ' read -r -a array <<< $(./make_variables.sh)

    set -a # automatically export all variables
    source .env
    set +a

    # Check if variable is defined in .env file
    if [[ -z ${REGISTRY_USER} ]]; then
      echo "Error! Variable REGISTRY_USER is not defined" 1>&2
      exit 1

    fi

    PROJECT_ROOT=$(pwd)
    PROJECT_NAME=$(basename ${PROJECT_ROOT})

    REGISTRY_USER=${REGISTRY_USER}
    DOCKER_REGISTRY=docker.pkg.github.com
    DOCKER_IMAGE_NAME=${PROJECT_NAME}
    DOCKER_IMAGE=${DOCKER_REGISTRY}/${REGISTRY_USER}/${PROJECT_NAME}/${DOCKER_IMAGE_NAME}
    DOCKER_TAG=${DOCKER_TAG:-latest}
    DOCKER_IMAGE_TAG=${DOCKER_IMAGE}:${DOCKER_TAG}

    RED="\033[1;31m"
    BLUE='\033[1;34m'
    GREEN='\033[1;32m'
    NC='\033[0m'
    bold=$(tput bold)
    normal=$(tput sgr0)
}

run_container() {

    make_variables
    get_container_id

    if [[ -z "${CONTAINER_ID}" ]]; then
        echo "Creating Container from image ${DOCKER_IMAGE_TAG} ..."

        docker run --rm --env-file .env -e DOCKER_USER=$USER -e uid=$UID -d -P -v $(pwd):/home/${PROJECT_NAME} -t ${DOCKER_IMAGE_TAG} $1 >/dev/null >&1

        echo "Done"

    else
	    echo "Container already running"
	fi

}

# Available options
while :
do
    case "$1" in
      -h | --help)
          display_help  # Call your function
          exit 0
          ;;

      -j | --jupyter_notebook)
          jupyter  # Call your function
          break
          ;;

      -d | --deploy)
          deploy_container  # Call your function
          break
          ;;

      -r | --run)
          run_container  # Call your function
          break
          ;;

      -s | --ssh)
          run_ssh_container  # Call your function
          break
          ;;

      "")
          display_help  # Call your function
          break
          ;;

      --) # End of all options
          shift
          break
          ;;
      -*)
          echo "Error: Unknown option: $1" >&2
          ## or call function display_help
          exit 1
          ;;
      *)  # No more options
          break
          ;;
    esac
done


#port2=$(docker ps -f "ancestor=${docker_image}" | grep -o "0.0.0.0:[0-9]*->[0-9]*" | cut -d ":" -f 2 | sed -n 2p)




