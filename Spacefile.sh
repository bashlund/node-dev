GET_IP()
{
    SPACE_SIGNATURE="name"

    local name="${1}"
    shift

    docker inspect "${name}" --format '{{ .NetworkSettings.IPAddress }}'
}

RUN()
{
    SPACE_SIGNATURE="image name [dir]"
    SPACE_DEP="DOCKER_EXIST"

    local image="${1}"
    shift

    local name="${1}"
    shift

    local dir="${1:-${PWD}}"
    shift

    DOCKER_EXIST "${name}"
    local is_running="$?"

    if [ "${is_running}" -eq 0 ]; then
        return
    fi

    docker run -d -w /home/node/project --restart=always -v ${dir}:/home/node/project --name "${name}" "${image}" tail -f /dev/null
}

NPM()
{
    SPACE_SIGNATURE="image dir [cmds]"
    SPACE_DEP="RUN VIM_FORMAT"

    local image="${1}"
    shift

    local dir="${1}"
    shift

    # Find out the container name
    local name=
    local olddir=
    while [ -n "${dir}" ] && [ "${olddir}" != "${dir}" ]; do
        if [ -f "${dir}/package.json" ]; then
            name="${dir##*/}"
            break;
        fi
        olddir="${dir}"
        dir="${dir%/*}"
    done

    if [ -z "${name}" ]; then
        printf "%s\\n" "Could not detect package.json" >&2
        return 1
    fi

    RUN "${image}" "${name}" "${dir}" >/dev/null

    local id=$(id -u)
    eval docker exec -u $id -i "${name}" "$@" 2>/dev/null | VIM_FORMAT
}

VIM_FORMAT()
{
    SPACE_DEP="VIM_FORMAT_LINE"

    local IFS=""
    local line=
    while read line; do
        VIM_FORMAT_LINE "${line}"
    done
}

VIM_FORMAT_LINE()
{
    if [ "${1#[ ]}" != "${1}" ]; then
        return
    fi

    local filename="${1%%(*}"
    if [ "${filename}" == "${1}" ]; then
        return
    fi
    local row="${1#*(}"
    row="${row%%,*}"
    local col="${1%%)*}"
    col="${col##*,}"
    local error="${1#*)}"

    printf "%s:%s:%s:%s\\n" "${filename}" "${row}" "${col}" "${error}"
}

EXEC()
{
    SPACE_SIGNATURE="name [cmds]"

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

    if [ "${cmd}" = "enter" ]; then
        [ "${is_running}" -gt 0 ] && {
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
