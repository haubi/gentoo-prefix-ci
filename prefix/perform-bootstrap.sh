#! /usr/bin/env bash

set -x
set -e

TRAPS=()

trap 'set +e; _TRAPS=("${TRAPS[@]}"); TRAPS=(); for TRAP in "${_TRAPS[@]}"; do ${TRAP}; done' 0

die() {
	if (( $# > 0 ))
	then
		printf "%s" "ERROR: " "$@"
		printf "\\n"
	fi
	exit 1
}

default-settings() {
	BOOTSTRAP_PREFIX_SH=
	PREFIX=
	RESUME=false
	LINUX32=
	export PREFIX_DISABLE_RAP=yes
	unset GENTOO_MIRRORS
	unset LATEST_TREE_YES TESTING_PV
	unset ftp_proxy http_proxy https_proxy RSYNC_PROXY 
}

decode-settings() {
	local arg

	for arg in "$@"
	do
		case ${arg} in
		--bootstrap-prefix-sh=*)
			BOOTSTRAP_PREFIX_SH=${arg#--bootstrap-prefix-sh=}
			;;
		--prefix=*)
			PREFIX=${arg#--prefix=}
			;;
		--rap=yes)
			unset PREFIX_DISABLE_RAP
			;;
		--rap=no)
			export PREFIX_DISABLE_RAP=yes
			;;
		--resume=yes)
			RESUME=true
			;;
		--force-32bit=yes)
			LINUX32=linux32
			;;
		--force-32bit=no)
			unset LINUX32
			;;
		--resume=no)
			RESUME=false
			;;
		--tree-date=latest)
			export LATEST_TREE_YES=1
			;;
		--portage-pv=testing)
			export TESTING_PV=latest
			;;
		--proxy=)
			unset ftp_proxy http_proxy https_proxy RSYNC_PROXY 
			;;
		--proxy=*)
			ftp_proxy=${arg#--proxy=}
			http_proxy=${ftp_proxy}
			https_proxy=${ftp_proxy}
			RSYNC_PROXY=${ftp_proxy#*://}
			export ftp_proxy http_proxy https_proxy RSYNC_PROXY 
			;;
		--gentoo-mirrors=)
			unset GENTOO_MIRRORS
			;;
		--gentoo-mirrors=*)
			export GENTOO_MIRRORS="${arg#--gentoo-mirrors=}"
			;;
		esac
	done
}

validate-settings() {
	[[ ${BOOTSTRAP_PREFIX_SH} ]] || die "missing --bootstrap-prefix-sh argument"
	[[ -r ${BOOTSTRAP_PREFIX_SH} ]] || die "cannot read bootstrap-prefix-sh ${BOOTSTRAP_PREFIX_SH}"
	[[ ${PREFIX} ]] || die "missing --prefix argument"
	[[ ! -r ${PREFIX}/stage1.log ]] || ${RESUME} || die "bootstrap was already started, not resuming ${PREFIX}"
}

perform-bootstrap() {
	mkdir -p "${PREFIX}"
	>> "${PREFIX}"/bootstrap.log
	tail -f "${PREFIX}"/bootstrap.log &
	TRAPS+=( "sleep 5" "kill $!" )
	${LINUX32} "${BOOTSTRAP_PREFIX_SH}" "${PREFIX}" noninteractive >> "${PREFIX}"/bootstrap.log 2>&1
}

default-settings
decode-settings "$@"
validate-settings
perform-bootstrap

true
