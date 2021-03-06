#!/bin/bash
################################################################
# Script: autoRun.sh
# Author: Hankai
# Date: 2018-04-26 09:22:12 AM
# Purpose: This script is used to config Centos7.3
################################################################

################################################################
################ Define some functions here ##################
################################################################
REMOTE_HOST_FILE="/home/local/etc/rdp_history"
TOOLBOX=/home/lambert/exchanges

function die_x()
{
	echo -e "\033[31m$*\033[0m"
	exit 255
}

function die()
{
	echo -e "\033[31mScript : ${FUNCNAME[*]} for:\033[0m $*"
	exit 255
}


function error()
{
	echo -e "\033[31m$*\033[0m"
}


function warn()
{
	echo -e "\033[33m$*\033[0m"
}


function note()
{
	echo -e "\033[36m$*\033[0m"
}


function info()
{
	echo -e "\033[32m$*\033[0m"
}


function check_dir()
{
	if [[ $# -gt 0 ]]
	then
		for X in "$@"
		do
			[[ -d ${X} ]] || die "${X} was not found!"
		done
	else
		die "check_dir(): Null param!"
	fi
}


function check_file()
{
	if [[ $# -gt 0 ]]
	then
		for X in "$@"
		do
			[[ -f ${X} ]] || die "${X} was not found!"
		done
	else
		die "check_file(): Null param!"
	fi
}


function check_exec()
{
	if [[ $# -gt 0 ]]
	then
		for X in "$@"
		do
			[[ -f ${X} ]] || die "${X} was not found!"
			[[ -x ${X} ]] || die "${X} was not executable!"
		done
	else
		die "check_exec(): Null param!"
	fi
}

function check_cmd() {
	[[ $# -eq 1 ]] || die "\"$*\" is more than 1 param!"
	command -v $1 >/dev/null || die "Command \"$1\" was not found in system!"
}

function check_root_privilege()
{
	# Compitable to sudo environment.
	[[ "X${USER}" == "Xroot" ]] || die "Current user is not root!"
	# Without practice
	#[[ $(id -u) -eq 0 ]] || die "Only user root is allowed to run this script!"
}


function do_xfreerdp() {
	command -v xfreerdp || return 255

	[[ -z $1 ]] && return 255
	HOST="$1"

	[[ -z $2 ]] && PORT='3389'

	OPTION_HOST="/v:${HOST}:${PORT}"
	OPTION_DOMAIN="/d:$3"
	OPTION_USER="/u:$4"
	OPTION_PASSWD="/p:$5"

	# Wayland
	#echo wlfreerdp /cert:tofu /drive:SHARE,"$(readlink -f "${HOME}")" +window-drag /w:1440 /h:900 /v:"$1" /d:"$2" /u:"$3" /p:"$4"
	#wlfreerdp -themes /disp /cert:tofu /drive:SHARE,"$(readlink -f "${HOME}")" +window-drag /w:1440 /h:900 /v:"$1" /d:"$2" /u:"$3" /p:"$4"

	# Xorg
	#echo xfreerdp /cert:tofu /drive:SHARE,"$(readlink -f "${HOME}")" +window-drag /usb:id,dev:046a:00b4 /w:1440 /h:900 /v:"$1" /u:"$2" /p:"$3"
	#xfreerdp /sec:nla +sec-ext /cert:tofu /drive:SHARE,"$(readlink -f "${HOME}")" +themes +decorations +menu-anims +window-drag /w:1440 /h:900 /v:"$1" /d:"$2" /u:"$3" /p:"$4"
	#xfreerdp /cert:tofu /drive:SHARE,"$(readlink -f "${HOME}")" \
	#	+window-drag /w:1440 /h:900 /v:"${HOST}" /u:"${USER}" /p:"${PASSWD}
	#xfreerdp /cert:tofu /drive:SHARE,"$(readlink -f "${HOME}")" \
	#	+window-drag /w:1440 /h:900 /v:"${HOST}" /u:"${USER}" /p:"${PASSWD}"
	echo "Try xfreerdp... "
	echo \
	xfreerdp /cert:tofu /drive:TOOLBOX,"${TOOLBOX}" \
		/auto-request-control \
		+async-channels +auto-reconnect \
		+bitmap-cache +gfx-progressive \
		+aero +themes +decorations +menu-anims +window-drag \
		/bpp:24 /w:1440 /h:900 \
		"${OPTION_HOST}" "${OPTION_DOMAIN}" "${OPTION_USER}" "${OPTION_PASSWD}" \
			| tee -a "/tmp/$(basename $0).log"

	#https_proxy="" exec xfreerdp /sec:nla /cert:tofu /drive:SHARE,"$(readlink -f "${HOME}")" +window-drag /w:1440 /h:900 /v:"$1" /d:"$2" /u:"$3" /p:"$4"
	https_proxy="" \
	xfreerdp /cert:tofu /drive:TOOLBOX,"${TOOLBOX}" \
		/auto-request-control \
		+async-channels +auto-reconnect \
		+bitmap-cache +gfx-progressive \
		+aero +themes +decorations +menu-anims +window-drag \
		/bpp:24 /w:1440 /h:900 \
		"${OPTION_HOST}" "${OPTION_DOMAIN}" "${OPTION_USER}" "${OPTION_PASSWD}"
	RET=$?

	[[ ${RET} -eq 0 || ${RET} -eq 5 ]] && return 0

	echo "xfreerdp failed, ret=${RET}"

	return ${RET}
}

function do_rdesktop() {
	command -v rdesktop || return 255

	[[ -z $1 ]] && return 255
	HOST="$1"

	[[ -z $2 ]] && PORT=3389
	OPTION_HOST="${HOST}:${PORT}"

	[[ -z $3 ]] || OPTION_DOMAIN="-d $3"
	[[ -z $4 ]] || OPTION_USER="-u $4"
	[[ -z $5 ]] || OPTION_PASSWD="-p $5"

	#rdesktop -m -N -C -z -x 0x80 -a 8 -k en-us -a 16 -g 1440x900 \
	#	-r sound:remote -r disk:RDP="$(readlink -f "${HOME}")" -r clipboard:CLIPBOARD \
	#	"${OPTION_DOMAIN}" "${OPTION_USER}" "${OPTION_PASSWD}" "${HOST}"

	#rdesktop -M -N -C -z -x 0x80 -a 8 -k en-us -a 16 -g 1440x900 \
	#	-r sound:remote -r disk:RDP="$(readlink -f "${HOME}")" -r clipboard:CLIPBOARD \
	#	-d "${DOMAIN}" -u "${USER}" -p "${PASSWD}" "${HOST}"

	#echo "${HOST}:${DOMAIN}:${USER}:${PASSWD}" >>"${REMOTE_HOST_FILE}"
	echo "Try rdesktop... "
	echo rdesktop -m -N -C -z -x 0x80 -a 8 -k en-us -a 16 -g 1440x900 \
		-r sound:remote -r disk:TOOLBOX="${TOOLBOX}" -r clipboard:CLIPBOARD \
		"${OPTION_DOMAIN}" "${OPTION_USER}" "${OPTION_PASSWD}" "${OPTION_HOST}" | tee -a "/tmp/$(basename $0).log"

	https_proxy="" rdesktop -m -N -C -z -x 0x80 -a 8 -k en-us -a 16 -g 1440x900 \
		-r sound:remote -r disk:TOOLBOX="${TOOLBOX}" -r clipboard:CLIPBOARD \
		"${OPTION_DOMAIN}" "${OPTION_USER}" "${OPTION_PASSWD}" "${OPTION_HOST}"
	RET=$?
	[[ ${RET} -eq 0 || ${RET} -eq 62 ]] && return 0

	echo "rdesktop failed, ret=${RET}"

	return ${RET}
}


function rdesk_one_string_old()
{
	local INSTR
	INSTR=$(zenity --width=400 --entry \
	--title "Remote Desktop" \
	--text "Connection params:" \
	--entry-text "hytera\150113013:******@10.161.53.50")

	[[ -z ${INSTR} ]] && die "Null param input!"

	local HOST
	HOST=$(echo "${INSTR}" | awk -F'@' '{print $2}')
	if [[ -z ${HOST} ]]
	then
		warn "Without domain/user/passwd."
		HOST="${INSTR}"
	else
		local DOMAINUSERPASSWD
		DOMAINUSERPASSWD=$(echo "${INSTR}" | awk -F'@' '{print $1}')
		local PASSWD
		PASSWD=$(echo "${DOMAINUSERPASSWD}" | awk -F':' '{print $2}')
		if [[ -z ${PASSWD} ]]
		then
			warn "Without password."
			local DOMAINUSER
			DOMAINUSER=${DOMAINUSERPASSWD}
		else
			local DOMAINUSER
			DOMAINUSER=$(echo "${DOMAINUSERPASSWD}" | awk -F':' '{print $1}')
		fi
		local USER
		USER=$(echo "${DOMAINUSER}" | awk -F"\\" '{print $2}')
		if [[ -z ${USER} ]]
		then
			warn "Without domain."
			local USER
			USER=${DOMAINUSER}
		else
			local DOMAIN
			DOMAIN=$(echo "${DOMAINUSER}" | awk -F"\\" '{print $1}')
		fi
	fi

	[[ 'X******' == "X${PASSWD}" ]] && PASSWD=Arety2018
	[[ -z ${DOMAIN} ]] || OPTION_DOMAIN="-d ${DOMAIN}"
	[[ -z ${USER}   ]] || OPTION_USER="-u ${USER}"
	[[ -z ${PASSWD} ]] || OPTION_PASSWD="-p ${PASSWD}"

	if ping -c 2 "${HOST}"
	then
		rdesktop_connect "${HOST}" "${DOMAIN}" "${USER}" "${PASSWD}"
	else
		zenity --width=180 --error --text="The host ${HOST} is unreachable!"
		exit 2
	fi
}


function add_new_session_with_vim()
{
	TMP_RDP_SESSION_FILE="$(mktemp --suffix=_new_rdp_session)"
	[[ -z ${TMP_RDP_SESSION_FILE} ]] && die "add_new_session(): Failed to create tmp file!"
	[[ -f "${TMP_RDP_SESSION_FILE}" ]] || die "add_new_session(): Failed to create tmp file!"

cat >"${TMP_RDP_SESSION_FILE}" <<EOF
Press "Shift" + "$" to input:
host____:
domain__:
username:
password:
descript:
EOF
	command -v vi && EDITOR=vi
	command -v vim && EDITOR=vim
	command -v nvim && EDITOR=nvim

	"${EDITOR}" +2 "${TMP_RDP_SESSION_FILE}"

	local RHOST="$(grep 'host____' ${TMP_RDP_SESSION_FILE} | awk -F: '{print $2}')"
	local DOMAIN="$(grep 'domain__' ${TMP_RDP_SESSION_FILE} | awk -F: '{print $2}')"
	local USERANME="$(grep 'username' ${TMP_RDP_SESSION_FILE} | awk -F: '{print $2}')"
	local PASSWORD="$(grep 'password' ${TMP_RDP_SESSION_FILE} | awk -F: '{print $2}')"
	local DESCRIPTION="$(grep 'descript' ${TMP_RDP_SESSION_FILE} | sed 's/\s\+/_/g' | awk -F: '{print $2}')"

	rm -fv "${TMP_RDP_SESSION_FILE}"

	echo "${RHOST}:${DOMAIN}:${USERANME}:${PASSWORD}:${DESCRIPTION}" | tee -a "${REMOTE_HOST_FILE}"

	exec "$0"
}


function rdesk_one_string()
{
	local INSTR
	INSTR=$(zenity --width=600 --entry \
	--title "Remote Desktop" \
	--text "Connection params:" \
	--entry-text "Hostname:Domain:Administrator:123456:Desciption")

	[[ -z ${INSTR} ]] && die "Null param input!"

	local HOST
	HOST=$(echo "${INSTR}" | awk -F: '{print $1}')
	if [[ -z ${HOST} ]]
	then
		warn "Param host is Null."
	else
		local DOMAIN
		DOMAIN=$(echo "${INSTR}" | awk -F: '{print $2}')
		if [[ -z ${DOMAIN} ]]
		then
			warn "Without domain."
		else
			local USER
			USER=$(echo "${INSTR}" | awk -F: '{print $3}')
			if [[ -z ${USER} ]]
			then
				warn "Without user."
			else
				local PASSWD
				PASSWD=$(echo "${INSTR}" | awk -F: '{print $4}')
				if [[ -z ${PASSWD} ]]
				then
					warn "Without password."
				fi
			fi
		fi
	fi

	#[[ 'X******' == "X${PASSWD}" ]] && PASSWD=Arety2018
	#[[ -z ${DOMAIN} ]] || OPTION_DOMAIN="-d ${DOMAIN}"
	#[[ -z ${USER}   ]] || OPTION_USER="-u ${USER}"
	#[[ -z ${PASSWD} ]] || OPTION_PASSWD="-p ${PASSWD}"

	if ping -c 2 "${HOST}"
	then
		rdesktop_connect "${HOST}" "${DOMAIN}" "${USER}" "${PASSWD}"
	else
		zenity --width=180 --error --text="The host ${HOST} is unreachable!"
		exit 2
	fi
}


function new_session_with_zenity()
{
	local INSTR
	INSTR=$(zenity --forms --title="Remote Desktop" \
		--text="With params:" \
		--separator=":" \
		--add-entry="Host*" \
		--add-entry="Port" \
		--add-entry="Domain" \
		--add-entry="User*" \
		--add-password="Password*" \
		--add-entry="Descript")

	echo "INSTR=${INSTR}"

	[[ -z ${INSTR} ]] && {
		echo "Null param input!"
		#new_session_with_zenity "$@"
		#return 255
		exec "$0" "$@"
	}

	local HOST
	HOST=$(echo "${INSTR}" | awk -F: '{print $1}')
	[[ -z ${HOST} ]] && {
		echo "Host name is absent!"
		new_session_with_zenity "${HOST}:${PORT}:${DOMAIN}:${USER}:${PASSWD}:${DESC}"
	}

	local PORT
	PORT=$(echo "${INSTR}" | awk -F: '{print $2}')

	local DOMAIN
	DOMAIN=$(echo "${INSTR}" | awk -F: '{print $3}')

	local USER
	USER=$(echo "${INSTR}" | awk -F: '{print $4}')
	[[ -z ${USER} ]] && {
		echo "User name is absent!"
		new_session_with_zenity "${HOST}:${PORT}:${DOMAIN}:${USER}:${PASSWD}:${DESC}"
	}

	local PASSWD
	PASSWD=$(echo "${INSTR}" | awk -F: '{print $5}')
	[[ -z ${PASSWD} ]] && {
		echo "Password is absent!"
		new_session_with_zenity "${HOST}:${PORT}:${DOMAIN}:${USER}:${PASSWD}:${DESC}"
	}

	local DESC
	DESC=$(echo "${INSTR}" | awk -F: '{print $6}')

	echo "${HOST}:${PORT}:${DOMAIN}:${USER}:${PASSWD}:${DESC}" | tee -a "${REMOTE_HOST_FILE}" \
		|| die "Failed to create new session!"

	rdesktop_connect "${HOST}:${PORT}:${DOMAIN}:${USER}:${PASSWD}:${DESC}" || {
		echo "rdesktop_connect()=$?"
		default_edit "${REMOTE_HOST_FILE}"
		exec "$0" "$@"
	}
}


function default_edit() {
	command -v vi >/dev/null && EDITOR=vi
	command -v vim >/dev/null && EDITOR=vim
	command -v nvim >/dev/null && EDITOR=nvim
	command -v gedit >/dev/null && EDITOR=gedit
	#command -v subl && EDITOR=subl

	"${EDITOR}" "$@"
}


function zenity_edit() {
	OPTION=$(zenity --width=250 --height=210 \
		--list --title "Zenity Select Editor Dialog" \
		--column "" \
		--hide-header \
		"sublime_text" \
		"gedit" \
		"neovim" \
		"[Quit]")

	EDITOR=vim
	case ${OPTION} in
		"sublime_text")
			EDITOR=subl;;
		"gedit")
			EDITOR=gedit;;
		"neovim")
			EDITOR=nvim;;
		"[Quit]")
			exit 0;;
	esac

	command -v "${EDITOR}" >/dev/null || {
		zenity --warning --width=200 --text "${EDITOR} was not found, try other editor!"
		zenity_edit "$@"
	}

	"${EDITOR}" "$@"
}


function rdesktop_connect()
{
	echo "$@"

	[[ -z "$1" ]] && die "rdesktop_connect(): Null string input."

	HOST="$(echo "$1" | awk -F: '{print $1}')"
	[[ -z "${HOST}" ]] && die "HOST is Null!"

	PORT="$(echo "$1" | awk -F: '{print $2}')"
	#[[ -z "${HOST}" ]] && die "PORT is Null!"

	DOMAIN="$(echo "$1" | awk -F: '{print $3}')"
	#[[ -z "${DOMAIN}" ]] && die "DOMAIN is Null!"

	USER="$(echo "$1" | awk -F: '{print $4}')"
	#[[ -z "${USER}" ]] && die "USER is Null!"

	PASSWD="$(echo "$1" | awk -F: '{print $5}')"
	#[[ -z "${PASSWD}" ]] && die "PASSWD is Null!"

	if ping -c 2 "${HOST}"
	then
		do_xfreerdp "${HOST}" "${PORT}" "${DOMAIN}" "${USER}" "${PASSWD}" # ||
		#do_rdesktop "${HOST}" "${PORT}" "${DOMAIN}" "${USER}" "${PASSWD}"
		echo "All done!"
	else
		zenity --width=180 --error --text="The host ${HOST} is unreachable!"
		exit 2
	fi
}

# Main Process
[[ $# -ge 4 ]] && {
	[[ -z "$1" ]] && die "HOST is Null!"
	[[ -z "$3" ]] && die "USER is Null!"
	[[ -z "$4}" ]] && die "PASSWD is Null!"

	grep "$1:$2:$3:$4" "${REMOTE_HOST_FILE}" || {
		echo "$1:$2:$3:$4:$5_$6_$7_$8_$9" >>"${REMOTE_HOST_FILE}"
	}

	do_xfreerdp "$1" "$2" "$3" "$4" || do_rdesktop "$1" "$2" "$3" "$4"
	exit $?
}

check_cmd "zenity"

[[ -f "${REMOTE_HOST_FILE}" ]] || {
	touch "${REMOTE_HOST_FILE}" || die "Failed to create ${REMOTE_HOST_FILE}!"
}

#unset https_proxy

# Debug:
#cat "${REMOTE_HOST_FILE}" | while read X; do
#	echo "FALSE \"${X}\""
#done

#		--column "Host:Domain:User:Passwd" \
#		--column "--------------------------------------------------" \
OPTN=$(zenity --width=700 --height=600 \
		--list --title "Zenity Remote Desktop Dialog" \
		--column "" \
		--hide-header \
		$(cat "${REMOTE_HOST_FILE}" | while read X; do
			echo "${X}"
		done
		) \
		"[Create new remote connection...]" \
		"[Edit connection list...]" \
		"[Edit this menu...]" \
		"[Quit]")

#zenity --width=500 --info --text="Confirm selection: ${OPTN}"

case ${OPTN} in
	"[Create new remote connection...]")
		#rdesk_one_string
		#rdesk_one_by_one
		#add_new_session_with_vim
		new_session_with_zenity
		;;
	"[Edit connection list...]")
		#zenity_edit "${REMOTE_HOST_FILE}"
		default_edit "${REMOTE_HOST_FILE}"
		exec $0 "$@"
		;;
	"[Edit this menu...]")
		#zenity_edit "$0"
		default_edit "$(readlink -f $0)"
		exec $0 "$@"
		;;
	"[Quit]")
		exit 0
		;;
	*)
		#zenity --width=120 --error --text="Invalid option!";;
		rdesktop_connect "${OPTN}"
		;;
esac

# xfreerdp /cert:tofu /drive:SHARE,"$(readlink -f "${HOME}")" +window-drag /w:1440 /h:900 /v:"${HOST}" /u:"${USER}" /p:"${PASSWD}"
