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
    shift $(($# > 0 ? 1: 0))

    DOCKER_EXIST "${name}"
    local is_running="$?"

    if [ "${is_running}" -eq 0 ]; then
        return
    fi

    docker run -d -w /home/node/project --restart=always --sysctl net.ipv6.conf.all.disable_ipv6=1 -v ${dir}:/home/node/project --name "${name}" "${image}" tail -f /dev/null
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
    eval docker exec -u $id -i "${name}" "$@" 2>/dev/null | VIM_FORMAT "${dir}"
}

REFACTOR()
{
    SPACE_SIGNATURE="image dir [cmds]"
    SPACE_DEP="RUN VIM_FORMAT2"

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
    eval docker exec -u $id -i "${name}" "$@" 2>/dev/null | VIM_FORMAT2 "${dir}"
}

VIM_FORMAT2()
{
    SPACE_SIGNATURE="basedir"
    SPACE_DEP="VIM_FORMAT_LINE2"

    local baseDir="${1}"
    shift

    local IFS=""
    local line=
    while read line; do
        VIM_FORMAT_LINE2 "${baseDir}" "${line}"
    done
}

VIM_FORMAT_LINE2()
{
    SPACE_SIGNATURE="basedir line"

    local baseDir="${1}"
    shift

    local line="${1}"
    shift

    if [ "${line#[ ]}" != "${line}" ]; then
        return
    fi

    #if [ "${line#*TS2724:}" = "${line}" ]; then
        #return
    #fi

    local filename="${line%%(*}"
    if [ "${filename}" = "${line}" ]; then
        return
    fi
    local row="${line#*(}"
    row="${row%%,*}"
    local col="${line%%)*}"
    col="${col##*,}"
    local error="${line#*)}"

    printf "%s/%s %s %s\\n" "${baseDir}" "${filename}" "${row}" "${error}"
}

VIM_FORMAT()
{
    SPACE_SIGNATURE="basedir"
    SPACE_DEP="VIM_FORMAT_LINE"

    local baseDir="${1}"
    shift

    local IFS=""
    local line=
    while read line; do
        VIM_FORMAT_LINE "${baseDir}" "${line}"
    done
}

VIM_FORMAT_LINE()
{
    SPACE_SIGNATURE="basedir line"

    local baseDir="${1}"
    shift

    local line="${1}"
    shift

    if [ "${line#[ ]}" != "${line}" ]; then
        return
    fi

    local filename="${line%%(*}"
    if [ "${filename}" = "${line}" ]; then
        return
    fi
    local row="${line#*(}"
    row="${row%%,*}"
    local col="${line%%)*}"
    col="${col##*,}"
    local error="${line#*)}"

    printf "%s/%s:%s:%s:%s\\n" "${baseDir}" "${filename}" "${row}" "${col}" "${error}"
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
