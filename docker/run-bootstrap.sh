#! /bin/bash

die() {
	${1+:} false && printf "$@" >&2
	exit 1
}

dockerfiles=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")
[[ -x ${dockerfiles}/run-bootstrap.sh ]] || die "Failed to find dockerfiles!"

docker_cleanup=false
docker_os=
bootstrap_opts=

for arg in "$@"
do
	case ${arg} in
	--docker-cleanup) docker_cleanup=: ;;
	--docker-os=*) docker_os=${arg#--docker-os=} ;;
	*) bootstrap_opts+=" ${arg}" ;;
	esac
done

if ${docker_cleanup}
then
	waited=0
	lockdir=${TMPDIR:-/tmp}/docker-starting
	while ! mkdir "${lockdir}"
	do
		echo "Not cleaning up while another agent starts up docker images..."
		cat "${lockdir}"/running
		sleep 30
		((waited=waited+1))
		if ((waited > 6))
		then
			echo "Cannot await end of another agent starting up docker images,"
			cat "${lockdir}"/running
			echo "If there is no other agent starting up docker images,"
			echo "you need to remove directory ${lockdir}."
			exit 1
		fi
	done

	trap "rm -rf '${lockdir}'" 0

	echo "pid $$ using AGENT_BUILDDIRECTORY=${AGENT_BUILDDIRECTORY}" > "${lockdir}"/running

	echo "Cleaning up unused docker containers (failing ones are in use)..."
	docker container prune -f || :
	echo "Cleaning up unused docker images (failing ones are in use)..."
	docker images -q | xargs docker rmi || :

	(
		# Wait for docker build to really use the new image
		# and container before releasing the cleanup lock.
		sleep 10
		rm -rf "${lockdir}"
	) &
fi

echo "Bootstrap based on ${dockerfiles}/Dockerfile.${docker_os}"
echo "Bootstrap options: ${bootstrap_opts}"
cat "${dockerfiles}"/Dockerfile.{${docker_os},linux-user,prefix-bootstrap,entrypoint} \
| docker build -f - --build-arg=BOOTSTRAP_OPTS="${bootstrap_opts}" .

ret=$?

trap '' 0

if ${docker_cleanup}
then
	wait # for the sleep releasing the cleanup lock
fi

exit ${ret}
