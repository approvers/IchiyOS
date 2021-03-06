#!/usr/bin/env bash

script_path="$(readlink -f ${0%/*})"

channnels=(
    "xfce"
    "lxde"
)

architectures=(
    "x86_64"
    "i686"
)

work_dir=fullbuild.ignore.work

retry=5


# Color echo
# usage: echo_color -b <backcolor> -t <textcolor> -d <decoration> [Text]
#
# Text Color
# 30 => Black
# 31 => Red
# 32 => Green
# 33 => Yellow
# 34 => Blue
# 35 => Magenta
# 36 => Cyan
# 37 => White
#
# Background color
# 40 => Black
# 41 => Red
# 42 => Green
# 43 => Yellow
# 44 => Blue
# 45 => Magenta
# 46 => Cyan
# 47 => White
#
# Text decoration
# You can specify multiple decorations with ;.
# 0 => All attributs off (ノーマル)
# 1 => Bold on (太字)
# 4 => Underscore (下線)
# 5 => Blink on (点滅)
# 7 => Reverse video on (色反転)
# 8 => Concealed on

echo_color() {
    local backcolor
    local textcolor
    local decotypes
    local echo_opts
    local arg
    local OPTIND
    local OPT

    echo_opts="-e"

    while getopts 'b:t:d:n' arg; do
        case "${arg}" in
            b) backcolor="${OPTARG}" ;;
            t) textcolor="${OPTARG}" ;;
            d) decotypes="${OPTARG}" ;;
            n) echo_opts="-n -e"     ;;
        esac
    done

    shift $((OPTIND - 1))

    echo ${echo_opts} "\e[$([[ -v backcolor ]] && echo -n "${backcolor}"; [[ -v textcolor ]] && echo -n ";${textcolor}"; [[ -v decotypes ]] && echo -n ";${decotypes}")m${@}\e[m"
}


# Show an INFO message
# $1: message string
_msg_info() {
    local echo_opts="-e"
    local arg
    local OPTIND
    local OPT
    while getopts 'n' arg; do
        case "${arg}" in
            n) echo_opts="${echo_opts} -n" ;;
        esac
    done
    shift $((OPTIND - 1))
    echo ${echo_opts} "$( echo_color -t '36' '[fullbuild.sh]')    $( echo_color -t '32' 'Info') ${@}"
}


# Show an Warning message
# $1: message string
_msg_warn() {
    local echo_opts="-e"
    local arg
    local OPTIND
    local OPT
    while getopts 'n' arg; do
        case "${arg}" in
            n) echo_opts="${echo_opts} -n" ;;
        esac
    done
    shift $((OPTIND - 1))
    echo ${echo_opts} "$( echo_color -t '36' '[fullbuild.sh]') $( echo_color -t '33' 'Warning') ${@}" >&2
}


# Show an debug message
# $1: message string
_msg_debug() {
    local echo_opts="-e"
    local arg
    local OPTIND
    local OPT
    while getopts 'n' arg; do
        case "${arg}" in
            n) echo_opts="${echo_opts} -n" ;;
        esac
    done
    shift $((OPTIND - 1))
    if [[ ${debug} = true ]]; then
        echo ${echo_opts} "$( echo_color -t '36' '[fullbuild.sh]')   $( echo_color -t '35' 'Debug') ${@}"
    fi
}


# Show an ERROR message then exit with status
# $1: message string
# $2: exit code number (with 0 does not exit)
_msg_error() {
    local echo_opts="-e"
    local arg
    local OPTIND
    local OPT
    local OPTARG
    while getopts 'n' arg; do
        case "${arg}" in
            n) echo_opts="${echo_opts} -n" ;;
        esac
    done
    shift $((OPTIND - 1))
    echo ${echo_opts} "$( echo_color -t '36' '[fullbuild.sh]')   $( echo_color -t '31' 'Error') ${1}" >&2
    if [[ -n "${2:-}" ]]; then
        exit ${2}
    fi
}


if [[ ! -d "${work_dir}" ]]; then
    mkdir -p "${work_dir}"
fi

trap_exit() {
    local status=${?}
    echo
    _msg_error "fullbuild.sh has been killed by the user."
    exit ${status}
}

trap 'trap_exit' 1 2 3 15

build() {
    options="-b --gitversion --noconfirm -l -a ${arch} ${cha}"

    if [[ ! -e "${work_dir}/fullbuild.${cha}_${arch}" ]]; then
        _msg_info "Build ${cha} with ${arch} architecture."
        sudo bash ${script_path}/build.sh ${options}
        touch "${work_dir}/fullbuild.${cha}_${arch}"
    fi
    sudo pacman -Sccc --noconfirm > /dev/null 2>&1

    if [[ ! -e "${work_dir}/fullbuild.${cha}_${arch}_jp" ]]; then
        _msg_info "Build the Japanese version of ${cha} on the ${arch} architecture."
        sudo bash ${script_path}/build.sh -j ${options}
        touch "${work_dir}/fullbuild.${cha}_${arch}_jp"
    fi
    sudo pacman -Sccc --noconfirm > /dev/null 2>&1
}


for cha in ${channnels[@]}; do
    for arch in ${architectures[@]}; do
        for i in $(seq 1 ${retry}); do
            build
        done
    done
done


_msg_info "All editions have been built"
