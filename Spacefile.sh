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
    SPACE_SIGNATURE="name [cmd]"

    local name="${1}"
    shift

    local id=$(id -u)
    eval docker exec -u $id -ti "${name}" "$@"
}

EXEC_ROOT()
{
    SPACE_SIGNATURE="name [cmd]"

    local name="${1}"
    shift

    eval docker exec -ti "${name}" "$@"
}

SHORTCUT()
{
    SPACE_SIGNATURE="image name shell [cmd] [args]"
    SPACE_DEP="RUN EXEC EXEC_ROOT GET_IP DOCKER_EXIST PRINT"

    local image="${1}"
    shift

    local name="${1}"
    shift

    local shell="${1}"
    shift

    local cmd="${1:-enter}"
    shift $(($# > 0 ? 1: 0))

    local args="$*"

    DOCKER_EXIST "${name}"
    local is_running="$?"

    echo $is_running
    if [ "${cmd}" = "enter" ]; then
        [ "${is_running}" -gt 0 ] && {
            echo is not running
            RUN "${image}" "${name}" || { PRINT "Could not run container." "error"; return 1; }
        }
        EXEC "${name}" "${shell}"
    elif [ "${cmd}" = "root" ]; then
        [ "${is_running}" -gt 0 ] && {
            RUN "${image}" "${name}" || { PRINT "Could not run container." "error"; return 1; }
        }
        EXEC_ROOT "${name}" "${shell}"
    elif [ "${cmd}" = "rm" ]; then
        docker rm -f "${name}"
    elif [ "${cmd}" = "exec" ]; then
        EXEC "${name}" "${args}"
    elif [ "${cmd}" = "ip" ]; then
        GET_IP "${name}"
    else
        PRINT "Unknown command." "error"
        return 1
    fi
}
