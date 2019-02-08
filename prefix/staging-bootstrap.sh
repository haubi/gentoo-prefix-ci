#! /usr/bin/env bash

exec 2>&1

. /etc/profile

set -ex

die() {
	if (( $# > 0 ))
	then
		printf "%s" "ERROR: " "$@"
		printf "\\n"
	fi
	exit 1
}

SOURCES=
STAGING=

for arg in "$@"
do
	case ${arg} in
	--sources=*) SOURCES=${arg#--sources=} ;;
	--staging=*) STAGING=${arg#--staging=} ;;
	esac
done

[[ -r ${SOURCES%/}/. ]] || die 'Missing --sources directory argument.'
[[ -r ${STAGING%/}/. ]] || die 'Missing --staging directory argument.'

[[ -x ${SOURCES%/}/prefix/perform-bootstrap.sh ]] ||
	die "missing ${SOURCES%/}/prefix/perform-bootstrap.sh"

cd "${STAGING}" || die "failed to enter staging directory (${STAGING})"

(
	unset https_proxy
	[[ -z ${AGENT_PROXYURL} ]] || export https_proxy=${AGENT_PROXYURL}
	wget -O ./bootstrap-prefix.sh https://gitweb.gentoo.org/repo/proj/prefix.git/plain/scripts/bootstrap-prefix.sh
)
chmod +x ./bootstrap-prefix.sh

"${SOURCES%/}/prefix/perform-bootstrap.sh" \
	--bootstrap-prefix-sh="${STAGING%/}/bootstrap-prefix.sh" \
	--prefix="${STAGING%/}"/gentoo-prefix \
	--resume=no \
	--rap=no \
	--tree-date=latest \
	--portage-pv=testing \
	--proxy="${AGENT_PROXYURL}"
