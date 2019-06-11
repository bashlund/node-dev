GET_IP()
{
    SPACE_SIGNATURE="name"

    local name="${1}"
    shift

    docker inspect "${name}" --format '{{ .NetworkSettings.IPAddress }}'
}

RUN()
{
    SPACE_SIGNATURE="image name"

    local image="${1}"
    shift

    local name="${1}"
    shift

    docker run -d -w /home/node/project --restart=always -v ${PWD}:/home/node/project --name "${name}" "${image}" tail -f /dev/null
}

EXEC()
{
    SPACE_SIGNATURE="image name [cmd]"

    local image="${1}"
    shift

    local name="${1}"
    shift

    #local cmd="$@"

    local id=$(id -u)
    eval docker exec -u $id -ti "${name}" "$@"
}
