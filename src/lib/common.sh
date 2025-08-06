#!/hint/bash

[[ -z ${DEVTOOLS_INCLUDE_COMMON_SH:-} ]] || return 0
DEVTOOLS_INCLUDE_COMMON_SH="$(set +o|grep nounset)"

set +u +o posix
# shellcheck disable=1091
. /usr/share/makepkg/util.sh
$DEVTOOLS_INCLUDE_COMMON_SH

# check if messages are to be printed using color
if [[ -t 2 && "$TERM" != dumb ]] || [[ ${DEVTOOLS_COLOR} == always ]]; then
	colorize
	if tput setaf 0 &>/dev/null; then
		PURPLE="$(tput setaf 5)"
		DARK_GREEN="$(tput setaf 2)"
		DARK_RED="$(tput setaf 1)"
		DARK_BLUE="$(tput setaf 4)"
		DARK_YELLOW="$(tput setaf 3)"
		UNDERLINE="$(tput smul)"
		GRAY=$(tput setaf 242)
	else
		PURPLE="\e[35m"
		DARK_GREEN="\e[32m"
		DARK_RED="\e[31m"
		DARK_BLUE="\e[34m"
		DARK_YELLOW="\e[33m"
		UNDERLINE="\e[4m"
		GRAY=""
	fi
else
	# shellcheck disable=2034
	declare -gr ALL_OFF='' BOLD='' BLUE='' GREEN='' RED='' YELLOW='' PURPLE='' DARK_RED='' DARK_GREEN='' DARK_BLUE='' DARK_YELLOW='' UNDERLINE='' GRAY=''
fi

stat_busy() {
	local mesg=$1; shift
	# shellcheck disable=2059
	printf "${GREEN}==>${ALL_OFF}${BOLD} ${mesg}...${ALL_OFF}" "$@" >&2
}

stat_progress() {
	# shellcheck disable=2059
	printf "${BOLD}.${ALL_OFF}" >&2
}

stat_done() {
	# shellcheck disable=2059
	printf "${BOLD}done${ALL_OFF}\n" >&2
}

stat_failed() {
	# shellcheck disable=2059
	printf "${BOLD}${RED}failed${ALL_OFF}\n" >&2
}

msg_success() {
	local msg=$1
	local padding
	padding=$(echo "${msg}"|sed -E 's/( *).*/\1/')
	msg=$(echo "${msg}"|sed -E 's/ *(.*)/\1/')
	printf "%s %s\n" "${padding}${GREEN}✓${ALL_OFF}" "${msg}" >&2
}

msg_error() {
	local msg=$1
	local padding
	padding=$(echo "${msg}"|sed -E 's/( *).*/\1/')
	msg=$(echo "${msg}"|sed -E 's/ *(.*)/\1/')
	printf "%s %s\n" "${padding}${RED}x${ALL_OFF}" "${msg}" >&2
}

msg_warn() {
	local msg=$1
	local padding
	padding=$(echo "${msg}"|sed -E 's/( *).*/\1/')
	msg=$(echo "${msg}"|sed -E 's/ *(.*)/\1/')
	printf "%s %s\n" "${padding}${YELLOW}!${ALL_OFF}" "${msg}" >&2
}

print_workdir_error() {
	if [[ ! -f "${WORKDIR}"/error ]]; then
		return
	fi
	while read -r LINE; do
		error '%s' "${LINE}"
	done < "${WORKDIR}/error"
}

_setup_workdir=false
# Ensure that there is no outside value for WORKDIR leaking in
unset WORKDIR
setup_workdir() {
	[[ -z ${WORKDIR:-} ]] && WORKDIR=$(mktemp -d --tmpdir "${0##*/}.XXXXXXXXXX")
	_setup_workdir=true
	trap 'trap_abort' INT QUIT TERM HUP
	trap 'trap_exit' EXIT
}

cleanup() {
	if [[ -n ${WORKDIR:-} ]] && $_setup_workdir; then
		rm -rf "$WORKDIR"
	fi
	if tput setaf 0 &>/dev/null; then
		tput cnorm >&2
	fi
	exit "${1:-0}"
}

abort() {
	error 'Aborting...'
	cleanup 255
}

trap_abort() {
	trap - EXIT INT QUIT TERM HUP
	abort
}

trap_exit() {
	local r=$?
	trap - EXIT INT QUIT TERM HUP
	cleanup $r
}

die() {
	(( $# )) && error "$@"
	cleanup 255
}
