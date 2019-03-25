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
	UPLOAD_RESULTS=false
	UPLOAD_RESULTS_TO="rsync1.prefix.bitzolder.nl::gentoo-portage-bootstraps"
	export PREFIX_DISABLE_RAP=yes
	unset GENTOO_MIRRORS
	unset DISTDIR
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
		--upload-results=yes)
			UPLOAD_RESULTS=:
			;;
		--upload-results=no)
			UPLOAD_RESULTS=false
			;;
		--gentoo-mirrors=)
			unset GENTOO_MIRRORS
			;;
		--gentoo-mirrors=*)
			export GENTOO_MIRRORS="${arg#--gentoo-mirrors=}"
			;;
		--gentoo-distdir=)
			unset DISTDIR
			;;
		--gentoo-distdir=*)
			export DISTDIR=${arg#--gentoo-distdir=}
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
	TRAPS+=( "maybe-upload-results --start-seconds=${SECONDS}" )
	${LINUX32} "${BOOTSTRAP_PREFIX_SH}" "${PREFIX}" noninteractive 2>&1 |
		tee -a "${PREFIX}"/bootstrap.log
	return ${PIPESTATUS[0]}
}

maybe-upload-results() {
	local end_seconds=${SECONDS}
	local start_seconds=0

	${UPLOAD_RESULTS} || return 0
	[[ -r ${PREFIX}/. ]] || return 0

	[[ -x /usr/bin/rsync ]] || die "Missing /usr/bin/rsync for upload"

	local hostname=$(hostname)
	[[ ${hostname} ]] || die "Failed to identify hostname for uplad"

	local chost=$(${LINUX32} "${BOOTSTRAP_PREFIX_SH}" chost.guess x || :)
	[[ ${chost} ]] || die "Failed to identify chost for upload"

	local date=$(date '+%Y%m%d' -d "$(<"${PREFIX}"/usr/portage/timestamp)" || :)
	[[ ${date} ]] || die "Failed to identify date for uplad"

	local arg
	for arg in "$@"
	do
		case ${arg} in
		--start-seconds=*)
			start_seconds=${arg#--start-seconds=}
			;;
		esac
	done
	echo $((end_seconds - start_seconds)) > "${PREFIX}"/elapsedtime

	rsync -q /dev/null "${UPLOAD_RESULTS_TO}"/${hostname}-$$/
	rsync -q /dev/null "${UPLOAD_RESULTS_TO}"/${hostname}-$$/${chost}/
	rsync -rltv \
		--exclude=work/ \
		--exclude=homedir/ \
		--exclude=files \
		--exclude=distdir/ \
		--exclude=image/ \
		"${PREFIX}"/{stage,.stage}* \
		"${BOOTSTRAP_PREFIX_SH}" \
		"${PREFIX}"/startprefix \
		"${PREFIX}"/elapsedtime \
		"${PREFIX}"/var/tmp/portage \
		"${PREFIX}"/var/log/emerge.log \
		"${UPLOAD_RESULTS_TO}"/${hostname}-$$/${chost}/${date}/
	rsync -q /dev/null "${UPLOAD_RESULTS_TO}"/${hostname}-$$/${chost}/${date}/push-complete/
}

default-settings
decode-settings "$@"
validate-settings
perform-bootstrap

exit $?
