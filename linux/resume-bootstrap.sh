#! /usr/bin/env bash

set -x

die() {
	${1+printf '*** ' "$@" >&2}
	exit 1
}

TOPDIR=$(dirname "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")

[[ ${TOPDIR}/linux/resume-bootstrap.sh -ef ${BASH_SOURCE[0]} ]] || die "Failed to find myself (from ${BASH_SOURCE[0]})."

cd "${TOPDIR}" || die

opts=()

for arg in ${BOOTSTRAP_OPTS} "$@"
do
	case ${arg} in
	--proxy=*)
		arg=${arg#--proxy=}
		for v in \
			HTTP_PROXY \
			http_proxy \
			HTTPS_PROXY \
			https_proxy \
			FTP_PROXY \
			ftp_proxy \
		; do
			export "${v}=${arg}"
		done
		;;
	*)
		opts+=( "${arg}" )
		;;
	esac
done

if [[ ! -x ./bootstrap-prefix.sh ]]
then
	wget -O ./bootstrap-prefix.sh \
		https://gitweb.gentoo.org/repo/proj/prefix.git/plain/scripts/bootstrap-prefix.sh \
	|| die
	chmod +x ./bootstrap-prefix.sh || die
fi

./prefix/perform-bootstrap.sh \
	--bootstrap-prefix-sh="$(pwd)"/bootstrap-prefix.sh \
	--prefix=/tmp/gentoo \
	--tree-date=latest \
	--portage-pv=testing \
	--resume=yes \
	"${opts[@]}" \
	"$@"
