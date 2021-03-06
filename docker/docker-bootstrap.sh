#! /usr/bin/env bash

set -x

uname

die() {
	${1+printf '*** ' "$@" >&2}
	exit 1
}

TRAPS=()

addtrap() {
	local trap
	for onetrap in "$@"
	do
		# let them execute in reverse order
		TRAPS=( "${onetrap}" "${TRAPS[@]}" )
	done
}

runtraps() {
	local traps=( "${TRAPS[@]}" )
	TRAPS=()
	for onetrap in "${traps[@]}"
	do
		eval "${onetrap}"
	done
}

trap 'runtraps' 0

TOPDIR=$(dirname "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")

[[ ${TOPDIR}/docker/docker-bootstrap.sh -ef ${BASH_SOURCE[0]} ]] || die "Failed to find myself (from ${BASH_SOURCE[0]})."

cd "${TOPDIR}" || die

image_basename=       # "gentooprefix/prefix"
image_namepart_guest= # "-rap" or "-guest"
image_namepart_bits=  # "-64bit" or "-32bit"
from_os=              # "fedora28"
from_image_tag= # 'intermediate' upon --resume
to_image_tag='latest' # 'intermediate' upon --timeout
docker_cleanup=false
docker_push=false
force_rap=true
force_32bit=false
bootstrap_opts=
resume_opts=
build_args=()

proxyvars=( 
	HTTP_PROXY
	http_proxy
	HTTPS_PROXY
	https_proxy
	FTP_PROXY
	ftp_proxy
)

for arg in "$@"
do
	case ${arg} in
	--image-basename=*)
		image_basename=${arg#--docker-image-basename=}
		;;
	--force-32bit=yes)
		bootstrap_opts+=" --force-32bit=yes"
		image_namepart_bits="-32bit"
		;;
	--force-32bit=no)
		bootstrap_opts+=" --force-32bit=no"
		image_namepart_bits="-64bit"
		;;
	--guest=no)
		bootstrap_opts+=" --rap=yes"
		image_namepart_guest="-rap"
		;;
	--guest=yes)
		bootstrap_opts+=" --rap=no"
		image_namepart_guest="-guest"
		;;
	--resume=no)
		resume_opts+=" ${arg}"
		from_image_tag=
		;;
	--resume=yes)
		resume_opts+=" ${arg}"
		from_image_tag='intermediate'
		;;
	--timeout=*)
		resume_opts+=" ${arg}"
		to_image_tag='intermediate'
		;;
	--from-os=*)
		from_os=${arg#--from-os=}
		;;
	--variant=*_*_*)
		variant=${arg#--variant=}
		case ${variant} in
		rap_*)
			image_namepart_guest="-rap"
			bootstrap_opts+=" --rap=yes"
			variant=${variant#rap_}
			;;
		guest_*)
			image_namepart_guest="-guest"
			bootstrap_opts+=" --rap=no"
			variant=${variant#guest_}
			;;
		esac
		case ${variant} in
		32bit_*)
			image_namepart_bits="-32bit"
			bootstrap_opts+=" --force-32bit=yes"
			variant=${variant#32bit_}
			;;
		64bit_*)
			image_namepart_bits="-64bit"
			bootstrap_opts+=" --force-32bit=no"
			variant=${variant#64bit_}
			;;
		esac
		from_os=${variant}
		;;
	--docker-cleanup)
		docker_cleanup=:
		;;
	--docker-push=no)
		docker_push=false
		;;
	--docker-push=yes)
		docker_push=:
		;;
	--proxy=*)
		arg=${arg#--proxy=}
		for v in ${proxyvars[*]}
		do
			export "${v}=${arg}"
		done
		;;
	--trace)
		PS4='($LINENO)+ '
		set -x
		;;
	*) resume_opts+=" ${arg}" ;;
	esac
done

for v in ${proxyvars[*]}
do
	[[ ${!v} ]] || continue
	build_args+=( "--build-arg=${v}=${!v}" )
done

image_name="${image_basename:-"gentooprefix/prefix"}${image_namepart_guest}${image_namepart_bits}-${from_os}"

lockdir="${TMPDIR:-/tmp}/docker-lock"
mypidfile="${lockdir}/pid.$$"
cleanuplock="${lockdir}/cleanup"

addtrap "rmdir '${lockdir}' 2>/dev/null"
if ! mkdir "${lockdir}" 2>/dev/null
then
	# something is running already, eventually performing cleanup too
	docker_cleanup=false
fi

addtrap "rm -f '${mypidfile}'"
printf "'%s' \\\n" "AGENT_BUILDDIRECTORY=${AGENT_BUILDDIRECTORY}" "$0" "$@" > "${mypidfile}" || die

trycount=0
while (( ++trycount <= 30 ))
do
	# acquire the cleanup lock
	if ! mkdir "${cleanuplock}"
	then
		sleep 1
		continue
	fi
	printf "'%s' \\\n" "AGENT_BUILDDIRECTORY=${AGENT_BUILDDIRECTORY}" "$0" "$@" > "${cleanuplock}/pid" || die
	break
done

if [[ ! -e ${mypidfile} ]]
then
	echo "Another process seems to be cleaning up:" >&2
	cat "${cleanuplock}/pid" >&2
	echo "If there is no other process running," >&2
	echo "consider removing ${cleanuplock} directory." >&2
	die "Cannot await another process cleaning up."
fi

if ${docker_cleanup}
then
	echo "Cleaning up unused docker containers (failing ones are in use)..."
	docker container prune -f || :
	echo "Cleaning up unused docker images (failing ones are in use)..."
	docker images -q | xargs docker rmi || :
fi

# release the cleanup lock
rm -f "${cleanuplock}/pid"
rmdir "${cleanuplock}"

if [[ ! ${from_image_tag} ]]
then
	from_image_tag='initial'
	[[ -r ${TOPDIR}/docker/Dockerfile.${from_os} ]] || die "Missing Dockerfile.${from_os}"
	echo "Creating image based on ${TOPDIR}/docker/Dockerfile.${from_os}"
	echo "Bootstrap options: ${bootstrap_opts}"
	docker build \
		-f "${TOPDIR}"/docker/Dockerfile.${from_os} \
		"${build_args[@]}" \
		--build-arg=BOOTSTRAP_OPTS="${bootstrap_opts}" \
		--tag="${image_name}:${from_image_tag}" \
		.
fi

docker_container=$(
	docker run \
		--detach=true \
		"${image_name}:${from_image_tag}" \
		-c "type sleep 2>/dev/null || . /etc/profile; sleep 10; ./sources/docker/resume-bootstrap.sh ${https_proxy:+--proxy="${https_proxy}"} ${resume_opts}"
) || die "Failed to run container using ${image_name}:${from_image_tag}."

docker attach "${docker_container}"
ret=$?

if [[ ${ret} != 0 && ${to_image_tag} == 'latest' ]]
then
	# do not tag failed image as latest
	to_image_tag='failed'
fi

docker commit "${docker_container}" "${image_name}:${to_image_tag}" \
|| die "Failed to commit container ${docker_container} to ${image_name}:${to_image_tag}"

if ${docker_push}
then
	docker push "${image_name}:${to_image_tag}" \
	|| die "Failed to push image ${image_name}:${to_image_tag}"
fi

exit ${ret}
