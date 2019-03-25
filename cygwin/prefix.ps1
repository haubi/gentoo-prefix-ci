Set-PSDebug -Trace 2

$cygroot = $env:BUILD_STAGINGDIRECTORY
Set-Location -Path $cygroot

# keep fork working even across replaced binaries
.\bin\mkdir.exe --mode=a=rwxt /var/run/cygfork
.\bin\bash.exe --noprofile --norc -c 'declare -p > agentenv.dump'

# VSTS git does checkout in text mode, need to map into cygwin world
.\bin\mkdir.exe --mode=a=rwxt -p /sources
.\bin\bash.exe --noprofile --norc -c 'exec 2>&1; set -x; sources=$(/bin/cygpath -m \"${BUILD_SOURCESDIRECTORY}\"); sources=${sources// /\\\\040}; echo \"${sources} /sources auto text,user 0 0\" >> /etc/fstab'
.\bin\mount.exe

.\bin\bash.exe --noprofile --norc -c 'exec 2>&1; if [[ ${AGENT_WORKFOLDER} ]] ; then d=\"$(/bin/cygpath -u \"${AGENT_WORKFOLDER}\")\" && mkdir -p \"${d}/gentoo-distfiles\" && distdir=\"--gentoo-distdir=${d}/gentoo-distfiles\"; fi; set -x; upload=yes; [[ $(/bin/hostname) == vsts19-ssi-01 ]] || upload=no; /bin/bash /sources/prefix/staging-bootstrap.sh --sources=/sources --staging=\"$(/bin/cygpath -u \"${BUILD_STAGINGDIRECTORY}\")\" ${AGENT_WORKFOLDER:+--gentoo-distdir=\"$(/bin/cygpath -u \"${AGENT_WORKFOLDER}/gentoo-distfiles\")\"} --upload-results=${upload}'
exit $LastExitCode
