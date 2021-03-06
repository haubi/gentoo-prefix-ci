Set-PSDebug -Trace 2

$cygroot = $env:BUILD_STAGINGDIRECTORY
Set-Location -Path $cygroot

# keep fork working even across replaced binaries
.\bin\mkdir.exe --mode=a=rwxt /var/run/cygfork
.\bin\uname.exe -a
.\bin\bash.exe --noprofile --norc -c 'declare -p > agentenv.dump'

# VSTS git does checkout in text mode, need to map into cygwin world
.\bin\mkdir.exe --mode=a=rwxt -p /sources
.\bin\bash.exe --noprofile --norc -c 'exec 2>&1; set -x; sources=$(/bin/cygpath -m \"${BUILD_SOURCESDIRECTORY}\"); sources=${sources// /\\\\040}; echo \"${sources} /sources auto text,user 0 0\" >> /etc/fstab'
.\bin\mount.exe

.\bin\bash.exe --noprofile --norc -c 'exec 2>&1; if [[ ${BUILD_BINARIESDIRECTORY} ]] ; then d=\"$(/bin/cygpath -u \"${BUILD_BINARIESDIRECTORY}\")\" && /bin/mkdir -p \"${d}/gentoo-distfiles\" && distdir=\"--gentoo-distdir=${d}/gentoo-distfiles\"; fi; set -x; upload=yes; [[ $(/bin/hostname),$(/bin/uname -r) == vsts19-ssi-01,*-gentoo-* ]] || upload=no; usecpucores=${NUMBER_OF_PROCESSORS}; (( ${usecpucores} >= 2 )) || usecpucores=2; /bin/bash /sources/prefix/staging-bootstrap.sh --sources=/sources --staging=\"$(/bin/cygpath -u \"${BUILD_STAGINGDIRECTORY}\")\" ${BUILD_BINARIESDIRECTORY:+--gentoo-distdir=\"$(/bin/cygpath -u \"${BUILD_BINARIESDIRECTORY}/gentoo-distfiles\")\"} --upload-results=${upload} --use-cpu-cores=${usecpucores}'
exit $LastExitCode
